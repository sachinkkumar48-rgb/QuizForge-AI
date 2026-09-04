/// Learning Continuation Plan Domain Entity (TITAN-KO-041.0 P41).
///
/// Encapsulates the actionable execution contract derived from an
/// [AdaptiveLearningDecision], providing downstream configuration handoffs
/// for P33 question selection, P34 session orchestration, and P35 practice execution.
library;

import 'package:meta/meta.dart';

import 'adaptive_decision_policy.dart';
import 'adaptive_learning_decision.dart';
import 'adaptive_practice_session_config.dart';
import 'adaptive_question_selection_config.dart';
import 'authoritative_learner_state.dart';
import 'remedial_lesson.dart';
import 'resumable_learning_session.dart';

/// Actionable execution plan derived from an [AdaptiveLearningDecision].
@immutable
class LearningContinuationPlan {
  /// Unique identifier of this continuation plan.
  final String planId;

  /// Underlying pedagogical decision that formulated this plan.
  final AdaptiveLearningDecision decision;

  /// Target learning coordinates.
  final LearningTarget target;

  /// Explicit question selection configuration for P33 selection service, if pre-computed.
  final AdaptiveQuestionSelectionConfig? selectionConfig;

  /// Explicit session orchestration configuration for P34 orchestrator, if pre-computed.
  final AdaptivePracticeSessionConfig? sessionConfig;

  /// Attached P25 remedial lesson if the decision type is remediation.
  final RemedialLesson? remedialLesson;

  /// Attached active session snapshot if the decision type is continuation.
  final ResumableLearningSession? resumableSession;

  /// Timestamp when the plan was formulated (UTC).
  final DateTime createdAt;

  /// Extensible plan execution metadata.
  final Map<String, dynamic> metadata;

  LearningContinuationPlan({
    required String planId,
    required this.decision,
    LearningTarget? target,
    this.selectionConfig,
    this.sessionConfig,
    this.remedialLesson,
    this.resumableSession,
    required DateTime createdAt,
    Map<String, dynamic>? metadata,
  })  : planId = planId.trim(),
        target = target ?? decision.target,
        createdAt = createdAt.toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (this.planId.isEmpty) {
      throw ArgumentError(
          'planId cannot be empty for LearningContinuationPlan');
    }
  }

  /// Whether this continuation plan has become stale relative to [currentState].
  ///
  /// Forwards directly to the underlying decision's revision validation.
  bool isStale(AuthoritativeLearnerState currentState) =>
      decision.isStale(currentState);

  /// Generates or resolves the [AdaptiveQuestionSelectionConfig] (P33) required to
  /// select questions matching this continuation plan.
  AdaptiveQuestionSelectionConfig toAdaptiveQuestionSelectionConfig() {
    if (selectionConfig != null) {
      return selectionConfig!;
    }

    final objectiveId = target.objectiveId;
    final scopedObjectives =
        objectiveId != null && objectiveId.isNotEmpty ? [objectiveId] : null;
    final topic = target.topic;
    final scopedTopics = topic != null && topic.isNotEmpty ? [topic] : null;
    final subject = target.subject;
    final scopedSubjects =
        subject != null && subject.isNotEmpty ? [subject] : null;

    switch (decision.type) {
      case LearningDecisionType.continuation:
        return AdaptiveQuestionSelectionConfig(
          examId: decision.examId,
          targetQuestionCount: 5,
          scopedObjectiveIds: scopedObjectives,
          scopedTopics: scopedTopics,
          scopedSubjects: scopedSubjects,
        );

      case LearningDecisionType.remediation:
        return AdaptiveQuestionSelectionConfig(
          examId: decision.examId,
          targetQuestionCount: 5,
          scopedObjectiveIds: scopedObjectives,
          scopedTopics: scopedTopics,
          scopedSubjects: scopedSubjects,
          weaknessWeight: 0.50,
          difficultyWeight: 0.10,
          qualityWeight: 0.20,
          freshnessWeight: 0.10,
          pyqPriorityWeight: 0.10,
        );

      case LearningDecisionType.review:
        return AdaptiveQuestionSelectionConfig(
          examId: decision.examId,
          targetQuestionCount: 5,
          scopedObjectiveIds: scopedObjectives,
          scopedTopics: scopedTopics,
          scopedSubjects: scopedSubjects,
          freshnessWeight: 0.30,
          pyqPriorityWeight: 0.30,
          weaknessWeight: 0.20,
          difficultyWeight: 0.10,
          qualityWeight: 0.10,
        );

      case LearningDecisionType.reinforcement:
        return AdaptiveQuestionSelectionConfig(
          examId: decision.examId,
          targetQuestionCount: 5,
          scopedObjectiveIds: scopedObjectives,
          scopedTopics: scopedTopics,
          scopedSubjects: scopedSubjects,
          weaknessWeight: 0.35,
          pyqPriorityWeight: 0.25,
          qualityWeight: 0.20,
          freshnessWeight: 0.10,
          difficultyWeight: 0.10,
        );

      case LearningDecisionType.advancement:
        return AdaptiveQuestionSelectionConfig(
          examId: decision.examId,
          targetQuestionCount: 5,
          scopedObjectiveIds: scopedObjectives,
          scopedTopics: scopedTopics,
          scopedSubjects: scopedSubjects,
          freshnessWeight: 0.25,
          pyqPriorityWeight: 0.25,
          qualityWeight: 0.25,
          difficultyWeight: 0.15,
          weaknessWeight: 0.10,
        );

      case LearningDecisionType.complete:
        return AdaptiveQuestionSelectionConfig(
          examId: decision.examId,
          targetQuestionCount: 1,
        );
    }
  }

  /// Generates or resolves the [AdaptivePracticeSessionConfig] (P34) required to
  /// orchestrate a practice session matching this continuation plan.
  AdaptivePracticeSessionConfig toAdaptivePracticeSessionConfig() {
    if (sessionConfig != null) {
      return sessionConfig!;
    }

    final mode = switch (decision.type) {
      LearningDecisionType.continuation => PracticeSessionMode.standard,
      LearningDecisionType.remediation => PracticeSessionMode.remedialPractice,
      LearningDecisionType.review => PracticeSessionMode.mixedRevision,
      LearningDecisionType.reinforcement => PracticeSessionMode.weaknessFocused,
      LearningDecisionType.advancement => PracticeSessionMode.standard,
      LearningDecisionType.complete => PracticeSessionMode.standard,
    };

    return AdaptivePracticeSessionConfig(
      examId: decision.examId,
      learnerId: decision.learnerId,
      sessionMode: mode,
      maxQuestions: decision.type == LearningDecisionType.complete ? 1 : 5,
      sectionSize: 5,
      metadata: {
        'planId': planId,
        'decisionId': decision.decisionId,
        'decisionType': decision.type.name,
        'authoritativeRevision': decision.authoritativeStateRevision,
        if (remedialLesson != null)
          'remedialLessonId': remedialLesson!.lessonId,
        if (resumableSession != null)
          'resumedSessionId': resumableSession!.sessionId,
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'decision': decision.toJson(),
        'target': target.toJson(),
        if (selectionConfig != null)
          'selectionConfig': selectionConfig!.toJson(),
        if (sessionConfig != null) 'sessionConfig': sessionConfig!.toJson(),
        if (remedialLesson != null) 'remedialLesson': remedialLesson!.toJson(),
        if (resumableSession != null)
          'resumableSessionId': resumableSession!.sessionId,
        'createdAt': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  factory LearningContinuationPlan.fromJson(Map<String, dynamic> json) =>
      LearningContinuationPlan(
        planId: json['planId'] as String? ?? '',
        decision: AdaptiveLearningDecision.fromJson(
            json['decision'] as Map<String, dynamic>),
        target: LearningTarget.fromJson(json['target'] as Map<String, dynamic>),
        selectionConfig: json['selectionConfig'] != null
            ? AdaptiveQuestionSelectionConfig.fromJson(
                json['selectionConfig'] as Map<String, dynamic>)
            : null,
        sessionConfig: json['sessionConfig'] != null
            ? AdaptivePracticeSessionConfig.fromJson(
                json['sessionConfig'] as Map<String, dynamic>)
            : null,
        remedialLesson: json['remedialLesson'] != null
            ? RemedialLesson.fromJson(
                json['remedialLesson'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningContinuationPlan &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          decision == other.decision &&
          target == other.target &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(planId, decision, target, createdAt);

  @override
  String toString() =>
      'LearningContinuationPlan($planId, decision: ${decision.type.name}, target: ${target.targetId})';
}
