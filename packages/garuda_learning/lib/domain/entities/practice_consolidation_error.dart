/// Practice Consolidation Error Domain Models (TITAN-KO-036.0 P36).
///
/// Structured domain errors and results for the practice outcome consolidation layer.
/// Prevents uncaught exceptions, guarantees deterministic error feedback, and maintains
/// robust domain safety across pipeline boundaries.
library;

import 'package:meta/meta.dart';

/// Categorical error codes for outcome consolidation operations.
enum PracticeConsolidationErrorCode {
  /// Session identifier is invalid, empty, or uninitialized.
  invalidSession,

  /// Execution state is inconsistent, missing required timestamps, or corrupted.
  invalidExecutionState,

  /// Outcome contains zero questions and cannot be consolidated under requested policy.
  emptyOutcome,

  /// Duplicate question IDs detected within the same session.
  duplicateQuestion,

  /// Question identity format is malformed or invalid.
  invalidQuestionIdentity,

  /// Question examId does not match the session examId (cross-exam contamination).
  examMismatch,

  /// Attempt data is malformed, missing required fields, or unparseable.
  invalidAttempt,

  /// State transition or execution status is unsupported for consolidation.
  unsupportedState,

  /// Aggregated evidence metrics violate mathematical bounds or constraints.
  malformedEvidence,

  /// Canonical JSON serialization or fingerprint hashing failed.
  serializationFailure,
}

/// Structured error payload for failed practice consolidation operations.
@immutable
class PracticeConsolidationError {
  /// Categorical error code.
  final PracticeConsolidationErrorCode code;

  /// Human-readable explanation of why consolidation failed.
  final String message;

  /// Structured contextual details for debugging and telemetry.
  final Map<String, dynamic> details;

  const PracticeConsolidationError({
    required this.code,
    required this.message,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
        'code': code.name,
        'message': message,
        if (details.isNotEmpty) 'details': details,
      };

  factory PracticeConsolidationError.fromJson(Map<String, dynamic> json) =>
      PracticeConsolidationError(
        code: PracticeConsolidationErrorCode.values.firstWhere(
          (c) => c.name == json['code'],
          orElse: () => PracticeConsolidationErrorCode.invalidExecutionState,
        ),
        message: json['message'] as String? ?? 'Consolidation error',
        details: Map<String, dynamic>.from(json['details'] as Map? ?? {}),
      );

  @override
  String toString() => 'PracticeConsolidationError(${code.name}: "$message")';
}

/// Generic deterministic result wrapper for practice consolidation operations.
@immutable
class PracticeConsolidationResult<T> {
  /// Successful result value, or null if the operation failed.
  final T? value;

  /// Structured error object, or null if the operation succeeded.
  final PracticeConsolidationError? error;

  /// Whether the operation completed successfully.
  bool get isSuccess => error == null && value != null;

  /// Whether the operation encountered a structured domain error.
  bool get isFailure => !isSuccess;

  const PracticeConsolidationResult.success(T this.value) : error = null;

  const PracticeConsolidationResult.failure(
      PracticeConsolidationError this.error)
      : value = null;

  /// Unwraps the value if successful, or throws a [StateError] containing the error message.
  T get valueOrThrow {
    if (isSuccess) return value as T;
    throw StateError('PracticeConsolidationResult failed: ${error?.message}');
  }

  @override
  String toString() => isSuccess
      ? 'PracticeConsolidationResult.success($value)'
      : 'PracticeConsolidationResult.failure($error)';
}
