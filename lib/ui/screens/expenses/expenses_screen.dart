import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/ui/screens/expenses/widgets/add_transaction_dialog.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/bento_grid.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';
import 'package:smart_finance/ui/widgets/smart_button.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Chi phí',
                subtitle: 'Theo dõi chi phí và quản lý hóa đơn hàng tháng.',
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isMobile = width < 600;
                  final isTablet = width >= 600 && width < 1024;

                  if (isMobile) {
                    return BentoGrid(
                      mobileColumns: 2,
                      tabletColumns: 3,
                      desktopColumns: 3,
                      cellHeight: 130,
                      spacing: 16,
                      children: [
                        BentoItem(colSpan: 2, rowSpan: 2, child: _BudgetCard()),
                        BentoItem(colSpan: 1, rowSpan: 1, child: _ScanActionCard()),
                        BentoItem(colSpan: 1, rowSpan: 1, child: _QuickAddCard()),
                        BentoItem(colSpan: 2, rowSpan: 1, child: _CsvUploadCard()),
                        BentoItem(colSpan: 2, rowSpan: 4, child: _ExpensesListCard(isDesktop: false)),
                      ],
                    );
                  }

                  if (isTablet) {
                    return BentoGrid(
                      mobileColumns: 2,
                      tabletColumns: 3,
                      desktopColumns: 3,
                      cellHeight: 130,
                      spacing: 16,
                      children: [
                        // R0, C0 (Span 1x2) -> Budget
                        BentoItem(colSpan: 1, rowSpan: 2, child: _BudgetCard()),
                        // R0, C1 (Span 2x4) -> List
                        BentoItem(colSpan: 2, rowSpan: 4, child: _ExpensesListCard(isDesktop: false)),
                        // R2, C0 (Span 1x1) -> Scan
                        BentoItem(colSpan: 1, rowSpan: 1, child: _ScanActionCard()),
                        // R3, C0 (Span 1x1) -> Row of Manual & CSV
                        BentoItem(colSpan: 1, rowSpan: 1, child: _QuickAddCard()),
                      ],
                    );
                  }

                  return BentoGrid(
                    mobileColumns: 2,
                    tabletColumns: 3,
                    desktopColumns: 3,
                    cellHeight: 140,
                    spacing: 20,
                    children: [
                      // R0, C0 (Span 1x2) -> Budget
                      BentoItem(colSpan: 1, rowSpan: 2, child: _BudgetCard()),
                      // R0, C1 (Span 2x4) -> List
                      BentoItem(colSpan: 2, rowSpan: 4, child: _ExpensesListCard(isDesktop: true)),
                      // R2, C0 (Span 1x1) -> Scan
                      BentoItem(colSpan: 1, rowSpan: 1, child: _ScanActionCard()),
                      // R3, C0 (Span 1x1) -> Row of Manual & CSV
                      BentoItem(colSpan: 1, rowSpan: 1, child: _QuickActionsRowCard()),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cards ───────────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
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
            'Ngân sách tháng',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '4.250k',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'đã tiêu',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 12,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Còn lại 2.250k',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Tổng 6.500k',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScanActionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      onTap: () {},
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
            Icon(Icons.document_scanner_rounded, size: 36, color: theme.colorScheme.onPrimary),
            const SizedBox(height: 12),
            Text(
              'Quét biên lai',
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

class _QuickAddCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      onTap: () => showDialog(
        context: context,
        builder: (context) => const AddTransactionDialog(),
      ),
      style: BentoCardStyle.outlined,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text('Nhập tay', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _CsvUploadCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      onTap: () {},
      style: BentoCardStyle.ghost,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file_rounded, size: 32, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text('Tải CSV', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// For Desktop where Manual and CSV share a 1x1 cell
class _QuickActionsRowCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickAddCard()),
        const SizedBox(width: 16),
        Expanded(child: _CsvUploadCard()),
      ],
    );
  }
}

// ─── List ────────────────────────────────────────────────────────────────────

class _ExpensesListCard extends ConsumerWidget {
  final bool isDesktop;
  const _ExpensesListCard({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionsState = ref.watch(transactionsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: BentoSectionHeader(
              title: 'Chi phí gần đây',
              action: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list_rounded),
                    color: theme.colorScheme.primary,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded),
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: transactionsState.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('Chưa có giao dịch nào.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                final categories = categoriesState.value ?? [];
                
                if (isDesktop) {
                  return SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 600),
                        child: DataTable(
                          headingRowColor: WidgetStatePropertyAll(
                              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
                          dataRowMaxHeight: 72,
                          dataRowMinHeight: 72,
                          columns: const [
                            DataColumn(label: Text('Chi phí', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Ngày', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Số tiền', style: TextStyle(fontWeight: FontWeight.w600))),
                            DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.w600))),
                          ],
                          rows: transactions.map((tx) {
                            final category = categories.firstWhere(
                              (c) => c.categoryId == tx.categoryId,
                              orElse: () => categories.isNotEmpty ? categories.first : categories.first,
                            );
                            
                            final iconName = category.iconName ?? 'attach_money';
                            IconData getIcon(String name) {
                              switch(name) {
                                case 'restaurant': return Icons.restaurant;
                                case 'flight': return Icons.flight;
                                case 'computer': return Icons.computer;
                                case 'local_gas_station': return Icons.local_gas_station;
                                default: return Icons.attach_money;
                              }
                            }
                            
                            final amountText = tx.transactionType == 'expense' 
                                ? '-${currencyFmt.format(tx.amount)}' 
                                : '+${currencyFmt.format(tx.amount)}';
                                
                            final amountColor = tx.transactionType == 'expense' 
                                ? theme.colorScheme.error
                                : const Color(0xFF10B981);

                            return DataRow(cells: [
                              DataCell(Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
                                    child: Icon(getIcon(iconName), color: theme.colorScheme.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(tx.description?.isNotEmpty == true ? tx.description! : 'Giao dịch', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(category.categoryName, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                ],
                              )),
                              DataCell(Text(category.categoryName)),
                              DataCell(Text(DateFormat('dd/MM/yyyy').format(tx.transactionDate))),
                              DataCell(Text(amountText, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Inter', color: amountColor))),
                              DataCell(IconButton(icon: const Icon(Icons.more_vert, size: 20), onPressed: () {})),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                } else {
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final category = categories.firstWhere(
                        (c) => c.categoryId == tx.categoryId,
                        orElse: () => categories.isNotEmpty ? categories.first : categories.first,
                      );
                      
                      final iconName = category.iconName ?? 'attach_money';
                      IconData getIcon(String name) {
                        switch(name) {
                          case 'restaurant': return Icons.restaurant;
                          case 'flight': return Icons.flight;
                          case 'computer': return Icons.computer;
                          case 'local_gas_station': return Icons.local_gas_station;
                          default: return Icons.attach_money;
                        }
                      }

                      final amountText = tx.transactionType == 'expense' 
                          ? '-${currencyFmt.format(tx.amount)}' 
                          : '+${currencyFmt.format(tx.amount)}';
                      final amountColor = tx.transactionType == 'expense' 
                          ? theme.colorScheme.error
                          : const Color(0xFF10B981);

                      return InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(getIcon(iconName), color: theme.colorScheme.primary, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.description?.isNotEmpty == true ? tx.description! : 'Giao dịch',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${category.categoryName} • ${DateFormat('dd/MM').format(tx.transactionDate)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                amountText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: amountColor,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Center(
              child: SmartButton.text(
                onPressed: () {},
                child: const Text('Xem tất cả chi phí', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
