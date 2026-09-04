/// Execution Audit Trail Domain Entities (TITAN-KO-042.0 P42).
///
/// Encapsulates step-by-step diagnostic audit logging, verification traces,
/// and timing provenance for deterministic adaptive plan execution.
library;

import 'package:meta/meta.dart';

/// Single auditable step executed during adaptive plan orchestration.
@immutable
class ExecutionAuditStep {
  /// 1-based sequential index of this audit step.
  final int stepIndex;

  /// Standardized name of this audit checkpoint.
  final String stepName;

  /// UTC timestamp when this step was evaluated.
  final DateTime timestamp;

  /// Whether this step completed successfully or without error.
  final bool isSuccess;

  /// Human-readable diagnostic description of the step outcome.
  final String message;

  /// Structured diagnostic metadata evaluated during this step.
  final Map<String, dynamic> details;

  ExecutionAuditStep({
    required this.stepIndex,
    required String stepName,
    required DateTime timestamp,
    this.isSuccess = true,
    required String message,
    Map<String, dynamic>? details,
  })  : stepName = stepName.trim(),
        timestamp = timestamp.toUtc(),
        message = message.trim(),
        details = Map<String, dynamic>.unmodifiable(details ?? const {}) {
    if (stepIndex < 1) {
      throw ArgumentError('stepIndex must be >= 1 (got $stepIndex)');
    }
    if (this.stepName.isEmpty) {
      throw ArgumentError('stepName cannot be empty for ExecutionAuditStep');
    }
    if (this.message.isEmpty) {
      throw ArgumentError('message cannot be empty for ExecutionAuditStep');
    }
  }

  Map<String, dynamic> toJson() => {
        'stepIndex': stepIndex,
        'stepName': stepName,
        'timestamp': timestamp.toIso8601String(),
        'isSuccess': isSuccess,
        'message': message,
        'details': details,
      };

  factory ExecutionAuditStep.fromJson(Map<String, dynamic> json) =>
      ExecutionAuditStep(
        stepIndex: json['stepIndex'] as int? ?? 1,
        stepName: json['stepName'] as String? ?? 'unknown',
        timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
        isSuccess: json['isSuccess'] as bool? ?? true,
        message: json['message'] as String? ?? '',
        details: json['details'] as Map<String, dynamic>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionAuditStep &&
          runtimeType == other.runtimeType &&
          stepIndex == other.stepIndex &&
          stepName == other.stepName &&
          isSuccess == other.isSuccess &&
          message == other.message;

  @override
  int get hashCode => Object.hash(stepIndex, stepName, isSuccess, message);

  @override
  String toString() =>
      'Step $stepIndex [$stepName] ${isSuccess ? "OK" : "FAILED"}: $message';
}

/// Auditable trace capturing the full execution lifecycle of a learning plan.
@immutable
class ExecutionAuditTrail {
  /// Unique identifier of this execution trace.
  final String traceId;

  /// Normalized target learner identifier.
  final String learnerId;

  /// Normalized target examination identifier.
  final String examId;

  /// Sequential list of audit steps recorded during execution.
  final List<ExecutionAuditStep> steps;

  /// UTC timestamp when execution began.
  final DateTime startedAt;

  /// UTC timestamp when execution completed or terminated.
  final DateTime completedAt;

  ExecutionAuditTrail({
    required String traceId,
    required String learnerId,
    required String examId,
    required List<ExecutionAuditStep> steps,
    required DateTime startedAt,
    required DateTime completedAt,
  })  : traceId = traceId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        steps = List<ExecutionAuditStep>.unmodifiable(steps),
        startedAt = startedAt.toUtc(),
        completedAt = completedAt.toUtc() {
    if (this.traceId.isEmpty) {
      throw ArgumentError('traceId cannot be empty for ExecutionAuditTrail');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError('learnerId cannot be empty for ExecutionAuditTrail');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty for ExecutionAuditTrail');
    }
  }

  /// Total elapsed execution duration in milliseconds.
  int get durationMs => completedAt.difference(startedAt).inMilliseconds;

  /// Whether all recorded steps were successful.
  bool get allStepsSuccessful => steps.every((s) => s.isSuccess);

  Map<String, dynamic> toJson() => {
        'traceId': traceId,
        'learnerId': learnerId,
        'examId': examId,
        'steps': steps.map((s) => s.toJson()).toList(),
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
      };

  factory ExecutionAuditTrail.fromJson(Map<String, dynamic> json) =>
      ExecutionAuditTrail(
        traceId: json['traceId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        steps: (json['steps'] as List<dynamic>? ?? const [])
            .map((e) => ExecutionAuditStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
        completedAt: DateTime.parse(json['completedAt'] as String).toUtc(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExecutionAuditTrail &&
          runtimeType == other.runtimeType &&
          traceId == other.traceId &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          steps.length == other.steps.length;

  @override
  int get hashCode => Object.hash(traceId, learnerId, examId, steps.length);

  @override
  String toString() =>
      'ExecutionAuditTrail($traceId, steps: ${steps.length}, duration: ${durationMs}ms)';
}
