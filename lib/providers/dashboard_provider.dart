import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/domain/services/finance_calculator.dart';
import 'package:smart_finance/providers/transactions_provider.dart';

// ─────────────────────────────────────────────────────────────
// Data class: Tóm tắt tài chính tổng quan
// ─────────────────────────────────────────────────────────────
class FinancialSummary {
  final int totalIncome;
  final int totalExpense;
  final int cashFlow; // Thu - Chi

  const FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.cashFlow,
  });

  factory FinancialSummary.empty() =>
      const FinancialSummary(totalIncome: 0, totalExpense: 0, cashFlow: 0);
}

// ─────────────────────────────────────────────────────────────
// Data class: Nhóm giao dịch theo ngày
// ─────────────────────────────────────────────────────────────
class TransactionGroup {
  final String dateLabel; // Ví dụ: "Hôm nay", "Hôm qua", "16/07/2026"
  final DateTime date;
  final List<TransactionModel> transactions;
  final int dayTotal; // Tổng tiền ngày đó (thu - chi)

  const TransactionGroup({
    required this.dateLabel,
    required this.date,
    required this.transactions,
    required this.dayTotal,
  });
}

// ─────────────────────────────────────────────────────────────
// Data class: Điểm dữ liệu biểu đồ dòng tiền (7 ngày gần nhất)
// ─────────────────────────────────────────────────────────────
class CashFlowPoint {
  final String label; // "T2", "T3", ...
  final int income;
  final int expense;

  const CashFlowPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
}

// ─────────────────────────────────────────────────────────────
// Provider: Tóm tắt tài chính tháng hiện tại
// ─────────────────────────────────────────────────────────────
final financialSummaryProvider = Provider<AsyncValue<FinancialSummary>>((ref) {
  final txAsync = ref.watch(transactionsProvider);

  return txAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
    data: (transactions) {
      final now = DateTime.now();
      // Lọc giao dịch trong tháng hiện tại
      final thisMonth = transactions.where((t) {
        return t.transactionDate.year == now.year &&
            t.transactionDate.month == now.month;
      }).toList();

      final income = FinanceCalculator.totalIncome(thisMonth);
      final expense = FinanceCalculator.totalExpense(thisMonth);

      return AsyncValue.data(
        FinancialSummary(
          totalIncome: income,
          totalExpense: expense,
          cashFlow: income - expense,
        ),
      );
    },
  );
});

// ─────────────────────────────────────────────────────────────
// Provider: Danh sách giao dịch nhóm theo ngày (cho Dashboard)
// ─────────────────────────────────────────────────────────────
final groupedTransactionsProvider =
    Provider<AsyncValue<List<TransactionGroup>>>((ref) {
      final txAsync = ref.watch(transactionsProvider);

      return txAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, s) => AsyncValue.error(e, s),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const AsyncValue.data([]);
          }

          // Sắp xếp mới nhất lên trên
          final sorted = [...transactions]
            ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

          // Nhóm theo ngày (yyyy-MM-dd)
          final Map<String, List<TransactionModel>> groups = {};
          for (final tx in sorted) {
            final key = DateFormat('yyyy-MM-dd').format(tx.transactionDate);
            groups.putIfAbsent(key, () => []).add(tx);
          }

          final today = DateTime.now();
          final yesterday = today.subtract(const Duration(days: 1));

          final result = groups.entries.map((entry) {
            final date = DateTime.parse(entry.key);
            final txList = entry.value;

            // Tính tổng ngày: thu dương, chi âm
            final dayTotal = txList.fold(0, (sum, t) {
              return sum +
                  (t.transactionType == TransactionType.income
                      ? t.amount
                      : -t.amount);
            });

            // Nhãn ngày thân thiện
            String label;
            if (_isSameDay(date, today)) {
              label = 'Hôm nay';
            } else if (_isSameDay(date, yesterday)) {
              label = 'Hôm qua';
            } else {
              label = DateFormat('dd/MM/yyyy').format(date);
            }

            return TransactionGroup(
              dateLabel: label,
              date: date,
              transactions: txList,
              dayTotal: dayTotal,
            );
          }).toList();

          // Đã sort theo date key → entries đảm bảo thứ tự mới nhất
          result.sort((a, b) => b.date.compareTo(a.date));
          return AsyncValue.data(result);
        },
      );
    });

// ─────────────────────────────────────────────────────────────
// Provider: Dữ liệu biểu đồ dòng tiền 7 ngày gần nhất
// ─────────────────────────────────────────────────────────────
final cashFlowChartProvider = Provider<AsyncValue<List<CashFlowPoint>>>((ref) {
  final txAsync = ref.watch(transactionsProvider);

  return txAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
    data: (transactions) {
      final today = DateTime.now();
      final points = <CashFlowPoint>[];

      // Tính 7 ngày gần nhất (từ 6 ngày trước → hôm nay)
      for (int i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final dayTx = transactions.where(
          (t) => _isSameDay(t.transactionDate, day),
        );

        final income = dayTx
            .where((t) => t.transactionType == TransactionType.income)
            .fold(0, (s, t) => s + t.amount);

        final expense = dayTx
            .where((t) => t.transactionType == TransactionType.expense)
            .fold(0, (s, t) => s + t.amount);

        final weekdayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
        points.add(
          CashFlowPoint(
            label: weekdayLabels[day.weekday % 7],
            income: income,
            expense: expense,
          ),
        );
      }
      return AsyncValue.data(points);
    },
  );
});

// ─────────────────────────────────────────────────────────────
// Provider: 3 giao dịch gần nhất (cho quick summary)
// ─────────────────────────────────────────────────────────────
final recentTransactionsProvider = Provider<AsyncValue<List<TransactionModel>>>(
  (ref) {
    final txAsync = ref.watch(transactionsProvider);
    return txAsync.whenData((list) {
      final sorted = [...list]
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return sorted.take(5).toList();
    });
  },
);

// Helper
bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
