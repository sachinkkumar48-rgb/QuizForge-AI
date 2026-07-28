import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 card presenting overall performance analysis.
class AssessmentAnalysisCard extends StatelessWidget {
  final AssessmentAnalysis analysis;

  const AssessmentAnalysisCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Performance Analysis',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              'Readiness Score: ${analysis.readinessScore.toStringAsFixed(1)} / 100',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text('Exam Prediction: ${analysis.examPrediction}'),
            Text(
                'Overall Accuracy: ${analysis.overallAccuracyPercentage.toStringAsFixed(1)}%'),
            Text(
                'Speed: ${analysis.speedQuestionsPerMinute.toStringAsFixed(1)} qns/min'),
          ],
        ),
      ),
    );
  }
}
