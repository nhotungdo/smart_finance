import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_finance/providers/theme_provider.dart';
import 'package:smart_finance/ui/widgets/main_layout.dart';

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
          builder: (context, state, child) => MainLayout(child: child),
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
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
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
}
