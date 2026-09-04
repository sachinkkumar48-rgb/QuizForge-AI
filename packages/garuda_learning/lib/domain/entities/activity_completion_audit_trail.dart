/// Activity Completion Audit Trail Domain Entities (TITAN-KO-043.0 P43).
///
/// Encapsulates chronological diagnostic trace records generated during
/// the activity completion, outcome normalization, and state reconciliation lifecycle.
library;

import 'package:meta/meta.dart';

/// Single discrete step within an activity completion workflow.
@immutable
class ActivityCompletionAuditStep {
  /// Name or category of the execution stage.
  final String stepName;

  /// Whether the step completed successfully.
  final bool isSuccess;

  /// UTC timestamp when the step executed.
  final DateTime timestamp;

  /// Contextual metrics, identifiers, or failure reasons.
  final Map<String, dynamic> details;

  ActivityCompletionAuditStep({
    required String stepName,
    required this.isSuccess,
    DateTime? timestamp,
    Map<String, dynamic>? details,
  })  : stepName = stepName.trim(),
        timestamp = (timestamp ?? DateTime.now()).toUtc(),
        details = Map<String, dynamic>.unmodifiable(
            details ?? const <String, dynamic>{}) {
    if (this.stepName.isEmpty) {
      throw ArgumentError(
          'stepName cannot be empty for ActivityCompletionAuditStep');
    }
  }

  Map<String, dynamic> toJson() => {
        'stepName': stepName,
        'isSuccess': isSuccess,
        'timestamp': timestamp.toIso8601String(),
        if (details.isNotEmpty) 'details': details,
      };

  factory ActivityCompletionAuditStep.fromJson(Map<String, dynamic> json) =>
      ActivityCompletionAuditStep(
        stepName: json['stepName'] as String? ?? '',
        isSuccess: json['isSuccess'] as bool? ?? false,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : null,
        details: json['details'] as Map<String, dynamic>?,
      );

  @override
  String toString() =>
      'ActivityCompletionAuditStep($stepName, success=$isSuccess, ts=$timestamp)';
}

/// Ordered sequence of diagnostic audit steps recording the completion lifecycle.
@immutable
class ActivityCompletionAuditTrail {
  /// Ordered list of audit steps from start to finish.
  final List<ActivityCompletionAuditStep> steps;

  ActivityCompletionAuditTrail({
    required List<ActivityCompletionAuditStep> steps,
  }) : steps = List.unmodifiable(steps);

  /// Creates an empty audit trail.
  const ActivityCompletionAuditTrail.empty() : steps = const [];

  /// Returns a new audit trail with an appended step.
  ActivityCompletionAuditTrail append(ActivityCompletionAuditStep step) {
    return ActivityCompletionAuditTrail(
      steps: [...steps, step],
    );
  }

  /// Appends a successful step.
  ActivityCompletionAuditTrail logSuccess(
    String stepName, {
    Map<String, dynamic>? details,
    DateTime? timestamp,
  }) {
    return append(
      ActivityCompletionAuditStep(
        stepName: stepName,
        isSuccess: true,
        details: details,
        timestamp: timestamp,
      ),
    );
  }

  /// Appends a failed step.
  ActivityCompletionAuditTrail logFailure(
    String stepName, {
    Map<String, dynamic>? details,
    DateTime? timestamp,
  }) {
    return append(
      ActivityCompletionAuditStep(
        stepName: stepName,
        isSuccess: false,
        details: details,
        timestamp: timestamp,
      ),
    );
  }

  /// Whether all steps recorded completed successfully.
  bool get allStepsSuccessful =>
      steps.isNotEmpty && steps.every((s) => s.isSuccess);

  /// Whether any step failed.
  bool get hasFailures => steps.any((s) => !s.isSuccess);

  /// Finds the first recorded step matching [stepName], or null.
  ActivityCompletionAuditStep? findStep(String stepName) {
    for (final s in steps) {
      if (s.stepName == stepName) return s;
    }
    return null;
  }

  List<Map<String, dynamic>> toJson() => steps.map((s) => s.toJson()).toList();

  factory ActivityCompletionAuditTrail.fromJson(List<dynamic> jsonList) =>
      ActivityCompletionAuditTrail(
        steps: jsonList
            .map((item) => ActivityCompletionAuditStep.fromJson(
                item as Map<String, dynamic>))
            .toList(),
      );

  @override
  String toString() =>
      'ActivityCompletionAuditTrail(steps=${steps.length}, allSuccess=$allStepsSuccessful)';
}
