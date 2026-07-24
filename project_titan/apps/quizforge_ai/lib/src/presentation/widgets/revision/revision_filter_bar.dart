import 'package:flutter/material.dart';

/// Reusable Material 3 filter bar widget for subject categories and urgency choices.
class RevisionFilterBar extends StatelessWidget {
  final String selectedCategory;
  final String filterOption;
  final List<String> categories;
  final List<String> filterOptions;
  final ValueChanged<String>? onCategorySelected;
  final ValueChanged<String>? onFilterOptionSelected;

  const RevisionFilterBar({
    super.key,
    required this.selectedCategory,
    required this.filterOption,
    this.categories = const [
      'All',
      'Indian Polity',
      'Indian Economy',
      'Modern History',
      'Environment',
    ],
    this.filterOptions = const ['All', 'Overdue', 'Due Today'],
    this.onCategorySelected,
    this.onFilterOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Filter Urgency: ',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 6,
              children: filterOptions.map((opt) {
                final isSel = opt.toLowerCase() == filterOption.toLowerCase();
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSel,
                  onSelected: (selected) {
                    if (selected) {
                      onFilterOptionSelected?.call(opt);
                    }
                  },
                  selectedColor: colorScheme.primaryContainer,
                  labelStyle: theme.textTheme.labelSmall?.copyWith(
                    color: isSel
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
                  selectedColor: colorScheme.secondaryContainer,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onSecondaryContainer
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
