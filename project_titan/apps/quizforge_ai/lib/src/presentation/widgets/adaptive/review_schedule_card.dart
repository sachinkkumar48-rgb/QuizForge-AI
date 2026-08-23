import 'package:flutter/material.dart';
import 'package:titan_pdf/titan_pdf.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import '../../theme/app_spacing.dart';

/// Card displaying spaced-repetition review items and quick review triggers.
class ReviewScheduleCard extends StatelessWidget {
  final List<ReviewScheduleItem> items;
  final ValueChanged<ReviewScheduleItem>? onReviewItem;
  final ValueChanged<ReaderDeepLinkRequest>? onOpenSource;

  const ReviewScheduleCard({
    super.key,
    required this.items,
    this.onReviewItem,
    this.onOpenSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueItems = items.where((i) => i.isDue()).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.alarm,
                  color:
                      dueItems.isNotEmpty ? Colors.amber.shade800 : Colors.teal,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spaced Review Schedule',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: dueItems.isNotEmpty
                        ? Colors.amber.withValues(alpha: 0.15)
                        : Colors.teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    dueItems.isNotEmpty
                        ? '${dueItems.length} DUE'
                        : 'UP TO DATE',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: dueItems.isNotEmpty
                          ? Colors.amber.shade900
                          : Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (dueItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No reviews currently overdue. Spaced repetition items will appear automatically based on your performance.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              )
            else
              Column(
                children: dueItems
                    .map((item) => _buildDueRow(context, item))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueRow(BuildContext context, ReviewScheduleItem item) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.topic,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Streak: ${item.consecutiveCorrect} correct • Status: ${item.status.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (item.documentId != null &&
                item.pageNumber != null &&
                onOpenSource != null)
              IconButton(
                icon: const Icon(Icons.menu_book, size: 18),
                tooltip: 'Study source in Reader (p. ${item.pageNumber})',
                onPressed: () {
                  onOpenSource!(
                    ReaderDeepLinkRequest(
                      documentId: item.documentId!,
                      pageNumber: item.pageNumber!,
                      chunkId: item.sourceChunkId,
                      source: 'review_schedule',
                    ),
                  );
                },
              ),
            if (onReviewItem != null)
              ElevatedButton(
                onPressed: () => onReviewItem!(item),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Review'),
              ),
          ],
        ),
      ),
    );
  }
}
