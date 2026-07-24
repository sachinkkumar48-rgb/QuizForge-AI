import 'package:flutter/material.dart';

import '../models/recommendation_models.dart';

/// Material 3 summary overview widget displaying key metrics for generated recommendations.
class RecommendationSummaryCard extends StatelessWidget {
  final List<Recommendation> recommendations;

  const RecommendationSummaryCard({
    super.key,
    required this.recommendations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final urgentCount = recommendations
        .where((r) => r.priority.toLowerCase() == 'urgent')
        .length;
    final totalMinutes = recommendations.fold<int>(
      0,
      (sum, r) => sum + r.estimatedStudyTimeMinutes,
    );
    final topFocusTopic = recommendations.isNotEmpty
        ? recommendations.first.topic
        : 'All Caught Up!';

    final formattedTime = _formatDuration(totalMinutes);

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(color: colorScheme.primary.withAlpha(64)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 28.0,
                ),
                const SizedBox(width: 10.0),
                Text(
                  'Personalized Study Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${recommendations.length} Active',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            // Metrics Grid / Row
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Urgent Actions',
                    value: '$urgentCount',
                    icon: Icons.notification_important_rounded,
                    color: urgentCount > 0
                        ? colorScheme.error
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Estimated Time',
                    value: formattedTime,
                    icon: Icons.timer_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    label: 'Top Focus',
                    value: topFocusTopic,
                    icon: Icons.track_changes_rounded,
                    color: colorScheme.onPrimaryContainer,
                    isText: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes <= 0) return '0 min';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return '${hours}h';
    return '${hours}h ${rem}m';
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isText;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isText = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 20.0, color: color),
        const SizedBox(height: 4.0),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10.0,
            color:
                Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(180),
          ),
        ),
      ],
    );
  }
}
