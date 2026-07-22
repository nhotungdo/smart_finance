import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
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
                      cellHeight: 160,
                      spacing: 16,
                      children: [
                        BentoItem(
                          colSpan: 2,
                          rowSpan: 1,
                          child: _QuickAddCard(),
                        ),
                        BentoItem(
                          colSpan: 2,
                          rowSpan: 4,
                          child: _ExpensesListCard(isDesktop: false),
                        ),
                      ],
                    );
                  }

                  if (isTablet) {
                    return BentoGrid(
                      mobileColumns: 2,
                      tabletColumns: 3,
                      desktopColumns: 3,
                      cellHeight: 160,
                      spacing: 16,
                      children: [
                        BentoItem(
                          colSpan: 2,
                          rowSpan: 4,
                          child: _ExpensesListCard(isDesktop: false),
                        ),
                        BentoItem(
                          colSpan: 1,
                          rowSpan: 1,
                          child: _QuickAddCard(),
                        ),
                      ],
                    );
                  }

                  return BentoGrid(
                    mobileColumns: 2,
                    tabletColumns: 3,
                    desktopColumns: 3,
                    cellHeight: 160,
                    spacing: 20,
                    children: [
                      BentoItem(
                        colSpan: 2,
                        rowSpan: 4,
                        child: _ExpensesListCard(isDesktop: true),
                      ),
                      BentoItem(colSpan: 1, rowSpan: 1, child: _QuickAddCard()),
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

Future<void> _confirmDeleteTransaction(
  BuildContext context,
  WidgetRef ref,
  String transactionId,
) async {
  final deleted = await _deleteTransactionAfterConfirmation(
    context,
    ref,
    transactionId,
  );
  if (deleted && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã xóa giao dịch')));
  }
}

Future<bool> _deleteTransactionAfterConfirmation(
  BuildContext context,
  WidgetRef ref,
  String transactionId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa giao dịch?'),
      content: const Text('Giao dịch sẽ được ẩn khỏi báo cáo và lịch sử.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  try {
    await ref
        .read(transactionsProvider.notifier)
        .deleteTransaction(transactionId);
    return true;
  } catch (error) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Không thể xóa giao dịch: $error')));
    return false;
  }
}

// ─── Cards ───────────────────────────────────────────────────────────────────

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
            Text(
              'Nhập tay',
              style: theme.textTheme.labelLarge?.copyWith(
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
            child: BentoSectionHeader(title: 'Chi phí gần đây'),
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
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có giao dịch nào.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final categories = categoriesState.value ?? [];
                final recentTransactions = transactions.take(5).toList();

                if (isDesktop) {
                  return SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 600),
                        child: DataTable(
                          showCheckboxColumn: false,
                          headingRowColor: WidgetStatePropertyAll(
                            theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                          ),
                          dataRowMaxHeight: 72,
                          dataRowMinHeight: 72,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Chi phí',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Danh mục',
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
                                'Hành động',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                          rows: recentTransactions.map((tx) {
                            CategoryModel? category;
                            for (final item in categories) {
                              if (item.categoryId == tx.categoryId) {
                                category = item;
                                break;
                              }
                            }

                            final iconName =
                                category?.iconName ?? 'attach_money';
                            IconData getIcon(String name) {
                              switch (name) {
                                case 'restaurant':
                                  return Icons.restaurant;
                                case 'flight':
                                  return Icons.flight;
                                case 'computer':
                                  return Icons.computer;
                                case 'local_gas_station':
                                  return Icons.local_gas_station;
                                default:
                                  return Icons.attach_money;
                              }
                            }

                            final amountText =
                                tx.transactionType == TransactionType.expense
                                ? '-${currencyFmt.format(tx.amount)}'
                                : '+${currencyFmt.format(tx.amount)}';

                            final amountColor =
                                tx.transactionType == TransactionType.expense
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary;

                            return DataRow(
                              onSelectChanged: (_) =>
                                  context.push('/expenses/${tx.transactionId}'),
                              cells: [
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          getIcon(iconName),
                                          color: theme.colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              tx.description?.isNotEmpty == true
                                                  ? tx.description!
                                                  : 'Giao dịch',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${category?.categoryName ?? 'Chưa phân loại'} • ${tx.approvalStatus.label}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    category?.categoryName ?? 'Chưa phân loại',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(tx.transactionDate),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    amountText,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                      color: amountColor,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  tx.invoiceId != null
                                      ? const Tooltip(
                                          message:
                                              'Giao dịch đã khóa theo hóa đơn',
                                          child: Icon(
                                            Icons.lock_outline_rounded,
                                          ),
                                        )
                                      : IconButton(
                                          tooltip: 'Xóa giao dịch',
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _confirmDeleteTransaction(
                                                context,
                                                ref,
                                                tx.transactionId,
                                              ),
                                        ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                } else {
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: recentTransactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = recentTransactions[index];
                      CategoryModel? category;
                      for (final item in categories) {
                        if (item.categoryId == tx.categoryId) {
                          category = item;
                          break;
                        }
                      }

                      final iconName = category?.iconName ?? 'attach_money';
                      IconData getIcon(String name) {
                        switch (name) {
                          case 'restaurant':
                            return Icons.restaurant;
                          case 'flight':
                            return Icons.flight;
                          case 'computer':
                            return Icons.computer;
                          case 'local_gas_station':
                            return Icons.local_gas_station;
                          default:
                            return Icons.attach_money;
                        }
                      }

                      final amountText =
                          tx.transactionType == TransactionType.expense
                          ? '-${currencyFmt.format(tx.amount)}'
                          : '+${currencyFmt.format(tx.amount)}';
                      final amountColor =
                          tx.transactionType == TransactionType.expense
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary;

                      return Dismissible(
                        key: ValueKey(tx.transactionId),
                        direction: tx.invoiceId == null
                            ? DismissDirection.endToStart
                            : DismissDirection.none,
                        movementDuration: const Duration(milliseconds: 250),
                        resizeDuration: const Duration(milliseconds: 220),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          color: theme.colorScheme.errorContainer,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        confirmDismiss: (_) async {
                          final deleted =
                              await _deleteTransactionAfterConfirmation(
                                context,
                                ref,
                                tx.transactionId,
                              );
                          if (deleted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã xóa giao dịch')),
                            );
                          }
                          return deleted;
                        },
                        child: InkWell(
                          onTap: () =>
                              context.push('/expenses/${tx.transactionId}'),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .primaryContainer
                                              .withValues(alpha: 0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          getIcon(iconName),
                                          color: theme.colorScheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              tx.description?.isNotEmpty == true
                                                  ? tx.description!
                                                  : 'Giao dịch',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${category?.categoryName ?? 'Chưa phân loại'} • ${DateFormat('dd/MM').format(tx.transactionDate)} • ${tx.approvalStatus.label}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      amountText,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: amountColor,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Inter',
                                          ),
                                    ),
                                    if (tx.receiptImagePath != null) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ],
                                    if (tx.invoiceId != null) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.lock_outline_rounded,
                                        size: 17,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
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
                onPressed: () => context.push('/expenses/history'),
                child: const Text(
                  'Xem tất cả chi phí',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
