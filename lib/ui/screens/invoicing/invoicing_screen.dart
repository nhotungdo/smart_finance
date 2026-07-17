import 'package:flutter/material.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/bento_grid.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:smart_finance/ui/widgets/smart_text_field.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/providers/pdf_export_provider.dart';

class InvoicingScreen extends ConsumerWidget {
  const InvoicingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by MainLayout
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  title: 'Tổng quan hóa đơn',
                  subtitle: 'Quản lý và theo dõi hóa đơn doanh nghiệp của bạn.',
                ),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isMobile = width < 600;
                    final isTablet = width >= 600 && width < 1024;
                    final isDesktop = width >= 1024;

                    final listColSpan = isDesktop ? 3 : (isTablet ? 2 : 1);

                    return BentoGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 3,
                      cellHeight: 170,
                      spacing: 20,
                      children: [
                        // Stats row
                        BentoItem(
                          colSpan: 1,
                          rowSpan: 1,
                          child: _OutstandingCard(),
                        ),
                        BentoItem(
                          colSpan: 1,
                          rowSpan: 1,
                          child: _OverdueCard(),
                        ),
                        if (!isMobile)
                          BentoItem(
                            colSpan: 1,
                            rowSpan: 1,
                            child: _CreateActionCard(),
                          ),

                        // List
                        BentoItem(
                          colSpan: listColSpan,
                          rowSpan: 4, // Allow table to have some height
                          child: _InvoiceListCard(
                            isDesktop: isDesktop || isTablet,
                          ),
                        ),

                        // Action for mobile
                        if (isMobile)
                          BentoItem(
                            colSpan: 1,
                            rowSpan: 1,
                            child: _CreateActionCard(),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Cards ───────────────────────────────────────────────────────────────────

class _OutstandingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      showAccentStrip: true,
      accentColor: theme.colorScheme.primary,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tổng chưa thanh toán',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '45.230k ₫',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '+12% so với tháng trước',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverdueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      showAccentStrip: true,
      accentColor: theme.colorScheme.error,
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.error.withValues(alpha: 0.1),
          theme.colorScheme.error.withValues(alpha: 0.0),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Số tiền quá hạn',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '8.450k ₫',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cần xử lý (4 hóa đơn)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateActionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      onTap: () => context.push('/invoicing/create'),
      accentColor: theme.colorScheme.primary,
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withValues(alpha: 0.8),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              size: 36,
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              'Tạo hóa đơn',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List ────────────────────────────────────────────────────────────────────

class _InvoiceListCard extends ConsumerWidget {
  final bool isDesktop;
  const _InvoiceListCard({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final invoicesState = ref.watch(invoicesProvider);

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: BentoSectionHeader(
              title: 'Hóa đơn gần đây',
              action: Row(
                children: [
                  IconButton(
                    onPressed: () => ref.invalidate(invoicesProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    color: theme.colorScheme.primary,
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 200,
                      child: SmartTextField(
                        labelText: '',
                        hintText: 'Tìm kiếm...',
                        prefixIcon: Icons.search_rounded,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: invoicesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Lỗi tải hóa đơn: $err',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
              data: (invoices) {
                if (invoices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có hóa đơn nào.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final numberFormat = NumberFormat.currency(
                  locale: 'vi_VN',
                  symbol: '₫',
                );
                final dateFormat = DateFormat('dd/MM/yyyy');

                if (isDesktop) {
                  return SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 800),
                        child: DataTable(
                          headingRowColor: WidgetStatePropertyAll(
                            theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                          dataRowMinHeight: 72,
                          dataRowMaxHeight: 72,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Mã HĐ',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Khách hàng',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Ngày',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Số tiền',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Trạng thái',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(label: Text('')),
                          ],
                          rows: invoices.map((inv) {
                            return _buildDataRow(
                              context,
                              ref,
                              theme,
                              inv,
                              inv.invoiceNumber ?? inv.id.substring(0, 8),
                              inv.supplierName ?? 'Khách lẻ',
                              inv.invoiceDate != null
                                  ? dateFormat.format(inv.invoiceDate!)
                                  : '-',
                              numberFormat.format(inv.totalAmount ?? 0),
                              inv.scanStatus == InvoiceScanStatus.scanned
                                  ? 'Hoàn tất'
                                  : 'Chờ xử lý',
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                } else {
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: invoices.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final inv = invoices[index];
                      return _buildMobileInvoiceItem(
                        context,
                        ref,
                        theme,
                        inv,
                        inv.invoiceNumber ?? inv.id.substring(0, 8),
                        inv.supplierName ?? 'Khách lẻ',
                        inv.invoiceDate != null
                            ? dateFormat.format(inv.invoiceDate!)
                            : '-',
                        numberFormat.format(inv.totalAmount ?? 0),
                        inv.scanStatus == InvoiceScanStatus.scanned
                            ? 'Hoàn tất'
                            : 'Chờ xử lý',
                      );
                    },
                  );
                }
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: SmartButton.text(
                onPressed: () {},
                child: const Text(
                  'Xem tất cả hóa đơn',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    InvoiceModel invoice,
    String id,
    String client,
    String date,
    String amount,
    String status,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            id,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          Text(client, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        DataCell(
          Text(
            date,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        DataCell(
          Text(
            amount,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(_buildStatusBadge(theme, status)),
        DataCell(
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Xem trước',
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () =>
                      context.push('/invoicing/preview/${invoice.id}'),
                ),
                IconButton(
                  tooltip: 'Xuất PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () => _exportInvoice(context, ref, invoice),
                ),
                IconButton(
                  tooltip: 'Tạo chi phí',
                  icon: const Icon(Icons.add_card_rounded),
                  onPressed: () =>
                      _createExpenseFromInvoice(context, ref, invoice),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileInvoiceItem(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    InvoiceModel invoice,
    String id,
    String client,
    String date,
    String amount,
    String status,
  ) {
    return InkWell(
      onTap: () => context.push('/invoicing/preview/${invoice.id}'),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  client,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(theme, status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      id,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontFamily: 'Inter',
                      ),
                    ),
                    Text(
                      date,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Xuất PDF',
                      onPressed: () => _exportInvoice(context, ref, invoice),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                    ),
                    IconButton(
                      tooltip: 'Tạo chi phí',
                      onPressed: () =>
                          _createExpenseFromInvoice(context, ref, invoice),
                      icon: const Icon(Icons.add_card_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createExpenseFromInvoice(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) async {
    final categories = await ref.read(categoriesProvider.future);
    final expenseCategories = categories
        .where((category) => category.categoryType == TransactionType.expense)
        .toList();

    if (!context.mounted) return;
    if (expenseCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có danh mục chi phí.')),
      );
      return;
    }

    var selectedCategoryId = expenseCategories.first.categoryId;
    final categoryId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo chi phí từ hóa đơn'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedCategoryId,
            decoration: const InputDecoration(labelText: 'Danh mục chi phí'),
            items: expenseCategories
                .map(
                  (category) => DropdownMenuItem(
                    value: category.categoryId,
                    child: Text(category.categoryName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedCategoryId = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(selectedCategoryId),
              child: const Text('Tạo chi phí'),
            ),
          ],
        ),
      ),
    );

    if (categoryId == null) return;
    try {
      await ref
          .read(transactionsProvider.notifier)
          .createExpenseFromInvoice(invoice: invoice, categoryId: categoryId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo giao dịch chi phí.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể tạo chi phí: $error')));
    }
  }

  Future<void> _exportInvoice(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) async {
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

  Widget _buildStatusBadge(ThemeData theme, String status) {
    final isDone = status == 'Hoàn tất';
    final bgColor = isDone
        ? const Color(0xFF10B981).withValues(alpha: 0.1)
        : const Color(0xFFF59E0B).withValues(alpha: 0.1);
    final textColor = isDone
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
