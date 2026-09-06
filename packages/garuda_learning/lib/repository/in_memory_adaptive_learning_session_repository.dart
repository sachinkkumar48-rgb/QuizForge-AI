/// In-Memory Adaptive Learning Session Repository (TITAN-KO-040.0 P40).
///
/// Deterministic, zero-dependency in-memory implementation of
/// [AdaptiveLearningSessionRepository] supporting monotonic revision protection,
/// multi-tenant context isolation, and full test reset capabilities.
library;

import '../domain/entities/adaptive_learning_session.dart';
import '../domain/entities/session_checkpoint.dart';
import '../domain/entities/session_checkpoint_exceptions.dart';
import '../domain/entities/session_recovery_error.dart';
import '../domain/entities/session_status.dart';
import 'adaptive_learning_session_repository.dart';

/// In-memory repository implementing [AdaptiveLearningSessionRepository].
class InMemoryAdaptiveLearningSessionRepository
    implements AdaptiveLearningSessionRepository {
  final Map<String, AdaptiveLearningSession> _sessions = {};
  final Map<String, List<SessionCheckpoint>> _checkpoints = {};

  InMemoryAdaptiveLearningSessionRepository();

  static String _key(String learnerId, String examId, String sessionId) =>
      '${learnerId.trim()}:${examId.trim().toLowerCase()}:${sessionId.trim()}';

  @override
  Future<void> createSession(AdaptiveLearningSession session) async {
    final key = _key(session.learnerId, session.examId, session.sessionId);
    if (_sessions.containsKey(key)) {
      throw SessionRecoveryException(
        code: SessionRecoveryErrorCode.invalidTransition,
        message:
            'Session "${session.sessionId}" already exists for ${session.learnerId}:${session.examId}',
        details: {'sessionId': session.sessionId},
      );
    }
    _sessions[key] = session;
  }

  @override
  Future<AdaptiveLearningSession?> getSession({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    final key = _key(learnerId, examId, sessionId);
    return _sessions[key];
  }

  @override
  Future<void> updateSession(AdaptiveLearningSession session) async {
    final key = _key(session.learnerId, session.examId, session.sessionId);
    if (!_sessions.containsKey(key)) {
      throw SessionNotFoundException(
        message: 'Cannot update non-existent session "${session.sessionId}"',
        sessionId: session.sessionId,
      );
    }
    _sessions[key] = session;
  }

  @override
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {
    final key =
        _key(checkpoint.learnerId, checkpoint.examId, checkpoint.sessionId);
    final history = _checkpoints.putIfAbsent(key, () => <SessionCheckpoint>[]);

    if (history.isNotEmpty) {
      final latest = history.last;
      if (checkpoint.checkpointRevision < latest.checkpointRevision) {
        throw StaleCheckpointException(
          message:
              'Stale checkpoint rejected: incoming revision ${checkpoint.checkpointRevision} < latest revision ${latest.checkpointRevision}',
          incomingRevision: checkpoint.checkpointRevision,
          existingRevision: latest.checkpointRevision,
          details: {'sessionId': checkpoint.sessionId},
        );
      } else if (checkpoint.checkpointRevision == latest.checkpointRevision) {
        if (checkpoint.checksum == latest.checksum) {
          // Idempotent write
          return;
        } else {
          throw StaleCheckpointException(
            message:
                'Stale checkpoint rejected: identical revision ${checkpoint.checkpointRevision} with diverging payload',
            incomingRevision: checkpoint.checkpointRevision,
            existingRevision: latest.checkpointRevision,
            details: {'sessionId': checkpoint.sessionId},
          );
        }
      }
    }

    history.add(checkpoint);
  }

  @override
  Future<SessionCheckpoint?> getLatestCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    final key = _key(learnerId, examId, sessionId);
    final history = _checkpoints[key];
    if (history == null || history.isEmpty) {
      return null;
    }
    return history.last;
  }

  @override
  Future<void> markCompleted({
    required String learnerId,
    required String examId,
    required String sessionId,
    required DateTime completedAt,
    Map<String, dynamic>? completionMetadata,
  }) async {
    final key = _key(learnerId, examId, sessionId);
    final existing = _sessions[key];
    if (existing == null) {
      throw SessionNotFoundException(
        message: 'Cannot mark non-existent session "$sessionId" as completed',
        sessionId: sessionId,
      );
    }

    final updatedMetadata = {
      ...existing.completionMetadata,
      ...?completionMetadata,
      'completedAt': completedAt.toUtc().toIso8601String(),
    };

    _sessions[key] = existing.copyWith(
      status: SessionStatus.completed,
      lastActivityAt: completedAt.toUtc(),
      completionMetadata: updatedMetadata,
    );
  }

  @override
  Future<void> markAbandoned({
    required String learnerId,
    required String examId,
    required String sessionId,
    required DateTime abandonedAt,
    String? reason,
  }) async {
    final key = _key(learnerId, examId, sessionId);
    final existing = _sessions[key];
    if (existing == null) {
      throw SessionNotFoundException(
        message: 'Cannot mark non-existent session "$sessionId" as abandoned',
        sessionId: sessionId,
      );
    }

    final updatedMetadata = {
      ...existing.completionMetadata,
      if (reason != null) 'abandonedReason': reason,
      'abandonedAt': abandonedAt.toUtc().toIso8601String(),
    };

    _sessions[key] = existing.copyWith(
      status: SessionStatus.abandoned,
      lastActivityAt: abandonedAt.toUtc(),
      completionMetadata: updatedMetadata,
    );
  }

  @override
  Future<List<SessionCheckpoint>> listCheckpoints({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    final key = _key(learnerId, examId, sessionId);
    final history = _checkpoints[key];
    if (history == null) return const [];
    return List<SessionCheckpoint>.unmodifiable(history);
  }

  @override
  Future<void> clear() async {
    _sessions.clear();
    _checkpoints.clear();
  }

  /// Direct test hook: inject raw checkpoint (simulates external writes or fault injection).
  void injectCheckpoint(SessionCheckpoint checkpoint) {
    final key =
        _key(checkpoint.learnerId, checkpoint.examId, checkpoint.sessionId);
    _checkpoints.putIfAbsent(key, () => <SessionCheckpoint>[]).add(checkpoint);
  }
}
