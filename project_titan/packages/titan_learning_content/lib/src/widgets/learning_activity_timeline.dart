import 'package:flutter/material.dart';
import '../models/learning_activity_record.dart';

/// Reusable Material 3 timeline widget rendering a chronological stream of learning activities.
class LearningActivityTimeline extends StatelessWidget {
  final LearningActivityRecord record;

  const LearningActivityTimeline({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (record.activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No recent activity recorded.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Card(
      elevation: 0.0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_toggle_off_rounded,
                    size: 20.0, color: colorScheme.primary),
                const SizedBox(width: 8.0),
                Text(
                  'Learning Activity Log (${record.activityCount})',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: record.activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8.0),
              itemBuilder: (context, index) {
                final activity = record.activities[index];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 12.0,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        _getActivityIcon(activity.activityType),
                        size: 14.0,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        '${activity.activityType.name.toUpperCase()} - ${activity.durationSeconds}s',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatTimestamp(activity.timestamp),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(dynamic type) {
    return Icons.check_circle_outline;
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
