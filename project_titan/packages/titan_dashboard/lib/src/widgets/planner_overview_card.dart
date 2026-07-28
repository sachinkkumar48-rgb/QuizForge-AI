import 'package:flutter/material.dart';

/// Material 3 daily study planner progress overview card.
class PlannerOverviewCard extends StatelessWidget {
  final double completedHours;
  final double targetHours;
  final int completedTasksCount;

  const PlannerOverviewCard({
    super.key,
    required this.completedHours,
    required this.targetHours,
    required this.completedTasksCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress =
        targetHours > 0 ? (completedHours / targetHours).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0.0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Study Plan',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${completedHours.toStringAsFixed(1)} / ${targetHours.toStringAsFixed(1)} hrs',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8.0,
              borderRadius: BorderRadius.circular(4.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              '$completedTasksCount tasks completed today',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
