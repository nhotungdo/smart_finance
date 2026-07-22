import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/providers/accounts_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:smart_finance/ui/widgets/page_header.dart';

class TransactionApprovalScreen extends ConsumerWidget {
  const TransactionApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingState = ref.watch(pendingTransactionsProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <UserModel>[];
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 600;
    final names = {
      for (final account in accounts) account.userId: account.fullName,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
          ref.invalidate(pendingTransactionsProvider);
          ref.invalidate(accountsProvider);
          await ref.read(pendingTransactionsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 16 : 24,
            vertical: compact ? 16 : 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeader(
                    title: 'Duyệt giao dịch',
                    subtitle:
                        'Kiểm tra các khoản thu chi do nhân viên gửi lên.',
                    compact: true,
                  ),
                  const SizedBox(height: 18),
                  pendingState.when(
                    loading: () => const SizedBox(
                      height: 320,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => _ErrorState(
                      message: error.toString(),
                      onRetry: () =>
                          ref.invalidate(pendingTransactionsProvider),
                    ),
                    data: (transactions) => transactions.isEmpty
                        ? _EmptyState(compact: compact)
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth >= 760) {
                                return _DesktopApprovalTable(
                                  transactions: transactions,
                                  creatorNames: names,
                                );
                              }
                              return Column(
                                children: transactions
                                    .map(
                                      (transaction) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: _MobileApprovalCard(
                                          transaction: transaction,
                                          creatorName:
                                              names[transaction.createdBy] ??
                                              'Nhân viên',
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopApprovalTable extends ConsumerWidget {
  const _DesktopApprovalTable({
    required this.transactions,
    required this.creatorNames,
  });

  final List<TransactionModel> transactions;
  final Map<String, String> creatorNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) => BentoCard(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              horizontalMargin: 20,
              columnSpacing: 24,
              headingRowHeight: 48,
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              columns: const [
                DataColumn(label: Text('Nhân viên')),
                DataColumn(label: Text('Nội dung')),
                DataColumn(label: Text('Loại')),
                DataColumn(label: Text('Ngày')),
                DataColumn(label: Text('Số tiền'), numeric: true),
                DataColumn(label: Text('Hành động')),
              ],
              rows: transactions.map((transaction) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 150,
                        child: Text(
                          creatorNames[transaction.createdBy] ?? 'Nhân viên',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 190,
                        child: Text(
                          transaction.description ?? 'Không có mô tả',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(_TypeChip(type: transaction.transactionType)),
                    DataCell(
                      Text(
                        DateFormat(
                          'dd/MM/yyyy',
                        ).format(transaction.transactionDate),
                      ),
                    ),
                    DataCell(
                      Text(_formatMoney(transaction.amount), maxLines: 1),
                    ),
                    DataCell(
                      _ReviewActions(transaction: transaction, compact: true),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileApprovalCard extends StatelessWidget {
  const _MobileApprovalCard({
    required this.transaction,
    required this.creatorName,
  });

  final TransactionModel transaction;
  final String creatorName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creatorName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(transaction.transactionDate),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _TypeChip(type: transaction.transactionType),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            transaction.description ?? 'Không có mô tả',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _formatMoney(transaction.amount),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: transaction.transactionType == TransactionType.income
                  ? const Color(0xFF059669)
                  : theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: _ReviewActions(transaction: transaction),
          ),
        ],
      ),
    );
  }
}

class _ReviewActions extends ConsumerStatefulWidget {
  const _ReviewActions({required this.transaction, this.compact = false});

  final TransactionModel transaction;
  final bool compact;

  @override
  ConsumerState<_ReviewActions> createState() => _ReviewActionsState();
}

class _ReviewActionsState extends ConsumerState<_ReviewActions> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return SizedBox(
        width: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _ReviewIconButton(
              tooltip: 'Từ chối',
              icon: Icons.close_rounded,
              foregroundColor: Theme.of(context).colorScheme.error,
              onPressed: _isSubmitting ? null : () => _reject(context),
            ),
            const SizedBox(width: 6),
            _ReviewIconButton(
              tooltip: 'Duyệt',
              icon: Icons.check_rounded,
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: _isSubmitting ? null : () => _approve(context),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: _isSubmitting ? null : () => _reject(context),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('Từ chối'),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : () => _approve(context),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Duyệt'),
        ),
      ],
    );
  }

  Future<void> _approve(BuildContext context) async {
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(transactionsProvider.notifier)
          .reviewTransaction(
            transactionId: widget.transaction.transactionId,
            decision: ApprovalStatus.approved,
          );
      if (context.mounted) _showMessage(context, 'Đã duyệt giao dịch.');
    } catch (error) {
      if (context.mounted) _showMessage(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reject(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _RejectDialog(),
    );
    if (reason == null || !context.mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(transactionsProvider.notifier)
          .reviewTransaction(
            transactionId: widget.transaction.transactionId,
            decision: ApprovalStatus.rejected,
            rejectionReason: reason,
          );
      if (context.mounted) _showMessage(context, 'Đã từ chối giao dịch.');
    } catch (error) {
      if (context.mounted) _showMessage(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _ReviewIconButton extends StatelessWidget {
  const _ReviewIconButton({
    required this.tooltip,
    required this.icon,
    required this.foregroundColor,
    required this.onPressed,
    this.backgroundColor,
  });

  final String tooltip;
  final IconData icon;
  final Color foregroundColor;
  final Color? backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(36),
        minimumSize: const Size.square(36),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        side: backgroundColor == null
            ? BorderSide(color: foregroundColor.withValues(alpha: 0.5))
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog();

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Từ chối giao dịch'),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: TextFormField(
          controller: _controller,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Lý do từ chối',
            hintText: 'Nhập lý do để nhân viên biết cần sửa gì',
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Vui lòng nhập lý do từ chối'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Xác nhận'),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TransactionType.income;
    final color = isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isIncome ? 'Thu' : 'Chi',
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: SizedBox(
        height: compact ? 160 : 220,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.task_alt_rounded, size: 52),
              SizedBox(height: 12),
              Text('Không có giao dịch nào đang chờ duyệt.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

String _formatMoney(int amount) {
  return '${NumberFormat.decimalPattern('vi_VN').format(amount)} đ';
}

void _showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error
          ? Theme.of(context).colorScheme.error
          : const Color(0xFF059669),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
