/// Adaptive PYQ Learning Priority Signal Domain Entities (TITAN-KO-032.0 P32).
///
/// Encapsulates deterministic, evidence-backed priority signals computed from
/// P31 Historical PYQ Intelligence and P23/P18 Learner Evidence.
///
/// Invariants:
/// - Pure quantitative signal — zero predictions ("will appear", "likely to appear").
/// - Zero claims of learner innate intelligence or exam pass guarantees.
/// - Explicit fallback hierarchy (objective -> topicFallback -> subjectFallback -> none).
/// - Machine-readable rationale breakdown.
/// - All scores bounded in [0.0, 1.0].
library;

import 'package:meta/meta.dart';

/// Level of granularity for a PYQ priority signal.
enum PrioritySignalLevel {
  /// Exact curriculum objective mapped directly to historical PYQ evidence.
  objective,

  /// Fallback to topic-level historical evidence when objective mapping is unavailable.
  topicFallback,

  /// Fallback to subject-level historical evidence when topic mapping is unavailable.
  subjectFallback,

  /// No historical PYQ evidence found for this entity.
  none;

  /// Whether this signal is an explicit fallback rather than direct objective mapping.
  bool get isFallback =>
      this == PrioritySignalLevel.topicFallback ||
      this == PrioritySignalLevel.subjectFallback;

  /// Whether any historical signal exists.
  bool get hasHistoricalSignal => this != PrioritySignalLevel.none;
}

/// Transparent, machine-readable breakdown of how a priority score was derived.
@immutable
class PyqPriorityRationale {
  /// Contribution of the historical share component:
  /// (w_hist * historicalShare * confidenceAdjustment) in [0.0, 1.0].
  final double historicalShareContribution;

  /// Contribution of historical recurrence across exam years:
  /// (w_rec * recurrence * confidenceAdjustment) in [0.0, 1.0].
  final double recurrenceContribution;

  /// Contribution of recent exam activity in caller window:
  /// (w_recent * recentHistoricalShare * confidenceAdjustment) in [0.0, 1.0].
  final double recencyContribution;

  /// Contribution of observed learner weakness from P23:
  /// (w_weak * learnerWeakness) in [0.0, 1.0].
  final double learnerWeaknessContribution;

  /// Confidence adjustment factor applied to historical components [0.0, 1.0].
  final double confidenceAdjustment;

  /// Granularity level or fallback level used.
  final PrioritySignalLevel fallbackLevel;

  /// Whether the historical corpus meets minimum evidence thresholds.
  final bool hasSufficientHistoricalEvidence;

  /// Whether the learner has sufficient recorded attempts.
  final bool hasSufficientLearnerEvidence;

  /// Short machine-readable rationale code.
  final String rationaleCode;

  const PyqPriorityRationale({
    required this.historicalShareContribution,
    required this.recurrenceContribution,
    required this.recencyContribution,
    required this.learnerWeaknessContribution,
    required this.confidenceAdjustment,
    required this.fallbackLevel,
    required this.hasSufficientHistoricalEvidence,
    required this.hasSufficientLearnerEvidence,
    required this.rationaleCode,
  });

  Map<String, dynamic> toJson() => {
        'historicalShareContribution': historicalShareContribution,
        'recurrenceContribution': recurrenceContribution,
        'recencyContribution': recencyContribution,
        'learnerWeaknessContribution': learnerWeaknessContribution,
        'confidenceAdjustment': confidenceAdjustment,
        'fallbackLevel': fallbackLevel.name,
        'hasSufficientHistoricalEvidence': hasSufficientHistoricalEvidence,
        'hasSufficientLearnerEvidence': hasSufficientLearnerEvidence,
        'rationaleCode': rationaleCode,
      };

  factory PyqPriorityRationale.fromJson(Map<String, dynamic> json) =>
      PyqPriorityRationale(
        historicalShareContribution:
            (json['historicalShareContribution'] as num?)?.toDouble() ?? 0.0,
        recurrenceContribution:
            (json['recurrenceContribution'] as num?)?.toDouble() ?? 0.0,
        recencyContribution:
            (json['recencyContribution'] as num?)?.toDouble() ?? 0.0,
        learnerWeaknessContribution:
            (json['learnerWeaknessContribution'] as num?)?.toDouble() ?? 0.0,
        confidenceAdjustment:
            (json['confidenceAdjustment'] as num?)?.toDouble() ?? 0.0,
        fallbackLevel: PrioritySignalLevel.values.firstWhere(
          (e) => e.name == json['fallbackLevel'],
          orElse: () => PrioritySignalLevel.none,
        ),
        hasSufficientHistoricalEvidence:
            json['hasSufficientHistoricalEvidence'] as bool? ?? false,
        hasSufficientLearnerEvidence:
            json['hasSufficientLearnerEvidence'] as bool? ?? false,
        rationaleCode: json['rationaleCode'] as String? ?? 'DEFAULT',
      );

  @override
  String toString() =>
      'PyqPriorityRationale(code: $rationaleCode, histShare: ${historicalShareContribution.toStringAsFixed(3)}, rec: ${recurrenceContribution.toStringAsFixed(3)}, recency: ${recencyContribution.toStringAsFixed(3)}, weak: ${learnerWeaknessContribution.toStringAsFixed(3)}, conf: ${confidenceAdjustment.toStringAsFixed(2)})';
}

/// Immutable, evidence-backed priority signal for an objective, topic, or subject.
@immutable
class PyqLearningPrioritySignal {
  /// Exam identifier (e.g. 'upsc', 'bpsc', 'ssc').
  final String examId;

  /// Curriculum learning objective ID (null if topic- or subject-only signal).
  final String? objectiveId;

  /// Topic name or identifier (null if subject-only signal).
  final String? topic;

  /// Subject name or identifier.
  final String? subject;

  /// Resolution level of this signal.
  final PrioritySignalLevel level;

  /// Total number of historical questions matching this entity.
  final int historicalQuestionCount;

  /// Historical share of exam corpus [0.0, 1.0] (0.0 if total questions == 0).
  final double historicalShare;

  /// Number of distinct historical years this entity appeared.
  final int yearsObserved;

  /// Count of recurring occurrences / years present.
  final int recurrenceCount;

  /// Share of questions within recent historical window [0.0, 1.0].
  final double recentHistoricalShare;

  /// Number of attempts by this learner on this objective/topic.
  final int learnerEvidenceCount;

  /// Observed learner accuracy [0.0, 1.0] (null if unattempted).
  final double? learnerAccuracy;

  /// Observed deficiency score from P23 [0.0, 1.0] (0.0 if not weak or unattempted).
  final double currentWeakness;

  /// Evidence confidence multiplier [0.0, 1.0].
  final double evidenceConfidence;

  /// Whether historical corpus has sufficient evidence for this exam.
  final bool hasSufficientHistoricalEvidence;

  /// Composite priority score in [0.0, 1.0].
  final double priorityScore;

  /// Machine-readable rationale breakdown.
  final PyqPriorityRationale rationale;

  const PyqLearningPrioritySignal({
    required this.examId,
    this.objectiveId,
    this.topic,
    this.subject,
    required this.level,
    required this.historicalQuestionCount,
    required this.historicalShare,
    required this.yearsObserved,
    required this.recurrenceCount,
    required this.recentHistoricalShare,
    required this.learnerEvidenceCount,
    this.learnerAccuracy,
    required this.currentWeakness,
    required this.evidenceConfidence,
    required this.hasSufficientHistoricalEvidence,
    required this.priorityScore,
    required this.rationale,
  });

  /// Primary entity identifier (objectiveId ?? topic ?? subject ?? examId).
  String get targetId => objectiveId ?? topic ?? subject ?? examId;

  Map<String, dynamic> toJson() => {
        'examId': examId,
        if (objectiveId != null) 'objectiveId': objectiveId,
        if (topic != null) 'topic': topic,
        if (subject != null) 'subject': subject,
        'level': level.name,
        'historicalQuestionCount': historicalQuestionCount,
        'historicalShare': historicalShare,
        'yearsObserved': yearsObserved,
        'recurrenceCount': recurrenceCount,
        'recentHistoricalShare': recentHistoricalShare,
        'learnerEvidenceCount': learnerEvidenceCount,
        if (learnerAccuracy != null) 'learnerAccuracy': learnerAccuracy,
        'currentWeakness': currentWeakness,
        'evidenceConfidence': evidenceConfidence,
        'hasSufficientHistoricalEvidence': hasSufficientHistoricalEvidence,
        'priorityScore': priorityScore,
        'rationale': rationale.toJson(),
      };

  factory PyqLearningPrioritySignal.fromJson(Map<String, dynamic> json) =>
      PyqLearningPrioritySignal(
        examId: json['examId'] as String? ?? '',
        objectiveId: json['objectiveId'] as String?,
        topic: json['topic'] as String?,
        subject: json['subject'] as String?,
        level: PrioritySignalLevel.values.firstWhere(
          (e) => e.name == json['level'],
          orElse: () => PrioritySignalLevel.none,
        ),
        historicalQuestionCount:
            (json['historicalQuestionCount'] as num?)?.toInt() ?? 0,
        historicalShare: (json['historicalShare'] as num?)?.toDouble() ?? 0.0,
        yearsObserved: (json['yearsObserved'] as num?)?.toInt() ?? 0,
        recurrenceCount: (json['recurrenceCount'] as num?)?.toInt() ?? 0,
        recentHistoricalShare:
            (json['recentHistoricalShare'] as num?)?.toDouble() ?? 0.0,
        learnerEvidenceCount:
            (json['learnerEvidenceCount'] as num?)?.toInt() ?? 0,
        learnerAccuracy: (json['learnerAccuracy'] as num?)?.toDouble(),
        currentWeakness: (json['currentWeakness'] as num?)?.toDouble() ?? 0.0,
        evidenceConfidence:
            (json['evidenceConfidence'] as num?)?.toDouble() ?? 0.0,
        hasSufficientHistoricalEvidence:
            json['hasSufficientHistoricalEvidence'] as bool? ?? false,
        priorityScore: (json['priorityScore'] as num?)?.toDouble() ?? 0.0,
        rationale: PyqPriorityRationale.fromJson(
          json['rationale'] as Map<String, dynamic>? ??
              const <String, dynamic>{},
        ),
      );

  @override
  String toString() =>
      'PyqLearningPrioritySignal(target: $targetId, level: ${level.name}, priorityScore: ${priorityScore.toStringAsFixed(4)}, histCount: $historicalQuestionCount, histShare: ${(historicalShare * 100).toStringAsFixed(1)}%, weakness: ${(currentWeakness * 100).toStringAsFixed(1)}%)';
}
