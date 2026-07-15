import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fade(duration: 400.ms).slideX(begin: -0.1, curve: Curves.easeOutQuad),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ).animate().fade(duration: 400.ms, delay: 100.ms).slideX(begin: -0.1, curve: Curves.easeOutQuad),
            ],
          ),
        ),
        if (action != null)
          action!.animate().fade(duration: 400.ms, delay: 200.ms).slideX(begin: 0.1, curve: Curves.easeOutQuad),
      ],
    );
  }
}
