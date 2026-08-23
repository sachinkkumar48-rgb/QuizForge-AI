import 'package:flutter/material.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import '../../theme/app_spacing.dart';

/// Hero UI card rendering the highest-priority deterministic next study action.
class StudyNextHeroCard extends StatelessWidget {
  final StudyNextRecommendation recommendation;
  final VoidCallback? onPrimaryAction;
  final ValueChanged<ReaderDeepLinkRequest>? onOpenSource;

  const StudyNextHeroCard({
    super.key,
    required this.recommendation,
    this.onPrimaryAction,
    this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color badgeColor;
    final IconData iconData;
    switch (recommendation.actionType) {
      case StudyNextActionType.reviewDue:
        badgeColor = Colors.amber.shade700;
        iconData = Icons.alarm;
        break;
      case StudyNextActionType.remedyWeakTopic:
        badgeColor = Colors.deepOrange.shade600;
        iconData = Icons.auto_fix_high;
        break;
      case StudyNextActionType.reviewDecliningTopic:
        badgeColor = Colors.orange.shade700;
        iconData = Icons.trending_down;
        break;
      case StudyNextActionType.practiceNewTopic:
        badgeColor = colorScheme.primary;
        iconData = Icons.school;
        break;
      case StudyNextActionType.startFirstAssessment:
        badgeColor = Colors.teal;
        iconData = Icons.play_arrow;
        break;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: badgeColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconData, size: 16, color: badgeColor),
                      const SizedBox(width: 6),
                      Text(
                        'STUDY NEXT',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Diff: ${recommendation.recommendedDifficulty.name.toUpperCase()}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              recommendation.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              recommendation.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Rationale: ${recommendation.rationale}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (recommendation.hasDeepLink && onOpenSource != null)
                  OutlinedButton.icon(
                    onPressed: () =>
                        onOpenSource!(recommendation.deepLinkRequest!),
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: Text(
                      'Study in Reader (p. ${recommendation.pageNumber ?? 1})',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: badgeColor,
                      side: BorderSide(color: badgeColor),
                    ),
                  ),
                if (onPrimaryAction != null)
                  ElevatedButton.icon(
                    onPressed: onPrimaryAction,
                    icon: const Icon(Icons.play_circle_fill, size: 18),
                    label: const Text('Start Adaptive Practice'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: badgeColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
