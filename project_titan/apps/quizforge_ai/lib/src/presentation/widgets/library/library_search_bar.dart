import 'package:flutter/material.dart';

/// Reusable Material 3 SearchBar widget with search query field and category filter chips.
class LibrarySearchBar extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onCategorySelected;
  final VoidCallback? onClearSearch;

  const LibrarySearchBar({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    this.categories = const [
      'All',
      'Polity',
      'Economy',
      'History',
      'Environment',
      'General Studies',
    ],
    this.onSearchChanged,
    this.onCategorySelected,
    this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: searchQuery,
              selection: TextSelection.collapsed(offset: searchQuery.length),
            ),
          ),
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search documents, categories, tags...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClearSearch,
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected =
                  cat.toLowerCase() == selectedCategory.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onCategorySelected?.call(cat);
                    }
                  },
                  selectedColor: colorScheme.primaryContainer,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
