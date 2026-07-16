import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _dotController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    context.go(session != null ? '/dashboard' : '/login');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isWide
            ? _WideSplash(theme: theme, isDark: isDark, dotController: _dotController)
            : _NarrowSplash(theme: theme, isDark: isDark, dotController: _dotController),
      ),
    );
  }
}

// ── Wide (Desktop/Tablet) Splash ─────────────────────────────────────────────
class _WideSplash extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final AnimationController dotController;

  const _WideSplash({
    required this.theme,
    required this.isDark,
    required this.dotController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Brand Bento tile
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF8FAFC), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : theme.colorScheme.primary.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  left: -60,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : theme.colorScheme.primary.withValues(alpha: 0.03),
                    ),
                  ),
                ),
                // Content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.15) : theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.2) : theme.colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Icon(Icons.auto_graph,
                            color: isDark ? Colors.white : theme.colorScheme.primary, size: 44),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'SmartFinance',
                        style: TextStyle(
                          color: isDark ? Colors.white : theme.colorScheme.primary,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Quản lý tài chính thông minh\ncho doanh nghiệp SME',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurfaceVariant,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: Loading Bento tiles
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BentoSplashTile(
                  theme: theme,
                  icon: Icons.bar_chart_rounded,
                  label: 'Báo cáo thời gian thực',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 14),
                _BentoSplashTile(
                  theme: theme,
                  icon: Icons.receipt_long_rounded,
                  label: 'Quản lý hóa đơn thông minh',
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 14),
                _BentoSplashTile(
                  theme: theme,
                  icon: Icons.sync_rounded,
                  label: 'Đồng bộ offline tự động',
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 40),
                // Loading dots
                _LoadingDots(controller: dotController, theme: theme),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Narrow (Mobile) Splash ────────────────────────────────────────────────────
class _NarrowSplash extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final AnimationController dotController;

  const _NarrowSplash({
    required this.theme,
    required this.isDark,
    required this.dotController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFF8FAFC), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_graph, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'SmartFinance',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Quản lý tài chính thông minh',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              // Feature tiles row
              Row(
                children: [
                  Expanded(
                    child: _BentoSplashTile(
                      theme: theme,
                      icon: Icons.bar_chart_rounded,
                      label: 'Báo cáo',
                      color: theme.colorScheme.primary,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _BentoSplashTile(
                      theme: theme,
                      icon: Icons.sync_rounded,
                      label: 'Offline',
                      color: const Color(0xFF10B981),
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _LoadingDots(controller: dotController, theme: theme),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoSplashTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  const _BentoSplashTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: compact
          ? Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(label,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  final ThemeData theme;

  const _LoadingDots({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final offset = i / 3;
            final value = (controller.value - offset).abs();
            final scale = value < 0.5 ? 1.0 + (0.5 - value) * 0.6 : 1.0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale.clamp(1.0, 1.3),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(
                      alpha: (0.4 + (1 - value) * 0.6).clamp(0.4, 1.0),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
