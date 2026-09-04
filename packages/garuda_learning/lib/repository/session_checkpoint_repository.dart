/// Session Checkpoint Repository Interface (TITAN-KO-040.0 P40).
///
/// Abstract repository contract for durable, deterministic storage of adaptive
/// session checkpoints with tenant isolation and monotonic revision protection.
library;

import '../domain/entities/session_checkpoint.dart';

/// Clean Architecture abstract repository contract for session checkpoint persistence.
abstract interface class SessionCheckpointRepository {
  /// Loads the persisted checkpoint for a specific learner, exam, and session context.
  ///
  /// Returns `null` if no checkpoint has been persisted yet.
  /// Throws [SessionRecoveryException] if the checkpoint is corrupted,
  /// carries an unsupported schema, or encounters an IO failure.
  Future<SessionCheckpoint?> loadCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  });

  /// Atomically persists [checkpoint] with monotonic revision protection.
  ///
  /// Semantics:
  /// - `incoming.checkpointRevision > existing.checkpointRevision`: Accepts and atomically writes incoming state.
  /// - `incoming.checkpointRevision == existing.checkpointRevision`: Idempotent no-op if identical payload;
  ///   otherwise rejects as a revision conflict by throwing [SessionRecoveryException] with [SessionRecoveryErrorCode.staleCheckpoint].
  /// - `incoming.checkpointRevision < existing.checkpointRevision`: Rejects stale write.
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint);

  /// Deletes checkpoint for a specific session context.
  Future<void> deleteCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  });

  /// Checks if a checkpoint exists for the given context.
  Future<bool> exists({
    required String learnerId,
    required String examId,
    required String sessionId,
  });

  /// Lists all checkpoints stored for a specific learner and exam context.
  Future<List<SessionCheckpoint>> listCheckpoints({
    required String learnerId,
    required String examId,
  });

  /// Clears all checkpoints (used for test isolation).
  Future<void> clear();
}
