import 'package:flutter/material.dart';
import '../core/conflict_resolver.dart';
import '../engine/sync_engine.dart';
import '../providers/cloud_sync_provider.dart';
import '../providers/custom_backend_sync_provider.dart';
import '../providers/firebase_sync_provider.dart';
import '../providers/google_drive_sync_provider.dart';

/// Cloud Synchronization Management Page Widget.
class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  final SyncEngine _engine = SyncEngine();
  final TextEditingController _serverUrlController =
      TextEditingController(text: 'https://api.quizforge.ai/v1/sync');
  final TextEditingController _tokenController =
      TextEditingController(text: 'sample_bearer_token');

  @override
  void dispose() {
    _serverUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _engine,
      builder: (context, _) {
        final activeType =
            _engine.activeProvider?.providerType ?? CloudProviderType.none;
        final state = _engine.state;
        final queueCount = _engine.queue.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cloud Synchronization'),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Sync Help',
                onPressed: () => _showHelpDialog(context),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Sync Status Banner Card
              Card(
                elevation: 2,
                color: state == SyncState.error
                    ? Colors.red.shade50
                    : state == SyncState.success
                        ? Colors.green.shade50
                        : Theme.of(context).cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: state == SyncState.syncing
                            ? Colors.blue.shade100
                            : state == SyncState.success
                                ? Colors.green.shade100
                                : state == SyncState.error
                                    ? Colors.red.shade100
                                    : Colors.grey.shade200,
                        child: state == SyncState.syncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                state == SyncState.success
                                    ? Icons.cloud_done
                                    : state == SyncState.error
                                        ? Icons.cloud_off
                                        : Icons.cloud_outlined,
                                color: state == SyncState.success
                                    ? Colors.green
                                    : state == SyncState.error
                                        ? Colors.red
                                        : Colors.grey.shade700,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state == SyncState.syncing
                                  ? 'Synchronizing...'
                                  : state == SyncState.success
                                      ? 'Sync Complete'
                                      : state == SyncState.error
                                          ? 'Sync Error'
                                          : 'Offline-First Ready',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _engine.lastSuccessfulSyncTime != null
                                  ? 'Last synced: ${_engine.lastSuccessfulSyncTime!.toLocal().toString().split('.').first}'
                                  : 'Not synchronized yet',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (_engine.lastErrorMessage.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                _engine.lastErrorMessage,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: state == SyncState.syncing
                      ? null
                      : () async {
                          final success = await _engine.syncNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? 'Sync completed successfully!'
                                    : 'Sync failed: ${_engine.lastErrorMessage}'),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.sync),
                  label: Text(state == SyncState.syncing
                      ? 'Synchronizing...'
                      : 'Sync Now ($queueCount Pending Mutations)'),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Cloud Providers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              RadioGroup<CloudProviderType>(
                groupValue: activeType,
                onChanged: (val) {
                  if (val == CloudProviderType.none) {
                    _engine.setCloudProvider(null);
                  } else if (val == CloudProviderType.googleDrive) {
                    _engine.setCloudProvider(GoogleDriveSyncProvider());
                  } else if (val == CloudProviderType.firebase) {
                    _engine.setCloudProvider(FirebaseSyncProvider());
                  } else if (val == CloudProviderType.customBackend) {
                    _engine.setCloudProvider(CustomBackendSyncProvider(
                      serverUrl: _serverUrlController.text,
                      authToken: _tokenController.text,
                    ));
                  }
                },
                child: Column(
                  children: const [
                    RadioListTile<CloudProviderType>(
                      value: CloudProviderType.none,
                      title: Text('Disabled (Local Offline Only)'),
                      subtitle:
                          Text('Store data strictly on this local device.'),
                    ),
                    RadioListTile<CloudProviderType>(
                      value: CloudProviderType.googleDrive,
                      title: Text('Google Drive'),
                      subtitle: Text(
                          'Sync snapshot to App Data folder on Google Drive.'),
                    ),
                    RadioListTile<CloudProviderType>(
                      value: CloudProviderType.firebase,
                      title: Text('Firebase Firestore'),
                      subtitle: Text(
                          'Sync real-time documents & collections via Firebase.'),
                    ),
                    RadioListTile<CloudProviderType>(
                      value: CloudProviderType.customBackend,
                      title: Text('Custom Server REST API'),
                      subtitle:
                          Text('Sync JSON snapshots via HTTPS bearer auth.'),
                    ),
                  ],
                ),
              ),

              if (activeType == CloudProviderType.customBackend) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _serverUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Server URL',
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Auth Token / Bearer Key',
                          prefixIcon: Icon(Icons.key),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Text(
                'Conflict Resolution Strategy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<ConflictResolutionStrategy>(
                initialValue: _engine.conflictStrategy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.merge_type),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ConflictResolutionStrategy.lastWriteWins,
                    child: Text('Last Write Wins (Recommended)'),
                  ),
                  DropdownMenuItem(
                    value: ConflictResolutionStrategy.remoteWins,
                    child: Text('Remote Wins (Overwrite Local)'),
                  ),
                  DropdownMenuItem(
                    value: ConflictResolutionStrategy.localWins,
                    child: Text('Local Wins (Keep Device Version)'),
                  ),
                  DropdownMenuItem(
                    value: ConflictResolutionStrategy.smartMerge,
                    child: Text('Smart Payload Merge'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _engine.setConflictStrategy(val);
                  }
                },
              ),

              const SizedBox(height: 24),
              Text(
                'Sync Targets Status',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),

              const ListTile(
                leading: Icon(Icons.bookmark),
                title: Text('Bookmarks'),
                subtitle: Text('Question bookmarks & snippets'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
              const ListTile(
                leading: Icon(Icons.note),
                title: Text('Notes'),
                subtitle: Text('Question user notes & custom study notes'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
              const ListTile(
                leading: Icon(Icons.bar_chart),
                title: Text('Statistics'),
                subtitle: Text('Exam attempts, accuracy & time metrics'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
              const ListTile(
                leading: Icon(Icons.schedule),
                title: Text('Revision Schedules'),
                subtitle: Text('Spaced repetition intervals & queues'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
              const ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                subtitle: Text('App configuration & preferences'),
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline-First Cloud Sync'),
        content: const Text(
          'QuizForge AI implements an offline-first synchronization architecture.\n\n'
          '• All changes are saved locally immediately.\n'
          '• When online, local and remote snapshots are merged using Conflict Resolution.\n'
          '• Supports Google Drive, Firebase, and Custom REST Server Backends.\n'
          '• Targets: Bookmarks, Notes, Statistics, Revision Schedules, and Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
