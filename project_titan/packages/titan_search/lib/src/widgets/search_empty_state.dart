import 'package:flutter/material.dart';

/// Material 3 empty state illustration widget displayed when no search results match.
class SearchEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onResetFilters;

  const SearchEmptyState({
    super.key,
    this.title = 'No Results Found',
    this.message =
        'Try adjusting your search terms, enabling synonym expansion, or selecting more scopes.',
    this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64.0,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onResetFilters != null) ...[
              const SizedBox(height: 16.0),
              OutlinedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.refresh, size: 18.0),
                label: const Text('Reset Scopes & Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
