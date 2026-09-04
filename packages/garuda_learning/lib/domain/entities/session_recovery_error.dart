/// Session Recovery Error Entities (TITAN-KO-040.0 P40).
///
/// Encapsulates strongly-typed domain errors and exceptions for resumable
/// session validation, checkpoint persistence, and restart recovery.
library;

/// Error code classification for session recovery failures.
enum SessionRecoveryErrorCode {
  /// Session has never been check-pointed (valid cold-start condition).
  coldStart,

  /// Specified session identifier was not found in checkpoint storage.
  sessionNotFound,

  /// No checkpoint exists for the requested session and tenant context.
  checkpointNotFound,

  /// Session has already reached a completed terminal state.
  alreadyCompleted,

  /// Session is in an abandoned or failed state and cannot be recovered.
  notRecoverable,

  /// Checkpoint payload fails cryptographic checksum or structural validation.
  corruptedCheckpoint,

  /// Underlying authoritative learner state is corrupted or unreadable.
  corruptedAuthoritativeState,

  /// Stale checkpoint detected: incoming revision <= existing revision.
  staleCheckpoint,

  /// Tenant mismatch: learnerId, examId, or sessionId does not match target context.
  identityMismatch,

  /// Checkpoint schema version is newer than supported by this runtime.
  incompatibleVersion,

  /// Underlying repository or storage IO operation failed.
  ioFailure,

  /// Attempted lifecycle transition is not permitted by domain rules.
  invalidTransition,

  /// Unclassified recovery failure.
  unknownFailure;
}

/// Typed domain exception for session checkpoint and recovery failures.
class SessionRecoveryException implements Exception {
  final SessionRecoveryErrorCode code;
  final String message;
  final Map<String, dynamic> details;

  const SessionRecoveryException({
    required this.code,
    required this.message,
    this.details = const {},
  });

  @override
  String toString() => 'SessionRecoveryException(${code.name}): $message';
}
