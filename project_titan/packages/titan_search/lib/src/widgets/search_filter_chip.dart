import 'package:flutter/material.dart';

/// Material 3 Filter Chip for toggling search options or active search scopes.
class SearchFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  const SearchFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon != null
          ? Icon(icon, size: 16.0)
          : (selected ? const Icon(Icons.check, size: 16.0) : null),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
    );
  }
}
