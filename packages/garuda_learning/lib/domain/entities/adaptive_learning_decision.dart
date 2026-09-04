/// Adaptive Learning Decision Domain Entities (TITAN-KO-041.0 P41).
///
/// Encapsulates strongly typed pedagogical decisions, targets, machine-readable
/// evidence structures, auditable decision traces, and revision freshness safety.
library;

import 'package:meta/meta.dart';

import 'adaptive_decision_policy.dart';
import 'authoritative_learner_state.dart';

/// Categorical type of target indicated by a learning decision.
enum LearningTargetType {
  /// Checkpoint cursor of an interrupted session.
  sessionCursor,

  /// Specific remedial lesson for concept remediation.
  remedialLesson,

  /// Previously mastered objective due for spaced review.
  reviewObjective,

  /// In-progress objective needing practice reinforcement.
  practiceObjective,

  /// Unattempted objective in the curriculum sequence.
  curriculumObjective,

  /// No active learning target (curriculum completed).
  none;
}

/// Coordinates and metadata identifying the chosen learning target.
@immutable
class LearningTarget {
  /// Unique identifier of the target.
  final String targetId;

  /// Categorical target type.
  final LearningTargetType targetType;

  /// Target learning objective identifier, if applicable.
  final String? objectiveId;

  /// Syllabus topic name, if applicable.
  final String? topic;

  /// Examination subject name, if applicable.
  final String? subject;

  /// Bound P25 remedial lesson identifier, if applicable.
  final String? remedialLessonId;

  /// 0-based question cursor index for session resumption, if applicable.
  final int? cursorIndex;

  /// Extensible target metadata.
  final Map<String, dynamic> metadata;

  LearningTarget({
    required String targetId,
    required this.targetType,
    this.objectiveId,
    this.topic,
    this.subject,
    this.remedialLessonId,
    this.cursorIndex,
    Map<String, dynamic>? metadata,
  })  : targetId = targetId.trim(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (this.targetId.isEmpty) {
      throw ArgumentError('targetId cannot be empty for LearningTarget');
    }
    if (cursorIndex != null && cursorIndex! < 0) {
      throw ArgumentError('cursorIndex cannot be negative ($cursorIndex)');
    }
  }

  /// Target representing an active session resumption cursor.
  factory LearningTarget.sessionCursor({
    required String sessionId,
    required int cursorIndex,
    String? objectiveId,
    String? topic,
  }) {
    return LearningTarget(
      targetId: 'cursor_${sessionId}_$cursorIndex',
      targetType: LearningTargetType.sessionCursor,
      objectiveId: objectiveId,
      topic: topic,
      cursorIndex: cursorIndex,
      metadata: {'sessionId': sessionId},
    );
  }

  /// Target representing a P25 remedial lesson.
  factory LearningTarget.remedialLesson({
    required String lessonId,
    required String objectiveId,
    String? topic,
    String? subject,
  }) {
    return LearningTarget(
      targetId: lessonId,
      targetType: LearningTargetType.remedialLesson,
      objectiveId: objectiveId,
      remedialLessonId: lessonId,
      topic: topic,
      subject: subject,
    );
  }

  /// Target representing practice or review of a learning objective.
  factory LearningTarget.objective({
    required String objectiveId,
    required LearningTargetType type,
    String? topic,
    String? subject,
  }) {
    return LearningTarget(
      targetId: objectiveId,
      targetType: type,
      objectiveId: objectiveId,
      topic: topic,
      subject: subject,
    );
  }

  /// Empty target when no action is required.
  static final LearningTarget none = LearningTarget(
    targetId: 'target_none',
    targetType: LearningTargetType.none,
  );

  Map<String, dynamic> toJson() => {
        'targetId': targetId,
        'targetType': targetType.name,
        if (objectiveId != null) 'objectiveId': objectiveId,
        if (topic != null) 'topic': topic,
        if (subject != null) 'subject': subject,
        if (remedialLessonId != null) 'remedialLessonId': remedialLessonId,
        if (cursorIndex != null) 'cursorIndex': cursorIndex,
        'metadata': metadata,
      };

  factory LearningTarget.fromJson(Map<String, dynamic> json) => LearningTarget(
        targetId: json['targetId'] as String? ?? 'target_unknown',
        targetType: LearningTargetType.values.firstWhere(
          (t) => t.name == json['targetType'],
          orElse: () => LearningTargetType.none,
        ),
        objectiveId: json['objectiveId'] as String?,
        topic: json['topic'] as String?,
        subject: json['subject'] as String?,
        remedialLessonId: json['remedialLessonId'] as String?,
        cursorIndex: json['cursorIndex'] as int?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LearningTarget &&
          runtimeType == other.runtimeType &&
          targetId == other.targetId &&
          targetType == other.targetType &&
          objectiveId == other.objectiveId &&
          cursorIndex == other.cursorIndex;

  @override
  int get hashCode =>
      Object.hash(targetId, targetType, objectiveId, cursorIndex);

  @override
  String toString() =>
      'LearningTarget(${targetType.name}: $targetId, obj: $objectiveId, cursor: $cursorIndex)';
}

/// Machine-readable empirical evidence justifying an adaptive decision.
@immutable
class LearningDecisionEvidence {
  /// Target objective identifier, if applicable.
  final String? objectiveId;

  /// Syllabus topic, if applicable.
  final String? topic;

  /// Examination subject, if applicable.
  final String? subject;

  /// Calculated mastery score in [0.0, 1.0].
  final double masteryScore;

  /// Total question attempts recorded.
  final int attemptCount;

  /// Total correct answers recorded.
  final int correctCount;

  /// Success rate ratio in [0.0, 1.0].
  final double successRate;

  /// Pedagogical confidence in observed metrics [0.0, 1.0].
  final double confidence;

  /// Number of remedial interventions completed for this objective.
  final int remediationCount;

  /// Timestamp of the last recorded attempt.
  final DateTime? lastPracticedAt;

  /// Elapsed days since the last completed review attempt.
  final int? daysSinceReview;

  /// Authoritative learner state revision at decision time.
  final int authoritativeStateRevision;

  /// Associated session checkpoint revision, if recovering.
  final int? checkpointRevision;

  /// Active session identifier, if continuing.
  final String? activeSessionId;

  /// Whether an unfinished session was detected.
  final bool hasUnfinishedSession;

  /// Diagnostic explanatory notes.
  final List<String> notes;

  LearningDecisionEvidence({
    this.objectiveId,
    this.topic,
    this.subject,
    this.masteryScore = 0.0,
    this.attemptCount = 0,
    this.correctCount = 0,
    this.successRate = 0.0,
    this.confidence = 1.0,
    this.remediationCount = 0,
    this.lastPracticedAt,
    this.daysSinceReview,
    required this.authoritativeStateRevision,
    this.checkpointRevision,
    this.activeSessionId,
    this.hasUnfinishedSession = false,
    List<String>? notes,
  }) : notes = List<String>.unmodifiable(notes ?? const <String>[]) {
    if (authoritativeStateRevision < 1) {
      throw ArgumentError('authoritativeStateRevision must be >= 1');
    }
    if (masteryScore < 0.0 || masteryScore > 1.0) {
      throw ArgumentError('masteryScore must be in [0.0, 1.0]');
    }
    if (successRate < 0.0 || successRate > 1.0) {
      throw ArgumentError('successRate must be in [0.0, 1.0]');
    }
  }

  Map<String, dynamic> toJson() => {
        if (objectiveId != null) 'objectiveId': objectiveId,
        if (topic != null) 'topic': topic,
        if (subject != null) 'subject': subject,
        'masteryScore': masteryScore,
        'attemptCount': attemptCount,
        'correctCount': correctCount,
        'successRate': successRate,
        'confidence': confidence,
        'remediationCount': remediationCount,
        if (lastPracticedAt != null)
          'lastPracticedAt': lastPracticedAt!.toIso8601String(),
        if (daysSinceReview != null) 'daysSinceReview': daysSinceReview,
        'authoritativeStateRevision': authoritativeStateRevision,
        if (checkpointRevision != null)
          'checkpointRevision': checkpointRevision,
        if (activeSessionId != null) 'activeSessionId': activeSessionId,
        'hasUnfinishedSession': hasUnfinishedSession,
        'notes': notes,
      };

  factory LearningDecisionEvidence.fromJson(Map<String, dynamic> json) =>
      LearningDecisionEvidence(
        objectiveId: json['objectiveId'] as String?,
        topic: json['topic'] as String?,
        subject: json['subject'] as String?,
        masteryScore: (json['masteryScore'] as num?)?.toDouble() ?? 0.0,
        attemptCount: json['attemptCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        successRate: (json['successRate'] as num?)?.toDouble() ?? 0.0,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
        remediationCount: json['remediationCount'] as int? ?? 0,
        lastPracticedAt: json['lastPracticedAt'] != null
            ? DateTime.parse(json['lastPracticedAt'] as String).toUtc()
            : null,
        daysSinceReview: json['daysSinceReview'] as int?,
        authoritativeStateRevision:
            json['authoritativeStateRevision'] as int? ?? 1,
        checkpointRevision: json['checkpointRevision'] as int?,
        activeSessionId: json['activeSessionId'] as String?,
        hasUnfinishedSession: json['hasUnfinishedSession'] as bool? ?? false,
        notes: (json['notes'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// Single auditable step in the decision reasoning trace.
@immutable
class DecisionTraceStep {
  final int stepIndex;
  final LearningDecisionType policy;
  final String ruleName;
  final bool isMatched;
  final String reason;
  final Map<String, dynamic> evaluatedMetrics;

  const DecisionTraceStep({
    required this.stepIndex,
    required this.policy,
    required this.ruleName,
    required this.isMatched,
    required this.reason,
    this.evaluatedMetrics = const {},
  });

  Map<String, dynamic> toJson() => {
        'stepIndex': stepIndex,
        'policy': policy.name,
        'ruleName': ruleName,
        'isMatched': isMatched,
        'reason': reason,
        'evaluatedMetrics': evaluatedMetrics,
      };

  factory DecisionTraceStep.fromJson(Map<String, dynamic> json) =>
      DecisionTraceStep(
        stepIndex: json['stepIndex'] as int? ?? 0,
        policy: LearningDecisionType.values.firstWhere(
          (t) => t.name == json['policy'],
          orElse: () => LearningDecisionType.continuation,
        ),
        ruleName: json['ruleName'] as String? ?? '',
        isMatched: json['isMatched'] as bool? ?? false,
        reason: json['reason'] as String? ?? '',
        evaluatedMetrics:
            json['evaluatedMetrics'] as Map<String, dynamic>? ?? const {},
      );

  @override
  String toString() =>
      'Step $stepIndex: [${policy.name}] ${isMatched ? "MATCHED" : "SKIPPED"} - $reason';
}

/// Auditable trace explaining the complete evaluation sequence.
@immutable
class DecisionTrace {
  final String traceId;
  final String learnerId;
  final String examId;
  final int authoritativeStateRevision;
  final DateTime evaluatedAt;
  final List<DecisionTraceStep> steps;
  final LearningDecisionType selectedType;
  final String summary;

  DecisionTrace({
    required String traceId,
    required String learnerId,
    required String examId,
    required this.authoritativeStateRevision,
    required DateTime evaluatedAt,
    required List<DecisionTraceStep> steps,
    required this.selectedType,
    required this.summary,
  })  : traceId = traceId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        evaluatedAt = evaluatedAt.toUtc(),
        steps = List<DecisionTraceStep>.unmodifiable(steps);

  Map<String, dynamic> toJson() => {
        'traceId': traceId,
        'learnerId': learnerId,
        'examId': examId,
        'authoritativeStateRevision': authoritativeStateRevision,
        'evaluatedAt': evaluatedAt.toIso8601String(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'selectedType': selectedType.name,
        'summary': summary,
      };

  factory DecisionTrace.fromJson(Map<String, dynamic> json) => DecisionTrace(
        traceId: json['traceId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        authoritativeStateRevision:
            json['authoritativeStateRevision'] as int? ?? 1,
        evaluatedAt: DateTime.parse(json['evaluatedAt'] as String).toUtc(),
        steps: (json['steps'] as List<dynamic>? ?? const [])
            .map((e) => DecisionTraceStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        selectedType: LearningDecisionType.values.firstWhere(
          (t) => t.name == json['selectedType'],
          orElse: () => LearningDecisionType.complete,
        ),
        summary: json['summary'] as String? ?? '',
      );
}

/// Complete immutable pedagogical decision produced by P41 decision engine.
@immutable
class AdaptiveLearningDecision {
  /// Unique deterministic decision identifier.
  final String decisionId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Decision category (continuation, remediation, review, reinforcement, advancement, complete).
  final LearningDecisionType type;

  /// Priority tier of this decision.
  final LearningDecisionPriority priority;

  /// Human-readable explanation of why this decision was formulated.
  final String reason;

  /// Target learning coordinates.
  final LearningTarget target;

  /// Machine-readable empirical evidence backing the decision.
  final LearningDecisionEvidence evidence;

  /// Authoritative state revision at evaluation time.
  final int authoritativeStateRevision;

  /// Checkpoint revision, if decision was derived from a session checkpoint.
  final int? checkpointRevision;

  /// UTC timestamp when the decision was formulated.
  final DateTime decidedAt;

  /// Auditable decision reasoning trace.
  final DecisionTrace? trace;

  AdaptiveLearningDecision({
    required String decisionId,
    required String learnerId,
    required String examId,
    required this.type,
    required this.priority,
    required this.reason,
    required this.target,
    required this.evidence,
    required this.authoritativeStateRevision,
    this.checkpointRevision,
    required DateTime decidedAt,
    this.trace,
  })  : decisionId = decisionId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        decidedAt = decidedAt.toUtc() {
    if (this.decisionId.isEmpty) {
      throw ArgumentError('decisionId cannot be empty');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (authoritativeStateRevision < 1) {
      throw ArgumentError('authoritativeStateRevision must be >= 1');
    }
  }

  /// Whether this decision is stale relative to [currentState].
  ///
  /// A decision is stale if the authoritative state has advanced beyond the revision
  /// this decision was formulated against.
  bool isStale(AuthoritativeLearnerState currentState) {
    if (currentState.learnerId != learnerId || currentState.examId != examId) {
      throw ArgumentError(
          'Tenant mismatch in isStale check: state (${currentState.learnerId}:${currentState.examId}) != decision ($learnerId:$examId)');
    }
    return currentState.revision > authoritativeStateRevision;
  }

  Map<String, dynamic> toJson() => {
        'decisionId': decisionId,
        'learnerId': learnerId,
        'examId': examId,
        'type': type.name,
        'priority': priority.name,
        'reason': reason,
        'target': target.toJson(),
        'evidence': evidence.toJson(),
        'authoritativeStateRevision': authoritativeStateRevision,
        if (checkpointRevision != null)
          'checkpointRevision': checkpointRevision,
        'decidedAt': decidedAt.toIso8601String(),
        if (trace != null) 'trace': trace!.toJson(),
      };

  factory AdaptiveLearningDecision.fromJson(Map<String, dynamic> json) =>
      AdaptiveLearningDecision(
        decisionId: json['decisionId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        type: LearningDecisionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => LearningDecisionType.complete,
        ),
        priority: LearningDecisionPriority.values.firstWhere(
          (p) => p.name == json['priority'],
          orElse: () => LearningDecisionPriority.none,
        ),
        reason: json['reason'] as String? ?? '',
        target: LearningTarget.fromJson(json['target'] as Map<String, dynamic>),
        evidence: LearningDecisionEvidence.fromJson(
            json['evidence'] as Map<String, dynamic>),
        authoritativeStateRevision:
            json['authoritativeStateRevision'] as int? ?? 1,
        checkpointRevision: json['checkpointRevision'] as int?,
        decidedAt: DateTime.parse(json['decidedAt'] as String).toUtc(),
        trace: json['trace'] != null
            ? DecisionTrace.fromJson(json['trace'] as Map<String, dynamic>)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveLearningDecision &&
          runtimeType == other.runtimeType &&
          decisionId == other.decisionId &&
          learnerId == other.learnerId &&
          examId == other.examId &&
          type == other.type &&
          authoritativeStateRevision == other.authoritativeStateRevision;

  @override
  int get hashCode => Object.hash(
        decisionId,
        learnerId,
        examId,
        type,
        authoritativeStateRevision,
      );

  @override
  String toString() =>
      'AdaptiveLearningDecision(${type.name} [$priority]: target=${target.targetId}, authRev=$authoritativeStateRevision)';
}
