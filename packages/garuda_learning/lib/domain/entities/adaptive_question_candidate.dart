/// Adaptive Question Candidate Domain Entity (TITAN-KO-033.0 P33).
///
/// Encapsulates an evaluated question candidate alongside its multi-dimensional
/// scoring signals, eligibility status, and exclusion reasons for full selection auditability.
///
/// Invariants:
/// - Reuses canonical [NormalizedQuestion] directly — zero question fabrication.
/// - Preserves 100% of question provenance, options, answer keys, and explanations.
/// - All scores bounded in [0.0, 1.0]. Zero negative values, zero NaN, zero Infinity.
/// - Pure quantitative scoring — zero predictive assertions ("will appear next year").
library;

import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:meta/meta.dart';

/// Explicit reason why a candidate question was excluded during selection.
enum QuestionExclusionReason {
  /// Question belongs to a different exam than the requested target exam.
  examMismatch,

  /// Question does not match the requested objective, topic, or subject scope.
  scopeMismatch,

  /// Excluded because excludePreviouslySeen is true and learner previously attempted it.
  previouslySeen,

  /// Excluded because exposureCount >= maxExposureCount.
  excessExposure,

  /// Excluded because the question was attempted too recently (within cooldown period).
  cooldownActive,

  /// Excluded because session diversity limit for this objective was reached.
  diversityObjectiveLimit,

  /// Excluded because session diversity limit for this topic was reached.
  diversityTopicLimit,

  /// Excluded because session diversity limit for this examination year was reached.
  diversityYearLimit;

  String get description {
    switch (this) {
      case QuestionExclusionReason.examMismatch:
        return 'Question exam does not match requested exam scope';
      case QuestionExclusionReason.scopeMismatch:
        return 'Question is outside requested objective, topic, or subject scope';
      case QuestionExclusionReason.previouslySeen:
        return 'Question was previously attempted by learner';
      case QuestionExclusionReason.excessExposure:
        return 'Question exceeded maximum allowable exposure count';
      case QuestionExclusionReason.cooldownActive:
        return 'Question was attempted recently and cooldown period is active';
      case QuestionExclusionReason.diversityObjectiveLimit:
        return 'Session quota for this learning objective has been reached';
      case QuestionExclusionReason.diversityTopicLimit:
        return 'Session quota for this topic has been reached';
      case QuestionExclusionReason.diversityYearLimit:
        return 'Session quota for this examination year has been reached';
    }
  }
}

/// Evaluated question candidate with full multi-signal scoring audit trail.
@immutable
class AdaptiveQuestionCandidate {
  /// Underlying canonical normalized question (reused directly).
  final NormalizedQuestion question;

  /// Historical priority score from P32 [0.0, 1.0].
  final double historicalPriority;

  /// Observed learner weakness score from P23/P18 [0.0, 1.0] (strictly 0.0 if unattempted/sparse).
  final double learnerWeakness;

  /// Number of times the learner has previously attempted/seen this question.
  final int exposureCount;

  /// UTC timestamp when the learner last attempted this question.
  final DateTime? lastExposedAt;

  /// Question freshness score [0.0, 1.0] (1.0 for unexposed questions, decays with exposure).
  final double recencyScore;

  /// Difficulty fit score [0.0, 1.0] (1.0 for perfect match or neutral target).
  final double difficultyFit;

  /// Question source provenance quality score [0.0, 1.0].
  final double sourceQualityScore;

  /// Composite deterministic selection score in [0.0, 1.0].
  final double selectionScore;

  /// Whether this candidate is eligible for session inclusion.
  final bool isEligible;

  /// Reason for exclusion if [isEligible] is false.
  final QuestionExclusionReason? exclusionReason;

  /// Transparent decimal contribution breakdown for each scoring component.
  final Map<String, double> scoreBreakdown;

  const AdaptiveQuestionCandidate({
    required this.question,
    required this.historicalPriority,
    required this.learnerWeakness,
    required this.exposureCount,
    this.lastExposedAt,
    required this.recencyScore,
    required this.difficultyFit,
    required this.sourceQualityScore,
    required this.selectionScore,
    required this.isEligible,
    this.exclusionReason,
    required this.scoreBreakdown,
  });

  /// Canonical question ID.
  String get questionId => question.id;

  /// Target exam ID.
  String get examId => question.examId;

  /// Examination year.
  int get year => question.year;

  /// Paper identifier.
  String get paper => question.paper;

  /// Subject classification.
  String get subject => question.subject;

  /// Topic classification.
  String get topic => question.topic;

  /// Mapped learning objective IDs.
  List<String> get objectiveIds => question.objectiveIds;

  /// Primary objective ID if available.
  String? get primaryObjectiveId =>
      question.objectiveIds.isNotEmpty ? question.objectiveIds.first : null;

  AdaptiveQuestionCandidate copyWith({
    NormalizedQuestion? question,
    double? historicalPriority,
    double? learnerWeakness,
    int? exposureCount,
    DateTime? lastExposedAt,
    double? recencyScore,
    double? difficultyFit,
    double? sourceQualityScore,
    double? selectionScore,
    bool? isEligible,
    QuestionExclusionReason? exclusionReason,
    Map<String, double>? scoreBreakdown,
  }) {
    return AdaptiveQuestionCandidate(
      question: question ?? this.question,
      historicalPriority: historicalPriority ?? this.historicalPriority,
      learnerWeakness: learnerWeakness ?? this.learnerWeakness,
      exposureCount: exposureCount ?? this.exposureCount,
      lastExposedAt: lastExposedAt ?? this.lastExposedAt,
      recencyScore: recencyScore ?? this.recencyScore,
      difficultyFit: difficultyFit ?? this.difficultyFit,
      sourceQualityScore: sourceQualityScore ?? this.sourceQualityScore,
      selectionScore: selectionScore ?? this.selectionScore,
      isEligible: isEligible ?? this.isEligible,
      exclusionReason: exclusionReason ?? this.exclusionReason,
      scoreBreakdown: scoreBreakdown ?? this.scoreBreakdown,
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'examId': examId,
        'year': year,
        'paper': paper,
        'subject': subject,
        'topic': topic,
        'objectiveIds': objectiveIds,
        'historicalPriority': historicalPriority,
        'learnerWeakness': learnerWeakness,
        'exposureCount': exposureCount,
        if (lastExposedAt != null)
          'lastExposedAt': lastExposedAt!.toIso8601String(),
        'recencyScore': recencyScore,
        'difficultyFit': difficultyFit,
        'sourceQualityScore': sourceQualityScore,
        'selectionScore': selectionScore,
        'isEligible': isEligible,
        if (exclusionReason != null) 'exclusionReason': exclusionReason!.name,
        'scoreBreakdown': scoreBreakdown,
      };

  @override
  String toString() =>
      'AdaptiveQuestionCandidate(id: $questionId, score: ${selectionScore.toStringAsFixed(4)}, eligible: $isEligible${exclusionReason != null ? ", reason: ${exclusionReason!.name}" : ""})';
}
