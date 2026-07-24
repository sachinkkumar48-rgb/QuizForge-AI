import 'package:flutter/material.dart';

import '../conflict/conflict_resolver.dart';
import '../models/sync_conflict.dart';

/// Material 3 Dialog empowering users to resolve manual sync conflicts.
class ConflictResolutionDialog extends StatelessWidget {
  final SyncConflict conflict;
  final ValueChanged<ConflictStrategy> onStrategySelected;

  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
    required this.onStrategySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.tertiary),
          const SizedBox(width: 8.0),
          const Text('Sync Conflict'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Conflicting changes detected for entity: ${conflict.localItem.entityType.name}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local Version: ${conflict.localItem.timestamp}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Payload: ${conflict.localItem.payload}'),
                  const Divider(),
                  Text(
                    'Server Version: ${conflict.remoteItem.timestamp}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Payload: ${conflict.remoteItem.payload}'),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onStrategySelected(ConflictStrategy.serverWins);
          },
          child: const Text('Use Server Version'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onStrategySelected(ConflictStrategy.localWins);
          },
          child: const Text('Use Local Version'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onStrategySelected(ConflictStrategy.merge);
          },
          child: const Text('Merge Changes'),
        ),
      ],
    );
  }
}
