import 'package:flutter/material.dart';

import '../models/planner_models.dart';

/// Material 3 Progress Indicator Card displaying daily task completion percentage,
/// progress bar, completed tasks fraction, and study time completed.
class ProgressIndicatorCard extends StatelessWidget {
  final StudySummary summary;

  const ProgressIndicatorCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progressFraction =
        (summary.completionPercentage / 100.0).clamp(0.0, 1.0);

    return Card(
      elevation: 1.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Daily Progress',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${summary.completionPercentage.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10.0),

            // M3 Linear Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: LinearProgressIndicator(
                value: progressFraction,
                minHeight: 10.0,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: summary.completionPercentage == 100.0
                    ? Colors.green
                    : colorScheme.primary,
              ),
            ),

            const SizedBox(height: 12.0),

            // Tasks Count & Time Completed Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 16.0,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      '${summary.completedTasksCount} / ${summary.totalTasksCount} tasks',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16.0,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      '${summary.completedMinutes} / ${summary.totalAllocatedMinutes} mins',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
