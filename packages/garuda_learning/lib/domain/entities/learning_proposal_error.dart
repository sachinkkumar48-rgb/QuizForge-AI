/// Learning Proposal Error and Result Monad (TITAN-KO-037.0 P37).
///
/// Encapsulates structured domain error codes and monadic result types for
/// learning-state update proposal derivation.
library;

import 'package:meta/meta.dart';

/// Categorical error codes for learning-state proposal operations.
enum LearningProposalErrorCode {
  /// Consolidated outcome or session ID is null, blank, or malformed.
  invalidOutcome,

  /// Target examination ID does not match question or evidence provenance.
  examMismatch,

  /// Inconsistent or corrupted practice evidence (e.g. negative counts, count mismatch).
  invalidEvidence,

  /// Duplicate question evidence IDs detected within a single proposal.
  duplicateSignal,

  /// Arithmetic or aggregation invariant violation.
  calculationError;
}

/// Structured error payload representing a domain-level proposal failure.
@immutable
class LearningProposalError {
  /// Categorical error code.
  final LearningProposalErrorCode code;

  /// Human-readable descriptive explanation of the failure.
  final String message;

  /// Optional contextual details for diagnostics.
  final Map<String, dynamic>? details;

  const LearningProposalError({
    required this.code,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'code': code.name,
        'message': message,
        if (details != null) 'details': details,
      };

  factory LearningProposalError.fromJson(Map<String, dynamic> json) =>
      LearningProposalError(
        code: LearningProposalErrorCode.values.firstWhere(
          (e) => e.name == json['code'],
          orElse: () => LearningProposalErrorCode.calculationError,
        ),
        message: json['message'] as String? ?? 'Unknown proposal error',
        details: json['details'] as Map<String, dynamic>?,
      );

  @override
  String toString() =>
      'LearningProposalError(code: ${code.name}, message: "$message")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningProposalError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);
}

/// Monadic result type for learning-state update proposal operations.
@immutable
class LearningProposalResult<T> {
  final T? _value;
  final LearningProposalError? _error;

  const LearningProposalResult.success(T value)
      : _value = value,
        _error = null;

  const LearningProposalResult.failure(LearningProposalError error)
      : _value = null,
        _error = error;

  /// Whether the operation succeeded.
  bool get isSuccess => _error == null;

  /// Whether the operation failed.
  bool get isFailure => _error != null;

  /// The successful value, or null on failure.
  T? get value => _value;

  /// The error payload, or null on success.
  LearningProposalError? get error => _error;

  /// Unwraps the value or throws a [StateError] with the failure message.
  T get valueOrThrow {
    if (isSuccess) return _value as T;
    throw StateError('Proposal failed with error: ${_error?.message}');
  }

  @override
  String toString() => isSuccess
      ? 'LearningProposalResult.success($_value)'
      : 'LearningProposalResult.failure($_error)';
}
