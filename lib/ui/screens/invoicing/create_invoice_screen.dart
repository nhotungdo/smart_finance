import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/providers/ocr_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/ocr_result_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/domain/services/finance_calculator.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key, this.sourceTransaction});

  final TransactionModel? sourceTransaction;

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
  TransactionType _invoiceType = TransactionType.expense;
  DateTime _invoiceDate = DateTime.now();
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
      duration: const Duration(milliseconds: 750),
    );
    _scanProgress = CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOutCubic,
    );
    final source = widget.sourceTransaction;
    if (source != null) {
      _invoiceType = TransactionType.expense;
      _invoiceDate = source.transactionDate;
      _selectedImagePath = source.receiptImagePath;
      _fillAmountsFromSource();
    }
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

    NavigatorState? scanNavigator;
    final scanDialogFuture = showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) {
        scanNavigator = Navigator.of(dialogContext);
        return PopScope(
          canPop: false,
          child: _SmartScanDialog(
            imageBytes: bytes,
            scanPosition: _scanProgress,
          ),
        );
      },
    );
    await WidgetsBinding.instance.endOfFrame;

    _scanController
      ..reset()
      ..repeat(reverse: true);
    try {
      await Future.wait<void>([
        Future<void>.delayed(const Duration(seconds: 2)),
        ref.read(ocrProvider.notifier).scanImage(pickedImage.path, _invoiceId),
      ]);
    } finally {
      _scanController.stop();
      if (scanNavigator?.mounted ?? false) {
        scanNavigator!.pop();
      }
      await scanDialogFuture;
    }

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
      _vatRate = rawVatRate == 8 ? 8 : 10;
      if (widget.sourceTransaction == null) {
        _subtotalController.text =
            (raw['subtotal'] as num?)?.round().toString() ?? '';
        _recalculateTotal();
      } else {
        _fillAmountsFromSource();
      }
      _isPopulatedFromOcr = true;
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
    final vat = widget.sourceTransaction == null
        ? FinanceCalculator.calculateVat(subtotal: subtotal, vatRate: _vatRate)
        : FinanceCalculator.calculateVatFromTotal(
            total: widget.sourceTransaction!.amount,
            vatRate: _vatRate,
          );
    _amountController.text = vat.total.toString();
  }

  void _fillAmountsFromSource() {
    final source = widget.sourceTransaction;
    if (source == null) return;
    final vat = FinanceCalculator.calculateVatFromTotal(
      total: source.amount,
      vatRate: _vatRate,
    );
    _subtotalController.text = vat.subtotal.toString();
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
    final vat = widget.sourceTransaction == null
        ? FinanceCalculator.calculateVat(subtotal: subtotal, vatRate: _vatRate)
        : FinanceCalculator.calculateVatFromTotal(
            total: widget.sourceTransaction!.amount,
            vatRate: _vatRate,
          );

    final invoice = InvoiceModel(
      id: _invoiceId,
      companyId: companyId,
      uploadedBy: user.id,
      invoiceType: _invoiceType,
      supplierName: _supplierController.text,
      supplierTaxCode: _taxCodeController.text,
      invoiceNumber:
          'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      invoiceDate: _invoiceDate,
      subtotal: vat.subtotal,
      vatRate: vat.vatRate,
      vatAmount: vat.vatAmount,
      totalAmount: vat.total,
      imagePath: _selectedImagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      scanStatus: _isPopulatedFromOcr
          ? InvoiceScanStatus.scanned
          : InvoiceScanStatus.notScanned,
    );

    setState(() => _isSaving = true);
    var invoiceSaved = false;
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
      invoiceSaved = true;
      final source = widget.sourceTransaction;
      if (source != null) {
        await ref
            .read(transactionsProvider.notifier)
            .linkInvoiceToTransaction(
              transactionId: source.transactionId,
              invoiceId: _invoiceId,
            );
      }
    } catch (error) {
      if (invoiceSaved && widget.sourceTransaction != null) {
        try {
          await ref.read(invoicesProvider.notifier).deleteInvoice(_invoiceId);
        } catch (_) {
          // The original link error is more useful to the user.
        }
      }
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

                  if (widget.sourceTransaction != null) ...[
                    _buildSourceTransactionNotice(theme),
                    const SizedBox(height: 20),
                  ],

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

  Widget _buildSourceTransactionNotice(ThemeData theme) {
    final source = widget.sourceTransaction!;
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final date = DateFormat('dd/MM/yyyy').format(source.transactionDate);

    return BentoCard(
      style: BentoCardStyle.outlined,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.link_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo hóa đơn từ giao dịch chi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${currency.format(source.amount)} • $date',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.income,
                  icon: Icon(Icons.south_west_rounded),
                  label: Text('Hóa đơn thu'),
                ),
                ButtonSegment(
                  value: TransactionType.expense,
                  icon: Icon(Icons.north_east_rounded),
                  label: Text('Hóa đơn chi'),
                ),
              ],
              selected: {_invoiceType},
              onSelectionChanged: widget.sourceTransaction == null
                  ? (selection) {
                      setState(() => _invoiceType = selection.first);
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 16),
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
    final parsedSubtotal = int.tryParse(
      _subtotalController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final displayedVat = widget.sourceTransaction == null
        ? FinanceCalculator.calculateVat(
            subtotal: parsedSubtotal ?? 0,
            vatRate: _vatRate,
          )
        : FinanceCalculator.calculateVatFromTotal(
            total: widget.sourceTransaction!.amount,
            vatRate: _vatRate,
          );

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
            onChanged: (_) => setState(() {
              if (widget.sourceTransaction == null) {
                _recalculateTotal();
              } else {
                _amountController.text = widget.sourceTransaction!.amount
                    .toString();
              }
            }),
            validator: (value) {
              final subtotal = int.tryParse((value ?? '').trim());
              if (subtotal == null || subtotal <= 0) {
                return 'Số tiền phải lớn hơn 0';
              }
              final source = widget.sourceTransaction;
              if (source != null &&
                  subtotal !=
                      FinanceCalculator.calculateVatFromTotal(
                        total: source.amount,
                        vatRate: _vatRate,
                      ).subtotal) {
                return 'Tổng hóa đơn phải bằng ${source.amount} VNĐ';
              }
              return null;
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
                if (widget.sourceTransaction == null) {
                  _recalculateTotal();
                } else {
                  _fillAmountsFromSource();
                }
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
                    : '${displayedVat.vatAmount} VNĐ',
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

class _SmartScanDialog extends StatelessWidget {
  const _SmartScanDialog({
    required this.imageBytes,
    required this.scanPosition,
  });

  final Uint8List imageBytes;
  final Animation<double> scanPosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.document_scanner_rounded, color: primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Smart Scan AI',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ColoredBox(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(imageBytes, fit: BoxFit.contain),
                        ColoredBox(color: Colors.black.withValues(alpha: 0.3)),
                        LayoutBuilder(
                          builder: (context, constraints) => AnimatedBuilder(
                            animation: scanPosition,
                            builder: (context, child) {
                              const bandHeight = 72.0;
                              final bandTop =
                                  scanPosition.value *
                                  (constraints.maxHeight - bandHeight);
                              final lineTop = bandTop + (bandHeight / 2) - 1;
                              return Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: bandTop,
                                    child: Container(
                                      height: bandHeight,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          stops: const [
                                            0,
                                            0.32,
                                            0.48,
                                            0.52,
                                            0.68,
                                            1,
                                          ],
                                          colors: [
                                            primary.withValues(alpha: 0),
                                            primary.withValues(alpha: 0.08),
                                            primary.withValues(alpha: 0.36),
                                            Colors.white.withValues(alpha: 0.7),
                                            primary.withValues(alpha: 0.12),
                                            primary.withValues(alpha: 0),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withValues(
                                              alpha: 0.32,
                                            ),
                                            blurRadius: 24,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: lineTop,
                                    child: Container(
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary,
                                            blurRadius: 18,
                                            spreadRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Đang phân tích hóa đơn...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hệ thống đang nhận diện mã số thuế và giá trị hóa đơn.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
