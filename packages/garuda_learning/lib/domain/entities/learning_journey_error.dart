/// Learning Journey Error and Exception Domain Models (TITAN-KO-041.0 P41).
///
/// Encapsulates typed, deterministic failure representations for production
/// adaptive learning journey orchestration.
library;

import 'package:meta/meta.dart';

/// Categorical error codes for learning journey operations.
enum LearningJourneyErrorCode {
  /// Tenant boundary violation (mismatched learnerId or examId).
  tenantMismatch,

  /// Requested journey session could not be located.
  missingSession,

  /// Required session checkpoint does not exist.
  missingCheckpoint,

  /// Checkpoint payload fails cryptographic SHA-256 checksum verification.
  corruptCheckpoint,

  /// Authoritative learner state is corrupted or cannot be deserialized safely.
  corruptState,

  /// Cryptographic checksum mismatch detected.
  checksumMismatch,

  /// Checkpoint or learner state revision conflict / stale revision write.
  staleRevision,

  /// Unsupported future schema version.
  incompatibleSchema,

  /// Underlying repository or persistence failure.
  repositoryFailure,

  /// Atomic persistence of checkpoint or authoritative state failed.
  persistenceFailure,

  /// Question format is invalid, missing options, or corrupted.
  malformedQuestion,

  /// Submitted answer is blank or outside valid option bounds.
  invalidAnswer,

  /// Illegal lifecycle transition attempted.
  invalidTransition,

  /// Duplicate attempt detected on an already answered question.
  duplicateAttempt,

  /// Duplicate outcome consolidation rejected.
  duplicateOutcome,

  /// Candidate pool has zero eligible questions matching constraints.
  selectionExhausted,

  /// Input question corpus is empty.
  emptyCorpus,

  /// Unclassified or unexpected failure.
  unknown;

  /// Whether this error represents a temporary/retryable condition.
  bool get isRetryable =>
      this == LearningJourneyErrorCode.repositoryFailure ||
      this == LearningJourneyErrorCode.persistenceFailure;

  /// Whether this error is permanently unrecoverable for the session.
  bool get isUnrecoverable =>
      this == LearningJourneyErrorCode.corruptCheckpoint ||
      this == LearningJourneyErrorCode.corruptState ||
      this == LearningJourneyErrorCode.incompatibleSchema ||
      this == LearningJourneyErrorCode.tenantMismatch;
}

/// Typed exception thrown by learning journey orchestration failures.
@immutable
class LearningJourneyException implements Exception {
  /// Categorical error code.
  final LearningJourneyErrorCode code;

  /// Human-readable diagnostic failure message.
  final String message;

  /// Optional contextual details.
  final Map<String, dynamic> details;

  /// Root underlying cause, if applicable.
  final Object? cause;

  const LearningJourneyException({
    required this.code,
    required this.message,
    this.details = const {},
    this.cause,
  });

  @override
  String toString() =>
      'LearningJourneyException(${code.name}): $message${details.isNotEmpty ? ' | details: $details' : ''}';
}
