import 'package:flutter/material.dart';

import '../orchestrator/unified_dashboard_state.dart';

/// Section 5: AI Tutor Card.
/// Displays Question of the Day, Suggested concept chip, and Ask AI Tutor action prompt button.
/// Reuses titan_ai_tutor.
class AITutorCard extends StatelessWidget {
  final AITutorData data;
  final VoidCallback? onAskTutorTap;

  const AITutorCard({
    super.key,
    required this.data,
    this.onAskTutorTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: 'AI Tutor Question of the Day Card',
      container: true,
      child: Card(
        elevation: 1,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: colorScheme.tertiary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI TUTOR',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Question of the Day',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.questionOfTheDay,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    'Suggested concept:',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelStyle: theme.textTheme.labelSmall,
                    label: Text(data.suggestedConcept),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onAskTutorTap,
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: const Text('Ask AI Tutor'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.tertiary,
                    foregroundColor: colorScheme.onTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
