import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 card presenting an assessment summary.
class AssessmentCard extends StatelessWidget {
  final Assessment assessment;
  final VoidCallback? onStart;

  const AssessmentCard({
    super.key,
    required this.assessment,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    assessment.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(assessment.type.displayName),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              assessment.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text('${assessment.totalDurationMinutes} mins'),
                const SizedBox(width: 16),
                Icon(Icons.quiz, size: 16, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text('${assessment.questions.length} questions'),
                const Spacer(),
                FilledButton(
                  onPressed: onStart,
                  child: const Text('Start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
