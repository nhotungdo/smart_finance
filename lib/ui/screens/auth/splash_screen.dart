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
  late AnimationController _revealCtrl;
  late AnimationController _dotCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _fadeAnim = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 200), () {
      _revealCtrl.forward();
      _slideCtrl.forward();
    });

    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2, milliseconds: 400));
    if (!mounted) return;
    final session = Supabase.instance.client.auth.currentSession;
    context.go(session != null ? '/dashboard' : '/login');
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _dotCtrl.dispose();
    _slideCtrl.dispose();
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
        child: SlideTransition(
          position: _slideAnim,
          child: isWide
              ? _WideSplash(theme: theme, isDark: isDark, dotCtrl: _dotCtrl)
              : _NarrowSplash(theme: theme, isDark: isDark, dotCtrl: _dotCtrl),
        ),
      ),
    );
  }
}

// ── Wide (Desktop/Tablet) Splash ─────────────────────────────────────────────
class _WideSplash extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;
  final AnimationController dotCtrl;

  const _WideSplash({
    required this.theme,
    required this.isDark,
    required this.dotCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: Brand hero
        Expanded(
          flex: 5,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF13111C), const Color(0xFF1E1B2E)]
                    : [const Color(0xFF6C63FF), const Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Stack(
              children: [
                // Decorative orbs
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -40,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 40,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo row
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Icon(Icons.auto_graph,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'SmartFinance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Hero text
                      Text(
                        'Tài chính\nthông minh\ncho SME 🚀',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Quản lý dòng tiền, hóa đơn và báo cáo\ntài chính trong một nền tảng duy nhất.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: Feature tiles + loading
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 32, 32, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang khởi động...',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đang kiểm tra phiên đăng nhập',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 36),
                _BentoFeatureTile(
                  theme: theme,
                  icon: Icons.bar_chart_rounded,
                  label: 'Báo cáo thời gian thực',
                  sublabel: 'P&L, dòng tiền, cân đối',
                  color: const Color(0xFF6C63FF),
                ),
                const SizedBox(height: 16),
                _BentoFeatureTile(
                  theme: theme,
                  icon: Icons.receipt_long_rounded,
                  label: 'Hóa đơn thông minh',
                  sublabel: 'Tạo, gửi và theo dõi',
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 16),
                _BentoFeatureTile(
                  theme: theme,
                  icon: Icons.sync_rounded,
                  label: 'Đồng bộ offline',
                  sublabel: 'Tự động khi có kết nối',
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 48),
                _LoadingDots(controller: dotCtrl, theme: theme),
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
  final AnimationController dotCtrl;

  const _NarrowSplash({
    required this.theme,
    required this.isDark,
    required this.dotCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D0D18), const Color(0xFF13111C)]
              : [const Color(0xFFF5F3FF), const Color(0xFFFAF9FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_graph, color: Colors.white, size: 52),
              ),
              const SizedBox(height: 28),
              Text(
                'SmartFinance',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.0,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Quản lý tài chính thông minh',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              // Feature row
              Row(
                children: [
                  Expanded(
                    child: _BentoCompactTile(
                      theme: theme,
                      icon: Icons.bar_chart_rounded,
                      label: 'Báo cáo',
                      color: const Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BentoCompactTile(
                      theme: theme,
                      icon: Icons.receipt_long_rounded,
                      label: 'Hóa đơn',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BentoCompactTile(
                      theme: theme,
                      icon: Icons.sync_rounded,
                      label: 'Offline',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              _LoadingDots(controller: dotCtrl, theme: theme),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature Tile (Wide) ───────────────────────────────────────────────────────
class _BentoFeatureTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _BentoFeatureTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE8E5FF),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: color.withValues(alpha: 0.5), size: 18),
        ],
      ),
    );
  }
}

// ── Compact Tile (Mobile) ─────────────────────────────────────────────────────
class _BentoCompactTile extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String label;
  final Color color;

  const _BentoCompactTile({
    required this.theme,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : color.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading dots ──────────────────────────────────────────────────────────────
class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  final ThemeData theme;

  const _LoadingDots({required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = ((controller.value - i * 0.25) % 1.0).abs();
            final opacity = (0.3 + (1.0 - phase) * 0.7).clamp(0.3, 1.0);
            final scale = (0.8 + (1.0 - phase) * 0.4).clamp(0.8, 1.2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withValues(alpha: opacity),
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
