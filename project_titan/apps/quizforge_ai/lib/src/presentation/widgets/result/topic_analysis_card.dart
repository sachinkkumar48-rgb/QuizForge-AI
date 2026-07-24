import 'package:flutter/material.dart';
import 'package:titan_analytics/titan_analytics.dart';

/// Reusable Material 3 widget displaying topic-wise accuracy and mastery level analysis.
class TopicAnalysisCard extends StatelessWidget {
  final List<TopicPerformance> topics;

  const TopicAnalysisCard({
    super.key,
    required this.topics,
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
                  Icons.topic,
                  color: colorScheme.secondary,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  'Topic Breakdown',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (topics.isEmpty)
              Text(
                'No topic data available.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topics.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = topics[index];
                  return _buildTopicItem(context, item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicItem(BuildContext context, TopicPerformance item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color masteryColor;
    switch (item.masteryLevel) {
      case 'Master':
        masteryColor = Colors.green;
        break;
      case 'Proficient':
        masteryColor = Colors.blue;
        break;
      default:
        masteryColor = colorScheme.error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.topic,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: masteryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.masteryLevel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: masteryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (item.accuracy / 100.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(masteryColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${item.accuracy.toStringAsFixed(0)}% (${item.correctCount}/${item.totalQuestions})',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
