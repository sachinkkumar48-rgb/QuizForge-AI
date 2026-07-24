import 'package:flutter/material.dart';

import '../../../models/ai_mentor_models.dart';

/// Reusable Material 3 Study Plan Checklist Card displaying
/// personalized study tasks with priority chips and completion checkboxes.
class StudyPlanCard extends StatelessWidget {
  final List<StudyPlanItem> studyPlan;
  final ValueChanged<String>? onToggleCompletion;

  const StudyPlanCard({
    super.key,
    required this.studyPlan,
    this.onToggleCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note,
                    color: Colors.deepPurple, size: 22),
                const SizedBox(width: 8),
                Text(
                  "AI Generated Study Plan",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            Text(
              "${studyPlan.where((e) => e.isCompleted).length}/${studyPlan.length} Completed",
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (studyPlan.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text("No study tasks scheduled yet."),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: studyPlan.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = studyPlan[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: item.isCompleted
                        ? Colors.green.withValues(alpha: 0.5)
                        : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                color: item.isCompleted
                    ? Colors.green.withValues(alpha: 0.04)
                    : colorScheme.surface,
                child: CheckboxListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  value: item.isCompleted,
                  onChanged: onToggleCompletion != null
                      ? (_) => onToggleCompletion!(item.id)
                      : null,
                  activeColor: Colors.green,
                  title: Row(
                    children: [
                      _priorityChip(item.priority),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.topic,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            decoration: item.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Text(
                          item.subject,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text("•"),
                        const SizedBox(width: 8),
                        Icon(Icons.timer_outlined,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          "${item.estimatedMinutes} mins",
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        const Text("•"),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.actionType,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _priorityChip(PlanPriority priority) {
    Color color;
    String label;
    switch (priority) {
      case PlanPriority.high:
        color = Colors.red;
        label = "High";
        break;
      case PlanPriority.medium:
        color = Colors.orange;
        label = "Medium";
        break;
      case PlanPriority.low:
        color = Colors.blue;
        label = "Low";
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
