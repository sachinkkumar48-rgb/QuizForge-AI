/// Personalized Learning Priority & Queue Entities (TITAN-KO-043.0 P43).
///
/// Encapsulates the prioritized, executable learning queue derived deterministically
/// from objective mastery, active checkpoints, and curriculum sequencing.
library;

import 'package:meta/meta.dart';

import 'mastery_progression_decision.dart';
import 'objective_mastery_status.dart';

/// Categorical type of executable action in the priority queue.
enum PriorityActionType {
  /// Resume an uncompleted in-flight practice drill.
  continueSession,

  /// Cold-start or diagnostic baseline assessment.
  takeDiagnostic,

  /// Targeted objective practice.
  practice,

  /// Previous year question drill.
  practicePyqs,

  /// Conceptual remedial micro-lesson and intervention.
  startRemedialLesson,

  /// Spaced repetition retention review for mastered objectives.
  reviewRevision,

  /// Fully mastered objective meeting all criteria.
  completed;

  String get displayName {
    switch (this) {
      case PriorityActionType.continueSession:
        return 'Continue';
      case PriorityActionType.takeDiagnostic:
        return 'Diagnostic';
      case PriorityActionType.practice:
        return 'Practice';
      case PriorityActionType.practicePyqs:
        return 'PYQ Practice';
      case PriorityActionType.startRemedialLesson:
        return 'Remediation';
      case PriorityActionType.reviewRevision:
        return 'Revision';
      case PriorityActionType.completed:
        return 'Completed';
    }
  }
}

/// Immutable prioritized learning item in the learner's queue.
@immutable
class PersonalizedLearningPriorityItem {
  /// Unique priority action identifier.
  final String id;

  /// Examination context identifier.
  final String examId;

  /// Syllabus subject identifier.
  final String subjectId;

  /// Human-readable subject title (e.g. "Indian Polity").
  final String subjectName;

  /// Syllabus topic identifier.
  final String topicId;

  /// Human-readable topic title (e.g. "Fundamental Rights").
  final String topicName;

  /// Target learning objective identifier.
  final String objectiveId;

  /// Human-readable objective title.
  final String objectiveTitle;

  /// Authoritative objective mastery status.
  final ObjectiveMasteryStatus masteryState;

  /// Granular progression stage.
  final ProgressionStage stage;

  /// 1-based priority position in the queue.
  final int priorityRank;

  /// Categorical executable action.
  final PriorityActionType action;

  /// Explicit pedagogical rationale for this priority assignment.
  final String reason;

  /// Fractional progress completed [0.0, 1.0].
  final double progress;

  /// Total recorded attempts for this objective.
  final int evidenceCount;

  /// Observed success rate [0.0, 1.0].
  final double accuracy;

  /// Whether questions or content exist for this item.
  final bool isAvailable;

  /// Whether this item can be directly launched by the learner right now.
  final bool isExecutable;

  /// Active recoverable session identifier, if resuming.
  final String? sessionId;

  /// Associated remedial lesson identifier, if remediation action.
  final String? remedialLessonId;

  /// Target question count for this item.
  final int? targetQuestionCount;

  /// Question cursor position if continuing.
  final int? questionCursor;

  PersonalizedLearningPriorityItem({
    required String id,
    required String examId,
    required String subjectId,
    required String subjectName,
    required String topicId,
    required String topicName,
    required String objectiveId,
    required String objectiveTitle,
    required this.masteryState,
    required this.stage,
    required this.priorityRank,
    required this.action,
    required this.reason,
    this.progress = 0.0,
    this.evidenceCount = 0,
    this.accuracy = 0.0,
    this.isAvailable = true,
    this.isExecutable = true,
    this.sessionId,
    this.remedialLessonId,
    this.targetQuestionCount,
    this.questionCursor,
  })  : id = id.trim(),
        examId = examId.trim().toLowerCase(),
        subjectId = subjectId.trim(),
        subjectName = subjectName.trim(),
        topicId = topicId.trim(),
        topicName = topicName.trim(),
        objectiveId = objectiveId.trim(),
        objectiveTitle = objectiveTitle.trim(),
        assert(priorityRank >= 0, 'priorityRank must be >= 0'),
        assert(progress >= 0.0 && progress <= 1.0, 'progress must be in [0, 1]'),
        assert(accuracy >= 0.0 && accuracy <= 1.0, 'accuracy must be in [0, 1]') {
    if (id.isEmpty) throw ArgumentError('id cannot be empty');
    if (objectiveId.isEmpty) throw ArgumentError('objectiveId cannot be empty');
  }

  PersonalizedLearningPriorityItem copyWith({
    String? id,
    String? examId,
    String? subjectId,
    String? subjectName,
    String? topicId,
    String? topicName,
    String? objectiveId,
    String? objectiveTitle,
    ObjectiveMasteryStatus? masteryState,
    ProgressionStage? stage,
    int? priorityRank,
    PriorityActionType? action,
    String? reason,
    double? progress,
    int? evidenceCount,
    double? accuracy,
    bool? isAvailable,
    bool? isExecutable,
    String? sessionId,
    String? remedialLessonId,
    int? targetQuestionCount,
    int? questionCursor,
  }) {
    return PersonalizedLearningPriorityItem(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      objectiveId: objectiveId ?? this.objectiveId,
      objectiveTitle: objectiveTitle ?? this.objectiveTitle,
      masteryState: masteryState ?? this.masteryState,
      stage: stage ?? this.stage,
      priorityRank: priorityRank ?? this.priorityRank,
      action: action ?? this.action,
      reason: reason ?? this.reason,
      progress: progress ?? this.progress,
      evidenceCount: evidenceCount ?? this.evidenceCount,
      accuracy: accuracy ?? this.accuracy,
      isAvailable: isAvailable ?? this.isAvailable,
      isExecutable: isExecutable ?? this.isExecutable,
      sessionId: sessionId ?? this.sessionId,
      remedialLessonId: remedialLessonId ?? this.remedialLessonId,
      targetQuestionCount: targetQuestionCount ?? this.targetQuestionCount,
      questionCursor: questionCursor ?? this.questionCursor,
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
        'masteryState': masteryState.name,
        'stage': stage.name,
        'priorityRank': priorityRank,
        'action': action.name,
        'reason': reason,
        'progress': progress,
        'evidenceCount': evidenceCount,
        'accuracy': accuracy,
        'isAvailable': isAvailable,
        'isExecutable': isExecutable,
        'sessionId': sessionId,
        'remedialLessonId': remedialLessonId,
        'targetQuestionCount': targetQuestionCount,
        'questionCursor': questionCursor,
      };

  factory PersonalizedLearningPriorityItem.fromJson(Map<String, dynamic> json) {
    return PersonalizedLearningPriorityItem(
      id: json['id'] as String? ?? '',
      examId: json['examId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      topicName: json['topicName'] as String? ?? '',
      objectiveId: json['objectiveId'] as String? ?? '',
      objectiveTitle: json['objectiveTitle'] as String? ?? '',
      masteryState: ObjectiveMasteryStatus.values.firstWhere(
        (e) => e.name == json['masteryState'],
        orElse: () => ObjectiveMasteryStatus.notAttempted,
      ),
      stage: ProgressionStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => ProgressionStage.notStarted,
      ),
      priorityRank: json['priorityRank'] as int? ?? 1,
      action: PriorityActionType.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => PriorityActionType.practice,
      ),
      reason: json['reason'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      evidenceCount: json['evidenceCount'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isExecutable: json['isExecutable'] as bool? ?? true,
      sessionId: json['sessionId'] as String?,
      remedialLessonId: json['remedialLessonId'] as String?,
      targetQuestionCount: json['targetQuestionCount'] as int?,
      questionCursor: json['questionCursor'] as int?,
    );
  }
}

/// Ordered queue of personalized learning priorities.
@immutable
class PersonalizedPriorityQueue {
  /// Unique queue evaluation identifier.
  final String queueId;

  /// Normalized learner identifier.
  final String learnerId;

  /// Normalized examination identifier.
  final String examId;

  /// Authoritative state revision at evaluation time.
  final int stateRevision;

  /// Evaluation timestamp in UTC.
  final DateTime evaluatedAt;

  /// Top-ranked priority item, if any actionable items exist.
  final PersonalizedLearningPriorityItem? currentPriority;

  /// Ordered list of prioritized learning actions.
  final List<PersonalizedLearningPriorityItem> items;

  /// Map of all objective progression decisions keyed by objectiveId.
  final Map<String, ObjectiveProgressionDecision> objectiveDecisions;

  PersonalizedPriorityQueue({
    required String queueId,
    required String learnerId,
    required String examId,
    required this.stateRevision,
    DateTime? evaluatedAt,
    this.currentPriority,
    List<PersonalizedLearningPriorityItem> items = const [],
    Map<String, ObjectiveProgressionDecision> objectiveDecisions = const {},
  })  : queueId = queueId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        evaluatedAt = (evaluatedAt ?? DateTime.now()).toUtc(),
        items = List<PersonalizedLearningPriorityItem>.unmodifiable(items),
        objectiveDecisions =
            Map<String, ObjectiveProgressionDecision>.unmodifiable(
                objectiveDecisions);

  /// Whether the queue is empty.
  bool get isEmpty => items.isEmpty;

  /// Whether the queue is not empty.
  bool get isNotEmpty => items.isNotEmpty;

  /// Total count of items in the queue.
  int get length => items.length;

  /// Factory creating an empty queue.
  factory PersonalizedPriorityQueue.empty({
    required String learnerId,
    required String examId,
    int stateRevision = 0,
    DateTime? evaluatedAt,
  }) {
    return PersonalizedPriorityQueue(
      queueId: 'queue_${learnerId}_${examId}_rev$stateRevision',
      learnerId: learnerId,
      examId: examId,
      stateRevision: stateRevision,
      evaluatedAt: evaluatedAt,
      items: const [],
      objectiveDecisions: const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'queueId': queueId,
        'learnerId': learnerId,
        'examId': examId,
        'stateRevision': stateRevision,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'currentPriority': currentPriority?.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
        'objectiveDecisions': objectiveDecisions.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
      };
}
