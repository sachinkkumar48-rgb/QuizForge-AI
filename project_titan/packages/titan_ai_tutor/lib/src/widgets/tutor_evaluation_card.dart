import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 card presenting evaluation results, grades, and recommendations.
class TutorEvaluationCard extends StatelessWidget {
  final TutorEvaluation evaluation;

  const TutorEvaluationCard({super.key, required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Evaluation Report',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(evaluation.grade.name.toUpperCase()),
                  backgroundColor: theme.colorScheme.primaryContainer,
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              'Score: ${evaluation.score.toStringAsFixed(1)} / 100',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(evaluation.feedbackText),
            if (evaluation.detectedMisconceptions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Detected Misconceptions:',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: Colors.red.shade700),
              ),
              ...evaluation.detectedMisconceptions
                  .map((m) => Text('• $m', style: theme.textTheme.bodySmall)),
            ],
            if (evaluation.recommendations.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Recommendations:',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.secondary),
              ),
              ...evaluation.recommendations
                  .map((r) => Text('• $r', style: theme.textTheme.bodySmall)),
            ],
          ],
        ),
      ),
    );
  }
}
