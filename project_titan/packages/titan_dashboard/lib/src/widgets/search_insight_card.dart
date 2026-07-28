import 'package:flutter/material.dart';

/// Material 3 card displaying recent search queries and semantic search trends.
class SearchInsightCard extends StatelessWidget {
  final List<String> recentQueries;
  final ValueChanged<String>? onQueryTap;

  const SearchInsightCard({
    super.key,
    required this.recentQueries,
    this.onQueryTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.search_rounded, color: colorScheme.secondary),
                const SizedBox(width: 8.0),
                Text(
                  'Recent Search Trends',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            if (recentQueries.isEmpty)
              Text(
                'No recent searches recorded.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 6.0,
                children: recentQueries.map((q) {
                  return ActionChip(
                    avatar: const Icon(Icons.history, size: 14.0),
                    label: Text(q),
                    onPressed: onQueryTap != null ? () => onQueryTap!(q) : null,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
