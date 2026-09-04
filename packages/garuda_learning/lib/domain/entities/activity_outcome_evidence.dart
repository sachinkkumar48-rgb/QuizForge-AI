/// Activity Outcome Evidence Domain Entity (TITAN-KO-043.0 P43).
///
/// Provides a typed evidence boundary capturing fine-grained traceability from:
/// Activity -> Session -> Question -> Attempt -> Objective/Topic -> Result.
/// Bridges runtime execution state directly into P36 outcome consolidation.
library;

import 'package:meta/meta.dart';

import 'adaptive_decision_policy.dart';
import 'attempt_result.dart';
import 'practice_outcome_evidence.dart';
import 'question_attempt.dart';

/// Structured evidence package generated during activity execution and completion.
@immutable
class ActivityOutcomeEvidence {
  /// Unique identifier of the completed learning activity.
  final String activityId;

  /// Pedagogical activity type executed.
  final LearningDecisionType activityType;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier.
  final String examId;

  /// Identifier of the triggering continuation plan.
  final String planId;

  /// Authoritative revision of the triggering continuation plan.
  final int planRevision;

  /// Practice session identifier, if session-backed.
  final String? sessionId;

  /// Granular question-level execution evidence items.
  final List<PracticeQuestionEvidence> questionEvidence;

  /// Concrete question attempts submitted by the learner.
  final List<QuestionAttempt> attempts;

  /// Evaluated results corresponding to the submitted attempts.
  final List<AttemptResult> attemptResults;

  /// Remedial lesson identifier, if this was a remediation activity.
  final String? remedialLessonId;

  /// Whether the remedial lesson was confirmed as read/completed.
  final bool? remedialLessonCompleted;

  /// UTC timestamp when this evidence snapshot was generated.
  final DateTime timestamp;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  ActivityOutcomeEvidence({
    required String activityId,
    required this.activityType,
    required String learnerId,
    required String examId,
    required String planId,
    required this.planRevision,
    this.sessionId,
    List<PracticeQuestionEvidence>? questionEvidence,
    List<QuestionAttempt>? attempts,
    List<AttemptResult>? attemptResults,
    this.remedialLessonId,
    this.remedialLessonCompleted,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : activityId = activityId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        planId = planId.trim(),
        questionEvidence = List.unmodifiable(questionEvidence ?? const []),
        attempts = List.unmodifiable(attempts ?? const []),
        attemptResults = List.unmodifiable(attemptResults ?? const []),
        timestamp = (timestamp ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(
            metadata ?? const <String, dynamic>{}) {
    if (this.activityId.isEmpty) {
      throw ArgumentError(
          'activityId cannot be empty for ActivityOutcomeEvidence');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError(
          'learnerId cannot be empty for ActivityOutcomeEvidence');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty for ActivityOutcomeEvidence');
    }
    if (this.planId.isEmpty) {
      throw ArgumentError('planId cannot be empty for ActivityOutcomeEvidence');
    }
    if (planRevision < 0) {
      throw ArgumentError('planRevision cannot be negative');
    }
  }

  Map<String, dynamic> toJson() => {
        'activityId': activityId,
        'activityType': activityType.name,
        'learnerId': learnerId,
        'examId': examId,
        'planId': planId,
        'planRevision': planRevision,
        if (sessionId != null) 'sessionId': sessionId,
        'questionEvidence': questionEvidence.map((q) => q.toJson()).toList(),
        'attempts': attempts.map((a) => a.toJson()).toList(),
        'attemptResults': attemptResults.map((r) => r.toJson()).toList(),
        if (remedialLessonId != null) 'remedialLessonId': remedialLessonId,
        if (remedialLessonCompleted != null)
          'remedialLessonCompleted': remedialLessonCompleted,
        'timestamp': timestamp.toIso8601String(),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory ActivityOutcomeEvidence.fromJson(Map<String, dynamic> json) =>
      ActivityOutcomeEvidence(
        activityId: json['activityId'] as String? ?? '',
        activityType: LearningDecisionType.values.firstWhere(
          (t) => t.name == json['activityType'],
          orElse: () => LearningDecisionType.advancement,
        ),
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        planId: json['planId'] as String? ?? '',
        planRevision: (json['planRevision'] as num?)?.toInt() ?? 0,
        sessionId: json['sessionId'] as String?,
        questionEvidence: (json['questionEvidence'] as List<dynamic>?)
            ?.map((item) =>
                PracticeQuestionEvidence.fromJson(item as Map<String, dynamic>))
            .toList(),
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
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  @override
  String toString() =>
      'ActivityOutcomeEvidence($activityId, type=${activityType.name}, questions=${questionEvidence.length}, attempts=${attempts.length})';
}
