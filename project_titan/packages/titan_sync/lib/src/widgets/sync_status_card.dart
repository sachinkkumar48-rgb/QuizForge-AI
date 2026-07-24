import 'package:flutter/material.dart';

import '../engine/sync_manager.dart';
import 'last_sync_tile.dart';
import 'pending_sync_badge.dart';

/// Material 3 Card widget summarizing cloud synchronization status and actions.
class SyncStatusCard extends StatelessWidget {
  final SyncEngineStatus status;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final VoidCallback? onSyncPressed;
  final VoidCallback? onRetryPressed;

  const SyncStatusCard({
    super.key,
    this.status = SyncEngineStatus.idle,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.onSyncPressed,
    this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case SyncEngineStatus.idle:
        statusText = 'Up to Date';
        statusColor = colorScheme.primary;
        statusIcon = Icons.cloud_done_outlined;
      case SyncEngineStatus.syncing:
        statusText = 'Syncing...';
        statusColor = colorScheme.secondary;
        statusIcon = Icons.cloud_sync_outlined;
      case SyncEngineStatus.success:
        statusText = 'Synced Successfully';
        statusColor = colorScheme.primary;
        statusIcon = Icons.check_circle_outline;
      case SyncEngineStatus.failed:
        statusText = 'Sync Failed';
        statusColor = colorScheme.error;
        statusIcon = Icons.cloud_off_outlined;
      case SyncEngineStatus.conflict:
        statusText = 'Sync Conflict Detected';
        statusColor = colorScheme.tertiary;
        statusIcon = Icons.warning_amber_rounded;
    }

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 28.0),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      LastSyncTile(lastSyncTime: lastSyncTime),
                    ],
                  ),
                ),
                PendingSyncBadge(count: pendingCount),
              ],
            ),
            const Divider(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == SyncEngineStatus.failed && onRetryPressed != null)
                  OutlinedButton.icon(
                    onPressed: onRetryPressed,
                    icon: const Icon(Icons.refresh, size: 18.0),
                    label: const Text('Retry Sync'),
                  ),
                const SizedBox(width: 8.0),
                FilledButton.icon(
                  onPressed:
                      status == SyncEngineStatus.syncing ? null : onSyncPressed,
                  icon: const Icon(Icons.sync_rounded, size: 18.0),
                  label: const Text('Sync Now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
