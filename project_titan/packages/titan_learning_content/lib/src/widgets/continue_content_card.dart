import 'package:flutter/material.dart';
import '../models/learning_content.dart';
import 'content_progress_indicator.dart';

/// Reusable Material 3 hero widget displaying active [LearningContent] and Resume button.
class ContinueContentCard extends StatelessWidget {
  final LearningContent content;
  final VoidCallback? onResumeTap;

  const ContinueContentCard({
    super.key,
    required this.content,
    this.onResumeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2.0,
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: colorScheme.onSecondaryContainer,
                  size: 24.0,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'RESUME LEARNING CONTENT',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    content.type.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              content.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              content.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSecondaryContainer.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 16.0),
            ContentProgressIndicator(
              progress: content.progress,
              showLabel: true,
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onResumeTap,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume Content'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
