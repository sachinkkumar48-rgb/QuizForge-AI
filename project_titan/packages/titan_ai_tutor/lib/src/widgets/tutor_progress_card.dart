import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 card presenting concept progress and mastery metrics.
class TutorProgressCard extends StatelessWidget {
  final TutorProgress progress;

  const TutorProgressCard({super.key, required this.progress});

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
            Text(
              'Mastery Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.masteryLevel / 100.0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score: ${progress.masteryLevel.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'Confidence: ${(progress.confidenceLevel * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
