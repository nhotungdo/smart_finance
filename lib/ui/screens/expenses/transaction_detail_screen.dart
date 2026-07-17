import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/ui/screens/expenses/widgets/receipt_image_view.dart';
import 'package:smart_finance/ui/screens/expenses/widgets/add_transaction_dialog.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionState = ref.watch(
      transactionDetailProvider(transactionId),
    );
    final categories = ref.watch(categoriesProvider).value ?? [];

    return transactionState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _MessageState(
        icon: Icons.error_outline_rounded,
        message: 'Không thể tải chi tiết giao dịch: $error',
        onBack: () => _goBack(context),
      ),
      data: (transaction) {
        if (transaction == null) {
          return _MessageState(
            icon: Icons.search_off_rounded,
            message: 'Không tìm thấy giao dịch này.',
            onBack: () => _goBack(context),
          );
        }
        return _TransactionDetails(
          transaction: transaction,
          category: _findCategory(categories, transaction.categoryId),
        );
      },
    );
  }
}

class _TransactionDetails extends ConsumerWidget {
  const _TransactionDetails({required this.transaction, this.category});

  final TransactionModel transaction;
  final CategoryModel? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpense = transaction.transactionType == TransactionType.expense;
    final accentColor = isExpense
        ? theme.colorScheme.error
        : const Color(0xFF10B981);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final date = DateFormat('dd/MM/yyyy');
    final dateTime = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Quay lại',
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (isExpense && transaction.invoiceId == null)
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/invoicing/create', extra: transaction),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text('Tạo hóa đơn'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: transaction.invoiceId != null
                        ? null
                        : () async {
                            await showDialog<void>(
                              context: context,
                              builder: (_) => AddTransactionDialog(
                                transaction: transaction,
                              ),
                            );
                            ref.invalidate(
                              transactionDetailProvider(
                                transaction.transactionId,
                              ),
                            );
                          },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      transaction.invoiceId == null
                          ? 'Sửa giao dịch'
                          : 'Đã khóa theo hóa đơn',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PageHeader(
                title: 'Chi tiết giao dịch',
                subtitle: transaction.description?.isNotEmpty == true
                    ? transaction.description!
                    : 'Thông tin khoản ${isExpense ? 'chi' : 'thu'}',
              ),
              const SizedBox(height: 24),
              BentoCard(
                showAccentStrip: true,
                accentColor: accentColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isExpense
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            isExpense ? 'Khoản chi' : 'Khoản thu',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${isExpense ? '-' : '+'}${currency.format(transaction.amount)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BentoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Thông tin giao dịch',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      icon: Icons.category_outlined,
                      label: 'Danh mục',
                      value: category?.categoryName ?? 'Chưa phân loại',
                    ),
                    _DetailRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Ngày giao dịch',
                      value: date.format(transaction.transactionDate),
                    ),
                    _DetailRow(
                      icon: Icons.notes_rounded,
                      label: 'Mô tả',
                      value: transaction.description?.isNotEmpty == true
                          ? transaction.description!
                          : 'Không có mô tả',
                    ),
                    _DetailRow(
                      icon: Icons.cloud_done_outlined,
                      label: 'Đồng bộ',
                      value: transaction.isSynced
                          ? 'Đã đồng bộ'
                          : 'Đang chờ đồng bộ',
                    ),
                    if (transaction.invoiceId != null)
                      _DetailRow(
                        icon: Icons.receipt_long_outlined,
                        label: 'Hóa đơn liên kết',
                        value: transaction.invoiceId!,
                        onTap: () => context.push(
                          '/invoicing/preview/${transaction.invoiceId}',
                        ),
                      ),
                    if (transaction.createdAt != null)
                      _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Thời điểm tạo',
                        value: dateTime.format(transaction.createdAt!),
                      ),
                    _DetailRow(
                      icon: Icons.tag_rounded,
                      label: 'Mã giao dịch',
                      value: transaction.transactionId,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              if (transaction.receiptImagePath != null) ...[
                const SizedBox(height: 20),
                BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Ảnh chứng từ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 460),
                          child: ReceiptImageView(
                            path: transaction.receiptImagePath!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                SizedBox(
                  width: 132,
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(
                    value,
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.onBack,
  });

  final IconData icon;
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Quay lại'),
            ),
          ],
        ),
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

void _goBack(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/expenses');
  }
}
