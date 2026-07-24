import 'package:flutter/material.dart';

import '../models/recommendation_models.dart';
import 'recommendation_priority_badge.dart';
import 'recommendation_reason_chip.dart';

/// Material 3 Card widget rendering a complete, explainable recommendation item.
class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback? onTap;
  final VoidCallback? onActionPressed;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final confidencePct = (recommendation.confidence * 100).toInt();

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(128),
          width: 1.0,
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Priority Badge, Source Chip, Confidence Score
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RecommendationPriorityBadge(
                    priority: recommendation.priority,
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withAlpha(150),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      recommendation.source,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14.0,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '$confidencePct% match',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),

              // Title
              Text(
                recommendation.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8.0),

              // Topic, Action Type & Estimated Study Time
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 14.0,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    recommendation.topic,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Icon(
                    Icons.schedule_rounded,
                    size: 14.0,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '${recommendation.estimatedStudyTimeMinutes} min study',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              if (recommendation.reasons.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: recommendation.reasons
                      .map((r) => RecommendationReasonChip(reason: r))
                      .toList(),
                ),
              ],

              const SizedBox(height: 12.0),

              // Bottom Action Button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onActionPressed ?? onTap,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16.0),
                  label: Text(
                    'Start ${recommendation.actionType}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
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
