/// Session Checkpoint & Recovery Typed Domain Exceptions (TITAN-KO-040.0 P40).
///
/// Explicit typed failure hierarchy covering checkpoint persistence, identity validation,
/// integrity verification, schema evolution, attempt deduplication, and completion ordering.
library;

import 'session_recovery_error.dart';

/// Base exception for all session checkpoint and recovery operations.
class SessionCheckpointException extends SessionRecoveryException {
  const SessionCheckpointException({
    required super.code,
    required super.message,
    super.details = const {},
  });

  @override
  String toString() => 'SessionCheckpointException(${code.name}): $message';
}

/// Thrown when tenant identity coordinates (learnerId, examId, sessionId) do not match.
class SessionIdentityMismatchException extends SessionCheckpointException {
  final String expected;
  final String actual;

  SessionIdentityMismatchException({
    required super.message,
    required this.expected,
    required this.actual,
    Map<String, dynamic> details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.identityMismatch,
          details: {
            ...details,
            'expected': expected,
            'actual': actual,
          },
        );

  @override
  String toString() =>
      'SessionIdentityMismatchException: $message (expected: $expected, actual: $actual)';
}

/// Thrown when a checkpoint write or restore operation detects a stale or regressed revision.
class StaleCheckpointException extends SessionCheckpointException {
  final int incomingRevision;
  final int existingRevision;

  StaleCheckpointException({
    required super.message,
    required this.incomingRevision,
    required this.existingRevision,
    Map<String, dynamic> details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.staleCheckpoint,
          details: {
            ...details,
            'incomingRevision': incomingRevision,
            'existingRevision': existingRevision,
          },
        );

  @override
  String toString() =>
      'StaleCheckpointException: $message (incoming: $incomingRevision, existing: $existingRevision)';
}

/// Thrown when a checkpoint payload fails cryptographic checksum or structure validation.
class CheckpointIntegrityException extends SessionCheckpointException {
  final String? expectedChecksum;
  final String? foundChecksum;

  CheckpointIntegrityException({
    required super.message,
    this.expectedChecksum,
    this.foundChecksum,
    Map<String, dynamic> details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.corruptedCheckpoint,
          details: {
            ...details,
            if (expectedChecksum != null) 'expectedChecksum': expectedChecksum,
            if (foundChecksum != null) 'foundChecksum': foundChecksum,
          },
        );

  @override
  String toString() => 'CheckpointIntegrityException: $message';
}

/// Thrown when checkpoint schema version is incompatible or unsupported.
class CheckpointSchemaException extends SessionCheckpointException {
  final int schemaVersion;

  CheckpointSchemaException({
    required super.message,
    required this.schemaVersion,
    Map<String, dynamic> details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.incompatibleVersion,
          details: {
            ...details,
            'schemaVersion': schemaVersion,
          },
        );

  @override
  String toString() =>
      'CheckpointSchemaException: $message (schemaVersion: $schemaVersion)';
}

/// Thrown when an attempt has already been consolidated and cannot be applied again.
class DuplicateAttemptException extends SessionCheckpointException {
  final String attemptToken;

  DuplicateAttemptException({
    required super.message,
    required this.attemptToken,
    Map<String, dynamic> details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.invalidTransition,
          details: {
            ...details,
            'attemptToken': attemptToken,
          },
        );

  @override
  String toString() =>
      'DuplicateAttemptException: $message (attemptToken: $attemptToken)';
}

/// Thrown when session finalization violates ordering or persistence constraints.
class SessionCompletionException extends SessionCheckpointException {
  SessionCompletionException({
    required super.message,
    super.details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.invalidTransition,
        );

  @override
  String toString() => 'SessionCompletionException: $message';
}

/// Thrown when a requested session is not found in the session repository.
class SessionNotFoundException extends SessionCheckpointException {
  final String sessionId;

  SessionNotFoundException({
    required super.message,
    required this.sessionId,
    Map<String, dynamic> details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.coldStart,
          details: {
            ...details,
            'sessionId': sessionId,
          },
        );

  @override
  String toString() =>
      'SessionNotFoundException: $message (sessionId: $sessionId)';
}

/// Thrown when an illegal lifecycle state transition is requested on a session.
class InvalidSessionTransitionException extends SessionCheckpointException {
  final String from;
  final String to;

  InvalidSessionTransitionException({
    required super.message,
    required this.from,
    required this.to,
    Map<String, dynamic> details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.invalidTransition,
          details: {
            ...details,
            'from': from,
            'to': to,
          },
        );

  @override
  String toString() =>
      'InvalidSessionTransitionException: $message ($from -> $to)';
}

/// Thrown when a tenant access violates session learner or exam ownership boundaries.
class SessionOwnershipException extends SessionCheckpointException {
  final String expectedLearner;
  final String actualLearner;

  SessionOwnershipException({
    required super.message,
    required this.expectedLearner,
    required this.actualLearner,
    Map<String, dynamic> details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.identityMismatch,
          details: {
            ...details,
            'expectedLearner': expectedLearner,
            'actualLearner': actualLearner,
          },
        );

  @override
  String toString() =>
      'SessionOwnershipException: $message (expected: $expectedLearner, actual: $actualLearner)';
}

/// Thrown when an attempt or mutation is submitted to an already completed session.
class CompletedSessionMutationException extends SessionCheckpointException {
  final String sessionId;

  CompletedSessionMutationException({
    required super.message,
    required this.sessionId,
    Map<String, dynamic> details = const {},
  }) : super(
          code: SessionRecoveryErrorCode.alreadyCompleted,
          details: {
            ...details,
            'sessionId': sessionId,
          },
        );

  @override
  String toString() =>
      'CompletedSessionMutationException: $message (sessionId: $sessionId)';
}
