import 'package:flutter/material.dart';
import '../models/note_summary.dart';

/// Material 3 Note Summary Card component.
class NoteSummaryCard extends StatelessWidget {
  final NoteSummary summary;

  const NoteSummaryCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLow,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('AI Executive Summary',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(summary.overview, style: theme.textTheme.bodyMedium),
            if (summary.keyTakeaways.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Key Takeaways:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              ...summary.keyTakeaways
                  .map((k) => Text('• $k', style: theme.textTheme.bodySmall)),
            ],
          ],
        ),
      ),
    );
  }
}
