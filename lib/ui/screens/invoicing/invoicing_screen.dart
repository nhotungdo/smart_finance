import 'package:flutter/material.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/bento_grid.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';
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

class _OutstandingCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(invoiceSummaryProvider);
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return BentoCard(
      showAccentStrip: true,
      accentColor: theme.colorScheme.primary,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Tổng giá trị hóa đơn',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              currency.format(summary.totalValue),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${summary.invoiceCount} hóa đơn',
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

class _OverdueCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(invoiceSummaryProvider);
    final pendingColor = theme.colorScheme.secondary;
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return BentoCard(
      showAccentStrip: true,
      accentColor: pendingColor,
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
                  'Đang chờ xử lý',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: pendingColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.pending_actions_rounded, color: pendingColor),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              currency.format(summary.pendingValue),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: pendingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${summary.pendingCount} hóa đơn chưa hoàn tất',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: pendingColor,
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
              title: 'Danh sách hóa đơn',
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
                  tooltip: invoice.invoiceType == TransactionType.income
                      ? 'Tạo khoản thu'
                      : 'Tạo chi phí',
                  icon: const Icon(Icons.add_card_rounded),
                  onPressed: () =>
                      _createTransactionFromInvoice(context, ref, invoice),
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
              children: [
                Expanded(
                  child: Text(
                    client,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(theme, status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
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
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Xuất PDF',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    onPressed: () => _exportInvoice(context, ref, invoice),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: invoice.invoiceType == TransactionType.income
                        ? 'Tạo khoản thu'
                        : 'Tạo chi phí',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                    onPressed: () =>
                        _createTransactionFromInvoice(context, ref, invoice),
                    icon: const Icon(Icons.add_card_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTransactionFromInvoice(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) async {
    final categories = await ref.read(categoriesProvider.future);
    final matchingCategories = categories
        .where((category) => category.categoryType == invoice.invoiceType)
        .toList();
    final isIncome = invoice.invoiceType == TransactionType.income;

    if (!context.mounted) return;
    if (matchingCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Chưa có danh mục ${isIncome ? 'khoản thu' : 'chi phí'}.',
          ),
        ),
      );
      return;
    }

    var selectedCategoryId = matchingCategories.first.categoryId;
    final categoryId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Tạo ${isIncome ? 'khoản thu' : 'chi phí'} từ hóa đơn'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedCategoryId,
            decoration: InputDecoration(
              labelText: 'Danh mục ${isIncome ? 'thu' : 'chi'}',
            ),
            items: matchingCategories
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
              child: Text(isIncome ? 'Tạo khoản thu' : 'Tạo chi phí'),
            ),
          ],
        ),
      ),
    );

    if (categoryId == null) return;
    try {
      await ref
          .read(transactionsProvider.notifier)
          .createTransactionFromInvoice(
            invoice: invoice,
            categoryId: categoryId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tạo giao dịch ${isIncome ? 'thu' : 'chi'}.'),
        ),
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
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : theme.colorScheme.secondary.withValues(alpha: 0.1);
    final textColor = isDone
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
