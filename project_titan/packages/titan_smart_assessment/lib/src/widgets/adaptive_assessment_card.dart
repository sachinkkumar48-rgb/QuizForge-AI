import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 card presenting IRT adaptive assessment state.
class AdaptiveAssessmentCard extends StatelessWidget {
  final AdaptiveAssessmentState state;

  const AdaptiveAssessmentCard({super.key, required this.state});

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
                Icon(Icons.tune, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Adaptive CAT State',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
                'Ability Estimate (Theta): ${state.currentTheta.toStringAsFixed(2)}'),
            Text('Standard Error: ${state.standardError.toStringAsFixed(2)}'),
            Text('Items Administered: ${state.itemsAdministered}'),
            Text('Streak: ${state.consecutiveCorrect} correct in a row'),
          ],
        ),
      ),
    );
  }
}
