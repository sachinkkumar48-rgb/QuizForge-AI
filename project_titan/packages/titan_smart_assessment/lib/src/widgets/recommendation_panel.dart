import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 panel displaying personalized study recommendations.
class RecommendationPanel extends StatelessWidget {
  final List<AssessmentRecommendation> recommendations;
  final void Function(AssessmentRecommendation rec)? onSelectAction;

  const RecommendationPanel({
    super.key,
    required this.recommendations,
    this.onSelectAction,
  });

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
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Recommended Action Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...recommendations.map(
              (rec) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.fitness_center,
                      size: 18, color: theme.colorScheme.primary),
                ),
                title: Text(rec.title),
                subtitle: Text(rec.description),
                trailing: FilledButton.tonal(
                  onPressed: () => onSelectAction?.call(rec),
                  child: Text(rec.actionType),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
