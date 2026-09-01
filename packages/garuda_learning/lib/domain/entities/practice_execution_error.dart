/// Practice Execution Error Domain Models (TITAN-KO-035.0 P35).
///
/// Structured domain errors and results for the adaptive practice execution layer.
/// Avoids uncaught exceptions and provides deterministic, actionable error feedback.
library;

import 'package:meta/meta.dart';

/// Categorical error codes for practice execution operations.
enum PracticeExecutionErrorCode {
  /// Session has not been started yet.
  sessionNotStarted,

  /// Session is already in a terminal completed state.
  sessionCompleted,

  /// Session is in a terminal abandoned state.
  sessionAbandoned,

  /// Session is currently paused and cannot accept submissions.
  sessionPaused,

  /// Requested question ID was not found in the session specification.
  questionNotFound,

  /// Question has already been answered and cannot be re-submitted.
  questionAlreadyAnswered,

  /// Submitted answer payload is empty, malformed, or invalid.
  invalidAnswer,

  /// Submitted question does not match the currently active question index.
  wrongQuestion,

  /// Question skipping is not permitted under the active configuration.
  skipNotAllowed,

  /// Question exam ID does not match the session exam ID.
  crossExamMismatch,

  /// Invalid lifecycle state transition requested.
  invalidTransition,
}

/// Structured error payload for failed practice execution operations.
@immutable
class PracticeExecutionError {
  /// Categorical error code.
  final PracticeExecutionErrorCode code;

  /// Human-readable explanation of why the operation failed.
  final String message;

  /// Optional contextual details (e.g., question ID, current state).
  final Map<String, dynamic> details;

  const PracticeExecutionError({
    required this.code,
    required this.message,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
        'code': code.name,
        'message': message,
        if (details.isNotEmpty) 'details': details,
      };

  factory PracticeExecutionError.fromJson(Map<String, dynamic> json) =>
      PracticeExecutionError(
        code: PracticeExecutionErrorCode.values.firstWhere(
          (c) => c.name == json['code'],
          orElse: () => PracticeExecutionErrorCode.invalidTransition,
        ),
        message: json['message'] as String? ?? 'Execution error',
        details: Map<String, dynamic>.from(json['details'] as Map? ?? {}),
      );

  @override
  String toString() => 'PracticeExecutionError(${code.name}: "$message")';
}

/// Generic deterministic result wrapper for practice execution actions.
@immutable
class PracticeExecutionResult<T> {
  /// Successful result value, or null if the operation failed.
  final T? value;

  /// Structured error object, or null if the operation succeeded.
  final PracticeExecutionError? error;

  /// Whether the operation completed successfully.
  bool get isSuccess => error == null && value != null;

  /// Whether the operation encountered a structured domain error.
  bool get isFailure => !isSuccess;

  const PracticeExecutionResult.success(T this.value) : error = null;

  const PracticeExecutionResult.failure(PracticeExecutionError this.error)
      : value = null;

  /// Unwraps the value if successful, or throws a [StateError] containing the error message.
  T get valueOrThrow {
    if (isSuccess) return value as T;
    throw StateError('PracticeExecutionResult failed: ${error?.message}');
  }

  @override
  String toString() => isSuccess
      ? 'PracticeExecutionResult.success($value)'
      : 'PracticeExecutionResult.failure($error)';
}
