/// Session Recovery Result Domain Entities (TITAN-KO-040.0 P40).
///
/// Encapsulates explicit, deterministic outcome representations of session
/// recovery operations distinguishing cold-starts, successful resumptions,
/// completed sessions, corruption, and version mismatches.
library;

import 'package:meta/meta.dart';

import 'authoritative_learner_state.dart';
import 'resumable_learning_session.dart';
import 'session_checkpoint.dart';
import 'session_recovery_error.dart';

/// Categorical status of a session recovery attempt.
enum SessionRecoveryResultStatus {
  /// Session was safely located, validated, and reconstructed from checkpoint.
  success,

  /// No prior session checkpoint exists (clean first launch).
  coldStart,

  /// Session was previously finalized and cannot be resumed for new attempts.
  alreadyCompleted,

  /// Session status is abandoned or failed and is not eligible for recovery.
  notRecoverable,

  /// Checkpoint payload fails checksum or authoritative state is corrupted.
  corrupt,

  /// Stale checkpoint or state revision conflict detected.
  stale,

  /// Identity mismatch between requested tenant context and checkpoint metadata.
  identityMismatch,

  /// Schema version is unsupported by the current engine runtime.
  incompatibleVersion,

  /// Unhandled or IO repository failure.
  failure;
}

/// Explicit domain result returned by session recovery operations.
@immutable
class SessionRecoveryResult {
  /// Categorical status of the recovery result.
  final SessionRecoveryResultStatus status;

  /// Reconstructed resumable session, populated only when [status] is [success].
  final ResumableLearningSession? session;

  /// Associated authoritative learner state, if available.
  final AuthoritativeLearnerState? authoritativeState;

  /// Loaded checkpoint used for recovery, if present.
  final SessionCheckpoint? checkpoint;

  /// Descriptive diagnostic message.
  final String message;

  /// Typed exception detailing failures, if applicable.
  final SessionRecoveryException? error;

  const SessionRecoveryResult({
    required this.status,
    this.session,
    this.authoritativeState,
    this.checkpoint,
    required this.message,
    this.error,
  });

  /// Whether recovery was completely successful and session is ready to execute.
  bool get isSuccess => status == SessionRecoveryResultStatus.success;

  /// Whether this is a valid clean cold start without prior checkpoints.
  bool get isColdStart => status == SessionRecoveryResultStatus.coldStart;

  /// Whether the session has already completed.
  bool get isAlreadyCompleted =>
      status == SessionRecoveryResultStatus.alreadyCompleted;

  /// Whether recovery was unsuccessful.
  bool get isFailure => !isSuccess;

  /// Constructs a successful recovery result.
  factory SessionRecoveryResult.success({
    required ResumableLearningSession session,
    required AuthoritativeLearnerState authoritativeState,
    required SessionCheckpoint checkpoint,
    String? message,
  }) {
    return SessionRecoveryResult(
      status: SessionRecoveryResultStatus.success,
      session: session,
      authoritativeState: authoritativeState,
      checkpoint: checkpoint,
      message: message ??
          'Session "${session.sessionId}" successfully recovered at question ${checkpoint.questionIndex + 1} (rev ${checkpoint.checkpointRevision}).',
    );
  }

  /// Constructs a cold-start result when no previous session checkpoint exists.
  factory SessionRecoveryResult.coldStart({
    required String learnerId,
    required String examId,
    required String sessionId,
    String? message,
  }) {
    return SessionRecoveryResult(
      status: SessionRecoveryResultStatus.coldStart,
      message: message ??
          'No prior checkpoint found for session "$sessionId" ($learnerId:$examId). Cold start required.',
      error: SessionRecoveryException(
        code: SessionRecoveryErrorCode.coldStart,
        message: 'No checkpoint found for session "$sessionId"',
        details: {
          'learnerId': learnerId,
          'examId': examId,
          'sessionId': sessionId,
        },
      ),
    );
  }

  /// Constructs an already-completed result for finished sessions.
  factory SessionRecoveryResult.alreadyCompleted({
    required SessionCheckpoint checkpoint,
    AuthoritativeLearnerState? authoritativeState,
    String? message,
  }) {
    return SessionRecoveryResult(
      status: SessionRecoveryResultStatus.alreadyCompleted,
      checkpoint: checkpoint,
      authoritativeState: authoritativeState,
      message: message ??
          'Session "${checkpoint.sessionId}" is already completed and cannot be resumed.',
      error: SessionRecoveryException(
        code: SessionRecoveryErrorCode.alreadyCompleted,
        message: 'Session "${checkpoint.sessionId}" was previously completed',
        details: {'sessionId': checkpoint.sessionId},
      ),
    );
  }

  /// Constructs a not-recoverable result for abandoned or failed sessions.
  factory SessionRecoveryResult.notRecoverable({
    required String sessionId,
    required String reason,
    SessionCheckpoint? checkpoint,
    SessionRecoveryException? error,
  }) {
    return SessionRecoveryResult(
      status: SessionRecoveryResultStatus.notRecoverable,
      checkpoint: checkpoint,
      message: 'Session "$sessionId" is not recoverable: $reason',
      error: error ??
          SessionRecoveryException(
            code: SessionRecoveryErrorCode.notRecoverable,
            message: reason,
            details: {'sessionId': sessionId},
          ),
    );
  }

  /// Constructs a corrupt result when checksum fails or state is structurally invalid.
  factory SessionRecoveryResult.corrupt({
    required String sessionId,
    required String reason,
    SessionRecoveryException? error,
  }) {
    return SessionRecoveryResult(
      status: SessionRecoveryResultStatus.corrupt,
      message: 'Session "$sessionId" checkpoint is corrupted: $reason',
      error: error ??
          SessionRecoveryException(
            code: SessionRecoveryErrorCode.corruptedCheckpoint,
            message: reason,
            details: {'sessionId': sessionId},
          ),
    );
  }

  /// Constructs a stale result when revision monotonicity is violated.
  factory SessionRecoveryResult.stale({
    required String sessionId,
    required int checkpointRevision,
    required int authoritativeRevision,
    SessionRecoveryException? error,
  }) {
    return SessionRecoveryResult(
      status: SessionRecoveryResultStatus.stale,
      message:
          'Stale session checkpoint detected for "$sessionId": chkRev=$checkpointRevision, authRev=$authoritativeRevision',
      error: error ??
          SessionRecoveryException(
            code: SessionRecoveryErrorCode.staleCheckpoint,
            message:
                'Stale checkpoint: chkRev $checkpointRevision, authRev $authoritativeRevision',
            details: {
              'sessionId': sessionId,
              'checkpointRevision': checkpointRevision,
              'authoritativeRevision': authoritativeRevision,
            },
          ),
    );
  }

  /// Constructs an identity-mismatch result for cross-tenant or cross-exam collision.
  factory SessionRecoveryResult.identityMismatch({
    required String expectedLearner,
    required String foundLearner,
    required String sessionId,
    SessionRecoveryException? error,
  }) {
    return SessionRecoveryResult(
      status: SessionRecoveryResultStatus.identityMismatch,
      message:
          'Tenant identity mismatch for session "$sessionId": expected "$expectedLearner", found "$foundLearner"',
      error: error ??
          SessionRecoveryException(
            code: SessionRecoveryErrorCode.identityMismatch,
            message:
                'Learner mismatch: expected "$expectedLearner", found "$foundLearner"',
            details: {
              'expectedLearner': expectedLearner,
              'foundLearner': foundLearner,
              'sessionId': sessionId,
            },
          ),
    );
  }

  /// Constructs an incompatible schema version result.
  factory SessionRecoveryResult.incompatibleVersion({
    required int schemaVersion,
    required String sessionId,
    SessionRecoveryException? error,
  }) {
    return SessionRecoveryResult(
      status: SessionRecoveryResultStatus.incompatibleVersion,
      message:
          'Incompatible checkpoint schema version $schemaVersion for session "$sessionId"',
      error: error ??
          SessionRecoveryException(
            code: SessionRecoveryErrorCode.incompatibleVersion,
            message: 'Incompatible schema version: $schemaVersion',
            details: {
              'schemaVersion': schemaVersion,
              'sessionId': sessionId,
            },
          ),
    );
  }

  /// Constructs a general or IO failure result.
  factory SessionRecoveryResult.failure({
    required String sessionId,
    required String message,
    SessionRecoveryException? error,
  }) {
    return SessionRecoveryResult(
      status: SessionRecoveryResultStatus.failure,
      message: message,
      error: error ??
          SessionRecoveryException(
            code: SessionRecoveryErrorCode.unknownFailure,
            message: message,
            details: {'sessionId': sessionId},
          ),
    );
  }

  @override
  String toString() =>
      'SessionRecoveryResult(${status.name}: $message, hasSession=${session != null})';
}
