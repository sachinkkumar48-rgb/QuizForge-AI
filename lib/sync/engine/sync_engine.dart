import 'package:flutter/foundation.dart';
import '../core/conflict_resolver.dart';
import '../core/sync_entity.dart';
import '../core/sync_metadata.dart';
import '../core/sync_snapshot.dart';
import '../core/sync_target.dart';
import '../providers/cloud_sync_provider.dart';
import 'sync_queue.dart';

/// Current status of the SyncEngine.
enum SyncState {
  idle,
  syncing,
  success,
  error,
}

/// Central offline-first Cloud Synchronization Engine for QuizForge AI.
class SyncEngine extends ChangeNotifier {
  static final SyncEngine _instance = SyncEngine._internal();
  factory SyncEngine() => _instance;

  SyncEngine._internal();

  final Map<SyncEntityType, SyncTarget> _targets = {};
  final SyncQueue _syncQueue = SyncQueue();

  CloudSyncProvider? _activeProvider;
  ConflictResolutionStrategy _conflictStrategy =
      ConflictResolutionStrategy.lastWriteWins;

  SyncState _state = SyncState.idle;
  String _lastErrorMessage = '';
  DateTime? _lastSuccessfulSyncTime;
  String _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';

  // Getters
  SyncState get state => _state;
  String get lastErrorMessage => _lastErrorMessage;
  DateTime? get lastSuccessfulSyncTime => _lastSuccessfulSyncTime;
  CloudSyncProvider? get activeProvider => _activeProvider;
  SyncQueue get queue => _syncQueue;
  String get deviceId => _deviceId;
  ConflictResolutionStrategy get conflictStrategy => _conflictStrategy;

  /// Set client device identifier.
  void setDeviceId(String id) {
    _deviceId = id;
    notifyListeners();
  }

  /// Register a domain sync target adapter.
  void registerTarget(SyncTarget target) {
    _targets[target.targetType] = target;
    notifyListeners();
  }

  /// Configure active cloud provider backend.
  void setCloudProvider(CloudSyncProvider? provider) {
    _activeProvider = provider;
    notifyListeners();
  }

  /// Configure conflict resolution strategy.
  void setConflictStrategy(ConflictResolutionStrategy strategy) {
    _conflictStrategy = strategy;
    notifyListeners();
  }

  /// Record local mutation into offline sync queue.
  void recordLocalMutation(SyncEntity<Map<String, dynamic>> entity) {
    _syncQueue.enqueue(entity);
    notifyListeners();
  }

  /// Perform full two-way synchronization cycle.
  Future<bool> syncNow() async {
    if (_activeProvider == null) {
      _state = SyncState.error;
      _lastErrorMessage = 'No active cloud sync provider configured';
      notifyListeners();
      return false;
    }

    _state = SyncState.syncing;
    _lastErrorMessage = '';
    notifyListeners();

    try {
      final connected = await _activeProvider!.isConnected() ||
          await _activeProvider!.authenticate();

      if (!connected) {
        throw Exception(
            'Failed to connect to cloud provider (${_activeProvider!.name})');
      }

      // 1. Gather all local entities across registered targets
      final List<SyncEntity<Map<String, dynamic>>> localBookmarks = [];
      final List<SyncEntity<Map<String, dynamic>>> localNotes = [];
      final List<SyncEntity<Map<String, dynamic>>> localStats = [];
      final List<SyncEntity<Map<String, dynamic>>> localRevisions = [];
      final List<SyncEntity<Map<String, dynamic>>> localSettings = [];

      if (_targets.containsKey(SyncEntityType.bookmark)) {
        localBookmarks.addAll(
            await _targets[SyncEntityType.bookmark]!.exportLocalEntities());
      }
      if (_targets.containsKey(SyncEntityType.note)) {
        localNotes
            .addAll(await _targets[SyncEntityType.note]!.exportLocalEntities());
      }
      if (_targets.containsKey(SyncEntityType.statistics)) {
        localStats.addAll(
            await _targets[SyncEntityType.statistics]!.exportLocalEntities());
      }
      if (_targets.containsKey(SyncEntityType.revisionSchedule)) {
        localRevisions.addAll(await _targets[SyncEntityType.revisionSchedule]!
            .exportLocalEntities());
      }
      if (_targets.containsKey(SyncEntityType.settings)) {
        localSettings.addAll(
            await _targets[SyncEntityType.settings]!.exportLocalEntities());
      }

      // 2. Fetch remote snapshot
      final remoteSnapshot = await _activeProvider!.downloadSnapshot();

      // 3. Resolve & Merge lists for each domain target
      final mergedBookmarks = _mergeDomainLists(
        local: localBookmarks,
        remote: remoteSnapshot?.bookmarks ?? [],
      );
      final mergedNotes = _mergeDomainLists(
        local: localNotes,
        remote: remoteSnapshot?.notes ?? [],
      );
      final mergedStats = _mergeDomainLists(
        local: localStats,
        remote: remoteSnapshot?.statistics ?? [],
      );
      final mergedRevisions = _mergeDomainLists(
        local: localRevisions,
        remote: remoteSnapshot?.revisionSchedules ?? [],
      );
      final mergedSettings = _mergeDomainLists(
        local: localSettings,
        remote: remoteSnapshot?.settings ?? [],
      );

      // 4. Apply merged changes to local targets
      if (_targets.containsKey(SyncEntityType.bookmark)) {
        await _targets[SyncEntityType.bookmark]!
            .applyRemoteEntities(mergedBookmarks);
      }
      if (_targets.containsKey(SyncEntityType.note)) {
        await _targets[SyncEntityType.note]!.applyRemoteEntities(mergedNotes);
      }
      if (_targets.containsKey(SyncEntityType.statistics)) {
        await _targets[SyncEntityType.statistics]!
            .applyRemoteEntities(mergedStats);
      }
      if (_targets.containsKey(SyncEntityType.revisionSchedule)) {
        await _targets[SyncEntityType.revisionSchedule]!
            .applyRemoteEntities(mergedRevisions);
      }
      if (_targets.containsKey(SyncEntityType.settings)) {
        await _targets[SyncEntityType.settings]!
            .applyRemoteEntities(mergedSettings);
      }

      // 5. Build unified merged snapshot & upload to cloud
      final mergedSnapshot = SyncSnapshot(
        snapshotId: 'snap_${DateTime.now().millisecondsSinceEpoch}',
        clientDeviceId: _deviceId,
        createdAt: DateTime.now().toUtc(),
        bookmarks: mergedBookmarks,
        notes: mergedNotes,
        statistics: mergedStats,
        revisionSchedules: mergedRevisions,
        settings: mergedSettings,
      );

      final uploadOk = await _activeProvider!.uploadSnapshot(mergedSnapshot);
      if (!uploadOk) {
        throw Exception('Cloud provider failed to save updated snapshot');
      }

      // 6. Update timestamps & clear queue on success
      _syncQueue.clear();
      _lastSuccessfulSyncTime = DateTime.now().toUtc();

      for (final t in _targets.values) {
        await t.updateLastSyncTime(_lastSuccessfulSyncTime!);
      }

      _state = SyncState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = SyncState.error;
      _lastErrorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  List<SyncEntity<Map<String, dynamic>>> _mergeDomainLists({
    required List<SyncEntity<Map<String, dynamic>>> local,
    required List<SyncEntity<Map<String, dynamic>>> remote,
  }) {
    final Map<String, SyncEntity<Map<String, dynamic>>> map = {};

    for (final loc in local) {
      map[loc.metadata.entityId] = loc;
    }

    for (final rem in remote) {
      final id = rem.metadata.entityId;
      if (!map.containsKey(id)) {
        map[id] = rem;
      } else {
        final loc = map[id]!;
        final result = ConflictResolver.resolve(
          local: loc,
          remote: rem,
          strategy: _conflictStrategy,
        );
        map[id] = result.resolvedEntity;
      }
    }

    return map.values.toList();
  }

  /// Reset engine state (for testing or logging out).
  void resetEngine() {
    _targets.clear();
    _syncQueue.clear();
    _activeProvider = null;
    _state = SyncState.idle;
    _lastErrorMessage = '';
    _lastSuccessfulSyncTime = null;
    notifyListeners();
  }
}
