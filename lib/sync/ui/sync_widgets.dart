import 'package:flutter/material.dart';
import '../core/conflict_resolver.dart';
import '../engine/sync_engine.dart';

/// Accessible visual status indicator showing sync and network states.
class SyncStatusIndicator extends StatelessWidget {
  final SyncState syncState;
  final ConnectivityStatus connectivityStatus;
  final VoidCallback? onTap;
  final double size;

  const SyncStatusIndicator({
    super.key,
    required this.syncState,
    required this.connectivityStatus,
    this.onTap,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData iconData;
    Color color;
    String semanticLabel;

    if (connectivityStatus == ConnectivityStatus.offline) {
      iconData = Icons.wifi_off_rounded;
      color = isDark ? Colors.orangeAccent : Colors.deepOrange;
      semanticLabel = 'Offline: Internet connection unavailable';
    } else if (connectivityStatus == ConnectivityStatus.limitedConnectivity) {
      iconData = Icons.signal_cellular_connected_no_internet_4_bar_rounded;
      color = Colors.amber;
      semanticLabel = 'Limited connection detected';
    } else {
      switch (syncState) {
        case SyncState.syncing:
          iconData = Icons.sync_rounded;
          color = isDark ? Colors.cyanAccent : Colors.blue;
          semanticLabel = 'Synchronizing changes with cloud';
          break;
        case SyncState.success:
          iconData = Icons.cloud_done_rounded;
          color = isDark ? Colors.greenAccent : Colors.green;
          semanticLabel = 'All items synchronized';
          break;
        case SyncState.error:
          iconData = Icons.sync_problem_rounded;
          color = isDark ? Colors.redAccent : Colors.red;
          semanticLabel = 'Synchronization error occurred';
          break;
        case SyncState.idle:
          iconData = Icons.cloud_queue_rounded;
          color = Theme.of(context).colorScheme.onSurface.withAlpha(178);
          semanticLabel = 'Sync idle and ready';
          break;
      }
    }

    final child = Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: true,
      child: Tooltip(
        message: semanticLabel,
        child: syncState == SyncState.syncing &&
                connectivityStatus == ConnectivityStatus.online
            ? SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            : Icon(
                iconData,
                color: color,
                size: size,
              ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: child,
        ),
      );
    }

    return child;
  }
}

/// Accessible card widget displaying synchronization metrics and action controls.
class SyncProgressCard extends StatelessWidget {
  final SyncResult? lastResult;
  final int pendingCount;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final VoidCallback? onSyncNow;
  final VoidCallback? onRetryFailed;

  const SyncProgressCard({
    super.key,
    this.lastResult,
    required this.pendingCount,
    required this.isSyncing,
    this.lastSyncTime,
    this.onSyncNow,
    this.onRetryFailed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formattedLastSync = lastSyncTime != null
        ? '${lastSyncTime!.hour.toString().padLeft(2, '0')}:${lastSyncTime!.minute.toString().padLeft(2, '0')}'
        : 'Never';

    return Semantics(
      container: true,
      label: 'Synchronization Progress Card',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? theme.colorScheme.surface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Offline Synchronization',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SyncStatusIndicator(
                    syncState: isSyncing
                        ? SyncState.syncing
                        : (lastResult != null && !lastResult!.isSuccess
                            ? SyncState.error
                            : SyncState.success),
                    connectivityStatus: ConnectivityStatus.online,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isSyncing) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _MetricTile(
                    label: 'Pending Queue',
                    value: '$pendingCount',
                    icon: Icons.pending_actions_rounded,
                  ),
                  _MetricTile(
                    label: 'Processed',
                    value: '${lastResult?.itemsProcessed ?? 0}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  _MetricTile(
                    label: 'Failed',
                    value: '${lastResult?.itemsFailed ?? 0}',
                    icon: Icons.error_outline_rounded,
                    isError: (lastResult?.itemsFailed ?? 0) > 0,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Last Synchronized: $formattedLastSync',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RetryButton(
                      onPressed: isSyncing ? null : onSyncNow,
                      isLoading: isSyncing,
                      label: 'Sync Now',
                    ),
                  ),
                  if (lastResult != null && lastResult!.itemsFailed > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRetryFailed,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry Failed'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isError;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? Colors.red : theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Accessible banner displayed at the top/bottom when internet connectivity is lost or limited.
class OfflineBanner extends StatelessWidget {
  final ConnectivityStatus connectivityStatus;
  final VoidCallback? onRetry;

  const OfflineBanner({
    super.key,
    required this.connectivityStatus,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (connectivityStatus == ConnectivityStatus.online) {
      return const SizedBox.shrink();
    }

    final isOffline = connectivityStatus == ConnectivityStatus.offline;
    final message = isOffline
        ? 'You are offline. Mutations are saved locally and will auto-sync when online.'
        : 'Limited connectivity detected. Sync operations may be delayed.';
    final backgroundColor =
        isOffline ? Colors.orange.shade800 : Colors.amber.shade900;

    return Semantics(
      liveRegion: true,
      label: 'Network Connectivity Alert: $message',
      child: Container(
        width: double.infinity,
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Accessible modal dialog enabling user conflict inspection and strategy selection.
class ConflictDialog extends StatelessWidget {
  final String entityId;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> remotePayload;
  final ValueChanged<ConflictResolutionStrategy> onResolve;

  const ConflictDialog({
    super.key,
    required this.entityId,
    required this.localPayload,
    required this.remotePayload,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: 'Conflict Resolution Dialog for item $entityId',
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Data Conflict Detected')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Entity ID: $entityId',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Please select how to resolve this conflict:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Newest Timestamp Wins'),
                subtitle:
                    const Text('Keeps version with most recent update time'),
                onTap: () {
                  Navigator.of(context).pop();
                  onResolve(ConflictResolutionStrategy.lastWriteWins);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_rounded),
                title: const Text('Server Wins'),
                subtitle:
                    const Text('Overwrites local with cloud server data'),
                onTap: () {
                  Navigator.of(context).pop();
                  onResolve(ConflictResolutionStrategy.remoteWins);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android_rounded),
                title: const Text('Local Wins'),
                subtitle: const Text('Preserves local changes on this device'),
                onTap: () {
                  Navigator.of(context).pop();
                  onResolve(ConflictResolutionStrategy.localWins);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Accessible interactive retry button supporting loading states and screen readers.
class RetryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;

  const RetryButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.label = 'Retry Sync',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null && !isLoading,
      label: '$label button',
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.sync_rounded, size: 18),
        label: Text(label),
      ),
    );
  }
}
