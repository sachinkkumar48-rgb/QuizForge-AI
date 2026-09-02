/// Practice Outcome Evidence Domain Entities (TITAN-KO-036.0 P36).
///
/// Encapsulates granular question-level execution evidence, aggregated performance
/// evidence (Topic, Objective, Section, Difficulty), and feedback exposure summaries.
///
/// Invariants:
/// - Pure descriptive evidence; zero cognitive/scientific predictions.
/// - Immutable domain models and deeply unmodifiable collections.
/// - Zero DateTime.now() drift; caller-supplied timestamps only.
/// - Safe bounded mathematical metrics with explicit zero-denominator safety (accuracy is null when attempted == 0).
/// - Full question provenance and multi-exam identity preservation.
library;

import 'package:meta/meta.dart';

import 'adaptive_question_candidate.dart';
import 'evaluation_method.dart';
import 'practice_execution_state.dart';

/// Categorical execution status of a single question within a practice session.
enum PracticeQuestionStatus {
  /// Question was submitted with an answer and evaluated as correct.
  answeredCorrect,

  /// Question was submitted with an answer and evaluated as incorrect.
  answeredIncorrect,

  /// Question was explicitly skipped by the learner.
  skipped,

  /// Question was scheduled in the session but never presented/answered (e.g. abandoned session).
  unanswered;

  /// Whether this question was submitted with an answer.
  bool get isAnswered =>
      this == PracticeQuestionStatus.answeredCorrect ||
      this == PracticeQuestionStatus.answeredIncorrect;

  /// Whether this question was correct.
  bool get isCorrect => this == PracticeQuestionStatus.answeredCorrect;

  /// Whether this question was skipped.
  bool get isSkipped => this == PracticeQuestionStatus.skipped;

  /// Whether this question was left unanswered.
  bool get isUnanswered => this == PracticeQuestionStatus.unanswered;
}

/// Granular question-level practice execution evidence.
@immutable
class PracticeQuestionEvidence {
  /// Canonical question ID.
  final String questionId;

  /// Examination identifier (e.g. 'upsc', 'bpsc', 'ssc').
  final String examId;

  /// Year of the PYQ question, if available.
  final int? year;

  /// Exam paper identifier (e.g. 'GS1', 'Prelims Paper 1'), if available.
  final String? paper;

  /// Subject classification (e.g. 'Polity', 'History', 'Geography').
  final String subject;

  /// Syllabus topic classification.
  final String topic;

  /// Canonical learning objective IDs mapped to this question.
  final List<String> objectiveIds;

  /// Difficulty level (e.g. 'Easy', 'Medium', 'Hard').
  final String difficulty;

  /// 0-based sequence index within the session execution order.
  final int questionIndex;

  /// Categorical status of this question's execution.
  final PracticeQuestionStatus status;

  /// The raw answer string submitted by the learner, or null if skipped/unanswered.
  final String? submittedAnswer;

  /// The authoritative official correct answer keys/text.
  final String correctAnswer;

  /// Whether the submitted answer was correct.
  final bool isCorrect;

  /// Whether an answer was submitted.
  final bool isAnswered;

  /// Whether the question was skipped.
  final bool isSkipped;

  /// Time spent on this question in seconds.
  final int elapsedSeconds;

  /// Timestamp when question was first presented, if recorded.
  final DateTime? presentedAt;

  /// Timestamp when answer or skip was recorded, if executed.
  final DateTime? answeredAt;

  /// Feedback exposure policy under which this question was executed.
  final PracticeFeedbackPolicy feedbackPolicy;

  /// Whether detailed explanation was exposed to the learner.
  final bool isExplanationExposed;

  /// Deterministic evaluation method used.
  final EvaluationMethod evaluationMethod;

  /// Associated question candidate metadata from P33/P34, if present.
  final AdaptiveQuestionCandidate? candidateMetadata;

  PracticeQuestionEvidence({
    required this.questionId,
    required this.examId,
    this.year,
    this.paper,
    required this.subject,
    required this.topic,
    required List<String> objectiveIds,
    required this.difficulty,
    required this.questionIndex,
    required this.status,
    this.submittedAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.isAnswered,
    required this.isSkipped,
    this.elapsedSeconds = 0,
    this.presentedAt,
    this.answeredAt,
    this.feedbackPolicy = PracticeFeedbackPolicy.immediate,
    this.isExplanationExposed = true,
    this.evaluationMethod = EvaluationMethod.multipleChoice,
    this.candidateMetadata,
  }) : objectiveIds = List<String>.unmodifiable(objectiveIds) {
    if (questionId.trim().isEmpty) {
      throw ArgumentError(
          'questionId cannot be empty for PracticeQuestionEvidence');
    }
    if (examId.trim().isEmpty) {
      throw ArgumentError(
          'examId cannot be empty for PracticeQuestionEvidence');
    }
    if (questionIndex < 0) {
      throw ArgumentError('questionIndex cannot be negative ($questionIndex)');
    }
    if (elapsedSeconds < 0) {
      throw ArgumentError(
          'elapsedSeconds cannot be negative ($elapsedSeconds)');
    }
  }

  /// Canonical JSON-serializable representation.
  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'examId': examId,
        if (year != null) 'year': year,
        if (paper != null) 'paper': paper,
        'subject': subject,
        'topic': topic,
        'objectiveIds': objectiveIds,
        'difficulty': difficulty,
        'questionIndex': questionIndex,
        'status': status.name,
        if (submittedAnswer != null) 'submittedAnswer': submittedAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
        'isAnswered': isAnswered,
        'isSkipped': isSkipped,
        'elapsedSeconds': elapsedSeconds,
        if (presentedAt != null) 'presentedAt': presentedAt!.toIso8601String(),
        if (answeredAt != null) 'answeredAt': answeredAt!.toIso8601String(),
        'feedbackPolicy': feedbackPolicy.name,
        'isExplanationExposed': isExplanationExposed,
        'evaluationMethod': evaluationMethod.name,
        if (candidateMetadata != null)
          'candidateMetadata': candidateMetadata!.toJson(),
      };

  factory PracticeQuestionEvidence.fromJson(Map<String, dynamic> json) =>
      PracticeQuestionEvidence(
        questionId: json['questionId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        year: json['year'] as int?,
        paper: json['paper'] as String?,
        subject: json['subject'] as String? ?? '',
        topic: json['topic'] as String? ?? '',
        objectiveIds: (json['objectiveIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        difficulty: json['difficulty'] as String? ?? 'Medium',
        questionIndex: json['questionIndex'] as int? ?? 0,
        status: PracticeQuestionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PracticeQuestionStatus.unanswered,
        ),
        submittedAnswer: json['submittedAnswer'] as String?,
        correctAnswer: json['correctAnswer'] as String? ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
        isAnswered: json['isAnswered'] as bool? ?? false,
        isSkipped: json['isSkipped'] as bool? ?? false,
        elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
        presentedAt: json['presentedAt'] != null
            ? DateTime.parse(json['presentedAt'] as String).toUtc()
            : null,
        answeredAt: json['answeredAt'] != null
            ? DateTime.parse(json['answeredAt'] as String).toUtc()
            : null,
        feedbackPolicy: PracticeFeedbackPolicy.values.firstWhere(
          (p) => p.name == json['feedbackPolicy'],
          orElse: () => PracticeFeedbackPolicy.immediate,
        ),
        isExplanationExposed: json['isExplanationExposed'] as bool? ?? true,
        evaluationMethod: EvaluationMethod.values.firstWhere(
          (m) => m.name == json['evaluationMethod'],
          orElse: () => EvaluationMethod.multipleChoice,
        ),
        candidateMetadata: json['candidateMetadata'] != null
            ? AdaptiveQuestionCandidate.fromJson(
                json['candidateMetadata'] as Map<String, dynamic>)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeQuestionEvidence &&
          questionId == other.questionId &&
          examId == other.examId &&
          questionIndex == other.questionIndex &&
          status == other.status &&
          submittedAnswer == other.submittedAnswer &&
          isCorrect == other.isCorrect &&
          elapsedSeconds == other.elapsedSeconds;

  @override
  int get hashCode => Object.hash(
        questionId,
        examId,
        questionIndex,
        status,
        submittedAnswer,
        isCorrect,
        elapsedSeconds,
      );

  @override
  String toString() =>
      'PracticeQuestionEvidence($questionId [$examId]: status=${status.name}, correct=$isCorrect, elapsed=${elapsedSeconds}s)';
}

/// Aggregated descriptive performance evidence per syllabus topic.
@immutable
class PracticeTopicEvidence {
  /// Syllabus topic identifier/name.
  final String topic;

  /// Optional subject group.
  final String? subject;

  /// Total questions in this topic within the session.
  final int totalQuestions;

  /// Total questions answered (submitted).
  final int attemptedCount;

  /// Total correctly answered questions.
  final int correctCount;

  /// Total incorrectly answered questions.
  final int incorrectCount;

  /// Total skipped questions.
  final int skippedCount;

  /// Total unanswered questions.
  final int unansweredCount;

  /// Completion rate in [0.0, 1.0] ( (attempted + skipped) / total ).
  final double completionRate;

  /// Accuracy ratio among attempted questions in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Percentage accuracy in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Ratio of skipped questions relative to total in [0.0, 1.0].
  final double skipRate;

  /// Total cumulative seconds spent on this topic.
  final int totalElapsedSeconds;

  /// Average seconds per attempted question (0.0 if attempted == 0).
  final double averageSecondsPerAttempt;

  PracticeTopicEvidence({
    required this.topic,
    this.subject,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    required this.completionRate,
    this.accuracy,
    this.accuracyPercentage,
    required this.skipRate,
    this.totalElapsedSeconds = 0,
    this.averageSecondsPerAttempt = 0.0,
  }) {
    if (topic.trim().isEmpty) {
      throw ArgumentError('topic cannot be empty for PracticeTopicEvidence');
    }
    if (totalQuestions < 0 || attemptedCount < 0 || correctCount < 0) {
      throw ArgumentError('Counts cannot be negative in PracticeTopicEvidence');
    }
    if (completionRate < 0.0 || completionRate > 1.0) {
      throw ArgumentError('completionRate must be in [0.0, 1.0]');
    }
    if (accuracy != null && (accuracy! < 0.0 || accuracy! > 1.0)) {
      throw ArgumentError('accuracy must be in [0.0, 1.0] or null');
    }
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        if (subject != null) 'subject': subject,
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
        'skipRate': skipRate,
        'totalElapsedSeconds': totalElapsedSeconds,
        'averageSecondsPerAttempt': averageSecondsPerAttempt,
      };

  factory PracticeTopicEvidence.fromJson(Map<String, dynamic> json) =>
      PracticeTopicEvidence(
        topic: json['topic'] as String? ?? '',
        subject: json['subject'] as String?,
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedCount: json['attemptedCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        incorrectCount: json['incorrectCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        unansweredCount: json['unansweredCount'] as int? ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        skipRate: (json['skipRate'] as num?)?.toDouble() ?? 0.0,
        totalElapsedSeconds: json['totalElapsedSeconds'] as int? ?? 0,
        averageSecondsPerAttempt:
            (json['averageSecondsPerAttempt'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  String toString() =>
      'PracticeTopicEvidence($topic: $correctCount/$attemptedCount correct of $totalQuestions, acc=${accuracyPercentage?.toStringAsFixed(1) ?? "N/A"}%)';
}

/// Aggregated descriptive performance evidence per learning objective.
@immutable
class PracticeObjectiveEvidence {
  /// Canonical learning objective ID.
  final String objectiveId;

  /// Total questions linked to this objective within the session.
  final int totalQuestions;

  /// Total questions answered (submitted).
  final int attemptedCount;

  /// Total correctly answered questions.
  final int correctCount;

  /// Total incorrectly answered questions.
  final int incorrectCount;

  /// Total skipped questions.
  final int skippedCount;

  /// Total unanswered questions.
  final int unansweredCount;

  /// Completion rate in [0.0, 1.0].
  final double completionRate;

  /// Accuracy ratio among attempted questions in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Percentage accuracy in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Ratio of skipped questions relative to total in [0.0, 1.0].
  final double skipRate;

  /// Total cumulative seconds spent on this objective.
  final int totalElapsedSeconds;

  /// Average seconds per attempted question.
  final double averageSecondsPerAttempt;

  PracticeObjectiveEvidence({
    required this.objectiveId,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    required this.completionRate,
    this.accuracy,
    this.accuracyPercentage,
    required this.skipRate,
    this.totalElapsedSeconds = 0,
    this.averageSecondsPerAttempt = 0.0,
  }) {
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError(
          'objectiveId cannot be empty for PracticeObjectiveEvidence');
    }
    if (totalQuestions < 0 || attemptedCount < 0 || correctCount < 0) {
      throw ArgumentError(
          'Counts cannot be negative in PracticeObjectiveEvidence');
    }
    if (completionRate < 0.0 || completionRate > 1.0) {
      throw ArgumentError('completionRate must be in [0.0, 1.0]');
    }
    if (accuracy != null && (accuracy! < 0.0 || accuracy! > 1.0)) {
      throw ArgumentError('accuracy must be in [0.0, 1.0] or null');
    }
  }

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
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
        'skipRate': skipRate,
        'totalElapsedSeconds': totalElapsedSeconds,
        'averageSecondsPerAttempt': averageSecondsPerAttempt,
      };

  factory PracticeObjectiveEvidence.fromJson(Map<String, dynamic> json) =>
      PracticeObjectiveEvidence(
        objectiveId: json['objectiveId'] as String? ?? '',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedCount: json['attemptedCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        incorrectCount: json['incorrectCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        unansweredCount: json['unansweredCount'] as int? ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        skipRate: (json['skipRate'] as num?)?.toDouble() ?? 0.0,
        totalElapsedSeconds: json['totalElapsedSeconds'] as int? ?? 0,
        averageSecondsPerAttempt:
            (json['averageSecondsPerAttempt'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  String toString() =>
      'PracticeObjectiveEvidence($objectiveId: $correctCount/$attemptedCount correct, acc=${accuracyPercentage?.toStringAsFixed(1) ?? "N/A"}%)';
}

/// Aggregated descriptive performance evidence per section partition.
@immutable
class PracticeSectionEvidence {
  /// 0-based section index within the session partition.
  final int sectionIndex;

  /// Optional section title or label.
  final String? sectionTitle;

  /// Total questions in this section.
  final int totalQuestions;

  /// Total questions answered (submitted).
  final int attemptedCount;

  /// Total correctly answered questions.
  final int correctCount;

  /// Total incorrectly answered questions.
  final int incorrectCount;

  /// Total skipped questions.
  final int skippedCount;

  /// Total unanswered questions.
  final int unansweredCount;

  /// Completion rate in [0.0, 1.0].
  final double completionRate;

  /// Accuracy ratio among attempted questions in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Percentage accuracy in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Ratio of skipped questions in [0.0, 1.0].
  final double skipRate;

  /// Total elapsed seconds in this section.
  final int totalElapsedSeconds;

  /// Average seconds per attempted question.
  final double averageSecondsPerAttempt;

  PracticeSectionEvidence({
    required this.sectionIndex,
    this.sectionTitle,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    required this.completionRate,
    this.accuracy,
    this.accuracyPercentage,
    required this.skipRate,
    this.totalElapsedSeconds = 0,
    this.averageSecondsPerAttempt = 0.0,
  }) {
    if (sectionIndex < 0) {
      throw ArgumentError('sectionIndex cannot be negative ($sectionIndex)');
    }
    if (totalQuestions < 0 || attemptedCount < 0) {
      throw ArgumentError(
          'Counts cannot be negative in PracticeSectionEvidence');
    }
  }

  Map<String, dynamic> toJson() => {
        'sectionIndex': sectionIndex,
        if (sectionTitle != null) 'sectionTitle': sectionTitle,
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
        'skipRate': skipRate,
        'totalElapsedSeconds': totalElapsedSeconds,
        'averageSecondsPerAttempt': averageSecondsPerAttempt,
      };

  factory PracticeSectionEvidence.fromJson(Map<String, dynamic> json) =>
      PracticeSectionEvidence(
        sectionIndex: json['sectionIndex'] as int? ?? 0,
        sectionTitle: json['sectionTitle'] as String?,
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedCount: json['attemptedCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        incorrectCount: json['incorrectCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        unansweredCount: json['unansweredCount'] as int? ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        skipRate: (json['skipRate'] as num?)?.toDouble() ?? 0.0,
        totalElapsedSeconds: json['totalElapsedSeconds'] as int? ?? 0,
        averageSecondsPerAttempt:
            (json['averageSecondsPerAttempt'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  String toString() =>
      'PracticeSectionEvidence(Section $sectionIndex: $correctCount/$attemptedCount correct, acc=${accuracyPercentage?.toStringAsFixed(1) ?? "N/A"}%)';
}

/// Aggregated descriptive performance evidence per question difficulty level.
@immutable
class PracticeDifficultyEvidence {
  /// Difficulty level classification string (e.g. 'Easy', 'Medium', 'Hard').
  final String difficulty;

  /// Total questions of this difficulty level.
  final int totalQuestions;

  /// Total questions answered (submitted).
  final int attemptedCount;

  /// Total correctly answered questions.
  final int correctCount;

  /// Total incorrectly answered questions.
  final int incorrectCount;

  /// Total skipped questions.
  final int skippedCount;

  /// Total unanswered questions.
  final int unansweredCount;

  /// Completion rate in [0.0, 1.0].
  final double completionRate;

  /// Accuracy ratio among attempted questions in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Percentage accuracy in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Ratio of skipped questions in [0.0, 1.0].
  final double skipRate;

  /// Total elapsed seconds for this difficulty level.
  final int totalElapsedSeconds;

  /// Average seconds per attempted question.
  final double averageSecondsPerAttempt;

  PracticeDifficultyEvidence({
    required this.difficulty,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    required this.completionRate,
    this.accuracy,
    this.accuracyPercentage,
    required this.skipRate,
    this.totalElapsedSeconds = 0,
    this.averageSecondsPerAttempt = 0.0,
  }) {
    if (difficulty.trim().isEmpty) {
      throw ArgumentError(
          'difficulty cannot be empty for PracticeDifficultyEvidence');
    }
    if (totalQuestions < 0 || attemptedCount < 0) {
      throw ArgumentError(
          'Counts cannot be negative in PracticeDifficultyEvidence');
    }
  }

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty,
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
        'skipRate': skipRate,
        'totalElapsedSeconds': totalElapsedSeconds,
        'averageSecondsPerAttempt': averageSecondsPerAttempt,
      };

  factory PracticeDifficultyEvidence.fromJson(Map<String, dynamic> json) =>
      PracticeDifficultyEvidence(
        difficulty: json['difficulty'] as String? ?? 'Medium',
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        attemptedCount: json['attemptedCount'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        incorrectCount: json['incorrectCount'] as int? ?? 0,
        skippedCount: json['skippedCount'] as int? ?? 0,
        unansweredCount: json['unansweredCount'] as int? ?? 0,
        completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        skipRate: (json['skipRate'] as num?)?.toDouble() ?? 0.0,
        totalElapsedSeconds: json['totalElapsedSeconds'] as int? ?? 0,
        averageSecondsPerAttempt:
            (json['averageSecondsPerAttempt'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  String toString() =>
      'PracticeDifficultyEvidence($difficulty: $correctCount/$attemptedCount correct, acc=${accuracyPercentage?.toStringAsFixed(1) ?? "N/A"}%)';
}

/// Summary of feedback policy and explanation exposure throughout session execution.
@immutable
class PracticeFeedbackSummary {
  /// The active feedback policy for the session.
  final PracticeFeedbackPolicy policy;

  /// Total feedback items generated.
  final int totalFeedbackGenerated;

  /// Total feedback instances where explanations were exposed immediately.
  final int explanationsExposedCount;

  /// Total feedback instances where explanations were withheld (deferred or simulation).
  final int explanationsWithheldCount;

  /// Ratio of exposed explanations in [0.0, 1.0] (0.0 if total == 0).
  final double exposureRate;

  PracticeFeedbackSummary({
    required this.policy,
    required this.totalFeedbackGenerated,
    required this.explanationsExposedCount,
    required this.explanationsWithheldCount,
    required this.exposureRate,
  }) {
    if (totalFeedbackGenerated < 0 || explanationsExposedCount < 0) {
      throw ArgumentError(
          'Counts cannot be negative in PracticeFeedbackSummary');
    }
    if (exposureRate < 0.0 || exposureRate > 1.0) {
      throw ArgumentError('exposureRate must be in [0.0, 1.0]');
    }
  }

  Map<String, dynamic> toJson() => {
        'policy': policy.name,
        'totalFeedbackGenerated': totalFeedbackGenerated,
        'explanationsExposedCount': explanationsExposedCount,
        'explanationsWithheldCount': explanationsWithheldCount,
        'exposureRate': exposureRate,
      };

  factory PracticeFeedbackSummary.fromJson(Map<String, dynamic> json) =>
      PracticeFeedbackSummary(
        policy: PracticeFeedbackPolicy.values.firstWhere(
          (p) => p.name == json['policy'],
          orElse: () => PracticeFeedbackPolicy.immediate,
        ),
        totalFeedbackGenerated: json['totalFeedbackGenerated'] as int? ?? 0,
        explanationsExposedCount: json['explanationsExposedCount'] as int? ?? 0,
        explanationsWithheldCount:
            json['explanationsWithheldCount'] as int? ?? 0,
        exposureRate: (json['exposureRate'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  String toString() =>
      'PracticeFeedbackSummary(${policy.name}: exposed=$explanationsExposedCount/$totalFeedbackGenerated, rate=${(exposureRate * 100).toStringAsFixed(1)}%)';
}
