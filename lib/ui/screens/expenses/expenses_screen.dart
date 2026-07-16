import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/ui/screens/expenses/widgets/add_transaction_dialog.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/bento_grid.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';
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
                      cellHeight: 140,
                      spacing: 16,
                      children: [
                        BentoItem(colSpan: 2, rowSpan: 2, child: _BudgetCard()),
                        BentoItem(colSpan: 1, rowSpan: 1, child: _ScanActionCard()),
                        BentoItem(colSpan: 1, rowSpan: 1, child: _QuickAddCard()),
                        BentoItem(colSpan: 2, rowSpan: 1, child: _CsvUploadCard()),
                        BentoItem(colSpan: 2, rowSpan: 5, child: _ExpensesListCard(isDesktop: false)),
                      ],
                    );
                  }

                  if (isTablet) {
                    return BentoGrid(
                      mobileColumns: 2,
                      tabletColumns: 3,
                      desktopColumns: 3,
                      cellHeight: 140,
                      spacing: 16,
                      children: [
                        // R0, C0 (Span 1x2) -> Budget
                        BentoItem(colSpan: 1, rowSpan: 2, child: _BudgetCard()),
                        // R0, C1 (Span 2x4) -> List
                        BentoItem(colSpan: 2, rowSpan: 4, child: _ExpensesListCard(isDesktop: false)),
                        // R2, C0 (Span 1x1) -> Scan
                        BentoItem(colSpan: 1, rowSpan: 1, child: _ScanActionCard()),
                        // R3, C0 (Span 1x1) -> Row of Manual & CSV
                        BentoItem(colSpan: 1, rowSpan: 1, child: _QuickActionsRowCard()),
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
              const SizedBox(height: 48),
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
      accentColor: const Color(0xFF6C63FF),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF6C63FF), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Ngân sách tháng',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '4.250k',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF6C63FF),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'đã tiêu',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 14,
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Còn lại 2.250k',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w700,
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
    return BentoCard(
      onTap: () {},
      accentColor: const Color(0xFF4F46E5),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF6C63FF),
          Color(0xFF4F46E5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.document_scanner_rounded, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quét biên lai',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
      accentColor: theme.colorScheme.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 36, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Nhập tay', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.upload_file_rounded, size: 24, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Text('Tải CSV', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
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
    final currencyFmt = NumberFormat.compactCurrency(locale: 'vi_VN', symbol: '₫');

    return BentoCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: BentoSectionHeader(
              title: 'Lịch sử giao dịch',
              subtitle: 'Các khoản chi phí gần đây',
              action: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list_rounded, size: 20),
                      color: theme.colorScheme.primary,
                      tooltip: 'Lọc',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search_rounded, size: 20),
                      color: theme.colorScheme.primary,
                      tooltip: 'Tìm kiếm',
                    ),
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
                        constraints: const BoxConstraints(minWidth: 800),
                        child: DataTable(
                          headingRowColor: WidgetStatePropertyAll(
                              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)),
                          dataRowMaxHeight: 76,
                          dataRowMinHeight: 76,
                          columns: const [
                            DataColumn(label: Text('Chi phí', style: TextStyle(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Danh mục', style: TextStyle(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Ngày', style: TextStyle(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Số tiền', style: TextStyle(fontWeight: FontWeight.w700))),
                            DataColumn(label: Text('Hành động', style: TextStyle(fontWeight: FontWeight.w700))),
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
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(14)),
                                    child: Icon(getIcon(iconName), color: theme.colorScheme.primary, size: 22),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(tx.description?.isNotEmpty == true ? tx.description! : 'Giao dịch', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text(category.categoryName, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                ],
                              )),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(category.categoryName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant)),
                              )),
                              DataCell(Text(DateFormat('dd/MM/yyyy').format(tx.transactionDate), style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(amountText, style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter', fontSize: 15, color: amountColor))),
                              DataCell(IconButton(icon: const Icon(Icons.more_horiz_rounded, size: 20), onPressed: () {})),
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
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(getIcon(iconName), color: theme.colorScheme.primary, size: 22),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description?.isNotEmpty == true ? tx.description! : 'Giao dịch',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${category.categoryName} • ${DateFormat('dd/MM HH:mm').format(tx.transactionDate)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                amountText,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: amountColor,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                  fontSize: 15,
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
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Tải thêm giao dịch', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
