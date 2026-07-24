import 'package:flutter/material.dart';
import 'package:titan_revision/titan_revision.dart';

/// Reusable Material 3 widget displaying SM-2 spaced repetition metrics and 0-5 recall rating buttons.
class SpacedRepetitionCard extends StatelessWidget {
  final RevisionItem item;
  final ValueChanged<int>? onRateRecall;

  const SpacedRepetitionCard({
    super.key,
    required this.item,
    this.onRateRecall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.av_timer,
                  color: colorScheme.secondary,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spaced Repetition Metrics (SM-2)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(context, 'Ease Factor', '${item.easeFactor}'),
                _buildStat(context, 'Interval', '${item.intervalDays} days'),
                _buildStat(context, 'Repetitions', '${item.repetitions}'),
                _buildStat(context, 'Mastery', item.masteryLevel),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Rate Your Recall Difficulty:',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (rating) {
                return _buildRatingButton(context, rating);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingButton(BuildContext context, int rating) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color btnColor;
    switch (rating) {
      case 5:
        btnColor = Colors.green;
        break;
      case 4:
        btnColor = Colors.teal;
        break;
      case 3:
        btnColor = Colors.amber.shade800;
        break;
      case 2:
        btnColor = Colors.orange;
        break;
      default:
        btnColor = colorScheme.error;
    }

    return InkWell(
      onTap: () => onRateRecall?.call(rating),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: btnColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: btnColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            '$rating',
            style: theme.textTheme.titleMedium?.copyWith(
              color: btnColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
