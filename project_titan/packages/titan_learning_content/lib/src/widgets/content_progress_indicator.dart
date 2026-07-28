import 'package:flutter/material.dart';
import '../models/content_progress.dart';

/// Reusable Material 3 progress bar widget for learning content completion status.
class ContentProgressIndicator extends StatelessWidget {
  final ContentProgress? progress;
  final bool showLabel;

  const ContentProgressIndicator({
    super.key,
    this.progress,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentage = progress?.completionPercentage ?? 0.0;
    final isCompleted = progress?.isCompleted ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}% Completed',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                isCompleted
                    ? 'Completed'
                    : '${progress?.timeSpentSeconds ?? 0}s spent',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
        ],
        LinearProgressIndicator(
          value: (percentage / 100.0).clamp(0.0, 1.0),
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            isCompleted ? colorScheme.primary : colorScheme.secondary,
          ),
          borderRadius: BorderRadius.circular(4.0),
        ),
      ],
    );
  }
}
