import 'package:flutter/material.dart';

/// Reusable Material 3 widget displaying topic mastery scores and completion levels.
class TopicMasteryCard extends StatelessWidget {
  final Map<String, double> topicMastery;

  const TopicMasteryCard({
    super.key,
    required this.topicMastery,
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
                  Icons.insights,
                  color: colorScheme.tertiary,
                  size: 26,
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
            if (topicMastery.isEmpty)
              Text(
                'No topic mastery data available.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topicMastery.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = topicMastery.entries.elementAt(index);
                  return _buildMasteryRow(context, entry.key, entry.value);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryRow(BuildContext context, String topic, double mastery) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color badgeColor;
    String badgeText;
    if (mastery >= 80.0) {
      badgeColor = Colors.green;
      badgeText = 'Master';
    } else if (mastery >= 60.0) {
      badgeColor = Colors.blue;
      badgeText = 'Proficient';
    } else if (mastery >= 40.0) {
      badgeColor = Colors.amber.shade800;
      badgeText = 'Learning';
    } else {
      badgeColor = colorScheme.error;
      badgeText = 'Novice';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                topic,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: badgeColor,
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
                  value: (mastery / 100.0).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${mastery.toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
