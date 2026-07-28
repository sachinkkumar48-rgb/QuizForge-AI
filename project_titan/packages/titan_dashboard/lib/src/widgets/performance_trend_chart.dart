import 'package:flutter/material.dart';

import '../models/performance_trend.dart';

/// Material 3 chart visualization component displaying accuracy and study performance trends.
class PerformanceTrendChart extends StatelessWidget {
  final PerformanceTrend trend;

  const PerformanceTrendChart({
    super.key,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  'Performance Trend',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  avatar: Icon(
                    trend.trendDirection == 'improving'
                        ? Icons.trending_up
                        : Icons.trending_flat,
                    size: 16.0,
                    color: Colors.green,
                  ),
                  label: Text(
                    trend.trendDirection.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(trend.accuracyPoints.length, (index) {
                final heightFactor =
                    trend.accuracyPoints[index].clamp(0.1, 1.0);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(trend.accuracyPoints[index] * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 4.0),
                    Container(
                      width: 24.0,
                      height: 80.0 * heightFactor,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Day ${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
