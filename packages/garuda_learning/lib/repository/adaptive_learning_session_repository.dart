/// Adaptive Learning Session Repository Contract (TITAN-KO-040.0 P40).
///
/// Abstract repository contract for durable persistence of adaptive learning
/// sessions and their associated checkpoints with strict multi-tenant isolation.
library;

import '../domain/entities/adaptive_learning_session.dart';
import '../domain/entities/session_checkpoint.dart';

/// Clean Architecture repository contract for session state and checkpoint persistence.
abstract interface class AdaptiveLearningSessionRepository {
  /// Atomically creates and persists an initial [session].
  ///
  /// Throws an exception if a session with identical coordinates already exists.
  Future<void> createSession(AdaptiveLearningSession session);

  /// Loads a session for the specific tenant context.
  ///
  /// Returns `null` if no matching session exists.
  Future<AdaptiveLearningSession?> getSession({
    required String learnerId,
    required String examId,
    required String sessionId,
  });

  /// Updates existing session state enforcing tenant ownership.
  Future<void> updateSession(AdaptiveLearningSession session);

  /// Persists a session checkpoint with monotonic revision enforcement.
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint);

  /// Retrieves the latest persisted checkpoint for the given session context.
  ///
  /// Returns `null` if no checkpoint exists for this session.
  Future<SessionCheckpoint?> getLatestCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  });

  /// Atomically transitions session to completed status.
  Future<void> markCompleted({
    required String learnerId,
    required String examId,
    required String sessionId,
    required DateTime completedAt,
    Map<String, dynamic>? completionMetadata,
  });

  /// Atomically marks a session as abandoned.
  Future<void> markAbandoned({
    required String learnerId,
    required String examId,
    required String sessionId,
    required DateTime abandonedAt,
    String? reason,
  });

  /// Lists all checkpoints stored for a session in ascending revision order.
  Future<List<SessionCheckpoint>> listCheckpoints({
    required String learnerId,
    required String examId,
    required String sessionId,
  });

  /// Clears all stored sessions and checkpoints (for test isolation).
  Future<void> clear();
}
