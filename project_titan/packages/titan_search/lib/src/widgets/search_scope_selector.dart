import 'package:flutter/material.dart';

import '../models/search_scope.dart';

/// Material 3 horizontally scrollable scope selection chip bar.
class SearchScopeSelector extends StatelessWidget {
  final Set<SearchScope> selectedScopes;
  final ValueChanged<Set<SearchScope>> onScopesChanged;

  const SearchScopeSelector({
    super.key,
    required this.selectedScopes,
    required this.onScopesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Row(
        children: SearchScope.values.map((scope) {
          final isSelected = selectedScopes.contains(scope);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(scope.displayName),
              selected: isSelected,
              onSelected: (selected) {
                final updated = Set<SearchScope>.from(selectedScopes);
                if (selected) {
                  updated.add(scope);
                } else {
                  if (updated.length > 1) {
                    updated.remove(scope);
                  }
                }
                onScopesChanged(updated);
              },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
