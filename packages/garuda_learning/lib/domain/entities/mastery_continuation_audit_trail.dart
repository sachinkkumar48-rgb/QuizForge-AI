/// Mastery Continuation Audit Trail (TITAN-KO-044.0 P44).
///
/// Provides diagnostic traceability and auditable decision logging across all
/// stages of the objective mastery evaluation and adaptive continuation cycle.
library;

import 'package:meta/meta.dart';

/// Single diagnostic step in the mastery continuation evaluation.
@immutable
class MasteryContinuationAuditStep {
  /// Name or category of this evaluation step.
  final String step;

  /// UTC timestamp of execution.
  final DateTime timestamp;

  /// Whether the step executed successfully.
  final bool isSuccess;

  /// Diagnostic metadata and contextual values inspected during the step.
  final Map<String, dynamic> details;

  MasteryContinuationAuditStep({
    required this.step,
    required DateTime timestamp,
    this.isSuccess = true,
    Map<String, dynamic>? details,
  })  : timestamp = timestamp.toUtc(),
        details = Map<String, dynamic>.unmodifiable(
            details ?? const <String, dynamic>{});

  Map<String, dynamic> toJson() => {
        'step': step,
        'timestamp': timestamp.toIso8601String(),
        'isSuccess': isSuccess,
        if (details.isNotEmpty) 'details': details,
      };

  factory MasteryContinuationAuditStep.fromJson(Map<String, dynamic> json) {
    return MasteryContinuationAuditStep(
      step: json['step'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String).toUtc()
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      isSuccess: json['isSuccess'] as bool? ?? true,
      details: json['details'] != null
          ? Map<String, dynamic>.from(json['details'] as Map)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasteryContinuationAuditStep &&
          runtimeType == other.runtimeType &&
          step == other.step &&
          timestamp == other.timestamp &&
          isSuccess == other.isSuccess;

  @override
  int get hashCode => Object.hash(step, timestamp, isSuccess);

  @override
  String toString() =>
      'MasteryContinuationAuditStep($step, success: $isSuccess, details: $details)';
}

/// Immutable collection of diagnostic steps representing the end-to-end evaluation trace.
@immutable
class MasteryContinuationAuditTrail {
  /// Ordered list of audit steps.
  final List<MasteryContinuationAuditStep> steps;

  MasteryContinuationAuditTrail({
    List<MasteryContinuationAuditStep>? steps,
  }) : steps = steps != null
            ? List<MasteryContinuationAuditStep>.unmodifiable(steps)
            : const [];

  const MasteryContinuationAuditTrail.empty() : steps = const [];

  /// Returns a new trail with a successful step appended.
  MasteryContinuationAuditTrail logSuccess(
    String step, {
    Map<String, dynamic>? details,
    DateTime? timestamp,
  }) {
    final newStep = MasteryContinuationAuditStep(
      step: step,
      timestamp:
          timestamp ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      isSuccess: true,
      details: details,
    );
    return MasteryContinuationAuditTrail(steps: [...steps, newStep]);
  }

  /// Returns a new trail with a failed step appended.
  MasteryContinuationAuditTrail logFailure(
    String step, {
    Map<String, dynamic>? details,
    DateTime? timestamp,
  }) {
    final newStep = MasteryContinuationAuditStep(
      step: step,
      timestamp:
          timestamp ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      isSuccess: false,
      details: details,
    );
    return MasteryContinuationAuditTrail(steps: [...steps, newStep]);
  }

  List<Map<String, dynamic>> toJson() => steps.map((s) => s.toJson()).toList();

  factory MasteryContinuationAuditTrail.fromJson(List<dynamic> jsonList) {
    return MasteryContinuationAuditTrail(
      steps: jsonList
          .map((item) => MasteryContinuationAuditStep.fromJson(
              item as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasteryContinuationAuditTrail &&
          runtimeType == other.runtimeType &&
          steps.length == other.steps.length;

  @override
  int get hashCode => steps.length.hashCode;

  @override
  String toString() => 'MasteryContinuationAuditTrail(${steps.length} steps)';
}
