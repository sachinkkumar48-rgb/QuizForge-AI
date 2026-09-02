/// Learning Evidence Signal Domain Entities (TITAN-KO-037.0 P37).
///
/// Encapsulates bounded, descriptive learning evidence signals derived from
/// practice session outcomes across individual questions, topics, learning objectives,
/// practice sections, and difficulty bands.
///
/// Invariants:
/// - Pure descriptive evidence; zero cognitive/scientific predictions.
/// - Zero DateTime.now() drift; caller-supplied timestamps only.
/// - Deeply immutable domain models and unmodifiable collections.
/// - Safe zero-denominator handling (accuracy is null when attempted == 0).
/// - Evidence strength strictly calibrated against observed sample volume.
library;

import 'package:meta/meta.dart';

import 'practice_outcome_evidence.dart';

/// Calibrated confidence/strength of the empirical evidence supporting a learning signal.
enum EvidenceStrength {
  /// Zero attempts or observations; zero evidence available.
  none,

  /// Exactly 1 observation; insufficient to establish any reliable pattern.
  insufficient,

  /// Exactly 2 observations; limited preliminary pattern.
  limited,

  /// 3 to 4 observations; moderate empirical evidence.
  moderate,

  /// 5 or more observations; strong within-session empirical evidence.
  strong;

  /// Determines the calibrated evidence strength from an attempted count.
  static EvidenceStrength fromAttemptCount(int attemptedCount) {
    if (attemptedCount <= 0) return EvidenceStrength.none;
    if (attemptedCount == 1) return EvidenceStrength.insufficient;
    if (attemptedCount == 2) return EvidenceStrength.limited;
    if (attemptedCount <= 4) return EvidenceStrength.moderate;
    return EvidenceStrength.strong;
  }

  /// Whether this evidence level meets the minimum threshold for pattern recognition (>= limited).
  bool get hasUsableEvidence =>
      this == EvidenceStrength.limited ||
      this == EvidenceStrength.moderate ||
      this == EvidenceStrength.strong;
}

/// Descriptive within-session outcome pattern or trajectory.
enum OutcomePattern {
  /// Insufficient attempts (0 or 1) to derive any empirical trajectory.
  insufficientEvidence,

  /// 2 or more attempts, all evaluated as correct (100% accuracy).
  consistentlyCorrect,

  /// 2 or more attempts, all evaluated as incorrect (0% accuracy).
  consistentlyIncorrect,

  /// 3 or more attempts showing chronological improvement (later accuracy > earlier accuracy).
  improving,

  /// 3 or more attempts showing chronological decline (earlier accuracy > later accuracy).
  declining,

  /// 2 or more attempts with mixed correctness and no clear directional trend.
  mixed,

  /// All processed questions were explicitly skipped.
  skippedOnly,

  /// All scheduled questions were left unanswered (e.g. abandoned before starting).
  unansweredOnly;

  /// Whether this pattern represents successful performance.
  bool get isPositive =>
      this == OutcomePattern.consistentlyCorrect ||
      this == OutcomePattern.improving;

  /// Whether this pattern warrants remedial attention.
  bool get isNegative =>
      this == OutcomePattern.consistentlyIncorrect ||
      this == OutcomePattern.declining;
}

/// Proposed downstream learning action derived from observed evidence.
///
/// These are **recommendations / proposals**, not direct mutations.
/// Downstream systems (P19, P20, P23, P32) decide how to consume them.
enum ProposedLearningAction {
  /// Zero evidence or baseline session requiring no immediate state change.
  noAction,

  /// Empirical evidence of consistent correctness; proposal to maintain/retain current mastery level.
  retainMastery,

  /// Empirical evidence of repeated or declining errors; proposal to consider review / remediation in P20/P32.
  reviewRemediation,

  /// Empirical evidence of mixed performance or limited errors; proposal for concept reinforcement.
  reinforceConcept,

  /// Introductory, unattempted, or skipped questions; proposal to continue standard syllabus exposure.
  continueExposure;
}

/// Granular learning evidence signal for an individual question attempt.
@immutable
class QuestionLearningSignal {
  /// Canonical question ID.
  final String questionId;

  /// Target examination identifier.
  final String examId;

  /// Subject classification.
  final String subject;

  /// Topic classification.
  final String topic;

  /// Associated learning objective IDs.
  final List<String> objectiveIds;

  /// Difficulty level.
  final String difficulty;

  /// Execution status.
  final PracticeQuestionStatus status;

  /// Whether the question was answered.
  final bool isAnswered;

  /// Whether the submitted answer was correct.
  final bool isCorrect;

  /// Whether the question was skipped.
  final bool isSkipped;

  /// Whether the question was left unanswered.
  final bool isUnanswered;

  /// Time spent on this question in seconds.
  final int elapsedSeconds;

  /// Calibrated evidence strength (single question attempt is always insufficient or none).
  final EvidenceStrength evidenceStrength;

  /// Proposed action for this specific question.
  final ProposedLearningAction proposedAction;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  QuestionLearningSignal({
    required this.questionId,
    required String examId,
    required this.subject,
    required this.topic,
    required List<String> objectiveIds,
    required this.difficulty,
    required this.status,
    required this.isAnswered,
    required this.isCorrect,
    required this.isSkipped,
    required this.isUnanswered,
    required this.elapsedSeconds,
    required this.evidenceStrength,
    required this.proposedAction,
    Map<String, dynamic>? metadata,
  })  : examId = examId.trim().toLowerCase(),
        objectiveIds = List<String>.unmodifiable(objectiveIds),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (questionId.trim().isEmpty) {
      throw ArgumentError(
          'questionId cannot be empty for QuestionLearningSignal');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty for QuestionLearningSignal');
    }
    if (elapsedSeconds < 0) {
      throw ArgumentError('elapsedSeconds cannot be negative');
    }
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'examId': examId,
        'subject': subject,
        'topic': topic,
        'objectiveIds': objectiveIds,
        'difficulty': difficulty,
        'status': status.name,
        'isAnswered': isAnswered,
        'isCorrect': isCorrect,
        'isSkipped': isSkipped,
        'isUnanswered': isUnanswered,
        'elapsedSeconds': elapsedSeconds,
        'evidenceStrength': evidenceStrength.name,
        'proposedAction': proposedAction.name,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  factory QuestionLearningSignal.fromJson(Map<String, dynamic> json) =>
      QuestionLearningSignal(
        questionId: json['questionId'] as String,
        examId: json['examId'] as String,
        subject: json['subject'] as String? ?? 'General Studies',
        topic: json['topic'] as String? ?? 'General',
        objectiveIds:
            List<String>.from(json['objectiveIds'] as List? ?? const []),
        difficulty: json['difficulty'] as String? ?? 'Medium',
        status: PracticeQuestionStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PracticeQuestionStatus.unanswered,
        ),
        isAnswered: json['isAnswered'] as bool? ?? false,
        isCorrect: json['isCorrect'] as bool? ?? false,
        isSkipped: json['isSkipped'] as bool? ?? false,
        isUnanswered: json['isUnanswered'] as bool? ?? false,
        elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
        evidenceStrength: EvidenceStrength.values.firstWhere(
          (e) => e.name == json['evidenceStrength'],
          orElse: () => EvidenceStrength.none,
        ),
        proposedAction: ProposedLearningAction.values.firstWhere(
          (e) => e.name == json['proposedAction'],
          orElse: () => ProposedLearningAction.noAction,
        ),
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
}

/// Bounded learning evidence signal for a syllabus topic.
@immutable
class TopicLearningSignal {
  /// Syllabus topic name.
  final String topic;

  /// Subject name.
  final String subject;

  /// Total questions in this topic.
  final int totalQuestions;

  /// Total questions answered in this topic.
  final int attemptedCount;

  /// Total questions answered correctly.
  final int correctCount;

  /// Total questions answered incorrectly.
  final int incorrectCount;

  /// Total questions skipped.
  final int skippedCount;

  /// Total questions unanswered.
  final int unansweredCount;

  /// Accuracy ratio among attempted questions in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Accuracy percentage in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Completion rate in [0.0, 1.0].
  final double completionRate;

  /// Calibrated evidence strength based on attempted volume.
  final EvidenceStrength evidenceStrength;

  /// Observed performance pattern within this topic.
  final OutcomePattern pattern;

  /// Proposed action for this topic.
  final ProposedLearningAction proposedAction;

  /// Average seconds spent per attempted question.
  final double averageSecondsPerAttempt;

  TopicLearningSignal({
    required this.topic,
    required this.subject,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    this.accuracy,
    this.accuracyPercentage,
    required this.completionRate,
    required this.evidenceStrength,
    required this.pattern,
    required this.proposedAction,
    required this.averageSecondsPerAttempt,
  }) {
    if (topic.trim().isEmpty) {
      throw ArgumentError('topic cannot be empty for TopicLearningSignal');
    }
    if (totalQuestions < 0 ||
        attemptedCount < 0 ||
        correctCount < 0 ||
        incorrectCount < 0 ||
        skippedCount < 0 ||
        unansweredCount < 0) {
      throw ArgumentError('Counts cannot be negative');
    }
  }

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'subject': subject,
        'totalQuestions': totalQuestions,
        'attemptedCount': attemptedCount,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'skippedCount': skippedCount,
        'unansweredCount': unansweredCount,
        if (accuracy != null) 'accuracy': accuracy,
        if (accuracyPercentage != null)
          'accuracyPercentage': accuracyPercentage,
        'completionRate': completionRate,
        'evidenceStrength': evidenceStrength.name,
        'pattern': pattern.name,
        'proposedAction': proposedAction.name,
        'averageSecondsPerAttempt': averageSecondsPerAttempt,
      };

  factory TopicLearningSignal.fromJson(Map<String, dynamic> json) =>
      TopicLearningSignal(
        topic: json['topic'] as String,
        subject: json['subject'] as String? ?? 'General Studies',
        totalQuestions: json['totalQuestions'] as int,
        attemptedCount: json['attemptedCount'] as int,
        correctCount: json['correctCount'] as int,
        incorrectCount: json['incorrectCount'] as int,
        skippedCount: json['skippedCount'] as int,
        unansweredCount: json['unansweredCount'] as int,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        completionRate: (json['completionRate'] as num).toDouble(),
        evidenceStrength: EvidenceStrength.values.firstWhere(
          (e) => e.name == json['evidenceStrength'],
          orElse: () => EvidenceStrength.none,
        ),
        pattern: OutcomePattern.values.firstWhere(
          (e) => e.name == json['pattern'],
          orElse: () => OutcomePattern.insufficientEvidence,
        ),
        proposedAction: ProposedLearningAction.values.firstWhere(
          (e) => e.name == json['proposedAction'],
          orElse: () => ProposedLearningAction.noAction,
        ),
        averageSecondsPerAttempt:
            (json['averageSecondsPerAttempt'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Bounded learning evidence signal for a curriculum learning objective.
@immutable
class ObjectiveLearningSignal {
  /// Canonical learning objective ID.
  final String objectiveId;

  /// Total questions scheduled for this objective.
  final int totalQuestions;

  /// Total questions attempted for this objective.
  final int attemptedCount;

  /// Total questions answered correctly.
  final int correctCount;

  /// Total questions answered incorrectly.
  final int incorrectCount;

  /// Total questions skipped.
  final int skippedCount;

  /// Total questions unanswered.
  final int unansweredCount;

  /// Accuracy ratio in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Accuracy percentage in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Completion rate in [0.0, 1.0].
  final double completionRate;

  /// Calibrated evidence strength based on attempted volume.
  final EvidenceStrength evidenceStrength;

  /// Observed performance pattern within this objective.
  final OutcomePattern pattern;

  /// Proposed action for this objective.
  final ProposedLearningAction proposedAction;

  ObjectiveLearningSignal({
    required this.objectiveId,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    this.accuracy,
    this.accuracyPercentage,
    required this.completionRate,
    required this.evidenceStrength,
    required this.pattern,
    required this.proposedAction,
  }) {
    if (objectiveId.trim().isEmpty) {
      throw ArgumentError(
          'objectiveId cannot be empty for ObjectiveLearningSignal');
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
        if (accuracy != null) 'accuracy': accuracy,
        if (accuracyPercentage != null)
          'accuracyPercentage': accuracyPercentage,
        'completionRate': completionRate,
        'evidenceStrength': evidenceStrength.name,
        'pattern': pattern.name,
        'proposedAction': proposedAction.name,
      };

  factory ObjectiveLearningSignal.fromJson(Map<String, dynamic> json) =>
      ObjectiveLearningSignal(
        objectiveId: json['objectiveId'] as String,
        totalQuestions: json['totalQuestions'] as int,
        attemptedCount: json['attemptedCount'] as int,
        correctCount: json['correctCount'] as int,
        incorrectCount: json['incorrectCount'] as int,
        skippedCount: json['skippedCount'] as int,
        unansweredCount: json['unansweredCount'] as int,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        completionRate: (json['completionRate'] as num).toDouble(),
        evidenceStrength: EvidenceStrength.values.firstWhere(
          (e) => e.name == json['evidenceStrength'],
          orElse: () => EvidenceStrength.none,
        ),
        pattern: OutcomePattern.values.firstWhere(
          (e) => e.name == json['pattern'],
          orElse: () => OutcomePattern.insufficientEvidence,
        ),
        proposedAction: ProposedLearningAction.values.firstWhere(
          (e) => e.name == json['proposedAction'],
          orElse: () => ProposedLearningAction.noAction,
        ),
      );
}

/// Bounded learning evidence signal for a practice section.
@immutable
class SectionLearningSignal {
  /// Section identifier (e.g. 'section_0', 'section_1').
  final String sectionId;

  /// 0-based section sequence index.
  final int sectionIndex;

  /// Total questions in this section.
  final int totalQuestions;

  /// Total attempted questions in this section.
  final int attemptedCount;

  /// Total correct answers.
  final int correctCount;

  /// Total incorrect answers.
  final int incorrectCount;

  /// Total skipped questions.
  final int skippedCount;

  /// Total unanswered questions.
  final int unansweredCount;

  /// Accuracy ratio in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Accuracy percentage in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Completion rate in [0.0, 1.0].
  final double completionRate;

  /// Calibrated evidence strength based on attempted volume.
  final EvidenceStrength evidenceStrength;

  /// Observed performance pattern within this section.
  final OutcomePattern pattern;

  /// Proposed action for this section.
  final ProposedLearningAction proposedAction;

  SectionLearningSignal({
    required this.sectionId,
    required this.sectionIndex,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    this.accuracy,
    this.accuracyPercentage,
    required this.completionRate,
    required this.evidenceStrength,
    required this.pattern,
    required this.proposedAction,
  }) {
    if (sectionId.trim().isEmpty) {
      throw ArgumentError(
          'sectionId cannot be empty for SectionLearningSignal');
    }
  }

  Map<String, dynamic> toJson() => {
        'sectionId': sectionId,
        'sectionIndex': sectionIndex,
        'totalQuestions': totalQuestions,
        'attemptedCount': attemptedCount,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'skippedCount': skippedCount,
        'unansweredCount': unansweredCount,
        if (accuracy != null) 'accuracy': accuracy,
        if (accuracyPercentage != null)
          'accuracyPercentage': accuracyPercentage,
        'completionRate': completionRate,
        'evidenceStrength': evidenceStrength.name,
        'pattern': pattern.name,
        'proposedAction': proposedAction.name,
      };

  factory SectionLearningSignal.fromJson(Map<String, dynamic> json) =>
      SectionLearningSignal(
        sectionId: json['sectionId'] as String,
        sectionIndex: json['sectionIndex'] as int? ?? 0,
        totalQuestions: json['totalQuestions'] as int,
        attemptedCount: json['attemptedCount'] as int,
        correctCount: json['correctCount'] as int,
        incorrectCount: json['incorrectCount'] as int,
        skippedCount: json['skippedCount'] as int,
        unansweredCount: json['unansweredCount'] as int,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        completionRate: (json['completionRate'] as num).toDouble(),
        evidenceStrength: EvidenceStrength.values.firstWhere(
          (e) => e.name == json['evidenceStrength'],
          orElse: () => EvidenceStrength.none,
        ),
        pattern: OutcomePattern.values.firstWhere(
          (e) => e.name == json['pattern'],
          orElse: () => OutcomePattern.insufficientEvidence,
        ),
        proposedAction: ProposedLearningAction.values.firstWhere(
          (e) => e.name == json['proposedAction'],
          orElse: () => ProposedLearningAction.noAction,
        ),
      );
}

/// Bounded learning evidence signal for a difficulty band.
@immutable
class DifficultyLearningSignal {
  /// Difficulty tier label (e.g. 'Easy', 'Medium', 'Hard').
  final String difficulty;

  /// Total questions in this difficulty band.
  final int totalQuestions;

  /// Total attempted questions.
  final int attemptedCount;

  /// Total correct answers.
  final int correctCount;

  /// Total incorrect answers.
  final int incorrectCount;

  /// Total skipped questions.
  final int skippedCount;

  /// Total unanswered questions.
  final int unansweredCount;

  /// Accuracy ratio in [0.0, 1.0], or null if attempted == 0.
  final double? accuracy;

  /// Accuracy percentage in [0.0, 100.0], or null if attempted == 0.
  final double? accuracyPercentage;

  /// Completion rate in [0.0, 1.0].
  final double completionRate;

  /// Calibrated evidence strength based on attempted volume.
  final EvidenceStrength evidenceStrength;

  /// Observed performance pattern within this difficulty band.
  final OutcomePattern pattern;

  /// Proposed action for this difficulty band.
  final ProposedLearningAction proposedAction;

  DifficultyLearningSignal({
    required this.difficulty,
    required this.totalQuestions,
    required this.attemptedCount,
    required this.correctCount,
    required this.incorrectCount,
    required this.skippedCount,
    required this.unansweredCount,
    this.accuracy,
    this.accuracyPercentage,
    required this.completionRate,
    required this.evidenceStrength,
    required this.pattern,
    required this.proposedAction,
  }) {
    if (difficulty.trim().isEmpty) {
      throw ArgumentError(
          'difficulty cannot be empty for DifficultyLearningSignal');
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
        if (accuracy != null) 'accuracy': accuracy,
        if (accuracyPercentage != null)
          'accuracyPercentage': accuracyPercentage,
        'completionRate': completionRate,
        'evidenceStrength': evidenceStrength.name,
        'pattern': pattern.name,
        'proposedAction': proposedAction.name,
      };

  factory DifficultyLearningSignal.fromJson(Map<String, dynamic> json) =>
      DifficultyLearningSignal(
        difficulty: json['difficulty'] as String,
        totalQuestions: json['totalQuestions'] as int,
        attemptedCount: json['attemptedCount'] as int,
        correctCount: json['correctCount'] as int,
        incorrectCount: json['incorrectCount'] as int,
        skippedCount: json['skippedCount'] as int,
        unansweredCount: json['unansweredCount'] as int,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        accuracyPercentage: (json['accuracyPercentage'] as num?)?.toDouble(),
        completionRate: (json['completionRate'] as num).toDouble(),
        evidenceStrength: EvidenceStrength.values.firstWhere(
          (e) => e.name == json['evidenceStrength'],
          orElse: () => EvidenceStrength.none,
        ),
        pattern: OutcomePattern.values.firstWhere(
          (e) => e.name == json['pattern'],
          orElse: () => OutcomePattern.insufficientEvidence,
        ),
        proposedAction: ProposedLearningAction.values.firstWhere(
          (e) => e.name == json['proposedAction'],
          orElse: () => ProposedLearningAction.noAction,
        ),
      );
}
