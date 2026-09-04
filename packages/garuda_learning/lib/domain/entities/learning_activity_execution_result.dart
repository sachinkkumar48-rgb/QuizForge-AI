/// Learning Activity Execution Result Domain Entity (TITAN-KO-042.0 P42).
///
/// Encapsulates the complete, strongly typed operational result produced by
/// [AdaptiveLearningPlanExecutor] with full execution coordinates, session specs,
/// execution states, diagnostic audit trails, and failure descriptors.
library;

import 'package:meta/meta.dart';

import 'adaptive_decision_policy.dart';
import 'adaptive_learning_decision.dart';
import 'adaptive_practice_session_spec.dart';
import 'adaptive_question_selection_result.dart';
import 'execution_audit_trail.dart';
import 'learning_activity_execution_status.dart';
import 'practice_execution_state.dart';
import 'remedial_lesson.dart';
import 'session_checkpoint.dart';

/// Comprehensive operational outcome of executing a learning plan.
@immutable
class LearningActivityExecutionResult {
  /// Unique request identifier from the triggering request.
  final String requestId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Triggering continuation plan identifier.
  final String planId;

  /// Triggering learning decision identifier.
  final String decisionId;

  /// Pedagogical activity type executed.
  final LearningDecisionType activityType;

  /// Operational execution status.
  final LearningActivityExecutionStatus status;

  /// Learning coordinates targeted by this execution.
  final LearningTarget target;

  /// Authoritative state revision at plan formulation time.
  final int sourceRevision;

  /// Authoritative state revision at execution dispatch time.
  final int executionRevision;

  /// Orchestrated practice session specification, if a session was created or resumed.
  final AdaptivePracticeSessionSpec? sessionSpec;

  /// Transient runtime practice execution state, if session was started or resumed.
  final PracticeExecutionState? executionState;

  /// Active or created session checkpoint snapshot.
  final SessionCheckpoint? checkpoint;

  /// Attached remedial lesson, if activity type is remediation.
  final RemedialLesson? remedialLesson;

  /// Question selection result backing this session, if selection occurred.
  final AdaptiveQuestionSelectionResult? selectionResult;

  /// Diagnostic audit trail recording each execution step.
  final ExecutionAuditTrail auditTrail;

  /// Structured error details if execution failed.
  final PlanExecutionError? error;

  /// UTC timestamp when execution concluded.
  final DateTime executedAt;

  /// Extensible result metadata.
  final Map<String, dynamic> metadata;

  LearningActivityExecutionResult({
    required String requestId,
    required String learnerId,
    required String examId,
    required String planId,
    required String decisionId,
    required this.activityType,
    required this.status,
    required this.target,
    required this.sourceRevision,
    required this.executionRevision,
    this.sessionSpec,
    this.executionState,
    this.checkpoint,
    this.remedialLesson,
    this.selectionResult,
    required this.auditTrail,
    this.error,
    required DateTime executedAt,
    Map<String, dynamic>? metadata,
  })  : requestId = requestId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        planId = planId.trim(),
        decisionId = decisionId.trim(),
        executedAt = executedAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (this.requestId.isEmpty) {
      throw ArgumentError(
          'requestId cannot be empty for LearningActivityExecutionResult');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for LearningActivityExecutionResult');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError(
          'examId cannot be empty for LearningActivityExecutionResult');
    }
    if (this.planId.isEmpty) {
      throw ArgumentError(
          'planId cannot be empty for LearningActivityExecutionResult');
    }
    if (this.decisionId.isEmpty) {
      throw ArgumentError(
          'decisionId cannot be empty for LearningActivityExecutionResult');
    }
  }

  /// Factory creating a successful execution result for a newly started session.
  factory LearningActivityExecutionResult.success({
    required String requestId,
    required String learnerId,
    required String examId,
    required String planId,
    required String decisionId,
    required LearningDecisionType activityType,
    required LearningTarget target,
    required int sourceRevision,
    required int executionRevision,
    required AdaptivePracticeSessionSpec sessionSpec,
    required PracticeExecutionState executionState,
    SessionCheckpoint? checkpoint,
    RemedialLesson? remedialLesson,
    AdaptiveQuestionSelectionResult? selectionResult,
    required ExecutionAuditTrail auditTrail,
    required DateTime executedAt,
    Map<String, dynamic>? metadata,
  }) =>
      LearningActivityExecutionResult(
        requestId: requestId,
        learnerId: learnerId,
        examId: examId,
        planId: planId,
        decisionId: decisionId,
        activityType: activityType,
        status: LearningActivityExecutionStatus.success,
        target: target,
        sourceRevision: sourceRevision,
        executionRevision: executionRevision,
        sessionSpec: sessionSpec,
        executionState: executionState,
        checkpoint: checkpoint,
        remedialLesson: remedialLesson,
        selectionResult: selectionResult,
        auditTrail: auditTrail,
        executedAt: executedAt,
        metadata: metadata,
      );

  /// Factory creating a resumed execution result for an existing session.
  factory LearningActivityExecutionResult.resumed({
    required String requestId,
    required String learnerId,
    required String examId,
    required String planId,
    required String decisionId,
    required LearningTarget target,
    required int sourceRevision,
    required int executionRevision,
    required AdaptivePracticeSessionSpec sessionSpec,
    required PracticeExecutionState executionState,
    required SessionCheckpoint checkpoint,
    required ExecutionAuditTrail auditTrail,
    required DateTime executedAt,
    Map<String, dynamic>? metadata,
  }) =>
      LearningActivityExecutionResult(
        requestId: requestId,
        learnerId: learnerId,
        examId: examId,
        planId: planId,
        decisionId: decisionId,
        activityType: LearningDecisionType.continuation,
        status: LearningActivityExecutionStatus.resumed,
        target: target,
        sourceRevision: sourceRevision,
        executionRevision: executionRevision,
        sessionSpec: sessionSpec,
        executionState: executionState,
        checkpoint: checkpoint,
        auditTrail: auditTrail,
        executedAt: executedAt,
        metadata: metadata,
      );

  /// Factory creating a completed execution result when syllabus is finished.
  factory LearningActivityExecutionResult.completed({
    required String requestId,
    required String learnerId,
    required String examId,
    required String planId,
    required String decisionId,
    required LearningTarget target,
    required int sourceRevision,
    required int executionRevision,
    required ExecutionAuditTrail auditTrail,
    required DateTime executedAt,
    Map<String, dynamic>? metadata,
  }) =>
      LearningActivityExecutionResult(
        requestId: requestId,
        learnerId: learnerId,
        examId: examId,
        planId: planId,
        decisionId: decisionId,
        activityType: LearningDecisionType.complete,
        status: LearningActivityExecutionStatus.completed,
        target: target,
        sourceRevision: sourceRevision,
        executionRevision: executionRevision,
        auditTrail: auditTrail,
        executedAt: executedAt,
        metadata: metadata,
      );

  /// Factory creating a failure execution result.
  factory LearningActivityExecutionResult.failure({
    required String requestId,
    required String learnerId,
    required String examId,
    required String planId,
    required String decisionId,
    required LearningDecisionType activityType,
    required LearningActivityExecutionStatus status,
    required LearningTarget target,
    required int sourceRevision,
    required int executionRevision,
    required PlanExecutionError error,
    required ExecutionAuditTrail auditTrail,
    required DateTime executedAt,
    Map<String, dynamic>? metadata,
  }) =>
      LearningActivityExecutionResult(
        requestId: requestId,
        learnerId: learnerId,
        examId: examId,
        planId: planId,
        decisionId: decisionId,
        activityType: activityType,
        status: status,
        target: target,
        sourceRevision: sourceRevision,
        executionRevision: executionRevision,
        error: error,
        auditTrail: auditTrail,
        executedAt: executedAt,
        metadata: metadata,
      );

  /// Whether this execution was successful.
  bool get isSuccess => status.isSuccess;

  /// Whether an active session was resumed.
  bool get isResumed => status == LearningActivityExecutionStatus.resumed;

  /// Whether the curriculum is complete with no active session needed.
  bool get isCompleted => status == LearningActivityExecutionStatus.completed;

  /// Whether an underlying session specification was generated or resumed.
  bool get hasSession => sessionSpec != null;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'learnerId': learnerId,
        'examId': examId,
        'planId': planId,
        'decisionId': decisionId,
        'activityType': activityType.name,
        'status': status.name,
        'target': target.toJson(),
        'sourceRevision': sourceRevision,
        'executionRevision': executionRevision,
        if (sessionSpec != null) 'sessionSpec': sessionSpec!.toJson(),
        if (executionState != null) 'executionState': executionState!.toJson(),
        if (checkpoint != null) 'checkpoint': checkpoint!.toJson(),
        if (remedialLesson != null) 'remedialLesson': remedialLesson!.toJson(),
        if (selectionResult != null)
          'selectionSummary': {
            'selectedCount': selectionResult!.selectedCount,
            'eligibleCount': selectionResult!.eligibleCount,
            'isConstraintLimited': selectionResult!.isConstraintLimited,
          },
        'auditTrail': auditTrail.toJson(),
        if (error != null) 'error': error!.toJson(),
        'executedAt': executedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory LearningActivityExecutionResult.fromJson(Map<String, dynamic> json) =>
      LearningActivityExecutionResult(
        requestId: json['requestId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        planId: json['planId'] as String? ?? '',
        decisionId: json['decisionId'] as String? ?? '',
        activityType: LearningDecisionType.values.firstWhere(
          (t) => t.name == json['activityType'],
          orElse: () => LearningDecisionType.complete,
        ),
        status: LearningActivityExecutionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => LearningActivityExecutionStatus.executionFailed,
        ),
        target: LearningTarget.fromJson(json['target'] as Map<String, dynamic>),
        sourceRevision: json['sourceRevision'] as int? ?? 1,
        executionRevision: json['executionRevision'] as int? ?? 1,
        sessionSpec: json['sessionSpec'] != null
            ? AdaptivePracticeSessionSpec.fromJson(
                json['sessionSpec'] as Map<String, dynamic>)
            : null,
        executionState: json['executionState'] != null
            ? PracticeExecutionState.fromJson(
                json['executionState'] as Map<String, dynamic>)
            : null,
        checkpoint: json['checkpoint'] != null
            ? SessionCheckpoint.fromJson(
                json['checkpoint'] as Map<String, dynamic>)
            : null,
        remedialLesson: json['remedialLesson'] != null
            ? RemedialLesson.fromJson(
                json['remedialLesson'] as Map<String, dynamic>)
            : null,
        auditTrail: ExecutionAuditTrail.fromJson(
            json['auditTrail'] as Map<String, dynamic>),
        error: json['error'] != null
            ? PlanExecutionError.fromJson(json['error'] as Map<String, dynamic>)
            : null,
        executedAt: DateTime.parse(json['executedAt'] as String).toUtc(),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningActivityExecutionResult &&
          runtimeType == other.runtimeType &&
          requestId == other.requestId &&
          planId == other.planId &&
          status == other.status &&
          executionRevision == other.executionRevision;

  @override
  int get hashCode => Object.hash(requestId, planId, status, executionRevision);

  @override
  String toString() =>
      'LearningActivityExecutionResult($requestId, status=${status.name}, act=${activityType.name}, target=${target.targetId})';
}
