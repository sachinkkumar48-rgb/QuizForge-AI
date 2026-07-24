import 'dart:async';

import 'package:titan_identity/titan_identity.dart';

import '../cloud/cloud_provider.dart';
import '../conflict/conflict_resolver.dart';
import '../models/sync_batch.dart';
import '../models/sync_conflict.dart';
import '../models/sync_item.dart';
import '../models/sync_result.dart';
import '../repository/sync_repository.dart';

/// Status state of the SyncManager engine.
enum SyncEngineStatus {
  idle,
  syncing,
  success,
  failed,
  conflict,
}

/// Core synchronization engine coordinating offline queueing, cloud push/pull,
/// incremental sync, and conflict resolution.
class SyncManager {
  final SyncRepository _repository;
  final CloudProvider _cloudProvider;
  final ConflictResolver _conflictResolver;
  final SessionManager? _sessionManager;

  DateTime? _lastSyncTime;
  SyncEngineStatus _status = SyncEngineStatus.idle;

  final StreamController<SyncResult> _resultController =
      StreamController<SyncResult>.broadcast();
  final StreamController<SyncEngineStatus> _statusController =
      StreamController<SyncEngineStatus>.broadcast();

  SyncManager({
    required SyncRepository repository,
    required CloudProvider cloudProvider,
    ConflictResolver? conflictResolver,
    SessionManager? sessionManager,
  })  : _repository = repository,
        _cloudProvider = cloudProvider,
        _conflictResolver = conflictResolver ?? const ConflictResolver(),
        _sessionManager = sessionManager;

  /// Current status of the sync engine.
  SyncEngineStatus get status => _status;

  /// Last successful sync timestamp.
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Stream emitting results of completed sync operations.
  Stream<SyncResult> get syncResultStream => _resultController.stream;

  /// Stream emitting real-time sync engine status changes.
  Stream<SyncEngineStatus> get statusStream => _statusController.stream;

  void _setStatus(SyncEngineStatus newStatus) {
    _status = newStatus;
    _statusController.add(_status);
  }

  /// Queues an item for eventual synchronization.
  Future<void> queueItem(SyncItem item) async {
    await _repository.queueItem(item);
  }

  /// Triggers an immediate full push/pull sync.
  Future<SyncResult> syncNow() async {
    if (_status == SyncEngineStatus.syncing) {
      return SyncResult.empty();
    }

    _setStatus(SyncEngineStatus.syncing);

    // Check secure token & user session if SessionManager is present
    final session = _sessionManager?.currentSession;
    if (_sessionManager != null && !_sessionManager.isAuthenticated) {
      final failedResult = SyncResult(
        isSuccess: false,
        itemsProcessed: 0,
        itemsFailed: 0,
        completedAt: DateTime.now(),
        errorMessage: 'User is not authenticated.',
      );
      _setStatus(SyncEngineStatus.failed);
      _resultController.add(failedResult);
      return failedResult;
    }

    final userId = session?.user.id ?? 'guest_local';
    int itemsProcessed = 0;
    int itemsFailed = 0;
    int conflictsDetected = 0;

    try {
      final pendingItems = await _repository.getPendingItems();

      if (pendingItems.isNotEmpty) {
        final batch = SyncBatch(
          batchId: 'batch_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          items: pendingItems,
          createdAt: DateTime.now(),
        );

        try {
          final confirmed = await _cloudProvider.pushBatch(batch);
          for (final item in confirmed) {
            await _repository.updateItem(item);
            itemsProcessed++;
          }
        } catch (e) {
          for (final item in pendingItems) {
            final failedItem = item.copyWith(
              status: SyncItemStatus.failed,
              retryCount: item.retryCount + 1,
              lastError: e.toString(),
            );
            await _repository.updateItem(failedItem);
            itemsFailed++;
          }
        }
      }

      // Pull remote changes
      try {
        final remoteItems = await _cloudProvider.pullChanges(
          userId: userId,
          since: _lastSyncTime,
        );

        final localItems = await _repository.getAllItems();
        final localMap = {for (var i in localItems) i.entityId: i};

        for (final remote in remoteItems) {
          final localMatch = localMap[remote.entityId];
          if (localMatch != null &&
              localMatch.status == SyncItemStatus.pending &&
              localMatch.timestamp != remote.timestamp) {
            // Data collision detected
            conflictsDetected++;
            final conflict = SyncConflict(
              conflictId:
                  'conflict_${remote.entityId}_${DateTime.now().millisecondsSinceEpoch}',
              localItem: localMatch,
              remoteItem: remote,
              detectedAt: DateTime.now(),
            );

            final resolvedConflict = _conflictResolver.resolve(conflict);
            if (resolvedConflict.isResolved &&
                resolvedConflict.resolvedItem != null) {
              await _repository.queueItem(resolvedConflict.resolvedItem!);
            } else {
              await _repository.saveConflict(resolvedConflict);
              await _repository.updateItem(
                localMatch.copyWith(status: SyncItemStatus.conflict),
              );
            }
          } else if (localMatch == null) {
            await _repository.queueItem(remote.copyWith(
              status: SyncItemStatus.synced,
            ));
            itemsProcessed++;
          } else if (localMatch.status == SyncItemStatus.synced) {
            if (remote.version > localMatch.version ||
                remote.timestamp.isAfter(localMatch.timestamp)) {
              await _repository.queueItem(remote.copyWith(
                status: SyncItemStatus.synced,
              ));
              itemsProcessed++;
            }
          } else if (localMatch.status == SyncItemStatus.pending) {
            await _repository.updateItem(
              localMatch.copyWith(status: SyncItemStatus.synced),
            );
          }
        }
      } catch (_) {
        // Network pull issue ignored if offline
      }

      _lastSyncTime = DateTime.now();
      final success = itemsFailed == 0;
      final result = SyncResult(
        isSuccess: success,
        itemsProcessed: itemsProcessed,
        itemsFailed: itemsFailed,
        conflictsDetected: conflictsDetected,
        completedAt: _lastSyncTime!,
      );

      _setStatus(success
          ? (conflictsDetected > 0
              ? SyncEngineStatus.conflict
              : SyncEngineStatus.success)
          : SyncEngineStatus.failed);

      _resultController.add(result);
      return result;
    } catch (e) {
      final errorResult = SyncResult(
        isSuccess: false,
        itemsProcessed: itemsProcessed,
        itemsFailed: itemsFailed,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
      );
      _setStatus(SyncEngineStatus.failed);
      _resultController.add(errorResult);
      return errorResult;
    }
  }

  /// Resolves a recorded conflict by conflictId.
  Future<void> resolveConflict(
    String conflictId, {
    ConflictStrategy strategy = ConflictStrategy.lastWriteWins,
    SyncItem? customItem,
  }) async {
    final conflicts = await _repository.getConflicts();
    final conflict = conflicts.firstWhere(
      (c) => c.conflictId == conflictId,
      orElse: () => throw StateError('Conflict $conflictId not found.'),
    );

    if (customItem != null) {
      await _repository.resolveConflict(conflictId, customItem);
    } else {
      final resolved = _conflictResolver.resolve(conflict, strategy: strategy);
      if (resolved.resolvedItem != null) {
        await _repository.resolveConflict(conflictId, resolved.resolvedItem!);
      }
    }
  }

  /// Retries failed sync items.
  Future<SyncResult> retryFailedSync() async {
    final allItems = await _repository.getAllItems();
    final failedItems =
        allItems.where((i) => i.status == SyncItemStatus.failed).toList();

    for (final item in failedItems) {
      await _repository.updateItem(
        item.copyWith(status: SyncItemStatus.pending),
      );
    }

    return syncNow();
  }

  /// Cleans up controllers on disposal.
  Future<void> dispose() async {
    await _resultController.close();
    await _statusController.close();
  }
}
