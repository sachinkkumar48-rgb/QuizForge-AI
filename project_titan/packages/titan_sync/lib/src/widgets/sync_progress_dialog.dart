import 'package:flutter/material.dart';

import '../models/sync_state.dart';

/// Material 3 dialog displaying real-time multi-device sync progress.
class SyncProgressDialog extends StatelessWidget {
  final SyncState state;
  final VoidCallback? onCancel;

  const SyncProgressDialog({
    super.key,
    required this.state,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.sync, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Synchronizing Data'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.phase == SyncPhase.resolvingConflicts
                ? 'Resolving data conflicts...'
                : 'Syncing learner progress across devices...',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: state.progress > 0 ? state.progress : null,
            backgroundColor: colorScheme.surfaceContainerHigh,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Ops: ${state.pendingOperationsCount}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${(state.progress * 100).toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}
