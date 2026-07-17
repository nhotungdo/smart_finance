import 'package:flutter/material.dart';

/// [BentoCard] — Ô thẻ cơ bản trong Bento Grid layout.
///
/// Mỗi BentoCard là một tile hình chữ nhật với bo góc lớn,
/// có thể có accent color, gradient nền, và hover animation.
///
/// Dùng bên trong [BentoGrid] hoặc độc lập.
class BentoCard extends StatefulWidget {
  final Widget child;
  final Color? accentColor;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showAccentStrip;
  final BentoCardStyle style;
  final double? height;
  final Color? backgroundColor;

  const BentoCard({
    super.key,
    required this.child,
    this.accentColor,
    this.gradient,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 28,
    this.onTap,
    this.showAccentStrip = false,
    this.style = BentoCardStyle.solid,
    this.height,
    this.backgroundColor,
  });

  @override
  State<BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<BentoCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scaleAnim;

  @override
  void initState() {
    super.initState();
    _configureInteractionAnimation();
  }

  @override
  void didUpdateWidget(covariant BentoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.onTap == null) != (widget.onTap == null)) {
      _controller?.dispose();
      _controller = null;
      _scaleAnim = null;
      _configureInteractionAnimation();
    }
  }

  void _configureInteractionAnimation() {
    if (widget.onTap == null) return;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _controller = controller;
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg =
        widget.backgroundColor ??
        (isDark
            ? const Color(0xFF1E293B) // slate-800
            : Colors.white);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE2E8F0);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.03);

    Widget content = SizedBox(
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          color: widget.style == BentoCardStyle.ghost ? Colors.transparent : bg,
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: widget.style == BentoCardStyle.outlined
                ? (widget.accentColor ?? theme.colorScheme.primary).withValues(
                    alpha: 0.4,
                  )
                : borderColor,
            width: widget.style == BentoCardStyle.outlined ? 1.5 : 1,
          ),
          boxShadow: widget.style == BentoCardStyle.ghost
              ? null
              : [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                  if (widget.accentColor != null)
                    BoxShadow(
                      color: widget.accentColor!.withValues(alpha: 0.08),
                      blurRadius: 32,
                      spreadRadius: -4,
                    ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Stack(
            children: [
              // Accent strip at top (optional)
              if (widget.showAccentStrip && widget.accentColor != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(widget.borderRadius),
                        topRight: Radius.circular(widget.borderRadius),
                      ),
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: widget.showAccentStrip && widget.accentColor != null
                    ? widget.padding.add(const EdgeInsets.only(top: 3))
                    : widget.padding,
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.onTap == null) return content;
    final controller = _controller!;
    final scaleAnimation = _scaleAnim!;

    return MouseRegion(
      onEnter: (_) => controller.forward(),
      onExit: (_) => controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => controller.forward(),
        onTapUp: (_) {
          controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: controller.reverse,
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, child) =>
              Transform.scale(scale: scaleAnimation.value, child: child),
          child: content,
        ),
      ),
    );
  }
}

enum BentoCardStyle {
  solid, // Filled background (default)
  ghost, // Transparent — no bg, no shadow
  outlined, // Transparent bg + colored border
}

/// [BentoIconTile] — Ô stat card compact: icon + label + value.
class BentoIconTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final String? subtitle;
  final Widget? trailing;

  const BentoIconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            if (trailing != null) ...[const Spacer(), trailing!],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// [BentoSectionHeader] — Header section trong Bento layout.
class BentoSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const BentoSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}
