/// Learning Session Recovery Service (TITAN-KO-040.0 P40).
///
/// Dedicated service responsible for locating persisted session checkpoints,
/// validating tenant identity and schema compatibility, coordinating with P39
/// authoritative learner state recovery, and safely resuming interrupted sessions
/// from their exact cursor position.
library;

import '../domain/entities/adaptive_practice_session_spec.dart';
import '../domain/entities/authoritative_recovery_result.dart';
import '../domain/entities/resumable_learning_session.dart';
import '../domain/entities/session_checkpoint.dart';
import '../domain/entities/session_recovery_error.dart';
import '../domain/entities/session_recovery_result.dart';
import '../repository/session_checkpoint_repository.dart';
import 'authoritative_learning_state_recovery_service.dart';

/// Production recovery coordinator for interrupted adaptive learning sessions.
class LearningSessionRecoveryService {
  final SessionCheckpointRepository _checkpointRepository;
  final AuthoritativeLearningStateRecoveryService _authoritativeRecoveryService;

  const LearningSessionRecoveryService({
    required SessionCheckpointRepository checkpointRepository,
    required AuthoritativeLearningStateRecoveryService
        authoritativeRecoveryService,
  })  : _checkpointRepository = checkpointRepository,
        _authoritativeRecoveryService = authoritativeRecoveryService;

  /// Underlying checkpoint repository handle.
  SessionCheckpointRepository get checkpointRepository => _checkpointRepository;

  /// Underlying authoritative learner state recovery service handle.
  AuthoritativeLearningStateRecoveryService get authoritativeRecoveryService =>
      _authoritativeRecoveryService;

  /// Recovers an interrupted adaptive learning session from its persisted checkpoint.
  ///
  /// Guarantees:
  /// - Distinguishes missing checkpoints as [SessionRecoveryResultStatus.coldStart].
  /// - Enforces multi-tenant isolation across `learnerId`, `examId`, and `sessionId`.
  /// - Verifies cryptographic checksums and rejects corrupted payloads explicitly.
  /// - Enforces schema version compatibility.
  /// - Detects stale authoritative state synchronization.
  /// - Reconstructs the session at the exact next uncompleted question cursor.
  Future<SessionRecoveryResult> recoverSession({
    required String learnerId,
    required String examId,
    required String sessionId,
    AdaptivePracticeSessionSpec? spec,
    DateTime? requestedAt,
  }) async {
    final cleanLearner = learnerId.trim();
    final cleanExam = examId.trim().toLowerCase();
    final cleanSession = sessionId.trim();
    final effectiveTs = (requestedAt ?? DateTime.now()).toUtc();

    if (cleanLearner.isEmpty || cleanExam.isEmpty || cleanSession.isEmpty) {
      return SessionRecoveryResult.failure(
        sessionId: cleanSession,
        message: 'learnerId, examId, and sessionId must be non-empty',
        error: const SessionRecoveryException(
          code: SessionRecoveryErrorCode.identityMismatch,
          message: 'Empty tenant context parameters',
        ),
      );
    }

    // 1. Locate persisted checkpoint
    SessionCheckpoint? checkpoint;
    try {
      checkpoint = await _checkpointRepository.loadCheckpoint(
        learnerId: cleanLearner,
        examId: cleanExam,
        sessionId: cleanSession,
      );
    } on SessionRecoveryException catch (e) {
      if (e.code == SessionRecoveryErrorCode.corruptedCheckpoint) {
        return SessionRecoveryResult.corrupt(
          sessionId: cleanSession,
          reason: e.message,
          error: e,
        );
      } else if (e.code == SessionRecoveryErrorCode.incompatibleVersion) {
        return SessionRecoveryResult.incompatibleVersion(
          schemaVersion: SessionCheckpoint.currentSchemaVersion,
          sessionId: cleanSession,
          error: e,
        );
      }
      return SessionRecoveryResult.failure(
        sessionId: cleanSession,
        message: e.message,
        error: e,
      );
    } catch (e) {
      return SessionRecoveryResult.failure(
        sessionId: cleanSession,
        message: 'Failed to load checkpoint: $e',
        error: SessionRecoveryException(
          code: SessionRecoveryErrorCode.ioFailure,
          message: e.toString(),
        ),
      );
    }

    // 2. Cold-start detection: no checkpoint exists
    if (checkpoint == null) {
      return SessionRecoveryResult.coldStart(
        learnerId: cleanLearner,
        examId: cleanExam,
        sessionId: cleanSession,
      );
    }

    // 3. Validate identity isolation
    if (checkpoint.learnerId != cleanLearner) {
      return SessionRecoveryResult.identityMismatch(
        expectedLearner: cleanLearner,
        foundLearner: checkpoint.learnerId,
        sessionId: cleanSession,
      );
    }
    if (checkpoint.examId != cleanExam) {
      return SessionRecoveryResult.identityMismatch(
        expectedLearner: cleanExam,
        foundLearner: checkpoint.examId,
        sessionId: cleanSession,
      );
    }
    if (checkpoint.sessionId != cleanSession) {
      return SessionRecoveryResult.identityMismatch(
        expectedLearner: cleanSession,
        foundLearner: checkpoint.sessionId,
        sessionId: cleanSession,
      );
    }

    // 4. Validate schema version
    if (checkpoint.schemaVersion > SessionCheckpoint.currentSchemaVersion) {
      return SessionRecoveryResult.incompatibleVersion(
        schemaVersion: checkpoint.schemaVersion,
        sessionId: cleanSession,
      );
    }

    // 5. Check if session already completed
    if (checkpoint.isCompleted) {
      return SessionRecoveryResult.alreadyCompleted(
        checkpoint: checkpoint,
      );
    }

    // 6. Check question cursor validity against spec if provided
    if (spec != null) {
      if (spec.examId.toLowerCase() != cleanExam) {
        return SessionRecoveryResult.identityMismatch(
          expectedLearner: cleanExam,
          foundLearner: spec.examId,
          sessionId: cleanSession,
        );
      }
      if (checkpoint.questionIndex > spec.totalQuestions) {
        return SessionRecoveryResult.corrupt(
          sessionId: cleanSession,
          reason:
              'Checkpoint questionIndex (${checkpoint.questionIndex}) exceeds total questions (${spec.totalQuestions}) in spec',
        );
      }
    }

    // 7. Load authoritative learner state through P39
    AuthoritativeRecoveryResult authRecoveryResult;
    try {
      authRecoveryResult = await _authoritativeRecoveryService.recover(
        learnerId: cleanLearner,
        examId: cleanExam,
        requestedAt: effectiveTs,
      );
    } catch (e) {
      return SessionRecoveryResult.corrupt(
        sessionId: cleanSession,
        reason: 'Failed to recover authoritative learner state: $e',
      );
    }

    if (authRecoveryResult.decision ==
        AuthoritativeRecoveryDecision.corrupted) {
      return SessionRecoveryResult.corrupt(
        sessionId: cleanSession,
        reason:
            'Authoritative learner state is corrupted: ${authRecoveryResult.error?.message}',
        error: SessionRecoveryException(
          code: SessionRecoveryErrorCode.corruptedAuthoritativeState,
          message: authRecoveryResult.error?.message ??
              'Authoritative state corrupt',
        ),
      );
    }

    if (authRecoveryResult.decision ==
        AuthoritativeRecoveryDecision.incompatibleSchema) {
      return SessionRecoveryResult.incompatibleVersion(
        schemaVersion: authRecoveryResult.schemaVersion ?? 1,
        sessionId: cleanSession,
      );
    }

    final authoritativeState = authRecoveryResult.state;
    if (authoritativeState == null) {
      return SessionRecoveryResult.corrupt(
        sessionId: cleanSession,
        reason: 'Authoritative learner state is null after recovery',
      );
    }

    // 8. Stale state check
    if (checkpoint.authoritativeStateRevision > authoritativeState.revision) {
      return SessionRecoveryResult.stale(
        sessionId: cleanSession,
        checkpointRevision: checkpoint.checkpointRevision,
        authoritativeRevision: authoritativeState.revision,
      );
    }

    // 9. Reconstruct ResumableLearningSession from checkpoint
    final session = ResumableLearningSession.fromCheckpoint(
      checkpoint: checkpoint,
      spec: spec,
      resumedAt: effectiveTs,
    );

    return SessionRecoveryResult.success(
      session: session,
      authoritativeState: authoritativeState,
      checkpoint: checkpoint,
    );
  }

  /// Atomically saves a session checkpoint.
  Future<void> saveCheckpoint(SessionCheckpoint checkpoint) async {
    await _checkpointRepository.saveCheckpoint(checkpoint);
  }

  /// Deletes a checkpoint for a specific session.
  Future<void> deleteCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    await _checkpointRepository.deleteCheckpoint(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );
  }

  /// Checks if a checkpoint exists for a specific session.
  Future<bool> hasCheckpoint({
    required String learnerId,
    required String examId,
    required String sessionId,
  }) async {
    return _checkpointRepository.exists(
      learnerId: learnerId,
      examId: examId,
      sessionId: sessionId,
    );
  }
}
