import 'package:flutter/material.dart';
import '../engine/cloud_sync_engine.dart';
import '../engine/sync_engine.dart';
import 'sync_widgets.dart';

/// Accessible dashboard card presenting real-time cloud synchronization status.
class CloudSyncStatusCard extends StatelessWidget {
  final CloudSyncManager manager;
  final VoidCallback? onSyncNow;

  const CloudSyncStatusCard({
    super.key,
    required this.manager,
    this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = manager.activeSession;
    final isSyncing = session?.status == CloudSyncSessionStatus.active;

    return Semantics(
      container: true,
      label: 'Cloud Synchronization Status Card',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? theme.colorScheme.surface : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_sync_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cloud Sync Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SyncStatusIndicator(
                    syncState: isSyncing
                        ? SyncState.syncing
                        : (manager.syncHistory.isNotEmpty &&
                                !manager.syncHistory.first.isSuccess
                            ? SyncState.error
                            : SyncState.success),
                    connectivityStatus: ConnectivityStatus.online,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isSyncing) CloudSyncProgress(session: session),
              const SizedBox(height: 8),
              Text(
                'Device ID: ${manager.deviceRegistration.deviceId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurface.withAlpha(178),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSyncing ? null : onSyncNow,
                      icon: isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: Text(isSyncing ? 'Syncing...' : 'Sync Cloud Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accessible card displaying registered device details and last sync timestamp.
class DeviceStatusCard extends StatelessWidget {
  final DeviceRegistration registration;

  const DeviceStatusCard({
    super.key,
    required this.registration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedLastSync = registration.lastSyncTimestamp != null
        ? '${registration.lastSyncTimestamp!.hour.toString().padLeft(2, '0')}:${registration.lastSyncTimestamp!.minute.toString().padLeft(2, '0')}'
        : 'Never';

    return Semantics(
      container: true,
      label: 'Registered Device Card for ${registration.deviceName}',
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.devices_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registration.deviceName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${registration.deviceType} • ID: ${registration.deviceId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last Sync: $formattedLastSync',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Accessible summary card presenting aggregate sync metrics.
class SyncStatisticsCard extends StatelessWidget {
  final CloudSyncStatistics statistics;

  const SyncStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: 'Synchronization Statistics Card',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sync Statistics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatTile(
                    label: 'Uploaded',
                    value: '${statistics.totalUploaded}',
                    icon: Icons.arrow_upward_rounded,
                    color: Colors.blue,
                  ),
                  _StatTile(
                    label: 'Downloaded',
                    value: '${statistics.totalDownloaded}',
                    icon: Icons.arrow_downward_rounded,
                    color: Colors.green,
                  ),
                  _StatTile(
                    label: 'Conflicts',
                    value: '${statistics.totalConflicts}',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                  _StatTile(
                    label: 'Success',
                    value: '${statistics.successRatePercentage.toStringAsFixed(0)}%',
                    icon: Icons.check_circle_rounded,
                    color: Colors.teal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Accessible progress indicator showing active batch sync phase.
class CloudSyncProgress extends StatelessWidget {
  final CloudSyncSession? session;

  const CloudSyncProgress({
    super.key,
    this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Batch synchronization in progress',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synchronizing batch deltas...',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Seq: ${session?.lastSyncedSequence ?? 0}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Accessible full page presenting scrollable sync history and audit logs.
class SyncHistoryPage extends StatelessWidget {
  final List<CloudSyncResult> history;
  final List<SyncAuditLog> auditLogs;
  final VoidCallback? onClearHistory;

  const SyncHistoryPage({
    super.key,
    required this.history,
    required this.auditLogs,
    this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synchronization History'),
        actions: [
          if (history.isNotEmpty && onClearHistory != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear History',
              onPressed: onClearHistory,
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No synchronization history recorded yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                return Semantics(
                  container: true,
                  label: 'Sync entry ${item.sessionId}',
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: ListTile(
                      leading: Icon(
                        item.isSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        color: item.isSuccess ? Colors.green : Colors.red,
                        size: 28,
                      ),
                      title: Text(
                        'Session: ${item.sessionId}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            'Uploaded: ${item.itemsUploaded} • Downloaded: ${item.itemsDownloaded} • Conflicts: ${item.conflicts}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Duration: ${item.duration.inMilliseconds} ms • Completed: ${item.endTime.toIso8601String().substring(11, 19)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(153),
                            ),
                          ),
                          if (item.errorMessage != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Error: ${item.errorMessage}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
