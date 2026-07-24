import 'package:flutter/material.dart';

/// Material 3 color-coded badge indicating the priority level of a recommendation.
class RecommendationPriorityBadge extends StatelessWidget {
  final String priority;
  final bool showIcon;

  const RecommendationPriorityBadge({
    super.key,
    required this.priority,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final BadgeStyle style = _getBadgeStyle(priority, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: style.borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              style.iconData,
              size: 14.0,
              color: style.foregroundColor,
            ),
            const SizedBox(width: 4.0),
          ],
          Text(
            priority.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: style.foregroundColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  BadgeStyle _getBadgeStyle(String priority, ColorScheme colorScheme) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return BadgeStyle(
          backgroundColor: colorScheme.errorContainer,
          borderColor: colorScheme.error,
          foregroundColor: colorScheme.onErrorContainer,
          iconData: Icons.error_outline_rounded,
        );
      case 'high':
        return BadgeStyle(
          backgroundColor: colorScheme.tertiaryContainer,
          borderColor: colorScheme.tertiary,
          foregroundColor: colorScheme.onTertiaryContainer,
          iconData: Icons.priority_high_rounded,
        );
      case 'medium':
        return BadgeStyle(
          backgroundColor: colorScheme.primaryContainer,
          borderColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimaryContainer,
          iconData: Icons.trending_up_rounded,
        );
      case 'low':
      default:
        return BadgeStyle(
          backgroundColor: colorScheme.surfaceContainerHighest,
          borderColor: colorScheme.outlineVariant,
          foregroundColor: colorScheme.onSurfaceVariant,
          iconData: Icons.info_outline_rounded,
        );
    }
  }
}

class BadgeStyle {
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final IconData iconData;

  const BadgeStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.iconData,
  });
}
