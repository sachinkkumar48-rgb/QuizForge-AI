import 'package:flutter/material.dart';
import 'package:titan_revision/titan_revision.dart';

/// Reusable Material 3 widget displaying a revision queue item with priority badge and recall action.
class RevisionQueueCard extends StatelessWidget {
  final RevisionItem item;
  final VoidCallback? onStartRecall;
  final ValueChanged<int>? onRatingSelected;

  const RevisionQueueCard({
    super.key,
    required this.item,
    this.onStartRecall,
    this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color priorityColor;
    switch (item.priority) {
      case 'Urgent':
        priorityColor = colorScheme.error;
        break;
      case 'High':
        priorityColor = Colors.deepOrange;
        break;
      case 'Medium':
        priorityColor = Colors.amber.shade800;
        break;
      default:
        priorityColor = Colors.green;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: priorityColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        item.priority,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.sourceTag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  item.isOverdue ? 'Overdue' : 'Due in ${item.intervalDays}d',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: item.isOverdue
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.topic,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (item.subtopic != null) ...[
              const SizedBox(height: 2),
              Text(
                item.subtopic!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (item.questionText != null) ...[
              const SizedBox(height: 8),
              Text(
                item.questionText!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Interval: ${item.intervalDays}d • EF: ${item.easeFactor}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onStartRecall,
                  icon: const Icon(Icons.psychology, size: 18),
                  label: const Text('Recall'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
