/// Learner State Sync Service (TITAN-KO-047.0 P47).
///
/// High-level orchestration engine coordinating offline-first local outbox queuing,
/// bi-directional cloud synchronization, optimistic concurrency checks, and deterministic conflict resolution.
library;

import 'dart:async';

import '../../domain/entities/authoritative_learner_state.dart';
import '../../domain/entities/persisted_authoritative_learner_state.dart';
import '../../domain/entities/sync_envelope.dart';
import '../../domain/entities/sync_status.dart';
import '../../repository/authoritative_learning_state_repository.dart';
import '../../repository/learning_activity_completion_repository.dart';
import '../../repository/remote_learning_state_repository.dart';
import '../../repository/session_checkpoint_repository.dart';
import '../../repository/sync_outbox_repository.dart';
import 'learner_state_conflict_resolver.dart';

/// Result summary of an execution of [LearnerStateSyncService.sync].
class SyncOperationResult {
  final SyncStatus status;
  final int localRevision;
  final int remoteRevision;
  final int itemsSynced;
  final int conflictsResolved;
  final bool isOffline;
  final String message;

  const SyncOperationResult({
    required this.status,
    required this.localRevision,
    required this.remoteRevision,
    this.itemsSynced = 0,
    this.conflictsResolved = 0,
    this.isOffline = false,
    required this.message,
  });
}

/// Snapshot summary of the sync state for a learner and exam.
class SyncStatusSummary {
  final String learnerId;
  final String examId;
  final SyncStatus status;
  final int pendingCount;
  final int currentRevision;
  final DateTime lastSyncTime;
  final String? lastError;

  const SyncStatusSummary({
    required this.learnerId,
    required this.examId,
    required this.status,
    required this.pendingCount,
    required this.currentRevision,
    required this.lastSyncTime,
    this.lastError,
  });
}

/// Orchestrator for offline-first cloud synchronization.
class LearnerStateSyncService {
  final AuthoritativeLearningStateRepository _localStateRepo;
  final SyncOutboxRepository _outboxRepo;
  final RemoteLearningStateRepository _remoteRepo;
  final LearnerStateConflictResolver _conflictResolver;
  final SessionCheckpointRepository? _checkpointRepo;
  final LearningActivityCompletionRepository? _completionRepo;

  final StreamController<SyncStatusSummary> _statusController =
      StreamController<SyncStatusSummary>.broadcast();

  LearnerStateSyncService({
    required AuthoritativeLearningStateRepository localStateRepo,
    required SyncOutboxRepository outboxRepo,
    required RemoteLearningStateRepository remoteRepo,
    LearnerStateConflictResolver? conflictResolver,
    SessionCheckpointRepository? checkpointRepo,
    LearningActivityCompletionRepository? completionRepo,
  })  : _localStateRepo = localStateRepo,
        _outboxRepo = outboxRepo,
        _remoteRepo = remoteRepo,
        _conflictResolver =
            conflictResolver ?? const LearnerStateConflictResolver(),
        _checkpointRepo = checkpointRepo,
        _completionRepo = completionRepo;

  Stream<SyncStatusSummary> get syncEvents => _statusController.stream;

  void dispose() {
    _statusController.close();
  }

  /// Queues a local authoritative state change into the durable outbox.
  ///
  /// Offline-First: never fails due to network unavailability.
  Future<SyncEnvelope> queueLocalStateChange(
    AuthoritativeLearnerState state, {
    required String deviceId,
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now().toUtc();
    final persisted =
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(state);
    final payload = persisted.toJson();

    final envelope = SyncEnvelope(
      syncId:
          'sync_${state.learnerId}_${state.examId}_rev${state.revision}_${now.millisecondsSinceEpoch}',
      learnerId: state.learnerId,
      examId: state.examId,
      revision: state.revision,
      deviceId: deviceId,
      createdAt: now,
      updatedAt: now,
      status: SyncStatus.pendingSync,
      payload: payload,
    );

    await _outboxRepo.enqueue(envelope);
    await _emitStatus(state.learnerId, state.examId);
    return envelope;
  }

  /// Executes bi-directional synchronization between local and remote.
  Future<SyncOperationResult> sync({
    required String learnerId,
    required String examId,
    required String deviceId,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();

    // 1. Connectivity check
    final bool isOnline = await _remoteRepo.isReachable();
    if (!isOnline) {
      final summary =
          await getSyncStatus(learnerId: cleanLearner, examId: cleanExam);
      return SyncOperationResult(
        status: summary.pendingCount > 0
            ? SyncStatus.pendingSync
            : SyncStatus.localOnly,
        localRevision: summary.currentRevision,
        remoteRevision: summary.currentRevision,
        isOffline: true,
        message:
            'Remote unreachable (offline). Progress safely queued in local outbox.',
      );
    }

    int itemsSynced = 0;
    int conflictsResolved = 0;

    // 2. Process pending local outbox envelopes (FIFO)
    final pendingList = await _outboxRepo.peekPending(
      learnerId: cleanLearner,
      examId: cleanExam,
    );

    for (final envelope in pendingList) {
      await _outboxRepo.markSyncing(envelope.syncId);
      final result = await _remoteRepo.pushState(envelope);

      if (result.success) {
        await _outboxRepo.markSynced(
          envelope.syncId,
          remoteRevision: result.remoteRevision!,
          syncedAt: result.syncedAt!,
        );
        itemsSynced++;
      } else if (result.isConflict) {
        // Resolve conflict deterministically
        final conflict = result.conflict!;
        final resolution = _conflictResolver.resolve(conflict);

        // Apply resolved state to local authoritative repository
        await _localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
              resolution.resolvedState),
        );

        await _outboxRepo.markConflict(envelope.syncId, conflict);

        // Queue resolved state as new candidate and push to remote
        final resolvedEnvelope = await queueLocalStateChange(
          resolution.resolvedState,
          deviceId: deviceId,
        );

        final pushResolvedResult =
            await _remoteRepo.pushState(resolvedEnvelope);
        if (pushResolvedResult.success) {
          await _outboxRepo.markSynced(
            resolvedEnvelope.syncId,
            remoteRevision: pushResolvedResult.remoteRevision!,
            syncedAt: pushResolvedResult.syncedAt!,
          );
          itemsSynced++;
        }
        conflictsResolved++;
      } else {
        await _outboxRepo.markFailed(
            envelope.syncId, result.errorMessage ?? 'Sync push failed');
      }
    }

    // 3. Pull latest remote state if local is behind
    final remoteFetch = await _remoteRepo.fetchState(
      learnerId: cleanLearner,
      examId: cleanExam,
    );

    int latestRemoteRev = 0;
    if (remoteFetch.success &&
        remoteFetch.exists &&
        remoteFetch.state != null) {
      latestRemoteRev = remoteFetch.state!.revision;
      final localPersisted = await _localStateRepo.load(
        learnerId: cleanLearner,
        examId: cleanExam,
      );

      if (localPersisted == null ||
          remoteFetch.state!.revision > localPersisted.revision) {
        await _localStateRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(
              remoteFetch.state!),
        );
      }
    }

    // 4. Synchronize session checkpoints if repository present
    final cpRepo = _checkpointRepo;
    if (cpRepo != null) {
      final checkpoints = await cpRepo.listCheckpoints(
        learnerId: cleanLearner,
        examId: cleanExam,
      );
      if (checkpoints.isNotEmpty) {
        // Push most recent checkpoint
        await _remoteRepo.pushCheckpoint(checkpoints.last, deviceId: deviceId);
      }
    }

    // 5. Synchronize completed learning activity records if present
    final compRepo = _completionRepo;
    if (compRepo != null) {
      final localActivities = await compRepo.getCompletedActivities(
        learnerId: cleanLearner,
        examId: cleanExam,
      );
      if (localActivities.isNotEmpty) {
        await _remoteRepo.pushActivities(localActivities);
      }
    }

    final finalPersisted = await _localStateRepo.load(
      learnerId: cleanLearner,
      examId: cleanExam,
    );
    final currentLocalRev = finalPersisted?.revision ?? 1;

    final summary = await _emitStatus(cleanLearner, cleanExam);

    return SyncOperationResult(
      status: summary.status,
      localRevision: currentLocalRev,
      remoteRevision:
          latestRemoteRev > currentLocalRev ? latestRemoteRev : currentLocalRev,
      itemsSynced: itemsSynced,
      conflictsResolved: conflictsResolved,
      message: conflictsResolved > 0
          ? 'Sync completed with $conflictsResolved conflicts resolved deterministically.'
          : 'Sync completed successfully.',
    );
  }

  /// Calculates the current sync status summary for a learner and exam.
  Future<SyncStatusSummary> getSyncStatus({
    required String learnerId,
    required String examId,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();

    final allEnvelopes = await _outboxRepo.getAll(
      learnerId: cleanLearner,
      examId: cleanExam,
    );
    final localPersisted = await _localStateRepo.load(
      learnerId: cleanLearner,
      examId: cleanExam,
    );
    final currentRevision = localPersisted?.revision ?? 1;

    int pendingCount = 0;
    bool hasSyncing = false;
    bool hasConflict = false;
    bool hasFailed = false;
    String? lastError;
    DateTime lastSync = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

    for (final env in allEnvelopes) {
      if (env.status == SyncStatus.pendingSync) pendingCount++;
      if (env.status == SyncStatus.syncing) hasSyncing = true;
      if (env.status == SyncStatus.conflict) hasConflict = true;
      if (env.status == SyncStatus.failed) {
        hasFailed = true;
        lastError = env.errorMessage;
      }
      if (env.status == SyncStatus.synced && env.updatedAt.isAfter(lastSync)) {
        lastSync = env.updatedAt;
      }
    }

    SyncStatus status;
    if (hasConflict) {
      status = SyncStatus.conflict;
    } else if (hasFailed) {
      status = SyncStatus.failed;
    } else if (hasSyncing) {
      status = SyncStatus.syncing;
    } else if (pendingCount > 0) {
      status = SyncStatus.pendingSync;
    } else if (lastSync.millisecondsSinceEpoch > 0) {
      status = SyncStatus.synced;
    } else {
      status = SyncStatus.localOnly;
    }

    return SyncStatusSummary(
      learnerId: cleanLearner,
      examId: cleanExam,
      status: status,
      pendingCount: pendingCount,
      currentRevision: currentRevision,
      lastSyncTime: lastSync,
      lastError: lastError,
    );
  }

  Future<SyncStatusSummary> _emitStatus(String learnerId, String examId) async {
    final summary = await getSyncStatus(learnerId: learnerId, examId: examId);
    if (!_statusController.isClosed) {
      _statusController.add(summary);
    }
    return summary;
  }
}
