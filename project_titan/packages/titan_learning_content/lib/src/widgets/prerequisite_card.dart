import 'package:flutter/material.dart';
import '../models/content_prerequisite.dart';

/// Reusable Material 3 widget displaying prerequisites required before accessing content.
class PrerequisiteCard extends StatelessWidget {
  final List<ContentPrerequisite> prerequisites;

  const PrerequisiteCard({
    super.key,
    required this.prerequisites,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (prerequisites.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0.0,
      color: colorScheme.errorContainer.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lock_clock_outlined,
                    size: 20.0, color: colorScheme.error),
                const SizedBox(width: 8.0),
                Text(
                  'Prerequisites Required',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            ...prerequisites.map(
              (pre) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  children: [
                    Icon(
                      pre.isMandatory
                          ? Icons.error_outline
                          : Icons.info_outline,
                      size: 14.0,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        '${pre.title} (Min Mastery: ${pre.minimumMasteryScore.toStringAsFixed(0)}%)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
