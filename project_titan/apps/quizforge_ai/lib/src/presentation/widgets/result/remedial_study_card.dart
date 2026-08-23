import 'package:flutter/material.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import '../../theme/app_spacing.dart';

/// Card presenting actionable remedial study recommendations and direct deep-link navigation back to TITAN Reader.
class RemedialStudyCard extends StatelessWidget {
  final List<RemedialStudyRecommendation> recommendations;
  final ValueChanged<RemedialStudyRecommendation>? onStudySource;
  final VoidCallback? onRetryIncorrect;

  const RemedialStudyCard({
    super.key,
    required this.recommendations,
    this.onStudySource,
    this.onRetryIncorrect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (recommendations.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.green.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.green, width: 1),
        ),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Row(
            children: [
              const Icon(Icons.verified, color: Colors.green, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Outstanding performance! No weak topics identified in this assessment.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_stories, color: colorScheme.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Remedial Study Loop',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${recommendations.length} Weak ${recommendations.length == 1 ? "Area" : "Areas"}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Targeted review recommendations connecting assessment gaps directly back to source document pages.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            ...recommendations.map((rec) =>
                _buildRecommendationItem(context, theme, colorScheme, rec)),
            if (onRetryIncorrect != null) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onRetryIncorrect,
                  icon: const Icon(Icons.replay, size: 18),
                  label: const Text('Retry Incorrect Questions'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    RemedialStudyRecommendation rec,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rec.topic,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (rec.pageNumbers.isNotEmpty)
                Chip(
                  label: Text('Page ${rec.primaryPageNumber}'),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rec.reason,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed:
                  onStudySource != null ? () => onStudySource!(rec) : null,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text('Study in Reader (p. ${rec.primaryPageNumber})'),
            ),
          ),
        ],
      ),
    );
  }
}
