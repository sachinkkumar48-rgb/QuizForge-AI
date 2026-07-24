import 'package:flutter/material.dart';

import '../models/planner_models.dart';
import 'study_task_card.dart';

/// Material 3 vertical timeline component rendering chronological study tasks
/// with connected timeline node lines and time slot indicators.
class StudyTimeline extends StatelessWidget {
  final List<StudyTask> tasks;
  final ValueChanged<StudyTask>? onTaskToggle;
  final ValueChanged<StudyTask>? onTaskTap;

  const StudyTimeline({
    super.key,
    required this.tasks,
    this.onTaskToggle,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 48.0,
                color: colorScheme.outline.withAlpha(128),
              ),
              const SizedBox(height: 12.0),
              Text(
                'No Tasks Scheduled',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Your daily study plan is empty. Generate a new plan to get started.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isFirst = index == 0;
        final isLast = index == tasks.length - 1;

        final timeString = task.scheduledStartTime != null
            ? _formatTime(task.scheduledStartTime!)
            : 'Slot ${index + 1}';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Time Column
            SizedBox(
              width: 65.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 14.0),
                child: Text(
                  timeString,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: task.isCompleted
                        ? colorScheme.outline
                        : colorScheme.primary,
                  ),
                ),
              ),
            ),

            // Timeline Node Column (Line + Circle)
            SizedBox(
              width: 24.0,
              child: Column(
                children: [
                  Container(
                    width: 2.0,
                    height: 14.0,
                    color: isFirst
                        ? Colors.transparent
                        : (task.isCompleted
                            ? colorScheme.primary
                            : colorScheme.outlineVariant),
                  ),
                  Icon(
                    task.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_checked_rounded,
                    size: 16.0,
                    color: task.isCompleted
                        ? colorScheme.primary
                        : (task.priority.toLowerCase() == 'urgent'
                            ? colorScheme.error
                            : colorScheme.secondary),
                  ),
                  Container(
                    width: 2.0,
                    height: isLast ? 0.0 : 80.0,
                    color: task.isCompleted
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8.0),

            // Task Card Component
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: StudyTaskCard(
                  task: task,
                  onToggleCompletion: onTaskToggle != null
                      ? (value) => onTaskToggle!(task)
                      : null,
                  onTap: onTaskTap != null ? () => onTaskTap!(task) : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
