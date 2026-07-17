import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/report_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/providers/reports_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/ui/screens/dashboard/dashboard_screen.dart';
import 'package:smart_finance/ui/screens/expenses/expenses_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoicing_screen.dart';
import 'package:smart_finance/ui/screens/reports/reports_screen.dart';

class _FakeTransactionsNotifier extends TransactionsNotifier {
  @override
  Future<List<TransactionModel>> build() async => _transactions;
}

class _FakeCategoriesNotifier extends CategoriesNotifier {
  @override
  Future<List<CategoryModel>> build() async => const [];
}

class _FakeInvoicesNotifier extends InvoicesNotifier {
  @override
  Future<List<InvoiceModel>> build() async => const [];
}

final _transactions = [
  TransactionModel(
    transactionId: 'income-1',
    amount: 2500000,
    transactionType: TransactionType.income,
    transactionDate: DateTime.now(),
    description: 'Doanh thu',
  ),
  TransactionModel(
    transactionId: 'expense-1',
    amount: 1200000,
    transactionType: TransactionType.expense,
    transactionDate: DateTime.now(),
    description: 'Mat bang',
  ),
];

ReportDataExtended _reportData() {
  final summary = ReportSummaryModel(
    totalIncome: 2500000,
    totalExpense: 1200000,
    netProfit: 1300000,
    currentAssets: 1300000,
    currentLiabilities: 120000,
    totalEquity: 1180000,
  );
  return ReportDataExtended(
    current: ReportData(
      summary: summary,
      expenseAnalysis: [
        ExpenseAnalysisModel(
          categoryId: 'office',
          categoryName: 'Van phong',
          colorCode: '#10B981',
          amount: 1200000,
          percentage: 100,
        ),
      ],
      profitLossChart: [
        ChartDataPoint(label: 'T1', value1: 2500000, value2: 1200000),
        ChartDataPoint(label: 'T2', value1: 1800000, value2: 900000),
      ],
    ),
    previous: summary,
    period: ReportPeriod.thisMonth,
    dateRange: ReportDateRange(
      start: DateTime(2026, 7),
      end: DateTime(2026, 7, 31),
    ),
  );
}

void main() {
  final responsiveSizes = <Size>[
    const Size(390, 844),
    const Size(844, 390),
    const Size(1280, 800),
  ];

  Future<void> pumpResponsiveScreen(
    WidgetTester tester,
    Widget screen, {
    ProviderScope Function(Widget child)? buildScope,
  }) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));

    for (final size in responsiveSizes) {
      await tester.binding.setSurfaceSize(size);
      final app = MaterialApp(home: Scaffold(body: screen));
      await tester.pumpWidget(
        buildScope?.call(app) ?? ProviderScope(child: app),
      );
      await tester.pumpAndSettle();
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: '${screen.runtimeType} overflowed at $size',
      );
    }
  }

  testWidgets('dashboard supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const DashboardScreen(),
      buildScope: (child) => ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(_FakeTransactionsNotifier.new),
        ],
        child: child,
      ),
    );
  });

  testWidgets('expenses supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const ExpensesScreen(),
      buildScope: (child) => ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(_FakeTransactionsNotifier.new),
          categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
        ],
        child: child,
      ),
    );
  });

  testWidgets('invoicing supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const InvoicingScreen(),
      buildScope: (child) => ProviderScope(
        overrides: [invoicesProvider.overrideWith(_FakeInvoicesNotifier.new)],
        child: child,
      ),
    );
  });

  testWidgets('reports supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const ReportsScreen(),
      buildScope: (child) => ProviderScope(
        overrides: [reportsProvider.overrideWith((ref) async => _reportData())],
        child: child,
      ),
    );
  });
}
