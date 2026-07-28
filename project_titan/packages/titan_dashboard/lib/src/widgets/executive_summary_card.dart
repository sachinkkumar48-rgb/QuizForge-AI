import 'package:flutter/material.dart';

import '../models/dashboard_snapshot.dart';

/// Material 3 executive summary card summarizing core metrics and top recommendation.
class ExecutiveSummaryCard extends StatelessWidget {
  final DashboardSnapshot snapshot;

  const ExecutiveSummaryCard({
    super.key,
    required this.snapshot,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.stars_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 20.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Executive Summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              snapshot.insights.topRecommendation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                Chip(
                  avatar: const Icon(Icons.bolt, size: 16.0),
                  label: Text(
                      '${snapshot.statistics.currentStreakDays} Day Streak'),
                  backgroundColor: colorScheme.surface,
                ),
                Chip(
                  avatar: const Icon(Icons.check_circle_outline, size: 16.0),
                  label: Text(
                      '${(snapshot.statistics.overallAccuracy * 100).toStringAsFixed(0)}% Accuracy'),
                  backgroundColor: colorScheme.surface,
                ),
                Chip(
                  avatar: const Icon(Icons.menu_book, size: 16.0),
                  label: Text(
                      '${snapshot.statistics.totalStudyHours} hrs Studied'),
                  backgroundColor: colorScheme.surface,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
