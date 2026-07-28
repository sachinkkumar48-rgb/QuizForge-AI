import 'package:flutter/material.dart';

import '../models/learning_session_models.dart';

/// Modal bottom sheet presented upon completing a lesson.
class LessonCompletionSheet extends StatelessWidget {
  final LearningFlowSummary summary;
  final VoidCallback onContinue;
  final VoidCallback onReturnToDashboard;

  const LessonCompletionSheet({
    super.key,
    required this.summary,
    required this.onContinue,
    required this.onReturnToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'Lesson Completed Summary Sheet',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.stars_rounded,
              size: 56,
              color: Colors.amber.shade700,
            ),
            const SizedBox(height: 12),
            Text(
              'Lesson Completed!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your progress, notes, and revision queue have been updated.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBadge(
                  context,
                  label: 'Duration',
                  value: '${summary.totalDurationMinutes} mins',
                  icon: Icons.timer_outlined,
                ),
                _buildStatBadge(
                  context,
                  label: 'Quiz Accuracy',
                  value: '${(summary.quizAccuracy * 100).toInt()}%',
                  icon: Icons.check_circle_outline_rounded,
                ),
                _buildStatBadge(
                  context,
                  label: 'Notes',
                  value: '${summary.notesCreatedCount}',
                  icon: Icons.edit_note_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReturnToDashboard,
                    child: const Text('Dashboard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onContinue,
                    child: const Text('Next Lesson'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
