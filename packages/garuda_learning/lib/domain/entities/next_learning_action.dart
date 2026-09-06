/// Next Learning Action Domain Entity (TITAN-KO-044.0 P44).
///
/// Encapsulates the recommended pedagogical next action derived deterministically
/// from objective-level learning evidence and authoritative learner state.
library;

import 'package:meta/meta.dart';

import 'adaptive_decision_policy.dart';

@immutable
class NextLearningAction {
  /// Pedagogical action category compatible with P41 decision engine.
  final LearningDecisionType actionType;

  /// Urgency / priority level of this action.
  final LearningDecisionPriority priority;

  /// Target learning objective identifier, if action is objective-scoped.
  final String? targetObjectiveId;

  /// Target curriculum topic, if applicable.
  final String? targetTopic;

  /// Bound remedial lesson identifier, if action is remediation.
  final String? remedialLessonId;

  /// Human and machine-readable explanation of why this action was selected.
  final String rationale;

  /// Optional parameters for downstream execution (e.g. question count, session mode).
  final Map<String, dynamic> parameters;

  NextLearningAction({
    required this.actionType,
    required this.priority,
    this.targetObjectiveId,
    this.targetTopic,
    this.remedialLessonId,
    required this.rationale,
    Map<String, dynamic>? parameters,
  }) : parameters = Map<String, dynamic>.unmodifiable(
            parameters ?? const <String, dynamic>{});

  /// Factory for terminal curriculum completion.
  factory NextLearningAction.complete({
    String rationale = 'All objectives mastered and no reviews due.',
  }) =>
      NextLearningAction(
        actionType: LearningDecisionType.complete,
        priority: LearningDecisionPriority.none,
        rationale: rationale,
      );

  /// Factory for targeted remediation.
  factory NextLearningAction.remediation({
    required String objectiveId,
    String? remedialLessonId,
    String? topic,
    required String rationale,
    LearningDecisionPriority priority = LearningDecisionPriority.urgent,
  }) =>
      NextLearningAction(
        actionType: LearningDecisionType.remediation,
        priority: priority,
        targetObjectiveId: objectiveId,
        targetTopic: topic,
        remedialLessonId: remedialLessonId,
        rationale: rationale,
      );

  /// Factory for spaced review.
  factory NextLearningAction.review({
    required String objectiveId,
    String? topic,
    required String rationale,
    LearningDecisionPriority priority = LearningDecisionPriority.high,
  }) =>
      NextLearningAction(
        actionType: LearningDecisionType.review,
        priority: priority,
        targetObjectiveId: objectiveId,
        targetTopic: topic,
        rationale: rationale,
      );

  /// Factory for in-progress reinforcement practice.
  factory NextLearningAction.reinforcement({
    required String objectiveId,
    String? topic,
    required String rationale,
    LearningDecisionPriority priority = LearningDecisionPriority.medium,
  }) =>
      NextLearningAction(
        actionType: LearningDecisionType.reinforcement,
        priority: priority,
        targetObjectiveId: objectiveId,
        targetTopic: topic,
        rationale: rationale,
      );

  /// Factory for syllabus advancement.
  factory NextLearningAction.advancement({
    required String objectiveId,
    String? topic,
    required String rationale,
    LearningDecisionPriority priority = LearningDecisionPriority.low,
  }) =>
      NextLearningAction(
        actionType: LearningDecisionType.advancement,
        priority: priority,
        targetObjectiveId: objectiveId,
        targetTopic: topic,
        rationale: rationale,
      );

  /// Factory for session continuation.
  factory NextLearningAction.continuation({
    required String sessionId,
    int? cursorIndex,
    String? objectiveId,
    required String rationale,
  }) =>
      NextLearningAction(
        actionType: LearningDecisionType.continuation,
        priority: LearningDecisionPriority.urgent,
        targetObjectiveId: objectiveId,
        parameters: {
          'sessionId': sessionId,
          if (cursorIndex != null) 'cursorIndex': cursorIndex,
        },
        rationale: rationale,
      );

  Map<String, dynamic> toJson() => {
        'actionType': actionType.name,
        'priority': priority.name,
        if (targetObjectiveId != null) 'targetObjectiveId': targetObjectiveId,
        if (targetTopic != null) 'targetTopic': targetTopic,
        if (remedialLessonId != null) 'remedialLessonId': remedialLessonId,
        'rationale': rationale,
        if (parameters.isNotEmpty) 'parameters': parameters,
      };

  factory NextLearningAction.fromJson(Map<String, dynamic> json) {
    return NextLearningAction(
      actionType: LearningDecisionType.values.firstWhere(
        (e) => e.name == json['actionType'],
        orElse: () => LearningDecisionType.complete,
      ),
      priority: LearningDecisionPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => LearningDecisionPriority.none,
      ),
      targetObjectiveId: json['targetObjectiveId'] as String?,
      targetTopic: json['targetTopic'] as String?,
      remedialLessonId: json['remedialLessonId'] as String?,
      rationale: json['rationale'] as String? ?? '',
      parameters: json['parameters'] != null
          ? Map<String, dynamic>.from(json['parameters'] as Map)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NextLearningAction &&
          runtimeType == other.runtimeType &&
          actionType == other.actionType &&
          priority == other.priority &&
          targetObjectiveId == other.targetObjectiveId &&
          targetTopic == other.targetTopic &&
          remedialLessonId == other.remedialLessonId &&
          rationale == other.rationale;

  @override
  int get hashCode => Object.hash(
        actionType,
        priority,
        targetObjectiveId,
        targetTopic,
        remedialLessonId,
        rationale,
      );

  @override
  String toString() =>
      'NextLearningAction(${actionType.name.toUpperCase()} [$priority], target: $targetObjectiveId, reason: $rationale)';
}
