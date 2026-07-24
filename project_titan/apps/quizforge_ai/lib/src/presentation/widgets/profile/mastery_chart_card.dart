import 'package:flutter/material.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';

/// Material 3 card displaying topic mastery percentages and level badges.
class MasteryChartCard extends StatelessWidget {
  final List<TopicMastery> topicMasteries;

  const MasteryChartCard({
    super.key,
    required this.topicMasteries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Topic Mastery Overview',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topicMasteries.isEmpty)
              Text(
                'No topic mastery data available.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...topicMasteries.map((m) => _buildMasteryRow(context, m)),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryRow(BuildContext context, TopicMastery mastery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color progressColor;
    switch (mastery.masteryLevel) {
      case 'Master':
        progressColor = Colors.green;
        break;
      case 'Proficient':
        progressColor = Colors.blue;
        break;
      case 'Learning':
        progressColor = Colors.orange;
        break;
      default:
        progressColor = colorScheme.error;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  mastery.topic,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Chip(
                label: Text(
                    '${mastery.masteryPercentage}% (${mastery.masteryLevel})'),
                backgroundColor: progressColor.withValues(alpha: 0.12),
                labelStyle: theme.textTheme.labelSmall?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (mastery.masteryPercentage / 100.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}
