import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Card showing immediate post-submission feedback, explanation, and remedial study link to TITAN Reader.
class ImmediateFeedbackCard extends StatelessWidget {
  final bool isCorrect;
  final String explanation;
  final int? pageNumber;
  final String? sourceChunkId;
  final VoidCallback? onStudySource;

  const ImmediateFeedbackCard({
    super.key,
    required this.isCorrect,
    required this.explanation,
    this.pageNumber,
    this.sourceChunkId,
    this.onStudySource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bannerColor = isCorrect ? Colors.green : colorScheme.error;
    final icon = isCorrect ? Icons.check_circle_outline : Icons.highlight_off;
    final title = isCorrect ? 'Correct!' : 'Incorrect';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: bannerColor.withValues(alpha: 0.5), width: 1.5),
      ),
      color: bannerColor.withValues(alpha: 0.06),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: bannerColor, size: 28),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: bannerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (pageNumber != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Page $pageNumber',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Explanation:',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              explanation,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            if (onStudySource != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onStudySource,
                  icon: const Icon(Icons.auto_stories, size: 18),
                  label: const Text('Study Source in Reader'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
