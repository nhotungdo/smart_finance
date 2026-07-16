class ReportSummaryModel {
  final int totalIncome;
  final int totalExpense;
  final int netProfit;
  final int currentAssets;
  final int currentLiabilities;
  final int totalEquity;

  ReportSummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfit,
    required this.currentAssets,
    required this.currentLiabilities,
    required this.totalEquity,
  });
}

class ExpenseAnalysisModel {
  final String categoryId;
  final String categoryName;
  final String colorCode;
  final int amount;
  final double percentage;

  ExpenseAnalysisModel({
    required this.categoryId,
    required this.categoryName,
    required this.colorCode,
    required this.amount,
    required this.percentage,
  });
}

class ChartDataPoint {
  final String label; // e.g., 'Jan', 'Feb', 'Q1', etc.
  final int value1; // e.g., Income
  final int value2; // e.g., Expense

  ChartDataPoint({required this.label, required this.value1, this.value2 = 0});
}

class ReportData {
  final ReportSummaryModel summary;
  final List<ExpenseAnalysisModel> expenseAnalysis;
  final List<ChartDataPoint> profitLossChart;

  ReportData({
    required this.summary,
    required this.expenseAnalysis,
    required this.profitLossChart,
  });
}
