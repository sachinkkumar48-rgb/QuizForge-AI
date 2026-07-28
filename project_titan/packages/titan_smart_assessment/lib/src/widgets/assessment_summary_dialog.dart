import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 dialog displaying final evaluation report & gains.
class AssessmentSummaryDialog extends StatelessWidget {
  final AssessmentResult result;
  final VoidCallback? onDismiss;

  const AssessmentSummaryDialog({
    super.key,
    required this.result,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.emoji_events, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Assessment Completed'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score: ${result.score.toStringAsFixed(1)} / ${result.totalPossibleScore}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text('Accuracy: ${result.percentage.toStringAsFixed(1)}%'),
          Text('Correct: ${result.correctCount} | Wrong: ${result.wrongCount}'),
          if (result.analysis != null) ...[
            const Divider(height: 16),
            Text(
                'Readiness Score: ${result.analysis!.readinessScore.toStringAsFixed(1)}/100'),
            Text('Prediction: ${result.analysis!.examPrediction}'),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).maybePop();
            onDismiss?.call();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
