import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';

class TransactionsHistoryScreen extends ConsumerWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(allTransactionsProvider);
    final categories = ref.watch(categoriesProvider).value ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Quay lại',
                  onPressed: () => _goBack(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: 8),
              PageHeader(
                title: 'Lịch sử giao dịch',
                subtitle: 'Toàn bộ các khoản thu và chi đã lưu.',
                action: IconButton.filledTonal(
                  tooltip: 'Tải lại',
                  onPressed: () => ref.invalidate(allTransactionsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: transactionsState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text('Không thể tải lịch sử: $error')),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const _EmptyHistory();
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth >= 820) {
                          return _DesktopHistory(
                            transactions: transactions,
                            categories: categories,
                          );
                        }
                        return _MobileHistory(
                          transactions: transactions,
                          categories: categories,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopHistory extends StatelessWidget {
  const _DesktopHistory({required this.transactions, required this.categories});

  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return BentoCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            headingRowColor: WidgetStatePropertyAll(
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            ),
            dataRowMinHeight: 64,
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(label: Text('Giao dịch')),
              DataColumn(label: Text('Loại')),
              DataColumn(label: Text('Danh mục')),
              DataColumn(label: Text('Ngày')),
              DataColumn(label: Text('Số tiền')),
              DataColumn(label: Text('')),
            ],
            rows: transactions.map((transaction) {
              final isExpense =
                  transaction.transactionType == TransactionType.expense;
              final amountColor = isExpense
                  ? theme.colorScheme.error
                  : const Color(0xFF10B981);
              final category = _findCategory(
                categories,
                transaction.categoryId,
              );
              return DataRow(
                onSelectChanged: (_) => _openDetails(context, transaction),
                cells: [
                  DataCell(
                    Text(
                      transaction.description?.isNotEmpty == true
                          ? transaction.description!
                          : 'Giao dịch',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(Text(isExpense ? 'Chi' : 'Thu')),
                  DataCell(Text(category?.categoryName ?? 'Chưa phân loại')),
                  DataCell(
                    Text(
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(transaction.transactionDate),
                    ),
                  ),
                  DataCell(
                    Text(
                      '${isExpense ? '-' : '+'}${currency.format(transaction.amount)}',
                      style: TextStyle(
                        color: amountColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const DataCell(Icon(Icons.chevron_right_rounded)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MobileHistory extends StatelessWidget {
  const _MobileHistory({required this.transactions, required this.categories});

  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        itemCount: transactions.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final category = _findCategory(categories, transaction.categoryId);
          return _HistoryTile(transaction: transaction, category: category);
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.transaction, this.category});

  final TransactionModel transaction;
  final CategoryModel? category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = transaction.transactionType == TransactionType.expense;
    final amountColor = isExpense
        ? theme.colorScheme.error
        : const Color(0xFF10B981);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return InkWell(
      onTap: () => _openDetails(context, transaction),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isExpense
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: amountColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description?.isNotEmpty == true
                        ? transaction.description!
                        : 'Giao dịch',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${category?.categoryName ?? 'Chưa phân loại'} • ${DateFormat('dd/MM/yyyy').format(transaction.transactionDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 132),
              child: Text(
                '${isExpense ? '-' : '+'}${currency.format(transaction.amount)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 52),
          SizedBox(height: 16),
          Text('Chưa có giao dịch nào.'),
        ],
      ),
    );
  }
}

CategoryModel? _findCategory(
  List<CategoryModel> categories,
  String? categoryId,
) {
  if (categoryId == null) return null;
  for (final category in categories) {
    if (category.categoryId == categoryId) return category;
  }
  return null;
}

void _openDetails(BuildContext context, TransactionModel transaction) {
  context.push('/expenses/${transaction.transactionId}');
}

void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/expenses');
  }
}
