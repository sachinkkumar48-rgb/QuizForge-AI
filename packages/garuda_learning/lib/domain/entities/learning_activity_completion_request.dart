/// Learning Activity Completion Request Domain Entity (TITAN-KO-043.0 P43).
///
/// Encapsulates the complete, immutable request bundle to finalize a learning activity,
/// normalize its outcome, construct evidence, and reconcile learner state.
library;

import 'package:meta/meta.dart';

import 'adaptive_decision_policy.dart';
import 'attempt_result.dart';
import 'authoritative_learner_state.dart';
import 'practice_execution_state.dart';
import 'question_attempt.dart';

/// Request payload to finalize an executed learning activity.
@immutable
class LearningActivityCompletionRequest {
  /// Unique request identifier.
  final String requestId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Unique identifier of the executed activity.
  final String activityId;

  /// Pedagogical activity type executed.
  final LearningDecisionType activityType;

  /// Identifier of the triggering continuation plan.
  final String planId;

  /// Authoritative revision of the continuation plan at formulation time.
  final int planRevision;

  /// Associated practice session ID, if activity was session-backed.
  final String? sessionId;

  /// Optional caller-supplied idempotency key.
  final String? idempotencyKey;

  /// Timestamp when the activity was started.
  final DateTime? startedAt;

  /// UTC timestamp when activity completion was requested/concluded.
  final DateTime completedAt;

  /// Active or finished runtime execution state, if available.
  final PracticeExecutionState? executionState;

  /// Explicit question attempts submitted during the activity, if not in [executionState].
  final List<QuestionAttempt>? attempts;

  /// Explicit evaluated attempt results, if not in [executionState].
  final List<AttemptResult>? attemptResults;

  /// Remedial lesson ID, if this was a remediation activity.
  final String? remedialLessonId;

  /// Whether the remedial lesson was verified as completed.
  final bool? remedialLessonCompleted;

  /// Authoritative learner state snapshot at request time, if pre-resolved.
  final AuthoritativeLearnerState? currentState;

  /// Extensible request metadata.
  final Map<String, dynamic> metadata;

  LearningActivityCompletionRequest({
    required String requestId,
    required String learnerId,
    required String examId,
    required String activityId,
    required this.activityType,
    required String planId,
    required this.planRevision,
    this.sessionId,
    this.idempotencyKey,
    this.startedAt,
    DateTime? completedAt,
    this.executionState,
    List<QuestionAttempt>? attempts,
    List<AttemptResult>? attemptResults,
    this.remedialLessonId,
    this.remedialLessonCompleted,
    this.currentState,
    Map<String, dynamic>? metadata,
  })  : requestId = requestId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        activityId = activityId.trim(),
        planId = planId.trim(),
        completedAt = (completedAt ?? DateTime.now()).toUtc(),
        attempts = attempts != null ? List.unmodifiable(attempts) : null,
        attemptResults =
            attemptResults != null ? List.unmodifiable(attemptResults) : null,
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (this.requestId.isEmpty) {
      throw ArgumentError(
          'requestId cannot be empty for LearningActivityCompletionRequest');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for LearningActivityCompletionRequest');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError(
          'examId cannot be empty for LearningActivityCompletionRequest');
    }
    if (this.activityId.isEmpty) {
      throw ArgumentError(
          'activityId cannot be empty for LearningActivityCompletionRequest');
    }
    if (this.planId.isEmpty) {
      throw ArgumentError(
          'planId cannot be empty for LearningActivityCompletionRequest');
    }
    if (planRevision < 0) {
      throw ArgumentError(
          'planRevision cannot be negative for LearningActivityCompletionRequest');
    }
  }

  /// Resolved deterministic idempotency key for this completion request.
  String get resolvedIdempotencyKey {
    final cleanKey = idempotencyKey?.trim();
    if (cleanKey != null && cleanKey.isNotEmpty) {
      return cleanKey;
    }
    final cleanSession = sessionId?.trim() ?? 'nosess';
    return 'comp_${learnerId}_${examId}_${activityId}_$cleanSession';
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'learnerId': learnerId,
        'examId': examId,
        'activityId': activityId,
        'activityType': activityType.name,
        'planId': planId,
        'planRevision': planRevision,
        if (sessionId != null) 'sessionId': sessionId,
        if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        if (executionState != null) 'executionState': executionState!.toJson(),
        if (attempts != null)
          'attempts': attempts!.map((a) => a.toJson()).toList(),
        if (attemptResults != null)
          'attemptResults': attemptResults!.map((r) => r.toJson()).toList(),
        if (remedialLessonId != null) 'remedialLessonId': remedialLessonId,
        if (remedialLessonCompleted != null)
          'remedialLessonCompleted': remedialLessonCompleted,
        if (currentState != null) 'currentState': currentState!.toJson(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory LearningActivityCompletionRequest.fromJson(
          Map<String, dynamic> json) =>
      LearningActivityCompletionRequest(
        requestId: json['requestId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        activityId: json['activityId'] as String? ?? '',
        activityType: LearningDecisionType.values.firstWhere(
          (t) => t.name == json['activityType'],
          orElse: () => LearningDecisionType.advancement,
        ),
        planId: json['planId'] as String? ?? '',
        planRevision: (json['planRevision'] as num?)?.toInt() ?? 0,
        sessionId: json['sessionId'] as String?,
        idempotencyKey: json['idempotencyKey'] as String?,
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String).toUtc()
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String).toUtc()
            : null,
        executionState: json['executionState'] != null
            ? PracticeExecutionState.fromJson(
                json['executionState'] as Map<String, dynamic>)
            : null,
        attempts: (json['attempts'] as List<dynamic>?)
            ?.map((item) =>
                QuestionAttempt.fromJson(item as Map<String, dynamic>))
            .toList(),
        attemptResults: (json['attemptResults'] as List<dynamic>?)
            ?.map(
                (item) => AttemptResult.fromJson(item as Map<String, dynamic>))
            .toList(),
        remedialLessonId: json['remedialLessonId'] as String?,
        remedialLessonCompleted: json['remedialLessonCompleted'] as bool?,
        currentState: json['currentState'] != null
            ? AuthoritativeLearnerState.fromJson(
                json['currentState'] as Map<String, dynamic>)
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  String toString() =>
      'LearningActivityCompletionRequest($requestId, activity=$activityId, type=${activityType.name}, rev=$planRevision)';
}
