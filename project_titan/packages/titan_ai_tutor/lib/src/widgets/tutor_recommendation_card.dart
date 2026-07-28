import 'package:flutter/material.dart';

/// Responsive Material 3 card presenting AI Tutor recommendations.
class TutorRecommendationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onAction;

  const TutorRecommendationCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.auto_awesome,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: FilledButton.tonal(
          onPressed: onAction,
          child: const Text('Start'),
        ),
      ),
    );
  }
}
