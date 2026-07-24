import 'package:flutter/material.dart';

/// Material 3 Card displaying recent user search history queries.
class RecentSearchCard extends StatelessWidget {
  final String query;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const RecentSearchCard({
    super.key,
    required this.query,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(Icons.history, size: 20.0),
      title: Text(
        query,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: onDelete != null
          ? IconButton(
              icon: const Icon(Icons.close, size: 18.0),
              onPressed: onDelete,
            )
          : null,
      onTap: onTap,
    );
  }
}
