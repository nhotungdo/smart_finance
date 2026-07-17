// ignore_for_file: deprecated_member_use
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/report_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/domain/services/finance_calculator.dart';

// ─────────────────────────────────────────────────────────────
// Enum: Bộ lọc thời gian
// ─────────────────────────────────────────────────────────────
enum ReportPeriod { thisMonth, previousMonth, fiscalYear }

extension ReportPeriodLabel on ReportPeriod {
  String get label {
    switch (this) {
      case ReportPeriod.thisMonth:
        return 'Tháng này';
      case ReportPeriod.previousMonth:
        return 'Tháng trước';
      case ReportPeriod.fiscalYear:
        return 'Toàn bộ kỳ tài khóa';
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
    case ReportPeriod.thisMonth:
      return ReportDateRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
      );
    case ReportPeriod.previousMonth:
      return ReportDateRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 0, 23, 59, 59),
      );
    case ReportPeriod.fiscalYear:
      return ReportDateRange(
        start: DateTime(now.year, 1, 1),
        end: DateTime(now.year, 12, 31, 23, 59, 59),
      );
  }
}

ReportDateRange getPreviousDateRange(ReportPeriod period) {
  final now = DateTime.now();
  switch (period) {
    case ReportPeriod.thisMonth:
      return ReportDateRange(
        start: DateTime(now.year, now.month - 1, 1),
        end: DateTime(now.year, now.month, 0, 23, 59, 59),
      );
    case ReportPeriod.previousMonth:
      return ReportDateRange(
        start: DateTime(now.year, now.month - 2, 1),
        end: DateTime(now.year, now.month - 1, 0, 23, 59, 59),
      );
    case ReportPeriod.fiscalYear:
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

final reportPeriodProvider =
    NotifierProvider<ReportPeriodNotifier, ReportPeriod>(
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
  final InvoiceComparisonSummary invoiceComparison;

  const ReportDataExtended({
    required this.current,
    required this.previous,
    required this.period,
    required this.dateRange,
    this.invoiceComparison = const InvoiceComparisonSummary(),
  });

  String trendLabel(int cur, int prev) {
    if (prev == 0) return cur > 0 ? '▲ Mới' : '-';
    final d = ((cur - prev) / prev) * 100;
    return '${d >= 0 ? '+' : ''}${d.toStringAsFixed(1)}%';
  }

  bool isTrendPositive(int cur, int prev) => cur >= prev;
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
  final defaultColors = [
    '#3B82F6',
    '#10B981',
    '#F59E0B',
    '#EF4444',
    '#8B5CF6',
    '#6B7280',
    '#F97316',
    '#06B6D4',
  ];
  final totalIncome = FinanceCalculator.totalIncome(txList);
  final totalExpense = FinanceCalculator.totalExpense(txList);
  final Map<String, int> expByCategory = {};

  for (final tx in txList) {
    if (tx.transactionType == TransactionType.expense) {
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
        categoryType: TransactionType.expense,
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
  }).toList()..sort((a, b) => b.percentage.compareTo(a.percentage));

  final chart = _buildChart(txList, period, range);
  final summary = ReportSummaryModel(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    netProfit: totalIncome - totalExpense,
    currentAssets: totalIncome - totalExpense,
    currentLiabilities: totalExpense ~/ 10,
    totalEquity: (totalIncome - totalExpense) - (totalExpense ~/ 10),
  );
  return ReportData(
    summary: summary,
    expenseAnalysis: analysis,
    profitLossChart: chart,
  );
}

// ─────────────────────────────────────────────────────────────
// Chart builder — nhóm theo đơn vị tương ứng
// ─────────────────────────────────────────────────────────────
List<ChartDataPoint> _buildChart(
  List<TransactionModel> txList,
  ReportPeriod period,
  ReportDateRange range,
) {
  int sumIncome(Iterable<TransactionModel> t) => t
      .where((x) => x.transactionType == TransactionType.income)
      .fold(0, (s, x) => s + x.amount);
  int sumExpense(Iterable<TransactionModel> t) => t
      .where((x) => x.transactionType == TransactionType.expense)
      .fold(0, (s, x) => s + x.amount);

  switch (period) {
    case ReportPeriod.thisMonth:
    case ReportPeriod.previousMonth:
      final daysInMonth = DateTime(
        range.start.year,
        range.start.month + 1,
        0,
      ).day;
      final weeks = <ChartDataPoint>[];
      for (int w = 0; w < 5; w++) {
        final sd = w * 7 + 1;
        if (sd > daysInMonth) break;
        final ed = (sd + 6).clamp(1, daysInMonth);
        final wt = txList.where(
          (t) => t.transactionDate.day >= sd && t.transactionDate.day <= ed,
        );
        weeks.add(
          ChartDataPoint(
            label: 'T${w + 1}',
            value1: sumIncome(wt),
            value2: sumExpense(wt),
          ),
        );
      }
      return weeks;

    case ReportPeriod.fiscalYear:
      const ml = [
        'T1',
        'T2',
        'T3',
        'T4',
        'T5',
        'T6',
        'T7',
        'T8',
        'T9',
        'T10',
        'T11',
        'T12',
      ];
      return List.generate(12, (i) {
        final mt = txList.where((t) => t.transactionDate.month == i + 1);
        return ChartDataPoint(
          label: ml[i],
          value1: sumIncome(mt),
          value2: sumExpense(mt),
        );
      });
  }
}

// ─────────────────────────────────────────────────────────────
// Main FutureProvider
// ─────────────────────────────────────────────────────────────
final reportsProvider = FutureProvider<ReportDataExtended>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final categories = await ref.watch(categoriesProvider.future);
  final profile = await ref.watch(currentUserProfileProvider.future);
  final companyId = profile?.companyId;
  if (companyId == null) {
    throw StateError('Tài khoản chưa có hồ sơ doanh nghiệp.');
  }
  final repo = ref.read(transactionRepositoryProvider);
  final invoiceRepo = ref.read(invoiceRepositoryProvider);

  final range = getDateRange(period);
  final prev = getPreviousDateRange(period);

  final results = await Future.wait<List<TransactionModel>>([
    repo.getTransactionsByDateRange(
      range.start,
      range.end,
      companyId: companyId,
    ),
    repo.getTransactionsByDateRange(prev.start, prev.end, companyId: companyId),
  ]);
  final invoices = await invoiceRepo.getInvoicesByDateRange(
    range.start,
    range.end,
    companyId: companyId,
  );

  final curReport = _computeReport(results[0], categories, period, range);
  final invoiceIncome = FinanceCalculator.invoiceTotals(
    invoices,
    TransactionType.income,
  );
  final invoiceExpense = FinanceCalculator.invoiceTotals(
    invoices,
    TransactionType.expense,
  );

  final pi = FinanceCalculator.totalIncome(results[1]);
  final pe = FinanceCalculator.totalExpense(results[1]);

  final prevSummary = ReportSummaryModel(
    totalIncome: pi,
    totalExpense: pe,
    netProfit: pi - pe,
    currentAssets: pi - pe,
    currentLiabilities: pe ~/ 10,
    totalEquity: (pi - pe) - (pe ~/ 10),
  );

  return ReportDataExtended(
    current: curReport,
    previous: prevSummary,
    period: period,
    dateRange: range,
    invoiceComparison: InvoiceComparisonSummary(
      transactionIncome: curReport.summary.totalIncome,
      transactionExpense: curReport.summary.totalExpense,
      invoiceIncomeSubtotal: invoiceIncome.subtotal,
      invoiceIncomeVat: invoiceIncome.vat,
      invoiceIncomeTotal: invoiceIncome.total,
      invoiceExpenseSubtotal: invoiceExpense.subtotal,
      invoiceExpenseVat: invoiceExpense.vat,
      invoiceExpenseTotal: invoiceExpense.total,
    ),
  );
});
