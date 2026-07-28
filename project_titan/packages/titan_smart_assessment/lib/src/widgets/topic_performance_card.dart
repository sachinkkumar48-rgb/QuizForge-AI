import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 card presenting topic-level performance metrics.
class TopicPerformanceCard extends StatelessWidget {
  final TopicStatistics topicStat;

  const TopicPerformanceCard({super.key, required this.topicStat});

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  topicStat.topicName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${topicStat.accuracyPercentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: topicStat.accuracyPercentage >= 60
                        ? Colors.green
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: topicStat.accuracyPercentage / 100.0,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),
            Text(
              'Correct: ${topicStat.correctAnswers} | Wrong: ${topicStat.wrongAnswers} | Skipped: ${topicStat.skipped}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
