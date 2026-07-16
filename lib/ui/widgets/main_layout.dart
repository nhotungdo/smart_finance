import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_finance/providers/theme_provider.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width > 900;
    final currentIndex = _selectedIndex(context);

    if (isDesktop) {
      return _DesktopLayout(
        currentIndex: currentIndex,
        ref: ref,
        child: child,
      );
    }

    return _MobileLayout(
      currentIndex: currentIndex,
      ref: ref,
      child: child,
    );
  }

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/dashboard')) return 0;
    if (path.startsWith('/invoicing')) return 1;
    if (path.startsWith('/expenses')) return 2;
    if (path.startsWith('/reports')) return 3;
    if (path.startsWith('/settings')) return 4;
    return 0;
  }
}

// ── Desktop Layout: Left Sidebar Bento ───────────────────────────────────────
class _DesktopLayout extends ConsumerWidget {
  final int currentIndex;
  final WidgetRef ref;
  final Widget child;
  const _DesktopLayout({
    required this.currentIndex,
    required this.ref,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sidebarBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final sidebarBorder = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          Container(
            width: 220,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(
                right: BorderSide(color: sidebarBorder, width: 1),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_graph,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SmartFinance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Nav items
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          _SidebarNavItem(
                            icon: Icons.dashboard_rounded,
                            label: 'Tổng quan',
                            isActive: currentIndex == 0,
                            onTap: () => context.go('/dashboard'),
                          ),
                          const SizedBox(height: 4),
                          _SidebarNavItem(
                            icon: Icons.receipt_long_rounded,
                            label: 'Hóa đơn',
                            isActive: currentIndex == 1,
                            onTap: () => context.go('/invoicing'),
                          ),
                          const SizedBox(height: 4),
                          _SidebarNavItem(
                            icon: Icons.payments_rounded,
                            label: 'Chi phí',
                            isActive: currentIndex == 2,
                            onTap: () => context.go('/expenses'),
                          ),
                          const SizedBox(height: 4),
                          _SidebarNavItem(
                            icon: Icons.bar_chart_rounded,
                            label: 'Báo cáo',
                            isActive: currentIndex == 3,
                            onTap: () => context.go('/reports'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom: theme toggle
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        _SidebarNavItem(
                          icon: Icons.settings_rounded,
                          label: 'Cài đặt',
                          isActive: currentIndex == 4,
                          onTap: () => context.go('/settings'),
                        ),
                        const SizedBox(height: 4),
                        _SidebarNavItem(
                          icon: theme.brightness == Brightness.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          label: theme.brightness == Brightness.dark
                              ? 'Giao diện sáng'
                              : 'Giao diện tối',
                          isActive: false,
                          onTap: () =>
                              ref.read(themeProvider.notifier).toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Content ──────────────────────────────────────────────────
          Expanded(
            child: SafeArea(
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeBg = theme.colorScheme.primary.withValues(alpha: 0.12);
    final hoverBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.04);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeBg
                : _hovered
                    ? hoverBg
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile Layout: Floating Bottom Nav ───────────────────────────────────────
class _MobileLayout extends ConsumerWidget {
  final int currentIndex;
  final WidgetRef ref;
  final Widget child;
  const _MobileLayout({
    required this.currentIndex,
    required this.ref,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_graph, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'SmartFinance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            color: theme.colorScheme.onSurfaceVariant,
            onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: child,
      bottomNavigationBar: Container(
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
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Tổng quan',
                  isActive: currentIndex == 0,
                  onTap: () => context.go('/dashboard'),
                ),
                _BottomNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Hóa đơn',
                  isActive: currentIndex == 1,
                  onTap: () => context.go('/invoicing'),
                ),
                _BottomNavItem(
                  icon: Icons.payments_rounded,
                  label: 'Chi phí',
                  isActive: currentIndex == 2,
                  onTap: () => context.go('/expenses'),
                ),
                _BottomNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Báo cáo',
                  isActive: currentIndex == 3,
                  onTap: () => context.go('/reports'),
                ),
                _BottomNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Cài đặt',
                  isActive: currentIndex == 4,
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
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
                borderRadius: BorderRadius.circular(20),
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
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
