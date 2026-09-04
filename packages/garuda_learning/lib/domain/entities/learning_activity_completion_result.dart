/// Learning Activity Completion Result Domain Entity (TITAN-KO-043.0 P43).
///
/// Encapsulates the comprehensive, immutable outcome of an activity completion workflow,
/// including normalized learning metrics, consolidated performance evidence,
/// resulting authoritative state transitions, and diagnostic audit steps.
library;

import 'package:meta/meta.dart';

import 'activity_completion_audit_trail.dart';
import 'activity_outcome_evidence.dart';
import 'authoritative_learner_state.dart';
import 'learning_activity_completion_status.dart';
import 'learning_activity_outcome.dart';
import 'practice_outcome_consolidation.dart';
import 'reconciliation_pipeline_result.dart';

/// Comprehensive operational outcome of finalizing a learning activity.
@immutable
class LearningActivityCompletionResult {
  /// Unique request identifier from the triggering completion request.
  final String requestId;

  /// Identifier of the finalized learning activity.
  final String activityId;

  /// Operational status of the completion process.
  final LearningActivityCompletionStatus status;

  /// Normalized, activity-independent learning outcome, if completion was successful or replayed.
  final LearningActivityOutcome? outcome;

  /// Traceable evidence bundle generated during completion.
  final ActivityOutcomeEvidence? evidence;

  /// Downstream P36 consolidated practice outcome, if practice was consolidated.
  final ConsolidatedPracticeOutcome? consolidatedOutcome;

  /// Result of P38/P39 reconciliation and persistence pipeline.
  final ReconciliationPipelineResult? reconciliationResult;

  /// Updated authoritative learner state snapshot with monotonic revision increment.
  final AuthoritativeLearnerState? resultingAuthoritativeState;

  /// Diagnostic chronological audit trail of all execution steps.
  final ActivityCompletionAuditTrail auditTrail;

  /// Structured error details if completion failed.
  final ActivityCompletionError? error;

  /// UTC timestamp when completion workflow concluded.
  final DateTime completedAt;

  /// Extensible result metadata.
  final Map<String, dynamic> metadata;

  LearningActivityCompletionResult({
    required String requestId,
    required String activityId,
    required this.status,
    this.outcome,
    this.evidence,
    this.consolidatedOutcome,
    this.reconciliationResult,
    this.resultingAuthoritativeState,
    required this.auditTrail,
    this.error,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  })  : requestId = requestId.trim(),
        activityId = activityId.trim(),
        completedAt = (completedAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (this.requestId.isEmpty) {
      throw ArgumentError(
          'requestId cannot be empty for LearningActivityCompletionResult');
    }
    if (this.activityId.isEmpty) {
      throw ArgumentError(
          'activityId cannot be empty for LearningActivityCompletionResult');
    }
  }

  /// Whether completion was successful (fresh completion or idempotent replay).
  bool get isSuccess => status.isSuccess;

  /// Whether completion was an idempotent replay of an already completed activity.
  bool get isAlreadyCompleted => status.isAlreadyCompleted;

  /// Whether authoritative learner state advanced its revision during completion.
  bool get hasStateAdvanced =>
      resultingAuthoritativeState != null &&
      reconciliationResult != null &&
      reconciliationResult!.isSuccess &&
      !reconciliationResult!.isIdempotentReplay;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'activityId': activityId,
        'status': status.name,
        if (outcome != null) 'outcome': outcome!.toJson(),
        if (evidence != null) 'evidence': evidence!.toJson(),
        if (consolidatedOutcome != null)
          'consolidatedOutcome': consolidatedOutcome!.toJson(),
        if (reconciliationResult != null)
          'reconciliationSummary': {
            'isSuccess': reconciliationResult!.isSuccess,
            'isIdempotentReplay': reconciliationResult!.isIdempotentReplay,
            'decision': reconciliationResult!.decision.name,
            'message': reconciliationResult!.message,
            'resultingRevision': reconciliationResult!.resultingRevision,
          },
        if (resultingAuthoritativeState != null)
          'resultingAuthoritativeState': resultingAuthoritativeState!.toJson(),
        'auditTrail': auditTrail.toJson(),
        if (error != null) 'error': error!.toJson(),
        'completedAt': completedAt.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory LearningActivityCompletionResult.fromJson(
          Map<String, dynamic> json) =>
      LearningActivityCompletionResult(
        requestId: json['requestId'] as String? ?? '',
        activityId: json['activityId'] as String? ?? '',
        status: LearningActivityCompletionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => LearningActivityCompletionStatus.executionFailed,
        ),
        outcome: json['outcome'] != null
            ? LearningActivityOutcome.fromJson(
                json['outcome'] as Map<String, dynamic>)
            : null,
        evidence: json['evidence'] != null
            ? ActivityOutcomeEvidence.fromJson(
                json['evidence'] as Map<String, dynamic>)
            : null,
        consolidatedOutcome: json['consolidatedOutcome'] != null
            ? ConsolidatedPracticeOutcome.fromJson(
                json['consolidatedOutcome'] as Map<String, dynamic>)
            : null,
        reconciliationResult: null,
        resultingAuthoritativeState: json['resultingAuthoritativeState'] != null
            ? AuthoritativeLearnerState.fromJson(
                json['resultingAuthoritativeState'] as Map<String, dynamic>)
            : null,
        auditTrail: json['auditTrail'] != null
            ? ActivityCompletionAuditTrail.fromJson(
                json['auditTrail'] as List<dynamic>)
            : const ActivityCompletionAuditTrail.empty(),
        error: json['error'] != null
            ? ActivityCompletionError.fromJson(
                json['error'] as Map<String, dynamic>)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String).toUtc()
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  String toString() =>
      'LearningActivityCompletionResult($requestId, activity=$activityId, status=${status.name}, success=$isSuccess)';
}
