/// Learner State Conflict Resolver (TITAN-KO-047.0 P47).
///
/// Pure deterministic domain service resolving divergence between concurrent
/// AuthoritativeLearnerState snapshots using CRDT-inspired monotonic rules.
///
/// Invariants:
/// - Attempts never roll back: merged attempts >= max(local, remote).
/// - Correct counts never roll back: merged correct >= max(local, remote).
/// - Mastery never rolls back: achieved status is permanent and terminal.
/// - Processed sessions form a strictly monotonic union.
/// - No progress is lost: union of all objectives from both snapshots.
/// - Revision advances monotonically: max(local.revision, remote.revision) + 1.
/// - Strict multi-tenant isolation: throws on mismatched learnerId or examId.
library;

import 'dart:collection';
import 'dart:math' as math;

import '../../domain/entities/authoritative_learner_state.dart';
import '../../domain/entities/learner_objective_status.dart';
import '../../domain/entities/learner_progress.dart';
import '../../domain/entities/sync_conflict.dart';

/// Result of a deterministic conflict resolution.
class ConflictResolutionResult {
  final SyncConflict conflict;
  final AuthoritativeLearnerState resolvedState;
  final String resolutionNotes;

  const ConflictResolutionResult({
    required this.conflict,
    required this.resolvedState,
    required this.resolutionNotes,
  });
}

/// Pure deterministic conflict resolver for AuthoritativeLearnerState.
class LearnerStateConflictResolver {
  const LearnerStateConflictResolver();

  /// Resolves divergence between [conflict.localState] and [conflict.remoteState]
  /// and returns a clean, merged state with an incremented revision.
  ConflictResolutionResult resolve(SyncConflict conflict) {
    final local = conflict.localState;
    final remote = conflict.remoteState;

    // Invariant: Strict tenant isolation
    if (local.learnerId != remote.learnerId) {
      throw ArgumentError(
        'Cross-learner conflict resolution prohibited: ${local.learnerId} vs ${remote.learnerId}',
      );
    }
    if (local.examId != remote.examId) {
      throw ArgumentError(
        'Cross-exam conflict resolution prohibited: ${local.examId} vs ${remote.examId}',
      );
    }

    final String learnerId = local.learnerId;
    final String examId = local.examId;

    // Invariant: Monotonic revision advancement
    final int resolvedRevision = math.max(local.revision, remote.revision) + 1;

    // Invariant: Monotonic union of processed sessions
    final Set<String> mergedSessions = SplayTreeSet<String>.from({
      ...local.processedSessionIds,
      ...remote.processedSessionIds,
    });

    // Invariant: Objective union across both states
    final allObjectiveIds = SplayTreeSet<String>.from({
      ...local.progressMap.keys,
      ...remote.progressMap.keys,
    });

    final Map<String, LearnerProgress> mergedProgressMap = {};

    for (final objId in allObjectiveIds) {
      final localProg = local.progressMap[objId];
      final remoteProg = remote.progressMap[objId];

      if (localProg == null && remoteProg != null) {
        // Only on remote
        mergedProgressMap[objId] = remoteProg;
      } else if (localProg != null && remoteProg == null) {
        // Only on local
        mergedProgressMap[objId] = localProg;
      } else if (localProg != null && remoteProg != null) {
        // Present on both: merge monotonically
        final int mergedAttempts =
            math.max(localProg.attemptCount, remoteProg.attemptCount);
        final int mergedCorrect =
            math.max(localProg.correctCount, remoteProg.correctCount);

        // Ensure correct count does not exceed attempt count
        final int sanitizedCorrect = math.min(mergedCorrect, mergedAttempts);

        // Invariant: Mastery cannot roll back
        final LearnerObjectiveStatus mergedStatus = _resolveMasteryStatus(
          localProg.status,
          remoteProg.status,
        );

        // Latest attempt timestamp
        DateTime? mergedLastAttempt;
        if (localProg.lastAttemptAt == null) {
          mergedLastAttempt = remoteProg.lastAttemptAt;
        } else if (remoteProg.lastAttemptAt == null) {
          mergedLastAttempt = localProg.lastAttemptAt;
        } else {
          mergedLastAttempt =
              localProg.lastAttemptAt!.isAfter(remoteProg.lastAttemptAt!)
                  ? localProg.lastAttemptAt
                  : remoteProg.lastAttemptAt;
        }

        mergedProgressMap[objId] = LearnerProgress(
          learnerId: learnerId,
          objectiveId: objId,
          attemptCount: mergedAttempts,
          correctCount: sanitizedCorrect,
          status: mergedStatus,
          lastAttemptAt: mergedLastAttempt,
        );
      }
    }

    // Determine latest updated timestamp
    final DateTime resolvedUpdatedAt =
        local.lastUpdatedAt.isAfter(remote.lastUpdatedAt)
            ? local.lastUpdatedAt
            : remote.lastUpdatedAt;

    final resolvedState = AuthoritativeLearnerState(
      learnerId: learnerId,
      examId: examId,
      revision: resolvedRevision,
      progressMap: mergedProgressMap,
      processedSessionIds: mergedSessions,
      lastUpdatedAt: resolvedUpdatedAt,
    );

    final notes = 'Merged ${allObjectiveIds.length} objectives, '
        '${mergedSessions.length} sessions. Advanced to rev $resolvedRevision.';

    final updatedConflict = conflict.copyWith(
      resolvedState: resolvedState,
      resolutionStrategy: notes,
    );

    return ConflictResolutionResult(
      conflict: updatedConflict,
      resolvedState: resolvedState,
      resolutionNotes: notes,
    );
  }

  LearnerObjectiveStatus _resolveMasteryStatus(
    LearnerObjectiveStatus a,
    LearnerObjectiveStatus b,
  ) {
    // Priority: achieved > inProgress > notStarted
    if (a == LearnerObjectiveStatus.achieved ||
        b == LearnerObjectiveStatus.achieved) {
      return LearnerObjectiveStatus.achieved;
    }
    if (a == LearnerObjectiveStatus.inProgress ||
        b == LearnerObjectiveStatus.inProgress) {
      return LearnerObjectiveStatus.inProgress;
    }
    return LearnerObjectiveStatus.notStarted;
  }
}
