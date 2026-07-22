import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/ui/screens/auth/splash_screen.dart';
import 'package:smart_finance/ui/screens/auth/login_screen.dart';
import 'package:smart_finance/ui/screens/auth/register_screen.dart';
import 'package:smart_finance/ui/screens/auth/forgot_password_screen.dart';
import 'package:smart_finance/ui/screens/dashboard/dashboard_screen.dart';
import 'package:smart_finance/ui/screens/expenses/expenses_screen.dart';
import 'package:smart_finance/ui/screens/expenses/transaction_detail_screen.dart';
import 'package:smart_finance/ui/screens/expenses/transactions_history_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoicing_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/create_invoice_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoice_preview_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoice_sent_screen.dart';
import 'package:smart_finance/ui/screens/reports/reports_screen.dart';
import 'package:smart_finance/ui/screens/settings/settings_screen.dart';
import 'package:smart_finance/ui/screens/manager/account_management_screen.dart';
import 'package:smart_finance/ui/screens/manager/transaction_approval_screen.dart';
import 'package:smart_finance/ui/routing/role_gate.dart';
import 'package:smart_finance/ui/widgets/main_layout.dart';
import 'package:smart_finance/data/models/transaction_model.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

Page<void> _shellPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 120),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.012, 0),
            end: Offset.zero,
          ).animate(curved),
          child: RepaintBoundary(child: child),
        ),
      );
    },
  );
}

class AuthStateRefreshListenable extends ChangeNotifier {
  AuthStateRefreshListenable() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter({required Listenable refreshListenable}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final path = state.matchedLocation;

      // Các route không cần xác thực
      final publicRoutes = ['/', '/login', '/register', '/forgot-password'];
      final isPublicRoute = publicRoutes.contains(path);

      // Nếu chưa đăng nhập và đang vào route cần xác thực → về trang đăng nhập
      if (!isLoggedIn && !isPublicRoute) {
        return '/login';
      }

      // Nếu đã đăng nhập và đang vào trang login/register/splash → vào Dashboard
      if (isLoggedIn &&
          (path == '/login' || path == '/register' || path == '/')) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainLayout(currentPath: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => _shellPage(
              state,
              const RoleGate(
                role: AppRole.accountant,
                child: DashboardScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/expenses',
            pageBuilder: (context, state) => _shellPage(
              state,
              const RoleGate(role: AppRole.accountant, child: ExpensesScreen()),
            ),
            routes: [
              GoRoute(
                path: 'history',
                builder: (context, state) => const RoleGate(
                  role: AppRole.accountant,
                  child: TransactionsHistoryScreen(),
                ),
              ),
              GoRoute(
                path: ':transactionId',
                builder: (context, state) => RoleGate(
                  role: AppRole.accountant,
                  child: TransactionDetailScreen(
                    transactionId: state.pathParameters['transactionId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/invoicing',
            pageBuilder: (context, state) => _shellPage(
              state,
              const RoleGate(
                role: AppRole.accountant,
                child: InvoicingScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/invoicing/create',
            builder: (context, state) => RoleGate(
              role: AppRole.accountant,
              child: CreateInvoiceScreen(
                sourceTransaction: state.extra is TransactionModel
                    ? state.extra! as TransactionModel
                    : null,
              ),
            ),
          ),
          GoRoute(
            path: '/invoicing/preview/:invoiceId',
            builder: (context, state) => RoleGate(
              role: AppRole.accountant,
              child: InvoicePreviewScreen(
                invoiceId: state.pathParameters['invoiceId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/invoicing/sent',
            builder: (context, state) => const RoleGate(
              role: AppRole.accountant,
              child: InvoiceSentScreen(),
            ),
          ),
          GoRoute(
            path: '/manager/approvals',
            pageBuilder: (context, state) => _shellPage(
              state,
              const RoleGate(
                role: AppRole.manager,
                child: TransactionApprovalScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/manager/accounts',
            pageBuilder: (context, state) => _shellPage(
              state,
              const RoleGate(
                role: AppRole.manager,
                child: AccountManagementScreen(),
              ),
            ),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                _shellPage(state, const ReportsScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _shellPage(state, const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
}
