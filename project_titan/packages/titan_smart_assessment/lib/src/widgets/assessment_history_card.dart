import 'package:flutter/material.dart';
import '../models/assessment_models.dart';

/// Responsive Material 3 card presenting past assessment result history.
class AssessmentHistoryCard extends StatelessWidget {
  final AssessmentResult result;
  final VoidCallback? onTap;

  const AssessmentHistoryCard({
    super.key,
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '${result.percentage.toInt()}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('Assessment ${result.assessmentId}'),
        subtitle: Text(
            'Score: ${result.score.toStringAsFixed(1)} / ${result.totalPossibleScore} | Date: ${result.completedAt.toLocal().toString().split(' ')[0]}'),
        trailing: Chip(
          label: Text(result.gradeLevel.name.toUpperCase()),
        ),
      ),
    );
  }
}
