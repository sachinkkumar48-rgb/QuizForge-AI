import 'package:flutter/material.dart';
import '../models/content_outcome.dart';

/// Reusable Material 3 widget displaying learning outcomes and skill badge rewards.
class LearningOutcomeCard extends StatelessWidget {
  final List<ContentOutcome> outcomes;

  const LearningOutcomeCard({
    super.key,
    required this.outcomes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (outcomes.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0.0,
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    size: 20.0, color: colorScheme.tertiary),
                const SizedBox(width: 8.0),
                Text(
                  'Expected Outcomes & Badges',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            ...outcomes.map(
              (outcome) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.star_border_rounded,
                        size: 16.0, color: colorScheme.tertiary),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${outcome.title} (+${outcome.masteryGain.toStringAsFixed(0)}% Mastery)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            outcome.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (outcome.skillBadge != null)
                      Chip(
                        avatar:
                            const Icon(Icons.military_tech_rounded, size: 14.0),
                        label: Text(outcome.skillBadge!),
                        backgroundColor: colorScheme.surface,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
