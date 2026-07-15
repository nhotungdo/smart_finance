import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/ui/screens/auth/splash_screen.dart';
import 'package:smart_finance/ui/screens/auth/login_screen.dart';
import 'package:smart_finance/ui/screens/auth/register_screen.dart';
import 'package:smart_finance/ui/screens/dashboard/dashboard_screen.dart';
import 'package:smart_finance/ui/screens/banking/banking_screen.dart';
import 'package:smart_finance/ui/screens/expenses/expenses_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoicing_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/create_invoice_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoice_preview_screen.dart';
import 'package:smart_finance/ui/screens/invoicing/invoice_sent_screen.dart';
import 'package:smart_finance/ui/screens/reports/reports_screen.dart';
import 'package:smart_finance/ui/widgets/main_layout.dart';

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
