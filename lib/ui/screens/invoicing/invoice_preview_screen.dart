import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/providers/pdf_export_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';

final invoicePreviewProvider = FutureProvider.autoDispose
    .family<InvoiceModel?, String>((ref, invoiceId) {
      return ref.read(invoiceRepositoryProvider).getInvoiceById(invoiceId);
    });

class InvoicePreviewScreen extends ConsumerWidget {
  const InvoicePreviewScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceState = ref.watch(invoicePreviewProvider(invoiceId));
    return invoiceState.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _PreviewError(message: 'Lỗi tải hóa đơn: $error'),
      data: (invoice) => invoice == null
          ? const _PreviewError(message: 'Không tìm thấy hóa đơn.')
          : _InvoiceDocument(invoice: invoice),
    );
  }
}

class _InvoiceDocument extends ConsumerWidget {
  const _InvoiceDocument({required this.invoice});

  final InvoiceModel invoice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 768;
    final pdfState = ref.watch(pdfExportProvider);
    final linkedTransaction = ref.watch(
      linkedTransactionForInvoiceProvider(invoice.id),
    );
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final date = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Quay lại',
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/invoicing'),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Xem trước hóa đơn',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SmartButton(
                      onPressed: pdfState.isLoading
                          ? null
                          : () => _exportPdf(context, ref),
                      isLoading: pdfState.isLoading,
                      icon: const Icon(Icons.print_outlined, size: 18),
                      child: const Text('In / Xuất PDF'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                linkedTransaction.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (transaction) => BentoCard(
                    borderRadius: 8,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          transaction == null
                              ? Icons.link_off_rounded
                              : Icons.link_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction == null
                                    ? 'Chưa tạo giao dịch từ hóa đơn'
                                    : 'Đã liên kết giao dịch',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (transaction != null)
                                Text(
                                  transaction.transactionId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (transaction != null)
                          IconButton(
                            tooltip: 'Xem giao dịch',
                            onPressed: () => context.push(
                              '/expenses/${transaction.transactionId}',
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                BentoCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerLowest,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(height: 6, color: theme.colorScheme.primary),
                      Padding(
                        padding: EdgeInsets.all(isDesktop ? 40 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInvoiceHeader(theme, date, isDesktop),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 24),
                            _buildSupplier(theme),
                            const SizedBox(height: 28),
                            _buildLineItem(theme, currency),
                            const SizedBox(height: 28),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: isDesktop ? 390 : double.infinity,
                                child: _buildTotals(theme, currency),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        color: theme.colorScheme.surfaceContainerLow,
                        child: Text(
                          'SmartFinance SME',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader(ThemeData theme, DateFormat date, bool isDesktop) {
    final company = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'SmartFinance SME',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Quản lý dòng tiền doanh nghiệp',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
    final metadata = Column(
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          invoice.invoiceType == TransactionType.income
              ? 'HÓA ĐƠN THU'
              : 'HÓA ĐƠN CHI',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(invoice.invoiceNumber ?? invoice.id),
        Text(
          invoice.invoiceDate == null
              ? 'Chưa cập nhật ngày'
              : date.format(invoice.invoiceDate!),
        ),
        const SizedBox(height: 8),
        _StatusBadge(status: invoice.scanStatus),
      ],
    );

    return Flex(
      direction: isDesktop ? Axis.horizontal : Axis.vertical,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [company, if (!isDesktop) const SizedBox(height: 24), metadata],
    );
  }

  Widget _buildSupplier(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          invoice.invoiceType == TransactionType.income
              ? 'KHÁCH HÀNG'
              : 'NHÀ CUNG CẤP',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          invoice.supplierName ?? 'Chưa cập nhật',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text('Mã số thuế: ${invoice.supplierTaxCode ?? 'Chưa cập nhật'}'),
      ],
    );
  }

  Widget _buildLineItem(ThemeData theme, NumberFormat currency) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: theme.colorScheme.surfaceContainerLow,
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Nội dung')),
                Expanded(child: Text('SL', textAlign: TextAlign.center)),
                Expanded(
                  flex: 2,
                  child: Text('Tiền hàng', textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text('Hàng hóa / dịch vụ theo hóa đơn'),
                ),
                const Expanded(child: Text('1', textAlign: TextAlign.center)),
                Expanded(
                  flex: 2,
                  child: Text(
                    currency.format(invoice.subtotal ?? 0),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(ThemeData theme, NumberFormat currency) {
    return Column(
      children: [
        _totalRow('Tiền hàng', currency.format(invoice.subtotal ?? 0)),
        _totalRow('Thuế suất VAT', '${invoice.vatRate ?? 0}%'),
        _totalRow('Tiền thuế VAT', currency.format(invoice.vatAmount ?? 0)),
        const Divider(height: 24),
        _totalRow(
          'Tổng thanh toán',
          currency.format(invoice.totalAmount ?? 0),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 16),
          Text(value, style: style),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    try {
      final result = await ref
          .read(pdfExportProvider.notifier)
          .exportInvoice(invoice);
      if (!context.mounted || result == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xuất PDF: ${result.filePath}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể xuất PDF: $error')));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final InvoiceScanStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isScanned = status == InvoiceScanStatus.scanned;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isScanned
            ? const Color(0xFF10B981).withValues(alpha: 0.12)
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isScanned ? 'Đã quét' : 'Chờ xử lý',
        style: theme.textTheme.labelSmall?.copyWith(
          color: isScanned
              ? const Color(0xFF047857)
              : theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/invoicing'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Quay lại hóa đơn'),
            ),
          ],
        ),
      ),
    );
  }
}
