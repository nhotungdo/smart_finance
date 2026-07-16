// ignore_for_file: deprecated_member_use
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/report_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';

// ─────────────────────────────────────────────────────────────
// Enum: Bộ lọc thời gian
// ─────────────────────────────────────────────────────────────
enum ReportPeriod { today, thisWeek, thisMonth, thisQuarter, thisYear }

extension ReportPeriodLabel on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.today:       return 'Hôm nay';
      case ReportPeriod.thisWeek:    return 'Tuần này';
      case ReportPeriod.thisMonth:   return 'Tháng này';
      case ReportPeriod.thisQuarter: return 'Quý này';
      case ReportPeriod.thisYear:    return 'Năm nay';
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Data class: Khoảng thời gian
// ─────────────────────────────────────────────────────────────
class ReportDateRange {
  final DateTime start;
  final DateTime end;
  const ReportDateRange({required this.start, required this.end});
}

// ─────────────────────────────────────────────────────────────
// Helper: Tính DateRange từ ReportPeriod
// ─────────────────────────────────────────────────────────────
ReportDateRange getDateRange(ReportPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case ReportPeriod.today:
      return ReportDateRange(
        start: DateTime(now.year, now.month, now.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case ReportPeriod.thisWeek:
      final s = now.subtract(Duration(days: now.weekday - 1));
      return ReportDateRange(
        start: DateTime(s.year, s.month, s.day),
        end: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );
    case ReportPeriod.thisMonth:
      return ReportDateRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
    case ReportPeriod.thisQuarter:
      final q = (now.month - 1) ~/ 3;
      final sm = q * 3 + 1;
      return ReportDateRange(
        start: DateTime(now.year, sm, 1),
        end: DateTime(now.year, sm + 3, 0, 23, 59, 59),
      );
    case ReportPeriod.thisYear:
      return ReportDateRange(
        start: DateTime(now.year, 1, 1),
        end: DateTime(now.year, 12, 31, 23, 59, 59),
      );
  }
}

ReportDateRange getPreviousDateRange(ReportPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case ReportPeriod.today:
      final y = now.subtract(const Duration(days: 1));
      return ReportDateRange(
        start: DateTime(y.year, y.month, y.day),
        end: DateTime(y.year, y.month, y.day, 23, 59, 59),
      );
    case ReportPeriod.thisWeek:
      final s = now.subtract(Duration(days: now.weekday - 1 + 7));
      final e = now.subtract(Duration(days: now.weekday));
      return ReportDateRange(
        start: DateTime(s.year, s.month, s.day),
        end: DateTime(e.year, e.month, e.day, 23, 59, 59),
      );
    case ReportPeriod.thisMonth:
      return ReportDateRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 0, 23, 59, 59),
      );
    case ReportPeriod.thisQuarter:
      final q = (now.month - 1) ~/ 3;
      final sm = q * 3 - 2;
      final em = q * 3;
      if (sm < 1) {
        return ReportDateRange(
          start: DateTime(now.year - 1, sm + 12, 1),
          end: DateTime(now.year - 1, em + 12 + 1, 0, 23, 59, 59),
        );
      }
      return ReportDateRange(
        start: DateTime(now.year, sm, 1),
        end: DateTime(now.year, em + 1, 0, 23, 59, 59),
      );
    case ReportPeriod.thisYear:
      return ReportDateRange(
        start: DateTime(now.year - 1, 1, 1),
        end: DateTime(now.year - 1, 12, 31, 23, 59, 59),
      );
  }
}

// ─────────────────────────────────────────────────────────────
// StateProvider: Bộ lọc đang chọn
// ─────────────────────────────────────────────────────────────
class ReportPeriodNotifier extends Notifier<ReportPeriod> {
  @override
  ReportPeriod build() => ReportPeriod.thisMonth;

  void update(ReportPeriod newPeriod) {
    state = newPeriod;
  }
}

final reportPeriodProvider = NotifierProvider<ReportPeriodNotifier, ReportPeriod>(
  () => ReportPeriodNotifier(),
);

// ─────────────────────────────────────────────────────────────
// Data class: Báo cáo đầy đủ kèm kỳ trước
// ─────────────────────────────────────────────────────────────
class ReportDataExtended {
  final ReportData current;
  final ReportSummaryModel previous;
  final ReportPeriod period;
  final ReportDateRange dateRange;

  const ReportDataExtended({
    required this.current,
    required this.previous,
    required this.period,
    required this.dateRange,
  });

  String trendLabel(double cur, double prev) {
    if (prev == 0) return cur > 0 ? '▲ Mới' : '-';
    final d = ((cur - prev) / prev) * 100;
    return '${d >= 0 ? '+' : ''}${d.toStringAsFixed(1)}%';
  }

  bool isTrendPositive(double cur, double prev) => cur >= prev;
}

// ─────────────────────────────────────────────────────────────
// Core computation
// ─────────────────────────────────────────────────────────────
ReportData _computeReport(
  List<TransactionModel> txList,
  List<CategoryModel> categories,
  ReportPeriod period,
  ReportDateRange range,
) {
  final defaultColors = ['#3B82F6','#10B981','#F59E0B','#EF4444','#8B5CF6','#6B7280','#F97316','#06B6D4'];
  double totalIncome = 0, totalExpense = 0;
  final Map<String, double> expByCategory = {};

  for (final tx in txList) {
    if (tx.transactionType == 'income') {
      totalIncome += tx.amount;
    } else {
      totalExpense += tx.amount;
      final k = tx.categoryId ?? 'uncategorized';
      expByCategory[k] = (expByCategory[k] ?? 0) + tx.amount;
    }
  }

  int ci = 0;
  final analysis = expByCategory.entries.map((e) {
    final cat = categories.firstWhere(
      (c) => c.categoryId == e.key,
      orElse: () => CategoryModel(
        categoryId: 'uncategorized',
        categoryName: 'Khác',
        categoryType: 'expense',
        colorCode: '#6B7280',
      ),
    );
    final pct = totalExpense > 0 ? (e.value / totalExpense) * 100 : 0.0;
    final color = cat.colorCode ?? defaultColors[ci % defaultColors.length];
    ci++;
    return ExpenseAnalysisModel(
      categoryId: e.key,
      categoryName: cat.categoryName,
      colorCode: color,
      amount: e.value,
      percentage: pct,
    );
  }).toList()
    ..sort((a, b) => b.percentage.compareTo(a.percentage));

  final chart = _buildChart(txList, period, range);
  final summary = ReportSummaryModel(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    netProfit: totalIncome - totalExpense,
    currentAssets: totalIncome - totalExpense,
    currentLiabilities: totalExpense * 0.1,
    totalEquity: (totalIncome - totalExpense) - totalExpense * 0.1,
  );
  return ReportData(summary: summary, expenseAnalysis: analysis, profitLossChart: chart);
}

// ─────────────────────────────────────────────────────────────
// Chart builder — nhóm theo đơn vị tương ứng
// ─────────────────────────────────────────────────────────────
List<ChartDataPoint> _buildChart(
  List<TransactionModel> txList,
  ReportPeriod period,
  ReportDateRange range,
) {
  double sumIncome(Iterable<TransactionModel> t) =>
      t.where((x) => x.transactionType == 'income').fold(0.0, (s, x) => s + x.amount);
  double sumExpense(Iterable<TransactionModel> t) =>
      t.where((x) => x.transactionType == 'expense').fold(0.0, (s, x) => s + x.amount);

  switch (period) {
    case ReportPeriod.today:
      // Theo từng giờ có giao dịch
      final hourSet = txList.map((t) => t.transactionDate.hour).toSet().toList()..sort();
      if (hourSet.isEmpty) {
        return [ChartDataPoint(label: 'Hôm nay', value1: 0, value2: 0)];
      }
      return hourSet.map((h) {
        final ht = txList.where((t) => t.transactionDate.hour == h);
        return ChartDataPoint(label: '${h}h', value1: sumIncome(ht), value2: sumExpense(ht));
      }).toList();

    case ReportPeriod.thisWeek:
      const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      return List.generate(7, (i) {
        final day = range.start.add(Duration(days: i));
        final dt = txList.where((t) =>
            t.transactionDate.year == day.year &&
            t.transactionDate.month == day.month &&
            t.transactionDate.day == day.day);
        return ChartDataPoint(label: labels[i], value1: sumIncome(dt), value2: sumExpense(dt));
      });

    case ReportPeriod.thisMonth:
      final daysInMonth = DateTime(range.start.year, range.start.month + 1, 0).day;
      final weeks = <ChartDataPoint>[];
      for (int w = 0; w < 5; w++) {
        final sd = w * 7 + 1;
        if (sd > daysInMonth) break;
        final ed = (sd + 6).clamp(1, daysInMonth);
        final wt = txList.where((t) => t.transactionDate.day >= sd && t.transactionDate.day <= ed);
        weeks.add(ChartDataPoint(label: 'T${w + 1}', value1: sumIncome(wt), value2: sumExpense(wt)));
      }
      return weeks;

    case ReportPeriod.thisQuarter:
      final sm = range.start.month;
      return List.generate(3, (i) {
        final m = sm + i;
        final mt = txList.where((t) => t.transactionDate.month == m);
        return ChartDataPoint(label: 'Th $m', value1: sumIncome(mt), value2: sumExpense(mt));
      });

    case ReportPeriod.thisYear:
      const ml = ['T1','T2','T3','T4','T5','T6','T7','T8','T9','T10','T11','T12'];
      return List.generate(12, (i) {
        final mt = txList.where((t) => t.transactionDate.month == i + 1);
        return ChartDataPoint(label: ml[i], value1: sumIncome(mt), value2: sumExpense(mt));
      });
  }
}

// ─────────────────────────────────────────────────────────────
// Main FutureProvider
// ─────────────────────────────────────────────────────────────
final reportsProvider = FutureProvider<ReportDataExtended>((ref) async {
  final period     = ref.watch(reportPeriodProvider);
  final categories = await ref.watch(categoriesProvider.future);
  final repo       = ref.read(transactionRepositoryProvider);

  final range = getDateRange(period);
  final prev  = getPreviousDateRange(period);

  final results = await Future.wait<List<TransactionModel>>([
    repo.getTransactionsByDateRange(range.start, range.end),
    repo.getTransactionsByDateRange(prev.start, prev.end),
  ]);

  final curReport = _computeReport(results[0], categories, period, range);

  double pi = 0, pe = 0;
  for (final tx in results[1]) {
    if (tx.transactionType == 'income') {
      pi += tx.amount;
    } else {
      pe += tx.amount;
    }
  }

  final prevSummary = ReportSummaryModel(
    totalIncome: pi,
    totalExpense: pe,
    netProfit: pi - pe,
    currentAssets: pi - pe,
    currentLiabilities: pe * 0.1,
    totalEquity: (pi - pe) - pe * 0.1,
  );

  return ReportDataExtended(
    current: curReport,
    previous: prevSummary,
    period: period,
    dateRange: range,
  );
});
