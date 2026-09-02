/// Practice Outcome Consolidation Domain Entities (TITAN-KO-036.0 P36).
///
/// Encapsulates the immutable, deterministic consolidated practice outcome model,
/// aggregating session performance, question evidence, dimensional groupings
/// (Topic, Objective, Section, Difficulty), feedback exposure summaries, P19 persistence
/// handoff attempts, and canonical SHA-256 fingerprint verification.
///
/// Invariants:
/// - Pure descriptive outcome; zero cognitive/scientific predictions.
/// - Immutable domain models and deeply unmodifiable collections.
/// - Zero DateTime.now() drift; caller-supplied timestamps only.
/// - Safe bounded mathematical metrics with explicit zero-denominator safety.
/// - Strict multi-exam isolation and question provenance preservation.
library;

import 'package:meta/meta.dart';

import 'adaptive_practice_session_config.dart';
import 'practice_execution_state.dart';
import 'practice_outcome_evidence.dart';
import 'question_attempt.dart';

/// Comprehensive consolidated outcome and learning evidence package produced from practice execution.
@immutable
class ConsolidatedPracticeOutcome {
  /// Session identifier matching the P34 specification and P35 execution state.
  final String sessionId;

  /// Examination identifier (e.g. 'upsc', 'bpsc', 'ssc').
  final String examId;

  /// Target learner identifier, if present.
  final String? learnerId;

  /// Pedagogical practice session mode.
  final PracticeSessionMode sessionMode;

  /// Final runtime execution lifecycle status.
  final PracticeExecutionStatus sessionStatus;

  /// Timestamp when session execution was started.
  final DateTime startedAt;

  /// Timestamp when session execution reached its terminal or evaluated state.
  final DateTime completedAt;

  /// Total questions scheduled in the session.
  final int totalQuestions;

  /// Total questions answered (submitted with an answer).
  final int attemptedCount;

  /// Total questions answered correctly.
  final int correctCount;

  /// Total questions answered incorrectly.
  final int incorrectCount;

  /// Total questions explicitly skipped.
  final int skippedCount;

  /// Total questions left unanswered (e.g. abandoned session).
  final int unansweredCount;

  /// Ratio of processed (answered + skipped) questions relative to total in [0.0, 1.0].
  final double completionRate;

  /// Accuracy ratio among attempted questions in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Percentage accuracy in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Overall session score ratio relative to total questions in [0.0, 1.0].
  final double scoreRatio;

  /// Cumulative duration spent across the session in seconds.
  final int totalDurationSeconds;

  /// Average seconds spent per attempted question (0.0 if attempted == 0).
  final double averageSecondsPerQuestion;

  /// Feedback policy and explanation exposure summary.
  final PracticeFeedbackSummary feedbackSummary;

  /// Aggregated performance evidence grouped by syllabus topic (keys sorted deterministically).
  final Map<String, PracticeTopicEvidence> topicEvidence;

  /// Aggregated performance evidence grouped by learning objective ID (keys sorted deterministically).
  final Map<String, PracticeObjectiveEvidence> objectiveEvidence;

  /// Aggregated performance evidence grouped by section partition (keys sorted deterministically).
  final Map<String, PracticeSectionEvidence> sectionEvidence;

  /// Aggregated performance evidence grouped by difficulty level (keys sorted deterministically).
  final Map<String, PracticeDifficultyEvidence> difficultyEvidence;

  /// Ordered sequence of question-level execution evidence matching session presentation order.
  final List<PracticeQuestionEvidence> questionEvidence;

  /// Validated, evidence-ready [QuestionAttempt] instances prepared for P19 persistence.
  final List<QuestionAttempt> handoffAttempts;

  /// Deterministic SHA-256 fingerprint representing this exact consolidated outcome.
  final String fingerprint;

  ConsolidatedPracticeOutcome({
    required this.sessionId,
    required this.examId,
    this.learnerId,
    required this.sessionMode,
    required this.sessionStatus,
    required this.startedAt,
    required this.completedAt,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    required this.completionRate,
    this.accuracy,
    this.accuracyPercentage,
    required this.scoreRatio,
    required this.totalDurationSeconds,
    required this.averageSecondsPerQuestion,
    required this.feedbackSummary,
    required Map<String, PracticeTopicEvidence> topicEvidence,
    required Map<String, PracticeObjectiveEvidence> objectiveEvidence,
    required Map<String, PracticeSectionEvidence> sectionEvidence,
    required Map<String, PracticeDifficultyEvidence> difficultyEvidence,
    required List<PracticeQuestionEvidence> questionEvidence,
    required List<QuestionAttempt> handoffAttempts,
    required this.fingerprint,
  })  : topicEvidence =
            Map<String, PracticeTopicEvidence>.unmodifiable(topicEvidence),
        objectiveEvidence = Map<String, PracticeObjectiveEvidence>.unmodifiable(
            objectiveEvidence),
        sectionEvidence =
            Map<String, PracticeSectionEvidence>.unmodifiable(sectionEvidence),
        difficultyEvidence =
            Map<String, PracticeDifficultyEvidence>.unmodifiable(
                difficultyEvidence),
        questionEvidence =
            List<PracticeQuestionEvidence>.unmodifiable(questionEvidence),
        handoffAttempts = List<QuestionAttempt>.unmodifiable(handoffAttempts) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError(
          'sessionId cannot be empty for ConsolidatedPracticeOutcome');
    }
    if (examId.trim().isEmpty) {
      throw ArgumentError(
          'examId cannot be empty for ConsolidatedPracticeOutcome');
    }
    if (totalQuestions < 0 || attemptedCount < 0 || correctCount < 0) {
      throw ArgumentError(
          'Counts cannot be negative in ConsolidatedPracticeOutcome');
    }
    if (completionRate < 0.0 || completionRate > 1.0) {
      throw ArgumentError(
          'completionRate must be in [0.0, 1.0] (got $completionRate)');
    }
    if (accuracy != null && (accuracy! < 0.0 || accuracy! > 1.0)) {
      throw ArgumentError(
          'accuracy must be in [0.0, 1.0] or null (got $accuracy)');
    }
    if (scoreRatio < 0.0 || scoreRatio > 1.0) {
      throw ArgumentError('scoreRatio must be in [0.0, 1.0] (got $scoreRatio)');
    }
    if (fingerprint.trim().isEmpty) {
      throw ArgumentError(
          'fingerprint cannot be empty for ConsolidatedPracticeOutcome');
    }
  }

  /// Converts the consolidated outcome into a standard JSON map.
  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'examId': examId,
        if (learnerId != null) 'learnerId': learnerId,
        'sessionMode': sessionMode.name,
        'sessionStatus': sessionStatus.name,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'totalQuestions': totalQuestions,
        'attemptedCount': attemptedCount,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'skippedCount': skippedCount,
        'unansweredCount': unansweredCount,
        'completionRate': completionRate,
        if (accuracy != null) 'accuracy': accuracy,
        if (accuracyPercentage != null)
          'accuracyPercentage': accuracyPercentage,
        'scoreRatio': scoreRatio,
        'totalDurationSeconds': totalDurationSeconds,
        'averageSecondsPerQuestion': averageSecondsPerQuestion,
        'feedbackSummary': feedbackSummary.toJson(),
        'topicEvidence': topicEvidence.map((k, v) => MapEntry(k, v.toJson())),
        'objectiveEvidence':
            objectiveEvidence.map((k, v) => MapEntry(k, v.toJson())),
        'sectionEvidence':
            sectionEvidence.map((k, v) => MapEntry(k, v.toJson())),
        'difficultyEvidence':
            difficultyEvidence.map((k, v) => MapEntry(k, v.toJson())),
        'questionEvidence': questionEvidence.map((q) => q.toJson()).toList(),
        'handoffAttempts': handoffAttempts.map((a) => a.toJson()).toList(),
        'fingerprint': fingerprint,
      };

  /// Constructs a [ConsolidatedPracticeOutcome] from a JSON map.
  factory ConsolidatedPracticeOutcome.fromJson(Map<String, dynamic> json) =>
      ConsolidatedPracticeOutcome(
        sessionId: json['sessionId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        learnerId: json['learnerId'] as String?,
        sessionMode: PracticeSessionMode.values.firstWhere(
          (m) => m.name == json['sessionMode'],
          orElse: () => PracticeSessionMode.standard,
        ),
        sessionStatus: PracticeExecutionStatus.values.firstWhere(
          (s) => s.name == json['sessionStatus'],
          orElse: () => PracticeExecutionStatus.completed,
        ),
        startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
        completedAt: DateTime.parse(json['completedAt'] as String).toUtc(),
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedCount: json['attemptedCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        incorrectCount: json['incorrectCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        unansweredCount: json['unansweredCount'] as int? ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        scoreRatio: (json['scoreRatio'] as num?)?.toDouble() ?? 0.0,
        totalDurationSeconds: json['totalDurationSeconds'] as int? ?? 0,
        averageSecondsPerQuestion:
            (json['averageSecondsPerQuestion'] as num?)?.toDouble() ?? 0.0,
        feedbackSummary: PracticeFeedbackSummary.fromJson(
            json['feedbackSummary'] as Map<String, dynamic>? ?? const {}),
        topicEvidence: (json['topicEvidence'] as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(
                k, PracticeTopicEvidence.fromJson(v as Map<String, dynamic>))),
        objectiveEvidence: (json['objectiveEvidence']
                    as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(k,
                PracticeObjectiveEvidence.fromJson(v as Map<String, dynamic>))),
        sectionEvidence: (json['sectionEvidence'] as Map<String, dynamic>? ??
                const {})
            .map((k, v) => MapEntry(k,
                PracticeSectionEvidence.fromJson(v as Map<String, dynamic>))),
        difficultyEvidence:
            (json['difficultyEvidence'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(
                    k,
                    PracticeDifficultyEvidence.fromJson(
                        v as Map<String, dynamic>))),
        questionEvidence: (json['questionEvidence'] as List<dynamic>? ??
                const [])
            .map((e) =>
                PracticeQuestionEvidence.fromJson(e as Map<String, dynamic>))
            .toList(),
        handoffAttempts: (json['handoffAttempts'] as List<dynamic>? ?? const [])
            .map((e) => QuestionAttempt.fromJson(e as Map<String, dynamic>))
            .toList(),
        fingerprint: json['fingerprint'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConsolidatedPracticeOutcome &&
          fingerprint == other.fingerprint &&
          sessionId == other.sessionId &&
          examId == other.examId;

  @override
  int get hashCode => Object.hash(sessionId, examId, fingerprint);

  @override
  String toString() =>
      'ConsolidatedPracticeOutcome($sessionId [$examId]: $correctCount/$totalQuestions correct, acc=${accuracyPercentage?.toStringAsFixed(1) ?? "N/A"}%, fp=${fingerprint.substring(0, 8)}...)';
}
