import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/ui/screens/auth/splash_screen.dart';
import 'package:smart_finance/ui/screens/auth/login_screen.dart';
import 'package:smart_finance/ui/screens/auth/register_screen.dart';
import 'package:smart_finance/ui/screens/auth/forgot_password_screen.dart';
import 'package:smart_finance/ui/screens/dashboard/dashboard_screen.dart';
import 'package:smart_finance/ui/screens/expenses/expenses_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoicing_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/create_invoice_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoice_preview_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoice_sent_screen.dart';
import 'package:smart_finance/ui/screens/reports/reports_screen.dart';
import 'package:smart_finance/ui/screens/settings/settings_screen.dart';
import 'package:smart_finance/ui/widgets/main_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

Page<void> _shellPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
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

    return null; // Không cần redirect
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
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) =>
              _shellPage(state, const DashboardScreen()),
        ),
        GoRoute(
          path: '/expenses',
          pageBuilder: (context, state) =>
              _shellPage(state, const ExpensesScreen()),
        ),
        GoRoute(
          path: '/invoicing',
          pageBuilder: (context, state) =>
              _shellPage(state, const InvoicingScreen()),
        ),
        GoRoute(
          path: '/invoicing/create',
          builder: (context, state) => const CreateInvoiceScreen(),
        ),
        GoRoute(
          path: '/invoicing/preview/:invoiceId',
          builder: (context, state) => InvoicePreviewScreen(
            invoiceId: state.pathParameters['invoiceId']!,
          ),
        ),
        GoRoute(
          path: '/invoicing/sent',
          builder: (context, state) => const InvoiceSentScreen(),
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
