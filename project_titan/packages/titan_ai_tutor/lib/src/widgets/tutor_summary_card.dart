import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 card presenting session summaries and learning gains.
class TutorSummaryCard extends StatelessWidget {
  final TutorSession session;

  const TutorSummaryCard({super.key, required this.session});

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
              'Session Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Concept: ${session.conceptId}'),
            Text('Status: ${session.status.name}'),
            Text('Exercises Completed: ${session.exercises.length}'),
            if (session.evaluation != null) ...[
              const Divider(height: 16),
              Text(
                'Final Score: ${session.evaluation!.score.toStringAsFixed(1)}%',
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
