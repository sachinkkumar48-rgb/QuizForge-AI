import 'dart:async';
import 'package:titan_identity/titan_identity.dart';

import '../cloud/cloud_provider.dart';
import '../conflict/conflict_resolver.dart';
import '../conflict/field_level_merger.dart';
import '../models/sync_batch.dart';
import '../models/sync_conflict.dart';
import '../models/sync_item.dart';
import '../models/sync_operation.dart';
import '../models/sync_queue.dart';
import '../models/sync_result.dart';
import '../models/sync_snapshot.dart';
import '../models/sync_state.dart';
import '../repository/sync_repository.dart';
import 'sync_telemetry_collector.dart';

/// Pure Dart Production Sync Orchestrator Engine for Project TITAN.
///
/// Orchestrates multi-device synchronization across 12 domain subsystems,
/// offline queueing, Last-Write-Wins (LWW) & field-level conflict resolution,
/// telemetry metrics collection, and background worker state management.
class SyncOrchestrator {
  final SyncRepository repository;
  final CloudProvider cloudProvider;
  final ConflictResolver conflictResolver;
  final FieldLevelMerger fieldLevelMerger;
  final SyncQueue queue;
  final SyncTelemetryCollector telemetryCollector;
  final SessionManager? sessionManager;

  SyncState _state = const SyncState.idle();
  DateTime? _lastSyncTime;
  bool _isOnline = true;
  bool _isClosed = false;

  final StreamController<SyncResult> _resultController =
      StreamController<SyncResult>.broadcast();
  final StreamController<SyncState> _stateController =
      StreamController<SyncState>.broadcast();

  SyncOrchestrator({
    required this.repository,
    required this.cloudProvider,
    ConflictResolver? conflictResolver,
    FieldLevelMerger? fieldLevelMerger,
    SyncQueue? queue,
    SyncTelemetryCollector? telemetryCollector,
    this.sessionManager,
  })  : conflictResolver = conflictResolver ?? const ConflictResolver(),
        fieldLevelMerger = fieldLevelMerger ?? const FieldLevelMerger(),
        queue = queue ?? SyncQueue(),
        telemetryCollector = telemetryCollector ?? SyncTelemetryCollector();

  /// Current sync state.
  SyncState get state => _state;

  /// Network online status.
  bool get isOnline => _isOnline;

  /// Stream emitting real-time state changes.
  Stream<SyncState> get stateStream => _stateController.stream;

  /// Stream emitting sync results.
  Stream<SyncResult> get resultStream => _resultController.stream;

  /// Last sync timestamp.
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Sets online status and triggers automatic queue recovery if reconnecting.
  void setOnlineStatus(bool online) {
    _isOnline = online;
    if (online && queue.isNotEmpty && !_state.isSyncing) {
      synchronize();
    }
  }

  void _updateState(SyncState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  /// Queues a local mutation entity for synchronization.
  Future<void> queueMutation({
    required SyncEntityType entityType,
    required String entityId,
    required SyncAction action,
    required Map<String, dynamic> payload,
    int version = 1,
    String deviceId = 'local_device',
  }) async {
    if (_isClosed) return;

    final item = SyncItem(
      id: 'sync_${entityType.name}_${entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload,
      version: version,
      status: SyncItemStatus.pending,
      timestamp: DateTime.now(),
    );

    final op = SyncOperation(
      operationId: 'op_${DateTime.now().microsecondsSinceEpoch}',
      entityType: entityType,
      entityId: entityId,
      action: action,
      payload: payload,
      timestamp: item.timestamp,
      version: version,
      deviceId: deviceId,
    );

    queue.enqueue(op, item);
    await repository.queueItem(item);

    _updateState(_state.copyWith(
      pendingOperationsCount: queue.length,
    ));
  }

  /// Triggers full push/pull multi-device synchronization.
  Future<SyncResult> synchronize({bool force = false}) async {
    if (_isClosed) {
      return SyncResult.empty();
    }

    if (_state.isSyncing && !force) {
      return SyncResult.empty();
    }

    final stopwatch = Stopwatch()..start();
    final syncId = 'sync_run_${DateTime.now().millisecondsSinceEpoch}';
    _updateState(_state.copyWith(phase: SyncPhase.syncing, progress: 0.1));

    // Check Authentication
    final session = sessionManager?.currentSession;
    if (sessionManager != null && !sessionManager!.isAuthenticated) {
      final failResult = SyncResult(
        isSuccess: false,
        itemsProcessed: 0,
        itemsFailed: 0,
        completedAt: DateTime.now(),
        errorMessage: 'User authentication required for cloud sync.',
      );

      _updateState(_state.copyWith(
        phase: SyncPhase.failed,
        lastError: failResult.errorMessage,
      ));

      telemetryCollector.record(SyncTelemetryRecord(
        syncId: syncId,
        duration: stopwatch.elapsed,
        itemsProcessed: 0,
        itemsFailed: 0,
        conflictsCount: 0,
        pendingOpsCount: queue.length,
        retryCount: 0,
        isSuccess: false,
        errorMessage: failResult.errorMessage,
        timestamp: DateTime.now(),
      ));

      return failResult;
    }

    final userId = session?.user.id ?? 'guest_local';
    int processed = 0;
    int failed = 0;
    int conflicts = 0;

    // Offline check
    if (!_isOnline) {
      _updateState(_state.copyWith(
        phase: SyncPhase.idle,
        pendingOperationsCount: queue.length,
      ));
      return SyncResult(
        isSuccess: true,
        itemsProcessed: 0,
        itemsFailed: 0,
        completedAt: DateTime.now(),
        errorMessage: 'Sync deferred: device is offline.',
      );
    }

    try {
      // Step 1: Push pending local batch
      final pendingItems = await repository.getPendingItems();
      if (pendingItems.isNotEmpty) {
        _updateState(_state.copyWith(progress: 0.3));

        final batch = SyncBatch(
          batchId: 'batch_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          items: pendingItems,
          createdAt: DateTime.now(),
        );

        try {
          final confirmed = await cloudProvider.pushBatch(batch);
          for (final item in confirmed) {
            await repository.updateItem(item);
            queue.removePendingItem(item.entityId);
            processed++;
          }
        } catch (e) {
          for (final item in pendingItems) {
            final failedItem = item.copyWith(
              status: SyncItemStatus.failed,
              retryCount: item.retryCount + 1,
              lastError: e.toString(),
            );
            await repository.updateItem(failedItem);
            failed++;
          }
        }
      }

      // Step 2: Pull remote changes
      _updateState(_state.copyWith(progress: 0.6));
      try {
        final remoteItems = await cloudProvider.pullChanges(
          userId: userId,
          since: _lastSyncTime,
        );

        final localItems = await repository.getAllItems();
        final localMap = {for (var i in localItems) i.entityId: i};

        for (final remote in remoteItems) {
          final localMatch = localMap[remote.entityId];

          if (localMatch != null &&
              localMatch.status == SyncItemStatus.pending &&
              localMatch.timestamp != remote.timestamp) {
            // Collision detected -> Field level merge
            conflicts++;
            _updateState(_state.copyWith(
              phase: SyncPhase.resolvingConflicts,
              activeConflictsCount: conflicts,
            ));

            final conflictObj = SyncConflict(
              conflictId: 'conflict_${remote.entityId}',
              localItem: localMatch,
              remoteItem: remote,
              detectedAt: DateTime.now(),
            );

            final resolvedConflict =
                fieldLevelMerger.resolveFieldLevel(conflictObj);
            if (resolvedConflict.isResolved &&
                resolvedConflict.resolvedItem != null) {
              await repository.updateItem(resolvedConflict.resolvedItem!);
              processed++;
            } else {
              await repository.saveConflict(resolvedConflict);
            }
          } else if (localMatch == null ||
              remote.timestamp.isAfter(localMatch.timestamp)) {
            await repository.queueItem(remote.copyWith(
              status: SyncItemStatus.synced,
            ));
            processed++;
          }
        }
      } catch (_) {}

      stopwatch.stop();
      _lastSyncTime = DateTime.now();
      final isSuccess = failed == 0;

      final result = SyncResult(
        isSuccess: isSuccess,
        itemsProcessed: processed,
        itemsFailed: failed,
        conflictsDetected: conflicts,
        completedAt: _lastSyncTime!,
      );

      _updateState(SyncState(
        phase: isSuccess ? SyncPhase.success : SyncPhase.failed,
        progress: 1.0,
        pendingOperationsCount: queue.length,
        activeConflictsCount: conflicts,
        lastSyncTime: _lastSyncTime,
        lastError: isSuccess ? null : 'Some operations failed',
      ));

      telemetryCollector.record(SyncTelemetryRecord(
        syncId: syncId,
        duration: stopwatch.elapsed,
        itemsProcessed: processed,
        itemsFailed: failed,
        conflictsCount: conflicts,
        pendingOpsCount: queue.length,
        retryCount: 0,
        isSuccess: isSuccess,
        timestamp: DateTime.now(),
      ));

      if (!_resultController.isClosed) {
        _resultController.add(result);
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      final errResult = SyncResult(
        isSuccess: false,
        itemsProcessed: processed,
        itemsFailed: failed,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
      );

      _updateState(_state.copyWith(
        phase: SyncPhase.failed,
        lastError: e.toString(),
      ));

      telemetryCollector.record(SyncTelemetryRecord(
        syncId: syncId,
        duration: stopwatch.elapsed,
        itemsProcessed: processed,
        itemsFailed: failed,
        conflictsCount: conflicts,
        pendingOpsCount: queue.length,
        retryCount: 1,
        isSuccess: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      ));

      if (!_resultController.isClosed) {
        _resultController.add(errResult);
      }

      return errResult;
    }
  }

  /// Creates a state snapshot across all domain entity types.
  Future<SyncSnapshot> createSnapshot({required String deviceId}) async {
    final allItems = await repository.getAllItems();
    final grouped = <SyncEntityType, Map<String, dynamic>>{};

    for (final item in allItems) {
      grouped.putIfAbsent(item.entityType, () => {})[item.entityId] =
          item.payload;
    }

    final userId = sessionManager?.currentSession?.user.id ?? 'local';
    final now = DateTime.now();

    return SyncSnapshot(
      snapshotId: 'snap_${now.millisecondsSinceEpoch}',
      userId: userId,
      deviceId: deviceId,
      createdAt: now,
      entitySnapshots: grouped,
      checksum: 'chk_${allItems.length}_${now.microsecondsSinceEpoch}',
    );
  }

  /// Closes internal controllers and releases resources.
  Future<void> close() async {
    _isClosed = true;
    await _resultController.close();
    await _stateController.close();
  }
}
