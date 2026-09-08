/// Remote Learning State Repository Contract (TITAN-KO-047.0 P47).
///
/// Provider-neutral abstraction for remote cloud synchronization of AuthoritativeLearnerState,
/// session checkpoints, and learning history, enforcing optimistic concurrency rules.
library;

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/session_checkpoint.dart';
import '../domain/entities/sync_conflict.dart';
import '../domain/entities/sync_envelope.dart';
import 'learning_activity_completion_repository.dart';

/// Result of a remote push operation on authoritative learner state.
class RemoteSyncResult {
  final bool success;
  final int? remoteRevision;
  final DateTime? syncedAt;
  final SyncConflict? conflict;
  final String? errorMessage;

  const RemoteSyncResult._({
    required this.success,
    this.remoteRevision,
    this.syncedAt,
    this.conflict,
    this.errorMessage,
  });

  factory RemoteSyncResult.success({
    required int remoteRevision,
    required DateTime syncedAt,
  }) =>
      RemoteSyncResult._(
        success: true,
        remoteRevision: remoteRevision,
        syncedAt: syncedAt,
      );

  factory RemoteSyncResult.conflict(SyncConflict conflict) =>
      RemoteSyncResult._(
        success: false,
        conflict: conflict,
        errorMessage: 'Conflict: ${conflict.reason.name}',
      );

  factory RemoteSyncResult.failure(String errorMessage) => RemoteSyncResult._(
        success: false,
        errorMessage: errorMessage,
      );

  bool get isConflict => conflict != null;
}

/// Result of a remote fetch operation on authoritative learner state.
class RemoteFetchResult {
  final AuthoritativeLearnerState? state;
  final int revision;
  final bool exists;
  final bool success;
  final String? errorMessage;

  const RemoteFetchResult._({
    required this.success,
    this.state,
    this.revision = 0,
    this.exists = false,
    this.errorMessage,
  });

  factory RemoteFetchResult.found(AuthoritativeLearnerState state) =>
      RemoteFetchResult._(
        success: true,
        state: state,
        revision: state.revision,
        exists: true,
      );

  factory RemoteFetchResult.empty() => const RemoteFetchResult._(
        success: true,
        exists: false,
        revision: 0,
      );

  factory RemoteFetchResult.failure(String errorMessage) => RemoteFetchResult._(
        success: false,
        errorMessage: errorMessage,
      );
}

/// Result of a remote checkpoint push.
class RemoteCheckpointResult {
  final bool success;
  final int? remoteRevision;
  final String? errorMessage;

  const RemoteCheckpointResult({
    required this.success,
    this.remoteRevision,
    this.errorMessage,
  });
}

/// Provider-neutral interface for remote learning state synchronization.
abstract class RemoteLearningStateRepository {
  /// Checks whether remote backend is currently reachable.
  Future<bool> isReachable();

  /// Pushes an authoritative learner state envelope to remote.
  /// Enforces optimistic concurrency (returns conflict if stale).
  Future<RemoteSyncResult> pushState(SyncEnvelope envelope);

  /// Fetches current authoritative state for a learner and exam from remote.
  Future<RemoteFetchResult> fetchState({
    required String learnerId,
    required String examId,
  });

  /// Pushes a session checkpoint to remote.
  Future<RemoteCheckpointResult> pushCheckpoint(
    SessionCheckpoint checkpoint, {
    required String deviceId,
  });

  /// Fetches a session checkpoint from remote.
  Future<SessionCheckpoint?> fetchCheckpoint({
    required String sessionId,
    required String learnerId,
    required String examId,
  });

  /// Pushes a batch of activity completion records to remote idempotently.
  Future<void> pushActivities(
    List<LearningActivityCompletionRecord> activities,
  );

  /// Fetches all activity completion records for a learner and exam from remote.
  Future<List<LearningActivityCompletionRecord>> fetchActivities({
    required String learnerId,
    required String examId,
  });
}
