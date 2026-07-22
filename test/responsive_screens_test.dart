import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/data/models/category_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/data/models/invoice_model.dart';
import 'package:smart_finance/data/models/report_model.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/providers/accounts_provider.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/providers/categories_provider.dart';
import 'package:smart_finance/providers/invoices_provider.dart';
import 'package:smart_finance/providers/reports_provider.dart';
import 'package:smart_finance/providers/transactions_provider.dart';
import 'package:smart_finance/providers/theme_provider.dart';
import 'package:smart_finance/ui/screens/auth/forgot_password_screen.dart';
import 'package:smart_finance/ui/screens/auth/login_screen.dart';
import 'package:smart_finance/ui/screens/auth/register_screen.dart';
import 'package:smart_finance/ui/screens/dashboard/dashboard_screen.dart';
import 'package:smart_finance/ui/screens/expenses/expenses_screen.dart';
import 'package:smart_finance/ui/screens/expenses/transaction_detail_screen.dart';
import 'package:smart_finance/ui/screens/expenses/transactions_history_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/create_invoice_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoice_preview_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoice_sent_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoicing_screen.dart';
import 'package:smart_finance/ui/screens/reports/reports_screen.dart';
import 'package:smart_finance/ui/screens/manager/account_management_screen.dart';
import 'package:smart_finance/ui/screens/manager/transaction_approval_screen.dart';
import 'package:smart_finance/ui/screens/settings/settings_screen.dart';
import 'package:smart_finance/ui/widgets/bento_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTransactionsNotifier extends TransactionsNotifier {
  @override
  Future<List<TransactionModel>> build() async => _transactions;
}

class _FakeCategoriesNotifier extends CategoriesNotifier {
  @override
  Future<List<CategoryModel>> build() async => _categories;
}

class _FakeInvoicesNotifier extends InvoicesNotifier {
  @override
  Future<List<InvoiceModel>> build() async => _invoices;
}

class _FakeAccountsNotifier extends AccountsNotifier {
  @override
  Future<List<UserModel>> build() async => _accounts;
}

final _manager = UserModel(
  userId: 'manager-1',
  companyId: 'company-1',
  roleId: AppRole.manager.roleId,
  fullName: 'Quản lý',
  email: 'manager@example.com',
);

final _accounts = [
  _manager,
  UserModel(
    userId: 'accountant-1',
    companyId: 'company-1',
    roleId: AppRole.accountant.roleId,
    fullName: 'Nhân viên kế toán',
    email: 'accountant@example.com',
  ),
];

final _pendingTransactions = [
  TransactionModel(
    transactionId: 'pending-1',
    companyId: 'company-1',
    createdBy: 'accountant-1',
    amount: 1200000,
    transactionType: TransactionType.expense,
    transactionDate: DateTime(2026, 7, 21),
    description: 'Chi phí văn phòng',
    approvalStatus: ApprovalStatus.pending,
  ),
];

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

final _categories = [
  CategoryModel(
    categoryId: 'sales',
    categoryName: 'Doanh thu bán hàng',
    categoryType: TransactionType.income,
  ),
  CategoryModel(
    categoryId: 'office',
    categoryName: 'Văn phòng',
    categoryType: TransactionType.expense,
  ),
];

final _invoices = [
  InvoiceModel(
    id: 'invoice-1',
    companyId: 'company-1',
    uploadedBy: 'user-1',
    supplierName: 'Công ty TNHH Giải Pháp Số Việt Nam',
    invoiceNumber: 'INV-67497209',
    invoiceDate: DateTime(2026, 7, 17),
    totalAmount: 3850000,
    scanStatus: InvoiceScanStatus.scanned,
    createdAt: DateTime(2026, 7, 17),
    updatedAt: DateTime(2026, 7, 17),
  ),
  InvoiceModel(
    id: 'invoice-2',
    companyId: 'company-1',
    uploadedBy: 'user-1',
    supplierName: 'ABc',
    invoiceNumber: 'INV-62464027',
    invoiceDate: DateTime(2026, 7, 17),
    totalAmount: 1320000,
    scanStatus: InvoiceScanStatus.notScanned,
    createdAt: DateTime(2026, 7, 17),
    updatedAt: DateTime(2026, 7, 17),
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
    invoiceComparison: const InvoiceComparisonSummary(
      transactionIncome: 2500000,
      transactionExpense: 1200000,
      invoiceIncomeSubtotal: 1800000,
      invoiceIncomeVat: 180000,
      invoiceIncomeTotal: 1980000,
      invoiceExpenseSubtotal: 900000,
      invoiceExpenseVat: 72000,
      invoiceExpenseTotal: 972000,
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

  testWidgets('login supports portrait, landscape and desktop', (tester) async {
    await pumpResponsiveScreen(tester, const LoginScreen());
  });

  testWidgets('register supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(tester, const RegisterScreen());
  });

  testWidgets('forgot password supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(tester, const ForgotPasswordScreen());
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

  testWidgets('create invoice supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const CreateInvoiceScreen(),
      buildScope: (child) => ProviderScope(
        overrides: [
          categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
        ],
        child: child,
      ),
    );

    expect(find.text('Loại giao dịch'), findsOneWidget);
    expect(find.text('Danh mục'), findsOneWidget);
    expect(find.text('Chưa nhận diện'), findsNWidgets(2));
    expect(find.byType(SegmentedButton<TransactionType>), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });

  testWidgets('invoice preview supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const InvoicePreviewScreen(invoiceId: 'invoice-1'),
      buildScope: (child) => ProviderScope(
        overrides: [
          invoicePreviewProvider.overrideWith(
            (ref, invoiceId) async => _invoices.first,
          ),
          linkedTransactionForInvoiceProvider.overrideWith(
            (ref, invoiceId) async => null,
          ),
        ],
        child: child,
      ),
    );
  });

  testWidgets('invoice sent supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(tester, const InvoiceSentScreen());
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

  testWidgets('settings supports portrait, landscape and desktop', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await pumpResponsiveScreen(
      tester,
      const SettingsScreen(),
      buildScope: (child) => ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentUserProvider.overrideWithValue(null),
        ],
        child: child,
      ),
    );
  });

  testWidgets('manager approval supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const TransactionApprovalScreen(),
      buildScope: (child) => ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) async => _manager),
          accountsProvider.overrideWith(_FakeAccountsNotifier.new),
          pendingTransactionsProvider.overrideWith(
            (ref) async => _pendingTransactions,
          ),
        ],
        child: child,
      ),
    );
  });

  testWidgets('account management supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const AccountManagementScreen(),
      buildScope: (child) => ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) async => _manager),
          accountsProvider.overrideWith(_FakeAccountsNotifier.new),
        ],
        child: child,
      ),
    );
  });

  testWidgets('manager account cards stay compact and landscape uses a table', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) async => _manager),
          accountsProvider.overrideWith(_FakeAccountsNotifier.new),
        ],
        child: const MaterialApp(home: AccountManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsNothing);
    expect(tester.getSize(find.byType(BentoCard).first).height, lessThan(160));

    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager approval empty state is compact on mobile', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) async => _manager),
          accountsProvider.overrideWith(_FakeAccountsNotifier.new),
          pendingTransactionsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: TransactionApprovalScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(BentoCard).first).height, lessThan(210));
    expect(tester.takeException(), isNull);
  });

  testWidgets('manager account form opens without landscape overflow', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(844, 390));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith((ref) async => _manager),
          accountsProvider.overrideWith(_FakeAccountsNotifier.new),
        ],
        child: const MaterialApp(home: AccountManagementScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thêm tài khoản').first);
    await tester.pumpAndSettle();

    expect(find.text('Email đăng nhập'), findsOneWidget);
    expect(find.text('Tạo tài khoản'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('transaction history supports portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const TransactionsHistoryScreen(),
      buildScope: (child) => ProviderScope(
        overrides: [
          allTransactionsProvider.overrideWith((ref) async => _transactions),
          categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
        ],
        child: child,
      ),
    );
  });

  testWidgets('transaction details support portrait, landscape and desktop', (
    tester,
  ) async {
    await pumpResponsiveScreen(
      tester,
      const TransactionDetailScreen(transactionId: 'expense-1'),
      buildScope: (child) => ProviderScope(
        overrides: [
          transactionDetailProvider.overrideWith(
            (ref, transactionId) async => _transactions.last,
          ),
          categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
        ],
        child: child,
      ),
    );
  });

  testWidgets('expense item opens its transaction details', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final router = _expensesTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(_FakeTransactionsNotifier.new),
          categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final transaction = find.text('Mat bang');
    await tester.ensureVisible(transaction);
    await tester.pumpAndSettle();
    await tester.tap(transaction);
    await tester.pumpAndSettle();

    expect(find.text('detail: expense-1'), findsOneWidget);
  });

  testWidgets('view all expenses opens transaction history', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final router = _expensesTestRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(_FakeTransactionsNotifier.new),
          categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final viewAll = find.text('Xem tất cả chi phí');
    await tester.ensureVisible(viewAll);
    await tester.pumpAndSettle();
    await tester.tap(viewAll);
    await tester.pumpAndSettle();

    expect(find.text('history destination'), findsOneWidget);
  });

  testWidgets('transaction table hides unused selection checkboxes', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allTransactionsProvider.overrideWith((ref) async => _transactions),
          categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TransactionsHistoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('recent expenses table hides unused selection checkboxes', (
    tester,
  ) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1280, 800));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionsProvider.overrideWith(_FakeTransactionsNotifier.new),
          categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
        ],
        child: const MaterialApp(home: Scaffold(body: ExpensesScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('expense transaction offers invoice creation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider.overrideWith(
            (ref, transactionId) async => _transactions.last,
          ),
          categoriesProvider.overrideWith(_FakeCategoriesNotifier.new),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: TransactionDetailScreen(transactionId: 'expense-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tạo hóa đơn'), findsOneWidget);
  });
}

GoRouter _expensesTestRouter() {
  return GoRouter(
    initialLocation: '/expenses',
    routes: [
      GoRoute(
        path: '/expenses',
        builder: (_, _) => const Scaffold(body: ExpensesScreen()),
        routes: [
          GoRoute(
            path: 'history',
            builder: (_, _) => const Scaffold(
              body: Center(child: Text('history destination')),
            ),
          ),
          GoRoute(
            path: ':transactionId',
            builder: (_, state) => Scaffold(
              body: Center(
                child: Text('detail: ${state.pathParameters['transactionId']}'),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
