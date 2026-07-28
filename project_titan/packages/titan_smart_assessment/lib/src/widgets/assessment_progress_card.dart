import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 card presenting session progress.
class AssessmentProgressCard extends StatelessWidget {
  final AssessmentSession session;
  final int totalQuestions;

  const AssessmentProgressCard({
    super.key,
    required this.session,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressRatio =
        totalQuestions > 0 ? (session.attempts.length / totalQuestions) : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assessment Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progressRatio.clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completed: ${session.attempts.length} / $totalQuestions',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '${(progressRatio * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
