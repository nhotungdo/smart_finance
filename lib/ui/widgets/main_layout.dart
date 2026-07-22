import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_finance/data/models/finance_enums.dart';
import 'package:smart_finance/providers/auth_provider.dart';
import 'package:smart_finance/providers/theme_provider.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key, required this.currentPath, required this.child});

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    final profileState = ref.watch(currentUserProfileProvider);
    return profileState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Không thể tải quyền tài khoản: $error')),
      ),
      data: (profile) {
        final role = profile?.role ?? AppRole.accountant;
        final destinations = _destinationsFor(role);
        final currentIndex = _selectedIndex(currentPath, destinations);
        return _AdaptiveScaffold(
          key: ValueKey(role),
          isDesktop: isDesktop,
          currentIndex: currentIndex,
          destinations: destinations,
          child: child,
        );
      },
    );
  }

  int _selectedIndex(
    String path,
    List<_NavigationDestinationData> destinations,
  ) {
    final index = destinations.indexWhere(
      (destination) => path.startsWith(destination.path),
    );
    return index < 0 ? 0 : index;
  }
}

class _NavigationDestinationData {
  const _NavigationDestinationData({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}

List<_NavigationDestinationData> _destinationsFor(AppRole role) {
  if (role == AppRole.manager) {
    return const [
      _NavigationDestinationData(
        icon: Icons.fact_check_rounded,
        label: 'Duyệt giao dịch',
        path: '/manager/approvals',
      ),
      _NavigationDestinationData(
        icon: Icons.manage_accounts_rounded,
        label: 'Tài khoản',
        path: '/manager/accounts',
      ),
      _NavigationDestinationData(
        icon: Icons.bar_chart_rounded,
        label: 'Báo cáo',
        path: '/reports',
      ),
      _NavigationDestinationData(
        icon: Icons.settings_rounded,
        label: 'Cài đặt',
        path: '/settings',
      ),
    ];
  }
  return const [
    _NavigationDestinationData(
      icon: Icons.dashboard_rounded,
      label: 'Tổng quan',
      path: '/dashboard',
    ),
    _NavigationDestinationData(
      icon: Icons.receipt_long_rounded,
      label: 'Hóa đơn',
      path: '/invoicing',
    ),
    _NavigationDestinationData(
      icon: Icons.payments_rounded,
      label: 'Chi phí',
      path: '/expenses',
    ),
    _NavigationDestinationData(
      icon: Icons.bar_chart_rounded,
      label: 'Báo cáo',
      path: '/reports',
    ),
    _NavigationDestinationData(
      icon: Icons.settings_rounded,
      label: 'Cài đặt',
      path: '/settings',
    ),
  ];
}

class _AdaptiveScaffold extends ConsumerWidget {
  const _AdaptiveScaffold({
    super.key,
    required this.isDesktop,
    required this.currentIndex,
    required this.destinations,
    required this.child,
  });

  final bool isDesktop;
  final int currentIndex;
  final List<_NavigationDestinationData> destinations;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isDesktop ? null : _buildMobileAppBar(theme, isDark, ref),
      body: Row(
        children: [
          if (isDesktop)
            _DesktopSidebar(
              currentIndex: currentIndex,
              isDark: isDark,
              destinations: destinations,
            ),
          Expanded(
            child: SafeArea(
              top: isDesktop,
              left: !isDesktop,
              child: ClipRect(child: RepaintBoundary(child: child)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : _MobileBottomNavigation(
              currentIndex: currentIndex,
              destinations: destinations,
            ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(
    ThemeData theme,
    bool isDark,
    WidgetRef ref,
  ) {
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Row(
        children: [
          _BrandMark(size: 30, iconSize: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'SmartFinance',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: isDark ? 'Giao diện sáng' : 'Giao diện tối',
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
          color: theme.colorScheme.onSurfaceVariant,
          onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar({
    required this.currentIndex,
    required this.isDark,
    required this.destinations,
  });

  final int currentIndex;
  final bool isDark;
  final List<_NavigationDestinationData> destinations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leftSafeInset = MediaQuery.paddingOf(context).left;
    final sidebarBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final sidebarBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE2E8F0);

    return Container(
      width: 220 + leftSafeInset,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: sidebarBorder)),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const _BrandMark(size: 36, iconSize: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SmartFinance',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < destinations.length - 1;
                        index++
                      ) ...[
                        _SidebarNavItem(
                          icon: destinations[index].icon,
                          label: destinations[index].label,
                          isActive: currentIndex == index,
                          onTap: currentIndex == index
                              ? null
                              : () => context.go(destinations[index].path),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  _SidebarNavItem(
                    icon: destinations.last.icon,
                    label: destinations.last.label,
                    isActive: currentIndex == destinations.length - 1,
                    onTap: currentIndex == destinations.length - 1
                        ? null
                        : () => context.go(destinations.last.path),
                  ),
                  const SizedBox(height: 4),
                  _SidebarNavItem(
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    label: isDark ? 'Giao diện sáng' : 'Giao diện tối',
                    isActive: false,
                    onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size, required this.iconSize});

  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.auto_graph, color: Colors.white, size: iconSize),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeBg = theme.colorScheme.primary.withValues(alpha: 0.12);
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: hoverBg,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation({
    required this.currentIndex,
    required this.destinations,
  });

  final int currentIndex;
  final List<_NavigationDestinationData> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var index = 0; index < destinations.length; index++)
                _BottomNavItem(
                  icon: destinations[index].icon,
                  label: destinations[index].label,
                  isActive: currentIndex == index,
                  onTap: currentIndex == index
                      ? null
                      : () => context.go(destinations[index].path),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
