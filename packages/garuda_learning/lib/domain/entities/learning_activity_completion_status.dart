/// Learning Activity Completion Status & Error Domain Models (TITAN-KO-043.0 P43).
///
/// Defines the operational lifecycle statuses, structured error codes, and exception models
/// for adaptive learning activity completion and outcome feedback.
library;

import 'package:meta/meta.dart';

/// Operational status resulting from an activity completion request.
enum LearningActivityCompletionStatus {
  /// Activity successfully finalized, outcome normalized, and state reconciled.
  success,

  /// Activity was previously completed; idempotent replay recognized without re-scoring.
  alreadyCompleted,

  /// Request violated domain invariants, pre-conditions, or tenant identity.
  invalidRequest,

  /// The continuation plan backing the activity is stale relative to current authoritative state.
  stalePlan,

  /// The plan revision claimed by the request is ahead of current authoritative state.
  futurePlanRevision,

  /// Expected session or execution state was not found or could not be resolved.
  missingSession,

  /// Attempt validation failed (duplicate questions, unknown question IDs, invalid values).
  invalidAttempts,

  /// Downstream P36 outcome consolidation failed.
  consolidationFailed,

  /// Downstream P38/P39 state reconciliation or persistence failed.
  reconciliationFailed,

  /// General unhandled execution failure during completion.
  executionFailed;

  /// Whether this completion status represents a successful outcome (fresh or idempotent replay).
  bool get isSuccess =>
      this == LearningActivityCompletionStatus.success ||
      this == LearningActivityCompletionStatus.alreadyCompleted;

  /// Whether this completion status was an idempotent replay of an already-processed activity.
  bool get isAlreadyCompleted =>
      this == LearningActivityCompletionStatus.alreadyCompleted;

  /// Whether this completion status represents a failure.
  bool get isFailure => !isSuccess;

  /// User-facing descriptive display label.
  String get displayName {
    switch (this) {
      case LearningActivityCompletionStatus.success:
        return 'Success';
      case LearningActivityCompletionStatus.alreadyCompleted:
        return 'Already Completed';
      case LearningActivityCompletionStatus.invalidRequest:
        return 'Invalid Request';
      case LearningActivityCompletionStatus.stalePlan:
        return 'Stale Plan';
      case LearningActivityCompletionStatus.futurePlanRevision:
        return 'Future Plan Revision';
      case LearningActivityCompletionStatus.missingSession:
        return 'Missing Session';
      case LearningActivityCompletionStatus.invalidAttempts:
        return 'Invalid Attempts';
      case LearningActivityCompletionStatus.consolidationFailed:
        return 'Consolidation Failed';
      case LearningActivityCompletionStatus.reconciliationFailed:
        return 'Reconciliation Failed';
      case LearningActivityCompletionStatus.executionFailed:
        return 'Execution Failed';
    }
  }
}

/// Standardized machine-readable error codes for activity completion failures.
enum ActivityCompletionErrorCode {
  /// Learner ID or Exam ID does not match the active session, plan, or tenant boundary.
  tenantMismatch,

  /// Plan revision is older than the current authoritative learner state revision.
  stalePlan,

  /// Plan revision is strictly greater than the current authoritative learner state revision.
  futurePlanRevision,

  /// Precondition validation failed on the completion request.
  preconditionFailed,

  /// Practice session referenced in the request was not found.
  missingSession,

  /// Duplicate attempts for the same question ID detected.
  duplicateAttempt,

  /// Question ID referenced in attempt was not part of the presented session questions.
  unknownQuestion,

  /// Attempt data contains contradictory or invalid metrics.
  invalidAttempts,

  /// Downstream P36 outcome consolidation produced an error.
  consolidationFailed,

  /// Downstream P38/P39 state reconciliation or persistence failed.
  reconciliationFailed,

  /// Completion record already exists with conflicting details.
  conflictingCompletion,

  /// General internal execution failure.
  executionFailed;
}

/// Structured, machine-readable error descriptor for activity completion failures.
@immutable
class ActivityCompletionError {
  /// Categorical error code.
  final ActivityCompletionErrorCode code;

  /// Human-readable diagnostic message explaining the root cause.
  final String message;

  /// Optional underlying exception or failure reason.
  final Object? cause;

  /// UTC timestamp when the failure occurred.
  final DateTime timestamp;

  /// Contextual details or metrics associated with the failure.
  final Map<String, dynamic> details;

  ActivityCompletionError({
    required this.code,
    required String message,
    this.cause,
    DateTime? timestamp,
    Map<String, dynamic>? details,
  })  : message = message.trim(),
        timestamp = (timestamp ?? DateTime.now()).toUtc(),
        details = Map<String, dynamic>.unmodifiable(
            details ?? const <String, dynamic>{});

  Map<String, dynamic> toJson() => {
        'code': code.name,
        'message': message,
        if (cause != null) 'cause': cause.toString(),
        'timestamp': timestamp.toIso8601String(),
        if (details.isNotEmpty) 'details': details,
      };

  factory ActivityCompletionError.fromJson(Map<String, dynamic> json) =>
      ActivityCompletionError(
        code: ActivityCompletionErrorCode.values.firstWhere(
          (c) => c.name == json['code'],
          orElse: () => ActivityCompletionErrorCode.executionFailed,
        ),
        message: json['message'] as String? ?? '',
        cause: json['cause'],
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : null,
        details: json['details'] as Map<String, dynamic>?,
      );

  @override
  String toString() => 'ActivityCompletionError(${code.name}: $message)';
}

/// Exception thrown when an activity completion workflow encounters a fatal error.
class ActivityCompletionException implements Exception {
  final ActivityCompletionError error;

  const ActivityCompletionException(this.error);

  ActivityCompletionErrorCode get code => error.code;
  String get message => error.message;

  @override
  String toString() => error.toString();
}
