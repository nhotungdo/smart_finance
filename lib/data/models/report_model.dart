class ReportSummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double netProfit;
  final double currentAssets;
  final double currentLiabilities;
  final double totalEquity;

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
  final double amount;
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
  final double value1; // e.g., Income
  final double value2; // e.g., Expense

  ChartDataPoint({
    required this.label,
    required this.value1,
    this.value2 = 0.0,
  });
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
