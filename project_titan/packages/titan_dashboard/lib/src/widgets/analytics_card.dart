import 'package:flutter/material.dart';

import '../orchestrator/unified_dashboard_state.dart';

/// Section 9: Weekly Analytics Card.
/// Displays study hours, consistency, accuracy, and retention rates. Reuses titan_dashboard & titan_analytics.
class AnalyticsCard extends StatelessWidget {
  final WeeklyAnalyticsData data;
  final VoidCallback? onAnalyticsTap;

  const AnalyticsCard({
    super.key,
    required this.data,
    this.onAnalyticsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Weekly Analytics Overview Card',
      container: true,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.analytics_rounded,
                            color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'WEEKLY ANALYTICS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    onPressed: onAnalyticsTap,
                    tooltip: 'View Detailed Analytics',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildMetricTile(
                    context,
                    title: 'Study Hours',
                    value: '${data.studyHours.toStringAsFixed(1)}h',
                    icon: Icons.timer_outlined,
                    color: colorScheme.primary,
                  ),
                  _buildMetricTile(
                    context,
                    title: 'Consistency',
                    value: '${(data.consistencyPercentage * 100).toInt()}%',
                    icon: Icons.date_range_outlined,
                    color: colorScheme.secondary,
                  ),
                  _buildMetricTile(
                    context,
                    title: 'Accuracy',
                    value: '${(data.accuracyPercentage * 100).toInt()}%',
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green,
                  ),
                  _buildMetricTile(
                    context,
                    title: 'Retention Rate',
                    value: '${(data.retentionPercentage * 100).toInt()}%',
                    icon: Icons.memory_outlined,
                    color: colorScheme.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
