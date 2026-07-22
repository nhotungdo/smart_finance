import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_finance/data/models/user_model.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/providers/theme_provider.dart';
import 'package:smart_finance/ui/screens/settings/settings_screen.dart';
import 'package:smart_finance/ui/widgets/main_layout.dart';

class _ThemeRouterApp extends ConsumerWidget {
  const _ThemeRouterApp({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ref.watch(themeProvider),
      routerConfig: router,
    );
  }
}

class _ThemeAwarePage extends StatelessWidget {
  const _ThemeAwarePage(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Center(child: Text(label)),
    );
  }
}

void main() {
  testWidgets('main layout keeps its routed child stable across breakpoints', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              MainLayout(currentPath: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) =>
                  const Center(child: Text('Responsive content')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentUserProfileProvider.overrideWith(
            (ref) async => UserModel(
              userId: 'accountant-1',
              companyId: 'company-1',
              roleId: 'role_accountant',
              fullName: 'Kế toán',
              email: 'accountant@example.com',
            ),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: const TextScaler.linear(1.3),
                padding: isLandscape
                    ? const EdgeInsets.symmetric(horizontal: 44)
                    : mediaQuery.padding,
              ),
              child: child!,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: 'Initial desktop layout overflowed',
    );

    for (final size in const [
      Size(390, 844),
      Size(844, 390),
      Size(1200, 800),
      Size(600, 900),
      Size(1280, 720),
      Size(1280, 560),
      Size(1330, 589),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();
      final layoutError = tester.takeException();
      expect(layoutError, isNull, reason: 'Main layout overflowed at $size');
      expect(find.text('Responsive content'), findsOneWidget);
    }
  });

  testWidgets('manager can open settings and toggle theme during navigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/manager/approvals',
      routes: [
        ShellRoute(
          builder: (context, state, child) =>
              MainLayout(currentPath: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: '/manager/approvals',
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                transitionDuration: const Duration(milliseconds: 160),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
                child: const _ThemeAwarePage('Approvals'),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => CustomTransitionPage<void>(
                key: state.pageKey,
                transitionDuration: const Duration(milliseconds: 160),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
                child: const SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          currentUserProvider.overrideWithValue(null),
          currentUserProfileProvider.overrideWith(
            (ref) async => UserModel(
              userId: 'manager-1',
              companyId: 'company-1',
              roleId: 'role_manager',
              fullName: 'Manager',
              email: 'manager@example.com',
            ),
          ),
        ],
        child: _ThemeRouterApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.byIcon(Icons.settings_rounded)));
    await mouse.down(tester.getCenter(find.byIcon(Icons.settings_rounded)));
    await mouse.up();
    await tester.pump(const Duration(milliseconds: 20));
    await mouse.moveTo(tester.getCenter(find.byIcon(Icons.dark_mode_rounded)));
    await mouse.down(tester.getCenter(find.byIcon(Icons.dark_mode_rounded)));
    await mouse.up();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
  });
}
