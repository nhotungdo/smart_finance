import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_finance/providers/ocr_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _amountController = TextEditingController();
  
  bool _isPopulatedFromOcr = false;

  @override
  void dispose() {
    _supplierController.dispose();
    _taxCodeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSmartScanPressed() async {
    final tempId = const Uuid().v4();
    await ref.read(ocrProvider.notifier).scanImage('fake/path/to/image.jpg', tempId);
  }

  void _onSavePressed() async {
    if (!_formKey.currentState!.validate()) return;
    
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'default_user_id';
    final companyId = user?.id ?? 'default_company_id';

    final invoice = InvoiceModel(
      id: const Uuid().v4(),
      companyId: companyId,
      uploadedBy: userId,
      supplierName: _supplierController.text,
      supplierTaxCode: _taxCodeController.text,
      invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      invoiceDate: DateTime.now(),
      totalAmount: double.tryParse(_amountController.text) ?? 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      scanStatus: _isPopulatedFromOcr ? 'processed' : 'manual',
    );

    await ref.read(invoicesProvider.notifier).addInvoice(invoice);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hóa đơn đã được lưu!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 768;
    
    ref.listen(ocrProvider, (previous, next) {
      next.whenData((ocrResult) {
        if (ocrResult != null && !_isPopulatedFromOcr) {
          setState(() {
            _supplierController.text = ocrResult.extractedSupplierName ?? '';
            _taxCodeController.text = ocrResult.extractedTaxCode ?? '';
            _amountController.text = ocrResult.extractedAmount?.toString() ?? '';
            _isPopulatedFromOcr = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã quét dữ liệu thành công!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      });
    });

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
                  _buildLineItems(context, theme),
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
        crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          if (!isDesktop) const SizedBox(height: 24),
          ocrState.isLoading
              ? const CircularProgressIndicator()
              : SmartButton(
                  onPressed: _onSmartScanPressed,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.document_scanner_rounded),
                      SizedBox(width: 8),
                      Text('Smart Scan AI'),
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
            action: Icon(Icons.business_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          SmartTextField(
            controller: _supplierController,
            labelText: 'Tên nhà cung cấp / khách hàng',
            validator: (val) => val == null || val.isEmpty ? 'Bắt buộc nhập' : null,
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
            action: Icon(Icons.monetization_on_rounded, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          SmartTextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            labelText: 'Tổng tiền (VNĐ)',
            validator: (val) => val == null || val.isEmpty ? 'Bắt buộc nhập' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLineItems(BuildContext context, ThemeData theme) {
    return BentoCard(
      style: BentoCardStyle.outlined,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.format_list_bulleted_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Các mục chi tiết sẽ được phát triển sau',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
            child: const Text('Hủy bỏ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SmartButton(
            onPressed: _onSavePressed,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save_rounded),
                SizedBox(width: 8),
                Text('Lưu hóa đơn', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
