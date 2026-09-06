/// Adaptive Mastery Continuation Result Envelope (TITAN-KO-044.0 P44).
///
/// Encapsulates the complete outcome of the mastery evaluation and continuation cycle,
/// containing typed feedback, the pre-formulated continuation plan, and audit traces.
library;

import 'package:meta/meta.dart';

import 'adaptive_continuation_feedback.dart';
import 'learning_continuation_plan.dart';
import 'mastery_continuation_audit_trail.dart';

/// Operational status of a mastery continuation evaluation.
enum AdaptiveMasteryContinuationStatus {
  /// Evaluation succeeded and generated fresh feedback and continuation plan.
  success,

  /// Idempotent replay detected; cached feedback returned without duplicate processing.
  alreadyEvaluated,

  /// Request failed precondition or multi-tenant validation.
  invalidRequest,

  /// State revision was stale or incompatible.
  staleState,

  /// General execution failure during evaluation.
  executionFailed;

  /// Whether the status indicates successful evaluation or retrieval.
  bool get isSuccess =>
      this == AdaptiveMasteryContinuationStatus.success ||
      this == AdaptiveMasteryContinuationStatus.alreadyEvaluated;

  /// Human-readable display label.
  String get displayName {
    switch (this) {
      case AdaptiveMasteryContinuationStatus.success:
        return 'Success';
      case AdaptiveMasteryContinuationStatus.alreadyEvaluated:
        return 'Already Evaluated';
      case AdaptiveMasteryContinuationStatus.invalidRequest:
        return 'Invalid Request';
      case AdaptiveMasteryContinuationStatus.staleState:
        return 'Stale State';
      case AdaptiveMasteryContinuationStatus.executionFailed:
        return 'Execution Failed';
    }
  }
}

/// Strongly typed diagnostic error for mastery continuation.
@immutable
class MasteryContinuationError {
  /// Machine-readable error code.
  final String code;

  /// Human-readable explanation.
  final String message;

  /// UTC timestamp when error occurred.
  final DateTime timestamp;

  /// Diagnostic metadata.
  final Map<String, dynamic> details;

  MasteryContinuationError({
    required this.code,
    required this.message,
    required DateTime timestamp,
    Map<String, dynamic>? details,
  })  : timestamp = timestamp.toUtc(),
        details = Map<String, dynamic>.unmodifiable(
            details ?? const <String, dynamic>{});

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (details.isNotEmpty) 'details': details,
      };

  factory MasteryContinuationError.fromJson(Map<String, dynamic> json) {
    return MasteryContinuationError(
      code: json['code'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String).toUtc()
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
    );
  }

  @override
  String toString() => 'MasteryContinuationError($code: $message)';
}

@immutable
class AdaptiveMasteryContinuationResult {
  /// Correlated request identifier.
  final String requestId;

  /// Operational outcome status.
  final AdaptiveMasteryContinuationStatus status;

  /// Comprehensive pedagogical feedback bundle, populated on success.
  final AdaptiveContinuationFeedback? feedback;

  /// Pre-formulated continuation plan ready for P42 executor dispatch.
  final LearningContinuationPlan? continuationPlan;

  /// Complete diagnostic audit trail.
  final MasteryContinuationAuditTrail auditTrail;

  /// Error details, populated on failure.
  final MasteryContinuationError? error;

  /// UTC timestamp of result finalization.
  final DateTime evaluatedAt;

  AdaptiveMasteryContinuationResult({
    required this.requestId,
    required this.status,
    this.feedback,
    this.continuationPlan,
    this.auditTrail = const MasteryContinuationAuditTrail.empty(),
    this.error,
    required DateTime evaluatedAt,
  }) : evaluatedAt = evaluatedAt.toUtc();

  /// Whether this result represents a successful evaluation.
  bool get isSuccess => status.isSuccess;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'status': status.name,
        if (feedback != null) 'feedback': feedback!.toJson(),
        if (continuationPlan != null)
          'continuationPlan': continuationPlan!.toJson(),
        'auditTrail': auditTrail.toJson(),
        if (error != null) 'error': error!.toJson(),
        'evaluatedAt': evaluatedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveMasteryContinuationResult &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId &&
          status == other.status &&
          feedback == other.feedback;

  @override
  int get hashCode => Object.hash(requestId, status, feedback);

  @override
  String toString() =>
      'AdaptiveMasteryContinuationResult($requestId, status: ${status.name})';
}
