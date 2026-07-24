import 'package:flutter/material.dart';

import '../models/planner_models.dart';

/// Material 3 Card widget rendering a single study plan task item
/// with completion checkbox, priority indicator, category icon, and duration.
class StudyTaskCard extends StatelessWidget {
  final StudyTask task;
  final ValueChanged<bool?>? onToggleCompletion;
  final VoidCallback? onTap;

  const StudyTaskCard({
    super.key,
    required this.task,
    this.onToggleCompletion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final categoryStyle = _getCategoryStyle(task.category, colorScheme);
    final priorityStyle = _getPriorityStyle(task.priority, colorScheme);

    return Card(
      elevation: task.isCompleted ? 0.0 : 1.0,
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: task.isCompleted
              ? colorScheme.outlineVariant.withAlpha(64)
              : categoryStyle.color.withAlpha(100),
          width: 1.0,
        ),
      ),
      color: task.isCompleted
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox Toggle
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: onToggleCompletion,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  activeColor: colorScheme.primary,
                ),
              ),

              const SizedBox(width: 8.0),

              // Main Task Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Chip + Rollover Tag + Priority Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: categoryStyle.color.withAlpha(30),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                categoryStyle.icon,
                                size: 12.0,
                                color: categoryStyle.color,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                task.category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: categoryStyle.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (task.isRollover) ...[
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              'Carried Forward',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onTertiaryContainer,
                                fontWeight: FontWeight.w600,
                                fontSize: 9.0,
                              ),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: priorityStyle.backgroundColor,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            task.priority.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: priorityStyle.foregroundColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9.0,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8.0),

                    // Task Title
                    Text(
                      task.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: task.isCompleted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),

                    const SizedBox(height: 4.0),

                    // Topic & Duration
                    Row(
                      children: [
                        Text(
                          task.topic,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.schedule_rounded,
                          size: 12.0,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          '${task.estimatedDurationMinutes} min',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CategoryStyle _getCategoryStyle(String category, ColorScheme colorScheme) {
    switch (category.toLowerCase()) {
      case 'revision':
        return _CategoryStyle(
          icon: Icons.replay_rounded,
          color: colorScheme.primary,
        );
      case 'concept learning':
        return _CategoryStyle(
          icon: Icons.menu_book_rounded,
          color: colorScheme.secondary,
        );
      case 'practice & pyq':
        return _CategoryStyle(
          icon: Icons.assignment_turned_in_rounded,
          color: colorScheme.tertiary,
        );
      case 'current affairs':
      default:
        return _CategoryStyle(
          icon: Icons.newspaper_rounded,
          color: colorScheme.outline,
        );
    }
  }

  _PriorityStyle _getPriorityStyle(String priority, ColorScheme colorScheme) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return _PriorityStyle(
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
        );
      case 'high':
        return _PriorityStyle(
          backgroundColor: colorScheme.tertiaryContainer,
          foregroundColor: colorScheme.onTertiaryContainer,
        );
      case 'medium':
        return _PriorityStyle(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
        );
      case 'low':
      default:
        return _PriorityStyle(
          backgroundColor: colorScheme.surfaceContainerHighest,
          foregroundColor: colorScheme.onSurfaceVariant,
        );
    }
  }
}

class _CategoryStyle {
  final IconData icon;
  final Color color;

  const _CategoryStyle({required this.icon, required this.color});
}

class _PriorityStyle {
  final Color backgroundColor;
  final Color foregroundColor;

  const _PriorityStyle({
    required this.backgroundColor,
    required this.foregroundColor,
  });
}
