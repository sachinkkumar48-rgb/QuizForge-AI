import 'package:flutter/material.dart';
import '../models/tutor_models.dart';

/// Responsive Material 3 card presenting learning goals.
class TutorGoalCard extends StatelessWidget {
  final TutorGoal goal;
  final VoidCallback? onTap;

  const TutorGoalCard({super.key, required this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          goal.status == TutorGoalStatus.achieved
              ? Icons.check_circle
              : Icons.flag,
          color: theme.colorScheme.primary,
        ),
        title: Text(goal.title),
        subtitle: Text(
            'Target Date: ${goal.targetDate.toLocal().toString().split(' ')[0]}'),
        trailing: SizedBox(
          width: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${goal.progressPercentage.toInt()}%'),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: goal.progressPercentage / 100.0),
            ],
          ),
        ),
      ),
    );
  }
}
