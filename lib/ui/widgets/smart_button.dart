import 'package:flutter/material.dart';

enum SmartButtonType { primary, outlined, text }

class SmartButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final SmartButtonType type;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final Widget? icon;

  const SmartButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.type = SmartButtonType.primary,
    this.padding,
    this.isLoading = false,
    this.icon,
  });

  const SmartButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.type = SmartButtonType.outlined,
    this.padding,
    this.isLoading = false,
    this.icon,
  });

  const SmartButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.type = SmartButtonType.text,
    this.padding,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<SmartButton> createState() => _SmartButtonState();
}

class _SmartButtonState extends State<SmartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = widget.isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : widget.child;

    Widget button;
    switch (widget.type) {
      case SmartButtonType.primary:
        if (widget.icon != null && !widget.isLoading) {
          button = ElevatedButton.icon(
            onPressed: widget.onPressed,
            icon: widget.icon!,
            label: content,
            style: widget.padding != null
                ? ElevatedButton.styleFrom(padding: widget.padding)
                : null,
          );
        } else {
          button = ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: widget.padding != null
                ? ElevatedButton.styleFrom(padding: widget.padding)
                : null,
            child: content,
          );
        }
        break;
      case SmartButtonType.outlined:
        if (widget.icon != null && !widget.isLoading) {
          button = OutlinedButton.icon(
            onPressed: widget.onPressed,
            icon: widget.icon!,
            label: content,
            style: widget.padding != null
                ? OutlinedButton.styleFrom(padding: widget.padding)
                : null,
          );
        } else {
          button = OutlinedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: widget.padding != null
                ? OutlinedButton.styleFrom(padding: widget.padding)
                : null,
            child: content,
          );
        }
        break;
      case SmartButtonType.text:
        if (widget.icon != null && !widget.isLoading) {
          button = TextButton.icon(
            onPressed: widget.onPressed,
            icon: widget.icon!,
            label: content,
            style: widget.padding != null
                ? TextButton.styleFrom(padding: widget.padding)
                : null,
          );
        } else {
          button = TextButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: widget.padding != null
                ? TextButton.styleFrom(padding: widget.padding)
                : null,
            child: content,
          );
        }
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow:
                      _isHovered && widget.type == SmartButtonType.primary
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: child,
              ),
            );
          },
          child: button,
        ),
      ),
    );
  }
}
