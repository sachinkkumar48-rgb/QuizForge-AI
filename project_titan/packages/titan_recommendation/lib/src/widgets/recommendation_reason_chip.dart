import 'package:flutter/material.dart';

import '../models/recommendation_models.dart';

/// Material 3 Chip widget for displaying explainable recommendation reasons.
class RecommendationReasonChip extends StatelessWidget {
  final RecommendationReason reason;

  const RecommendationReasonChip({
    super.key,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final weightPct = (reason.weight * 100).toInt();

    return Tooltip(
      message: reason.description,
      child: RawChip(
        avatar: CircleAvatar(
          backgroundColor: colorScheme.secondaryContainer,
          radius: 10,
          child: Text(
            '$weightPct%',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
        label: Text(
          reason.title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        backgroundColor: colorScheme.surfaceContainerHigh,
        side: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }
}
