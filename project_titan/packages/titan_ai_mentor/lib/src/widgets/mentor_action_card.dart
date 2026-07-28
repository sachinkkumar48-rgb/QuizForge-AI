import 'package:flutter/material.dart';

import '../models/mentor_recommendation.dart';

/// Material 3 action card for recommended action items embedded in mentor responses.
class MentorActionCard extends StatelessWidget {
  final MentorRecommendation recommendation;
  final VoidCallback? onPressed;

  const MentorActionCard({
    super.key,
    required this.recommendation,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        leading: Icon(Icons.bolt, color: colorScheme.tertiary),
        title: Text(
          recommendation.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          recommendation.description,
          style: theme.textTheme.bodySmall,
        ),
        trailing: FilledButton.tonal(
          onPressed: onPressed,
          child: const Text('Start'),
        ),
      ),
    );
  }
}
