/// Reconciliation Error and Result Monad (TITAN-KO-038.0 P38).
///
/// Encapsulates structured domain error codes and monadic result types for
/// adaptive learning state reconciliation operations.
library;

import 'package:meta/meta.dart';

/// Categorical error codes for learning state reconciliation operations.
enum ReconciliationErrorCode {
  /// Authoritative learner state is null, blank, or structurally invalid.
  invalidState,

  /// Proposal is null, blank, or structurally invalid.
  invalidProposal,

  /// Target examination ID does not match across authoritative state and proposal.
  examMismatch,

  /// Target learner ID does not match across authoritative state and proposal.
  learnerMismatch,

  /// Proposal is stale relative to authoritative state last-updated timestamp or version.
  staleState,

  /// Provided expected base state fingerprint does not match authoritative state fingerprint.
  fingerprintMismatch,

  /// Incompatible or unresolvable conflict detected.
  conflictViolation,

  /// Arithmetic or aggregation invariant violation during reconciliation.
  calculationError;
}

/// Structured error payload representing a domain-level reconciliation failure.
@immutable
class ReconciliationError {
  /// Categorical error code.
  final ReconciliationErrorCode code;

  /// Human-readable descriptive explanation of the failure.
  final String message;

  /// Optional contextual details for diagnostics.
  final Map<String, dynamic>? details;

  const ReconciliationError({
    required this.code,
    required this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'code': code.name,
        'message': message,
        if (details != null) 'details': details,
      };

  factory ReconciliationError.fromJson(Map<String, dynamic> json) =>
      ReconciliationError(
        code: ReconciliationErrorCode.values.firstWhere(
          (e) => e.name == json['code'],
          orElse: () => ReconciliationErrorCode.calculationError,
        ),
        message: json['message'] as String? ?? 'Unknown reconciliation error',
        details: json['details'] as Map<String, dynamic>?,
      );

  @override
  String toString() =>
      'ReconciliationError(code: ${code.name}, message: "$message")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReconciliationError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message;

  @override
  int get hashCode => Object.hash(code, message);
}

/// Monadic result type for learning-state reconciliation operations.
@immutable
class ReconciliationResult<T> {
  final T? _value;
  final ReconciliationError? _error;

  const ReconciliationResult.success(T value)
      : _value = value,
        _error = null;

  const ReconciliationResult.failure(ReconciliationError error)
      : _value = null,
        _error = error;

  /// Whether the operation succeeded.
  bool get isSuccess => _error == null;

  /// Whether the operation failed.
  bool get isFailure => _error != null;

  /// The successful value, or null on failure.
  T? get value => _value;

  /// Alias for [value] when working with reconciled proposals.
  T? get proposal => _value;

  /// The error payload, or null on success.
  ReconciliationError? get error => _error;

  /// Unwraps the value or throws a [StateError] with the failure message.
  T get valueOrThrow {
    if (isSuccess) return _value as T;
    throw StateError('Reconciliation failed with error: ${_error?.message}');
  }

  @override
  String toString() => isSuccess
      ? 'ReconciliationResult.success($_value)'
      : 'ReconciliationResult.failure($_error)';
}
