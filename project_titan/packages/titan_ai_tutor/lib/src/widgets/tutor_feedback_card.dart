import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 card presenting evaluation feedback.
class TutorFeedbackCard extends StatelessWidget {
  final TutorFeedback feedback;

  const TutorFeedbackCard({super.key, required this.feedback});

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
                Icon(
                  feedback.isPositive ? Icons.thumb_up : Icons.thumb_down,
                  color: feedback.isPositive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Feedback (${feedback.rating}/5)',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(feedback.comment),
            if (feedback.suggestedFocus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Suggested Focus: ${feedback.suggestedFocus}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
