/// Personalized Learning Plan Domain Entities (TITAN-KO-043.0 P43).
///
/// Encapsulates the deterministic, inspectable, and explainable personalized
/// learning plan roadmap derived from diagnostic evidence, authoritative learner state,
/// curriculum prerequisites, and verified question availability.
library;

import 'package:meta/meta.dart';

/// Type of learning action in a personalized learning plan.
enum PlanActionType {
  /// Continue an in-flight practice session from a saved checkpoint.
  continueSession,

  /// Initial diagnostic assessment to establish baseline competency.
  takeDiagnostic,

  /// Targeted remedial micro-lesson addressing persistent errors.
  startRemedialLesson,

  /// Adaptive practice on a specific curriculum objective.
  practiceObjective,

  /// General past-year question drill.
  practicePyqs,

  /// Spaced repetition review or reinforcement of a mastered topic.
  reviewRevision;

  String get displayName => switch (this) {
        PlanActionType.continueSession => 'Resume Practice',
        PlanActionType.takeDiagnostic => 'Diagnostic Assessment',
        PlanActionType.startRemedialLesson => 'Remedial Lesson',
        PlanActionType.practiceObjective => 'Adaptive Practice',
        PlanActionType.practicePyqs => 'PYQ Drill',
        PlanActionType.reviewRevision => 'Spaced Review',
      };
}

/// Execution lifecycle status of an action within a learning plan.
enum PlanActionStatus {
  /// Currently the primary active recommendation.
  recommended,

  /// In progress (active session in flight).
  inProgress,

  /// Successfully achieved or completed.
  completed,

  /// Upcoming scheduled action in sequence.
  pending;

  String get displayName => switch (this) {
        PlanActionStatus.recommended => 'Recommended Next',
        PlanActionStatus.inProgress => 'In Progress',
        PlanActionStatus.completed => 'Completed',
        PlanActionStatus.pending => 'Upcoming',
      };
}

/// Machine-readable pedagogical reason code explaining why an action was scheduled.
enum PlanReasonCode {
  /// Incomplete in-flight session checkpoint exists.
  inFlightSession,

  /// Identified as a weak topic during diagnostic evaluation.
  diagnosticWeakness,

  /// Persistent failures detected in authoritative state (<60% accuracy).
  persistentFailure,

  /// Foundational prerequisite required before advanced topics can be unlocked.
  prerequisiteFoundation,

  /// Current active knowledge frontier ready for practice.
  activeFrontier,

  /// Remedial lesson available for identified conceptual gap.
  remedialIndication,

  /// Mastered objective scheduled for retention reinforcement.
  revisionReinforcement,

  /// Remaining syllabus topic in curriculum sequence.
  curriculumRemaining;

  String get code => name;
}

/// Immutable descriptor of a concrete, executable learning action.
@immutable
class PersonalizedLearningAction {
  /// Stable deterministic action identifier.
  final String id;

  /// Target examination identifier (e.g. 'upsc_prelims_gs1').
  final String examId;

  /// Subject identifier (e.g. 'indian_polity').
  final String subjectId;

  /// Display name of the subject.
  final String subjectName;

  /// Topic identifier (e.g. 'fundamental_rights').
  final String topicId;

  /// Display name of the topic.
  final String topicName;

  /// Canonical curriculum learning objective ID (e.g. 'lo_article_21_foundations').
  final String objectiveId;

  /// Title of the learning objective.
  final String objectiveTitle;

  /// Type of learning action.
  final PlanActionType actionType;

  /// 0-indexed position in the plan sequence.
  final int orderIndex;

  /// Machine-readable rationale code.
  final PlanReasonCode reasonCode;

  /// Learner-facing explainable rationale ("Why this was selected").
  final String reason;

  /// Action execution status.
  final PlanActionStatus status;

  /// In-flight session ID if actionType == continueSession.
  final String? sessionId;

  /// Question index to resume from, if applicable.
  final int? sessionCursor;

  /// Attached remedial lesson ID if actionType == startRemedialLesson.
  final String? remedialLessonId;

  /// Available practice question count.
  final int targetQuestionCount;

  /// Whether verified questions or content exist to execute this action.
  final bool isExecutable;

  const PersonalizedLearningAction({
    required this.id,
    required this.examId,
    required this.subjectId,
    required this.subjectName,
    required this.topicId,
    required this.topicName,
    required this.objectiveId,
    required this.objectiveTitle,
    required this.actionType,
    required this.orderIndex,
    required this.reasonCode,
    required this.reason,
    this.status = PlanActionStatus.pending,
    this.sessionId,
    this.sessionCursor,
    this.remedialLessonId,
    this.targetQuestionCount = 0,
    this.isExecutable = true,
  });

  PersonalizedLearningAction copyWith({
    String? id,
    String? examId,
    String? subjectId,
    String? subjectName,
    String? topicId,
    String? topicName,
    String? objectiveId,
    String? objectiveTitle,
    PlanActionType? actionType,
    int? orderIndex,
    PlanReasonCode? reasonCode,
    String? reason,
    PlanActionStatus? status,
    String? sessionId,
    int? sessionCursor,
    String? remedialLessonId,
    int? targetQuestionCount,
    bool? isExecutable,
  }) {
    return PersonalizedLearningAction(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      objectiveId: objectiveId ?? this.objectiveId,
      objectiveTitle: objectiveTitle ?? this.objectiveTitle,
      actionType: actionType ?? this.actionType,
      orderIndex: orderIndex ?? this.orderIndex,
      reasonCode: reasonCode ?? this.reasonCode,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      sessionCursor: sessionCursor ?? this.sessionCursor,
      remedialLessonId: remedialLessonId ?? this.remedialLessonId,
      targetQuestionCount: targetQuestionCount ?? this.targetQuestionCount,
      isExecutable: isExecutable ?? this.isExecutable,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'examId': examId,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'topicId': topicId,
        'topicName': topicName,
        'objectiveId': objectiveId,
        'objectiveTitle': objectiveTitle,
        'actionType': actionType.name,
        'orderIndex': orderIndex,
        'reasonCode': reasonCode.name,
        'reason': reason,
        'status': status.name,
        'sessionId': sessionId,
        'sessionCursor': sessionCursor,
        'remedialLessonId': remedialLessonId,
        'targetQuestionCount': targetQuestionCount,
        'isExecutable': isExecutable,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalizedLearningAction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          actionType == other.actionType &&
          objectiveId == other.objectiveId &&
          orderIndex == other.orderIndex;

  @override
  int get hashCode => Object.hash(id, actionType, objectiveId, orderIndex);
}

/// Complete immutable personalized learning plan for a learner.
@immutable
class PersonalizedLearningPlan {
  /// Deterministic plan identifier.
  final String planId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Generation timestamp (UTC).
  final DateTime generatedAt;

  /// Monotonic revision sequence number of authoritative state when plan was formulated.
  final int stateRevision;

  /// Complete list of ordered learning actions.
  final List<PersonalizedLearningAction> actions;

  PersonalizedLearningPlan({
    required String planId,
    required String learnerId,
    required String examId,
    required DateTime generatedAt,
    this.stateRevision = 1,
    required List<PersonalizedLearningAction> actions,
  })  : planId = planId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        generatedAt = generatedAt.toUtc(),
        actions = List.unmodifiable(actions);

  /// Returns the single primary next action for the learner.
  PersonalizedLearningAction? get recommendedAction {
    if (actions.isEmpty) return null;
    return actions.cast<PersonalizedLearningAction?>().firstWhere(
      (a) =>
          a?.status == PlanActionStatus.recommended ||
          a?.status == PlanActionStatus.inProgress,
      orElse: () {
        return actions.cast<PersonalizedLearningAction?>().firstWhere(
              (a) => a?.status == PlanActionStatus.pending,
              orElse: () => null,
            );
      },
    );
  }

  /// Returns all upcoming pending actions after the recommended one.
  List<PersonalizedLearningAction> get upcomingActions {
    final rec = recommendedAction;
    return actions
        .where((a) =>
            a.status == PlanActionStatus.pending &&
            (rec == null || a.id != rec.id))
        .toList();
  }

  /// Returns all completed actions in this plan.
  List<PersonalizedLearningAction> get completedActions {
    return actions
        .where((a) => a.status == PlanActionStatus.completed)
        .toList();
  }

  /// Total count of planned actions.
  int get totalActions => actions.length;

  /// Count of completed actions.
  int get completedCount => completedActions.length;

  /// Plan completion ratio in [0.0, 1.0].
  double get progressPercentage =>
      totalActions > 0 ? (completedCount / totalActions) : 0.0;

  /// Whether the plan contains any actionable items.
  bool get hasActions => actions.isNotEmpty;

  /// Whether all actions in the plan have been completed.
  bool get isCompleted => totalActions > 0 && completedCount == totalActions;

  PersonalizedLearningPlan copyWith({
    String? planId,
    String? learnerId,
    String? examId,
    DateTime? generatedAt,
    int? stateRevision,
    List<PersonalizedLearningAction>? actions,
  }) {
    return PersonalizedLearningPlan(
      planId: planId ?? this.planId,
      learnerId: learnerId ?? this.learnerId,
      examId: examId ?? this.examId,
      generatedAt: generatedAt ?? this.generatedAt,
      stateRevision: stateRevision ?? this.stateRevision,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'learnerId': learnerId,
        'examId': examId,
        'generatedAt': generatedAt.toIso8601String(),
        'stateRevision': stateRevision,
        'actions': actions.map((a) => a.toJson()).toList(),
        'completedCount': completedCount,
        'totalActions': totalActions,
        'progressPercentage': progressPercentage,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalizedLearningPlan &&
          runtimeType == other.runtimeType &&
          planId == other.planId &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          stateRevision == other.stateRevision;

  @override
  int get hashCode => Object.hash(planId, learnerId, examId, stateRevision);
}
