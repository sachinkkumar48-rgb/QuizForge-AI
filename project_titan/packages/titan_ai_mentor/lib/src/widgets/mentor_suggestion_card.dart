import 'package:flutter/material.dart';

/// Material 3 Chip card displaying quick suggested prompts.
class MentorSuggestionCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const MentorSuggestionCard({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      avatar:
          Icon(Icons.lightbulb_outline, size: 16.0, color: colorScheme.primary),
      label: Text(label),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    );
  }
}
