import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/providers/theme_provider.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > 768; // Based on md breakpoint in Tailwind

    // Determine current index based on GoRouter location
    int currentIndex = _calculateSelectedIndex(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: isDesktop ? _buildTopAppBar(context, theme, currentIndex, ref) : _buildMobileAppBar(context, theme, ref),
      body: child,
      bottomNavigationBar: isDesktop ? null : _buildBottomNavBar(context, theme, currentIndex),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/invoicing')) return 1;
    if (location.startsWith('/expenses')) return 2;
    if (location.startsWith('/reports')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/invoicing');
        break;
      case 2:
        context.go('/expenses');
        break;
      case 3:
        context.go('/reports');
        break;
    }
  }

  PreferredSizeWidget _buildTopAppBar(BuildContext context, ThemeData theme, int currentIndex, WidgetRef ref) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Icon(Icons.battery_charging_full, color: theme.colorScheme.primary), // battery_profile placeholder
          const SizedBox(width: 8),
          Text(
            'SmartFinance',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDesktopNavItem(context, 'Tổng quan', '/dashboard', currentIndex == 0),
            _buildDesktopNavItem(context, 'Hóa đơn', '/invoicing', currentIndex == 1),
            _buildDesktopNavItem(context, 'Chi phí', '/expenses', currentIndex == 2),
            _buildDesktopNavItem(context, 'Báo cáo', '/reports', currentIndex == 3),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
              color: theme.colorScheme.primary,
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.notifications),
              color: theme.colorScheme.primary,
              onPressed: () {},
            ),
            const SizedBox(width: 16),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildMobileAppBar(BuildContext context, ThemeData theme, WidgetRef ref) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          Icon(Icons.battery_charging_full, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'SmartFinance',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
          color: theme.colorScheme.primary,
          onPressed: () {
            ref.read(themeProvider.notifier).toggleTheme();
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          color: theme.colorScheme.primary,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDesktopNavItem(BuildContext context, String title, String route, bool isActive) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () {
          context.go(route);
        },
        style: TextButton.styleFrom(
          foregroundColor: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        child: Text(title),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, ThemeData theme, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onItemTapped(index, context),
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.colorScheme.surface,
      selectedItemColor: theme.colorScheme.primary,
      unselectedItemColor: theme.colorScheme.onSurfaceVariant,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Tổng quan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Hóa đơn',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.payments),
          label: 'Chi phí',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Báo cáo',
        ),
      ],
    );
  }
}
