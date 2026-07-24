import 'package:flutter/material.dart';

/// Material 3 Card displaying an auto-completion suggested query.
class SuggestedQueryCard extends StatelessWidget {
  final String suggestion;
  final VoidCallback onTap;

  const SuggestedQueryCard({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(Icons.north_west,
          size: 18.0, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        suggestion,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
