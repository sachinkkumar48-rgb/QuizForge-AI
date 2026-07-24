import 'package:flutter/material.dart';

import '../models/search_result.dart';
import '../models/search_scope.dart';

/// Material 3 Card widget displaying a ranked search result item.
class SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback? onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      result.scope.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.auto_awesome,
                      size: 14.0, color: colorScheme.tertiary),
                  const SizedBox(width: 4.0),
                  Text(
                    'Score ${(result.score * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                result.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                result.snippet,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (result.matchedTerms.isNotEmpty) ...[
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 4.0,
                  children: result.matchedTerms.map((term) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        term,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10.0,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
