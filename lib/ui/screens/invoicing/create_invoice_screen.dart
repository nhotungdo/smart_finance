import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/providers/ocr_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/ocr_result_model.dart';
import 'package:smart_finance/domain/services/finance_calculator.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _amountController = TextEditingController();
  final _subtotalController = TextEditingController();

  bool _isPopulatedFromOcr = false;
  bool _isSaving = false;
  int _vatRate = 10;
  final String _invoiceId = const Uuid().v4();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _selectedImagePath;
  OcrResultModel? _ocrResult;
  late final AnimationController _scanController;
  late final Animation<double> _scanProgress;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanProgress = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _taxCodeController.dispose();
    _amountController.dispose();
    _subtotalController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _onSmartScanPressed() async {
    final supportsCamera =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (supportsCamera)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Chụp hóa đơn'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final pickedImage = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (pickedImage == null) return;

    final bytes = await pickedImage.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImageBytes = bytes;
      _selectedImageName = pickedImage.name;
      _selectedImagePath = pickedImage.path;
      _isPopulatedFromOcr = false;
      _ocrResult = null;
    });

    final animationFuture = _scanController.forward(from: 0);
    final scanFuture = ref
        .read(ocrProvider.notifier)
        .scanImage(pickedImage.path, _invoiceId);
    await Future.wait<void>([animationFuture, scanFuture]);

    if (!mounted) return;
    final ocrState = ref.read(ocrProvider);
    if (ocrState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể quét hóa đơn: ${ocrState.error}')),
      );
      return;
    }

    final result = ocrState.value;
    if (result == null) return;
    final raw = jsonDecode(result.rawMockData ?? '{}') as Map<String, dynamic>;
    final rawVatRate = (raw['vat_rate'] as num?)?.round() ?? 10;
    setState(() {
      _ocrResult = result;
      _supplierController.text = result.extractedSupplierName ?? '';
      _taxCodeController.text = result.extractedTaxCode ?? '';
      _subtotalController.text =
          (raw['subtotal'] as num?)?.round().toString() ?? '';
      _vatRate = rawVatRate == 8 ? 8 : 10;
      _isPopulatedFromOcr = true;
      _recalculateTotal();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã quét dữ liệu, hãy kiểm tra trước khi lưu.'),
      ),
    );
  }

  void _recalculateTotal() {
    final subtotal = int.tryParse(
      _subtotalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (subtotal == null) {
      _amountController.clear();
      return;
    }
    final vat = FinanceCalculator.calculateVat(
      subtotal: subtotal,
      vatRate: _vatRate,
    );
    _amountController.text = vat.total.toString();
  }

  Future<void> _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    final profile = await ref.read(currentUserProfileProvider.future);
    final companyId = profile?.companyId;
    if (user == null || companyId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản chưa có hồ sơ doanh nghiệp.')),
      );
      return;
    }

    final subtotal = int.parse(
      _subtotalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final vat = FinanceCalculator.calculateVat(
      subtotal: subtotal,
      vatRate: _vatRate,
    );

    final invoice = InvoiceModel(
      id: _invoiceId,
      companyId: companyId,
      uploadedBy: user.id,
      supplierName: _supplierController.text,
      supplierTaxCode: _taxCodeController.text,
      invoiceNumber:
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      invoiceDate: DateTime.now(),
      subtotal: vat.subtotal,
      vatRate: vat.vatRate,
      vatAmount: vat.vatAmount,
      totalAmount: vat.total,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      scanStatus: _isPopulatedFromOcr
          ? InvoiceScanStatus.scanned
          : InvoiceScanStatus.notScanned,
    );

    setState(() => _isSaving = true);
    try {
      await ref
          .read(invoicesProvider.notifier)
          .saveReviewedInvoice(
            invoice: invoice,
            imageBytes: _selectedImageBytes,
            imageFileName: _selectedImageName,
            localImagePath: _selectedImagePath,
            ocrResult: _ocrResult,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu hóa đơn: $error')));
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hóa đơn đã được lưu!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.go('/invoicing/preview/$_invoiceId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 768;

    final ocrState = ref.watch(ocrProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 896),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, isDesktop, ocrState),
                  const SizedBox(height: 32),

                  // Wrap the sections in a responsive row/col for Bento styling
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildClientDetails(theme)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildTotalDetails(theme)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildClientDetails(theme),
                        const SizedBox(height: 20),
                        _buildTotalDetails(theme),
                      ],
                    ),

                  const SizedBox(height: 20),
                  _buildLineItems(context, theme, ocrState.isLoading),
                  const SizedBox(height: 20),
                  _buildActions(context, theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDesktop, AsyncValue ocrState) {
    return BentoCard(
      padding: const EdgeInsets.all(32),
      child: Flex(
        direction: isDesktop ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: isDesktop
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạo hóa đơn mới',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Soạn hóa đơn để lưu vào hệ thống.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isDesktop) const SizedBox(height: 24),
          SmartButton(
            onPressed: ocrState.isLoading ? null : _onSmartScanPressed,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ocrState.isLoading)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.document_scanner_rounded),
                const SizedBox(width: 8),
                Text(ocrState.isLoading ? 'Đang quét...' : 'Smart Scan AI'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetails(ThemeData theme) {
    return BentoCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoSectionHeader(
            title: 'Chi tiết đối tác',
            action: Icon(
              Icons.business_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          SmartTextField(
            controller: _supplierController,
            labelText: 'Tên nhà cung cấp / khách hàng',
            validator: (val) =>
                val == null || val.isEmpty ? 'Bắt buộc nhập' : null,
          ),
          const SizedBox(height: 16),
          SmartTextField(
            controller: _taxCodeController,
            labelText: 'Mã số thuế',
          ),
        ],
      ),
    );
  }

  Widget _buildTotalDetails(ThemeData theme) {
    return BentoCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BentoSectionHeader(
            title: 'Tổng tiền',
            action: Icon(
              Icons.monetization_on_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          SmartTextField(
            controller: _subtotalController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            labelText: 'Tiền trước thuế (VNĐ)',
            onChanged: (_) => setState(_recalculateTotal),
            validator: (value) {
              final subtotal = int.tryParse((value ?? '').trim());
              return subtotal == null || subtotal <= 0
                  ? 'Số tiền phải lớn hơn 0'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 8, label: Text('VAT 8%')),
              ButtonSegment(value: 10, label: Text('VAT 10%')),
            ],
            selected: {_vatRate},
            onSelectionChanged: (selection) {
              setState(() {
                _vatRate = selection.first;
                _recalculateTotal();
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tiền VAT', style: theme.textTheme.bodyMedium),
              Text(
                _subtotalController.text.isEmpty
                    ? '0 VNĐ'
                    : '${FinanceCalculator.calculateVat(subtotal: int.tryParse(_subtotalController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0, vatRate: _vatRate).vatAmount} VNĐ',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng cộng', style: theme.textTheme.titleMedium),
              Text(
                '${_amountController.text.isEmpty ? '0' : _amountController.text} VNĐ',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineItems(
    BuildContext context,
    ThemeData theme,
    bool isScanning,
  ) {
    return BentoCard(
      style: BentoCardStyle.outlined,
      padding: const EdgeInsets.all(32),
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedImageBytes == null)
              Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(_selectedImageBytes!, fit: BoxFit.contain),
              ),
            if (isScanning)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(
                  color: theme.colorScheme.scrim.withValues(alpha: 0.34),
                  child: LayoutBuilder(
                    builder: (context, constraints) => AnimatedBuilder(
                      animation: _scanProgress,
                      builder: (context, child) => Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top:
                                _scanProgress.value *
                                (constraints.maxHeight - 4),
                            child: Container(
                              height: 4,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Đang phân tích hóa đơn...',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 16,
        runSpacing: 16,
        children: [
          SmartButton.text(
            onPressed: () => context.pop(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SmartButton(
            onPressed: _isSaving ? null : _onSavePressed,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSaving)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.save_rounded),
                const SizedBox(width: 8),
                const Text(
                  'Lưu hóa đơn',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
