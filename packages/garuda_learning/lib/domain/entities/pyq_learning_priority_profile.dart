/// Adaptive PYQ Learning Priority Profile Entity (TITAN-KO-032.0 P32).
///
/// Deterministic container capturing priority signals for all objectives, topics,
/// and subjects for a specific target exam, alongside evidence threshold status.
///
/// Invariants:
/// - No DateTime.now() — explicit caller-supplied timestamp only.
/// - Deterministically sorted signal lists (priorityScore DESC, identifier ASC).
/// - Fast O(1) indexed lookup by objectiveId, topic, or subject.
/// - Explicit fallback hierarchy (objective -> topicFallback -> subjectFallback -> none).
library;

import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:meta/meta.dart';

import 'pyq_learning_priority_config.dart';
import 'pyq_learning_priority_signal.dart';

@immutable
class PyqLearningPriorityProfile {
  /// Target exam identifier (e.g. 'upsc', 'bpsc', 'ssc').
  final String examId;

  /// Explicit UTC timestamp of evaluation (caller-supplied; never DateTime.now()).
  final DateTime? evaluatedAt;

  /// Evaluated objective priority signals, sorted by priorityScore DESC, objectiveId ASC.
  final List<PyqLearningPrioritySignal> objectiveSignals;

  /// Evaluated topic priority signals, sorted by priorityScore DESC, topic ASC.
  final List<PyqLearningPrioritySignal> topicSignals;

  /// Evaluated subject priority signals, sorted by priorityScore DESC, subject ASC.
  final List<PyqLearningPrioritySignal> subjectSignals;

  /// Whether the historical corpus for this exam meets minimum evidence thresholds.
  final bool sufficientEvidence;

  /// Total historical questions available in the exam corpus.
  final int corpusQuestionCount;

  /// Validated configuration used to generate this profile.
  final PyqLearningPriorityConfig config;

  /// Evidence thresholds applied.
  final EvidenceThresholds thresholds;

  /// Optional evaluation metadata.
  final Map<String, dynamic> metadata;

  // Internal lookups for O(1) retrieval
  final Map<String, PyqLearningPrioritySignal> _objectiveMap;
  final Map<String, PyqLearningPrioritySignal> _topicMap;
  final Map<String, PyqLearningPrioritySignal> _subjectMap;

  PyqLearningPriorityProfile({
    required this.examId,
    this.evaluatedAt,
    required List<PyqLearningPrioritySignal> objectiveSignals,
    required List<PyqLearningPrioritySignal> topicSignals,
    required List<PyqLearningPrioritySignal> subjectSignals,
    required this.sufficientEvidence,
    required this.corpusQuestionCount,
    required this.config,
    required this.thresholds,
    Map<String, dynamic>? metadata,
  })  : objectiveSignals = List.unmodifiable(objectiveSignals),
        topicSignals = List.unmodifiable(topicSignals),
        subjectSignals = List.unmodifiable(subjectSignals),
        metadata = Map.unmodifiable(metadata ?? const <String, dynamic>{}),
        _objectiveMap = {
          for (final s in objectiveSignals)
            if (s.objectiveId != null) s.objectiveId!: s,
        },
        _topicMap = {
          for (final s in topicSignals)
            if (s.topic != null) s.topic!: s,
        },
        _subjectMap = {
          for (final s in subjectSignals)
            if (s.subject != null) s.subject!: s,
        };

  /// Retrieves the priority signal for an objective.
  ///
  /// Fallback Hierarchy:
  /// 1. Objective-level signal if mapped in historical PYQ corpus.
  /// 2. Topic-level signal fallback if [topic] is provided and has historical evidence.
  /// 3. Subject-level signal fallback if [subject] is provided and has historical evidence.
  /// 4. Safe neutral fallback with level [PrioritySignalLevel.none] and 0.0 historical score.
  PyqLearningPrioritySignal getObjectiveSignal(
    String objectiveId, {
    String? topic,
    String? subject,
    int learnerEvidenceCount = 0,
    double? learnerAccuracy,
    double currentWeakness = 0.0,
  }) {
    // 1. Direct objective mapping
    final direct = _objectiveMap[objectiveId];
    if (direct != null) return direct;

    // 2. Topic fallback
    if (topic != null && topic.isNotEmpty) {
      final topicSignal = _topicMap[topic];
      if (topicSignal != null) {
        return _deriveFallbackSignal(
          originalTargetId: objectiveId,
          baseSignal: topicSignal,
          fallbackLevel: PrioritySignalLevel.topicFallback,
          objectiveId: objectiveId,
          topic: topic,
          subject: subject ?? topicSignal.subject,
          learnerEvidenceCount: learnerEvidenceCount,
          learnerAccuracy: learnerAccuracy,
          currentWeakness: currentWeakness,
        );
      }
    }

    // 3. Subject fallback
    if (subject != null && subject.isNotEmpty) {
      final subjectSignal = _subjectMap[subject];
      if (subjectSignal != null) {
        return _deriveFallbackSignal(
          originalTargetId: objectiveId,
          baseSignal: subjectSignal,
          fallbackLevel: PrioritySignalLevel.subjectFallback,
          objectiveId: objectiveId,
          topic: topic,
          subject: subject,
          learnerEvidenceCount: learnerEvidenceCount,
          learnerAccuracy: learnerAccuracy,
          currentWeakness: currentWeakness,
        );
      }
    }

    // 4. No historical signal
    final hasLearnerEv = learnerEvidenceCount >= config.minimumLearnerAttempts;
    final weakContrib = hasLearnerEv
        ? (config.normalizedWeaknessWeight * currentWeakness).clamp(0.0, 1.0)
        : 0.0;

    return PyqLearningPrioritySignal(
      examId: examId,
      objectiveId: objectiveId,
      topic: topic,
      subject: subject,
      level: PrioritySignalLevel.none,
      historicalQuestionCount: 0,
      historicalShare: 0.0,
      yearsObserved: 0,
      recurrenceCount: 0,
      recentHistoricalShare: 0.0,
      learnerEvidenceCount: learnerEvidenceCount,
      learnerAccuracy: learnerAccuracy,
      currentWeakness: hasLearnerEv ? currentWeakness : 0.0,
      evidenceConfidence: 0.0,
      hasSufficientHistoricalEvidence: false,
      priorityScore: weakContrib,
      rationale: PyqPriorityRationale(
        historicalShareContribution: 0.0,
        recurrenceContribution: 0.0,
        recencyContribution: 0.0,
        learnerWeaknessContribution: weakContrib,
        confidenceAdjustment: 0.0,
        fallbackLevel: PrioritySignalLevel.none,
        hasSufficientHistoricalEvidence: false,
        hasSufficientLearnerEvidence: hasLearnerEv,
        rationaleCode: 'NO_HISTORICAL_EVIDENCE',
      ),
    );
  }

  /// Retrieves topic-level priority signal, or fallback if unknown.
  PyqLearningPrioritySignal getTopicSignal(
    String topic, {
    String? subject,
    int learnerEvidenceCount = 0,
    double? learnerAccuracy,
    double currentWeakness = 0.0,
  }) {
    final direct = _topicMap[topic];
    if (direct != null) return direct;

    if (subject != null && subject.isNotEmpty) {
      final subjectSignal = _subjectMap[subject];
      if (subjectSignal != null) {
        return _deriveFallbackSignal(
          originalTargetId: topic,
          baseSignal: subjectSignal,
          fallbackLevel: PrioritySignalLevel.subjectFallback,
          topic: topic,
          subject: subject,
          learnerEvidenceCount: learnerEvidenceCount,
          learnerAccuracy: learnerAccuracy,
          currentWeakness: currentWeakness,
        );
      }
    }

    final hasLearnerEv = learnerEvidenceCount >= config.minimumLearnerAttempts;
    final weakContrib = hasLearnerEv
        ? (config.normalizedWeaknessWeight * currentWeakness).clamp(0.0, 1.0)
        : 0.0;

    return PyqLearningPrioritySignal(
      examId: examId,
      topic: topic,
      subject: subject,
      level: PrioritySignalLevel.none,
      historicalQuestionCount: 0,
      historicalShare: 0.0,
      yearsObserved: 0,
      recurrenceCount: 0,
      recentHistoricalShare: 0.0,
      learnerEvidenceCount: learnerEvidenceCount,
      learnerAccuracy: learnerAccuracy,
      currentWeakness: hasLearnerEv ? currentWeakness : 0.0,
      evidenceConfidence: 0.0,
      hasSufficientHistoricalEvidence: false,
      priorityScore: weakContrib,
      rationale: PyqPriorityRationale(
        historicalShareContribution: 0.0,
        recurrenceContribution: 0.0,
        recencyContribution: 0.0,
        learnerWeaknessContribution: weakContrib,
        confidenceAdjustment: 0.0,
        fallbackLevel: PrioritySignalLevel.none,
        hasSufficientHistoricalEvidence: false,
        hasSufficientLearnerEvidence: hasLearnerEv,
        rationaleCode: 'NO_HISTORICAL_EVIDENCE',
      ),
    );
  }

  /// Retrieves subject-level priority signal.
  PyqLearningPrioritySignal getSubjectSignal(
    String subject, {
    int learnerEvidenceCount = 0,
    double? learnerAccuracy,
    double currentWeakness = 0.0,
  }) {
    final direct = _subjectMap[subject];
    if (direct != null) return direct;

    final hasLearnerEv = learnerEvidenceCount >= config.minimumLearnerAttempts;
    final weakContrib = hasLearnerEv
        ? (config.normalizedWeaknessWeight * currentWeakness).clamp(0.0, 1.0)
        : 0.0;

    return PyqLearningPrioritySignal(
      examId: examId,
      subject: subject,
      level: PrioritySignalLevel.none,
      historicalQuestionCount: 0,
      historicalShare: 0.0,
      yearsObserved: 0,
      recurrenceCount: 0,
      recentHistoricalShare: 0.0,
      learnerEvidenceCount: learnerEvidenceCount,
      learnerAccuracy: learnerAccuracy,
      currentWeakness: hasLearnerEv ? currentWeakness : 0.0,
      evidenceConfidence: 0.0,
      hasSufficientHistoricalEvidence: false,
      priorityScore: weakContrib,
      rationale: PyqPriorityRationale(
        historicalShareContribution: 0.0,
        recurrenceContribution: 0.0,
        recencyContribution: 0.0,
        learnerWeaknessContribution: weakContrib,
        confidenceAdjustment: 0.0,
        fallbackLevel: PrioritySignalLevel.none,
        hasSufficientHistoricalEvidence: false,
        hasSufficientLearnerEvidence: hasLearnerEv,
        rationaleCode: 'NO_HISTORICAL_EVIDENCE',
      ),
    );
  }

  /// Helper to derive a fallback signal with explicit level annotation and recalculated rationale.
  PyqLearningPrioritySignal _deriveFallbackSignal({
    required String originalTargetId,
    required PyqLearningPrioritySignal baseSignal,
    required PrioritySignalLevel fallbackLevel,
    String? objectiveId,
    String? topic,
    String? subject,
    required int learnerEvidenceCount,
    double? learnerAccuracy,
    required double currentWeakness,
  }) {
    final hasLearnerEv = learnerEvidenceCount >= config.minimumLearnerAttempts;
    final effectiveWeakness = hasLearnerEv ? currentWeakness : 0.0;

    final weakContrib =
        (config.normalizedWeaknessWeight * effectiveWeakness).clamp(0.0, 1.0);
    final histContrib = baseSignal.rationale.historicalShareContribution;
    final recContrib = baseSignal.rationale.recurrenceContribution;
    final recencyContrib = baseSignal.rationale.recencyContribution;

    final composite = (histContrib + recContrib + recencyContrib + weakContrib)
        .clamp(0.0, 1.0);

    return PyqLearningPrioritySignal(
      examId: examId,
      objectiveId: objectiveId,
      topic: topic,
      subject: subject,
      level: fallbackLevel,
      historicalQuestionCount: baseSignal.historicalQuestionCount,
      historicalShare: baseSignal.historicalShare,
      yearsObserved: baseSignal.yearsObserved,
      recurrenceCount: baseSignal.recurrenceCount,
      recentHistoricalShare: baseSignal.recentHistoricalShare,
      learnerEvidenceCount: learnerEvidenceCount,
      learnerAccuracy: learnerAccuracy,
      currentWeakness: effectiveWeakness,
      evidenceConfidence: baseSignal.evidenceConfidence,
      hasSufficientHistoricalEvidence:
          baseSignal.hasSufficientHistoricalEvidence,
      priorityScore: composite,
      rationale: PyqPriorityRationale(
        historicalShareContribution: histContrib,
        recurrenceContribution: recContrib,
        recencyContribution: recencyContrib,
        learnerWeaknessContribution: weakContrib,
        confidenceAdjustment: baseSignal.evidenceConfidence,
        fallbackLevel: fallbackLevel,
        hasSufficientHistoricalEvidence:
            baseSignal.hasSufficientHistoricalEvidence,
        hasSufficientLearnerEvidence: hasLearnerEv,
        rationaleCode: 'FALLBACK_${fallbackLevel.name.toUpperCase()}',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'examId': examId,
        if (evaluatedAt != null) 'evaluatedAt': evaluatedAt!.toIso8601String(),
        'objectiveSignals': objectiveSignals.map((s) => s.toJson()).toList(),
        'topicSignals': topicSignals.map((s) => s.toJson()).toList(),
        'subjectSignals': subjectSignals.map((s) => s.toJson()).toList(),
        'sufficientEvidence': sufficientEvidence,
        'corpusQuestionCount': corpusQuestionCount,
        'config': config.toJson(),
        'thresholds': thresholds.toJson(),
        'metadata': metadata,
      };
}
