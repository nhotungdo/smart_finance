import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/banking/presentation/screens/banking_screen.dart';
import '../../features/expenses/presentation/screens/expenses_screen.dart';
import '../../features/invoicing/presentation/screens/invoicing_screen.dart';
import '../../features/invoicing/presentation/screens/create_invoice_screen.dart';
import '../../features/invoicing/presentation/screens/invoice_preview_screen.dart';
import '../../features/invoicing/presentation/screens/invoice_sent_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/dashboard/presentation/widgets/main_layout.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/banking',
          builder: (context, state) => const BankingScreen(),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) => const ExpensesScreen(),
        ),
        GoRoute(
          path: '/invoicing',
          builder: (context, state) => const InvoicingScreen(),
        ),
        GoRoute(
          path: '/invoicing/create',
          builder: (context, state) => const CreateInvoiceScreen(),
        ),
        GoRoute(
          path: '/invoicing/preview',
          builder: (context, state) => const InvoicePreviewScreen(),
        ),
        GoRoute(
          path: '/invoicing/sent',
          builder: (context, state) => const InvoiceSentScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (context, state) => const ReportsScreen(),
        ),
      ],
    ),
  ],
);
