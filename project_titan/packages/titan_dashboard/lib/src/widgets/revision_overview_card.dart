import 'package:flutter/material.dart';

/// Material 3 revision overview card displaying pending SuperMemo spaced repetition status.
class RevisionOverviewCard extends StatelessWidget {
  final int pendingRevisionsCount;
  final VoidCallback? onTap;

  const RevisionOverviewCard({
    super.key,
    required this.pendingRevisionsCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: CircleAvatar(
          backgroundColor: colorScheme.tertiaryContainer,
          child: Icon(Icons.style, color: colorScheme.onTertiaryContainer),
        ),
        title: const Text('Spaced Repetition Queue'),
        subtitle:
            Text('$pendingRevisionsCount flashcard items pending review today'),
        trailing: FilledButton.tonal(
          onPressed: onTap,
          child: const Text('Revise'),
        ),
      ),
    );
  }
}
