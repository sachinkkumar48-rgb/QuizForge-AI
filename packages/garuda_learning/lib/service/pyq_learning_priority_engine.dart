/// Adaptive PYQ Learning Priority Engine (TITAN-KO-032.0 P32).
///
/// Pure, deterministic calculation engine that synthesizes P31 Historical PYQ
/// Intelligence with P23 Learner Diagnostics and P18 Progress Evidence.
///
/// Educational Safety Invariants:
/// - Strictly calls P31 engine; never duplicates historical corpus aggregations.
/// - Consumes P23 analytics; never recalculates mastery, retention, or velocity.
/// - Absence of learner evidence NEVER constitutes a weak spot (learner weakness = 0.0).
/// - High historical PYQ representation NEVER implies learner weakness.
/// - Pure quantitative scoring; zero predictive assertions ("will appear next year").
/// - Deterministic tie-breaking: priorityScore DESC, targetId ASC.
/// - Zero DateTime.now() — caller-supplied evaluation timestamps only.
library;

import 'package:garuda_pyq/garuda_pyq.dart';

import '../domain/entities/learner_progress.dart';
import '../domain/entities/pyq_learning_priority_config.dart';
import '../domain/entities/pyq_learning_priority_profile.dart';
import '../domain/entities/pyq_learning_priority_signal.dart';
import '../domain/entities/weak_spot_profile.dart';

/// Purely deterministic engine evaluating PYQ learning priority profiles.
class PyqLearningPriorityEngine {
  /// Validated priority configuration.
  final PyqLearningPriorityConfig config;

  /// P31 Historical Intelligence Engine used for corpus analytics.
  final PyqHistoricalIntelligenceEngine p31Engine;

  PyqLearningPriorityEngine({
    PyqLearningPriorityConfig? config,
    this.p31Engine = const PyqHistoricalIntelligenceEngine(),
  }) : config = config ?? PyqLearningPriorityConfig();

  /// Evaluates an exam-wide priority profile from an existing P31 [ExamIntelligenceProfile].
  ///
  /// Parameters:
  /// - [examProfile]: Authoritative P31 intelligence profile for the target exam.
  /// - [weakSpotProfile]: Optional P23 diagnosed weak-spot profile for the learner.
  /// - [progressList]: Optional P18 raw progress records for the learner.
  /// - [evaluatedAt]: Explicit UTC timestamp.
  /// - [recentWindowYears]: Number of trailing years to consider for recency (default: 3).
  PyqLearningPriorityProfile evaluateFromExamProfile({
    required ExamIntelligenceProfile examProfile,
    WeakSpotProfile? weakSpotProfile,
    List<LearnerProgress>? progressList,
    DateTime? evaluatedAt,
    int recentWindowYears = 3,
  }) {
    final effectiveEvaluatedAt = evaluatedAt?.toUtc();
    final examId = examProfile.examId.toLowerCase().trim();
    final totalQuestions = examProfile.questionCount;
    final sufficientEvidence = examProfile.sufficientEvidence &&
        totalQuestions >= config.minimumHistoricalQuestions;

    // 1. Compute corpus confidence multiplier
    final double historicalConfidence;
    if (!config.confidenceGating) {
      historicalConfidence = 1.0;
    } else if (totalQuestions == 0) {
      historicalConfidence = 0.0;
    } else if (totalQuestions < config.minimumHistoricalQuestions) {
      historicalConfidence =
          (totalQuestions / config.minimumHistoricalQuestions).clamp(0.0, 1.0);
    } else {
      historicalConfidence = 1.0;
    }

    // 2. Index learner evidence
    final learnerMap = _indexLearnerEvidence(
      weakSpotProfile: weakSpotProfile,
      progressList: progressList,
    );

    // 3. Resolve recent year window
    final distinctYears = examProfile.yearDistribution.entries.length;
    final maxYear = examProfile.maxYear;
    final recentStartYear =
        (maxYear != null) ? (maxYear - recentWindowYears + 1) : 0;

    int totalRecentQuestions = 0;
    int recentDistinctYears = 0;
    final recentCountsByTopic = <String, int>{};
    final recentCountsBySubject = <String, int>{};

    for (final yearEntry in examProfile.yearDistribution.entries) {
      if (yearEntry.year >= recentStartYear) {
        recentDistinctYears++;
        totalRecentQuestions += yearEntry.questionCount;
        for (final t in yearEntry.topicDistribution.entries) {
          recentCountsByTopic[t.key] =
              (recentCountsByTopic[t.key] ?? 0) + t.value;
        }
        for (final s in yearEntry.subjectDistribution.entries) {
          recentCountsBySubject[s.key] =
              (recentCountsBySubject[s.key] ?? 0) + s.value;
        }
      }
    }

    // Index topic and subject recurrence profiles
    final topicRecurrenceMap = <String, RecurringProfile>{
      for (final r in examProfile.topicRecurrence) r.id: r,
    };
    final objectiveRecurrenceMap = <String, RecurringProfile>{
      for (final r in examProfile.objectiveRecurrence) r.id: r,
    };

    // 4. Generate Objective Priority Signals
    final objectiveSignals = <PyqLearningPrioritySignal>[];
    for (final entry in examProfile.objectiveCoverage.coveredObjectives) {
      final objId = entry.objectiveId;
      final histCount = entry.questionCount;
      final histShare = totalQuestions > 0 ? (histCount / totalQuestions) : 0.0;

      final recProfile = objectiveRecurrenceMap[objId];
      final yearsObserved = entry.yearsRepresented.length;
      final recurrenceCount = recProfile?.yearCount ?? yearsObserved;
      final recurrenceScore = distinctYears > 0
          ? (recurrenceCount / distinctYears).clamp(0.0, 1.0)
          : 0.0;

      // Calculate recent share for this objective (fraction of recent years represented)
      int recentYearsCount = 0;
      for (final y in entry.yearsRepresented) {
        if (y >= recentStartYear) {
          recentYearsCount++;
        }
      }
      final recentHistoricalShare = recentDistinctYears > 0
          ? (recentYearsCount / recentDistinctYears).clamp(0.0, 1.0)
          : 0.0;

      // Learner evidence
      final learnerEv = learnerMap[objId];
      final learnerCount = learnerEv?.attemptCount ?? 0;
      final learnerAcc = learnerEv?.accuracy;
      final weakness = learnerEv?.deficiencyScore ?? 0.0;
      final hasSufficientLearnerEv =
          learnerCount >= config.minimumLearnerAttempts;
      final effectiveWeakness = hasSufficientLearnerEv ? weakness : 0.0;

      // Compute weighted components
      final histContrib =
          (config.normalizedHistoricalWeight * histShare * historicalConfidence)
              .clamp(0.0, 1.0);
      final recContrib = (config.normalizedRecurrenceWeight *
              recurrenceScore *
              historicalConfidence)
          .clamp(0.0, 1.0);
      final recencyContrib = (config.normalizedRecencyWeight *
              recentHistoricalShare *
              historicalConfidence)
          .clamp(0.0, 1.0);
      final weakContrib =
          (config.normalizedWeaknessWeight * effectiveWeakness).clamp(0.0, 1.0);

      final priorityScore =
          (histContrib + recContrib + recencyContrib + weakContrib)
              .clamp(0.0, 1.0);

      objectiveSignals.add(PyqLearningPrioritySignal(
        examId: examId,
        objectiveId: objId,
        subject: entry.subjectsRepresented.isNotEmpty
            ? entry.subjectsRepresented.first
            : null,
        level: PrioritySignalLevel.objective,
        historicalQuestionCount: histCount,
        historicalShare: histShare,
        yearsObserved: yearsObserved,
        recurrenceCount: recurrenceCount,
        recentHistoricalShare: recentHistoricalShare,
        learnerEvidenceCount: learnerCount,
        learnerAccuracy: learnerAcc,
        currentWeakness: effectiveWeakness,
        evidenceConfidence: historicalConfidence,
        hasSufficientHistoricalEvidence: sufficientEvidence,
        priorityScore: priorityScore,
        rationale: PyqPriorityRationale(
          historicalShareContribution: histContrib,
          recurrenceContribution: recContrib,
          recencyContribution: recencyContrib,
          learnerWeaknessContribution: weakContrib,
          confidenceAdjustment: historicalConfidence,
          fallbackLevel: PrioritySignalLevel.objective,
          hasSufficientHistoricalEvidence: sufficientEvidence,
          hasSufficientLearnerEvidence: hasSufficientLearnerEv,
          rationaleCode: 'OBJECTIVE_SIGNAL',
        ),
      ));
    }

    // 5. Generate Topic Priority Signals
    final topicSignals = <PyqLearningPrioritySignal>[];
    for (final entry in examProfile.topicWeightage.entries) {
      final topic = entry.category;
      final histCount = entry.count;
      final histShare = totalQuestions > 0 ? (histCount / totalQuestions) : 0.0;

      final recProfile = topicRecurrenceMap[topic];
      final recurrenceCount = recProfile?.yearCount ?? 0;
      final recurrenceScore = distinctYears > 0
          ? (recurrenceCount / distinctYears).clamp(0.0, 1.0)
          : 0.0;

      final recentCount = recentCountsByTopic[topic] ?? 0;
      final recentHistoricalShare = totalRecentQuestions > 0
          ? (recentCount / totalRecentQuestions).clamp(0.0, 1.0)
          : 0.0;

      // Topic learner evidence
      final learnerEv = learnerMap[topic];
      final learnerCount = learnerEv?.attemptCount ?? 0;
      final learnerAcc = learnerEv?.accuracy;
      final weakness = learnerEv?.deficiencyScore ?? 0.0;
      final hasSufficientLearnerEv =
          learnerCount >= config.minimumLearnerAttempts;
      final effectiveWeakness = hasSufficientLearnerEv ? weakness : 0.0;

      final histContrib =
          (config.normalizedHistoricalWeight * histShare * historicalConfidence)
              .clamp(0.0, 1.0);
      final recContrib = (config.normalizedRecurrenceWeight *
              recurrenceScore *
              historicalConfidence)
          .clamp(0.0, 1.0);
      final recencyContrib = (config.normalizedRecencyWeight *
              recentHistoricalShare *
              historicalConfidence)
          .clamp(0.0, 1.0);
      final weakContrib =
          (config.normalizedWeaknessWeight * effectiveWeakness).clamp(0.0, 1.0);

      final priorityScore =
          (histContrib + recContrib + recencyContrib + weakContrib)
              .clamp(0.0, 1.0);

      topicSignals.add(PyqLearningPrioritySignal(
        examId: examId,
        topic: topic,
        level: PrioritySignalLevel.topicFallback,
        historicalQuestionCount: histCount,
        historicalShare: histShare,
        yearsObserved: recProfile?.yearsPresent.length ?? 0,
        recurrenceCount: recurrenceCount,
        recentHistoricalShare: recentHistoricalShare,
        learnerEvidenceCount: learnerCount,
        learnerAccuracy: learnerAcc,
        currentWeakness: effectiveWeakness,
        evidenceConfidence: historicalConfidence,
        hasSufficientHistoricalEvidence: sufficientEvidence,
        priorityScore: priorityScore,
        rationale: PyqPriorityRationale(
          historicalShareContribution: histContrib,
          recurrenceContribution: recContrib,
          recencyContribution: recencyContrib,
          learnerWeaknessContribution: weakContrib,
          confidenceAdjustment: historicalConfidence,
          fallbackLevel: PrioritySignalLevel.topicFallback,
          hasSufficientHistoricalEvidence: sufficientEvidence,
          hasSufficientLearnerEvidence: hasSufficientLearnerEv,
          rationaleCode: 'TOPIC_SIGNAL',
        ),
      ));
    }

    // 6. Generate Subject Priority Signals
    final subjectSignals = <PyqLearningPrioritySignal>[];
    for (final entry in examProfile.subjectWeightage.entries) {
      final subject = entry.category;
      final histCount = entry.count;
      final histShare = totalQuestions > 0 ? (histCount / totalQuestions) : 0.0;

      final recentCount = recentCountsBySubject[subject] ?? 0;
      final recentHistoricalShare = totalRecentQuestions > 0
          ? (recentCount / totalRecentQuestions).clamp(0.0, 1.0)
          : 0.0;

      // Subject learner evidence
      final learnerEv = learnerMap[subject];
      final learnerCount = learnerEv?.attemptCount ?? 0;
      final learnerAcc = learnerEv?.accuracy;
      final weakness = learnerEv?.deficiencyScore ?? 0.0;
      final hasSufficientLearnerEv =
          learnerCount >= config.minimumLearnerAttempts;
      final effectiveWeakness = hasSufficientLearnerEv ? weakness : 0.0;

      final histContrib =
          (config.normalizedHistoricalWeight * histShare * historicalConfidence)
              .clamp(0.0, 1.0);
      // Subjects don't use recurrence directly (use 1.0 if present)
      final recContrib =
          (config.normalizedRecurrenceWeight * 1.0 * historicalConfidence)
              .clamp(0.0, 1.0);
      final recencyContrib = (config.normalizedRecencyWeight *
              recentHistoricalShare *
              historicalConfidence)
          .clamp(0.0, 1.0);
      final weakContrib =
          (config.normalizedWeaknessWeight * effectiveWeakness).clamp(0.0, 1.0);

      final priorityScore =
          (histContrib + recContrib + recencyContrib + weakContrib)
              .clamp(0.0, 1.0);

      subjectSignals.add(PyqLearningPrioritySignal(
        examId: examId,
        subject: subject,
        level: PrioritySignalLevel.subjectFallback,
        historicalQuestionCount: histCount,
        historicalShare: histShare,
        yearsObserved: distinctYears,
        recurrenceCount: distinctYears,
        recentHistoricalShare: recentHistoricalShare,
        learnerEvidenceCount: learnerCount,
        learnerAccuracy: learnerAcc,
        currentWeakness: effectiveWeakness,
        evidenceConfidence: historicalConfidence,
        hasSufficientHistoricalEvidence: sufficientEvidence,
        priorityScore: priorityScore,
        rationale: PyqPriorityRationale(
          historicalShareContribution: histContrib,
          recurrenceContribution: recContrib,
          recencyContribution: recencyContrib,
          learnerWeaknessContribution: weakContrib,
          confidenceAdjustment: historicalConfidence,
          fallbackLevel: PrioritySignalLevel.subjectFallback,
          hasSufficientHistoricalEvidence: sufficientEvidence,
          hasSufficientLearnerEvidence: hasSufficientLearnerEv,
          rationaleCode: 'SUBJECT_SIGNAL',
        ),
      ));
    }

    // 7. Deterministic sorting: priorityScore DESC, identifier ASC
    objectiveSignals.sort((a, b) {
      final cmp = b.priorityScore.compareTo(a.priorityScore);
      if (cmp != 0) return cmp;
      return (a.objectiveId ?? '').compareTo(b.objectiveId ?? '');
    });

    topicSignals.sort((a, b) {
      final cmp = b.priorityScore.compareTo(a.priorityScore);
      if (cmp != 0) return cmp;
      return (a.topic ?? '').compareTo(b.topic ?? '');
    });

    subjectSignals.sort((a, b) {
      final cmp = b.priorityScore.compareTo(a.priorityScore);
      if (cmp != 0) return cmp;
      return (a.subject ?? '').compareTo(b.subject ?? '');
    });

    return PyqLearningPriorityProfile(
      examId: examId,
      evaluatedAt: effectiveEvaluatedAt,
      objectiveSignals: objectiveSignals,
      topicSignals: topicSignals,
      subjectSignals: subjectSignals,
      sufficientEvidence: sufficientEvidence,
      corpusQuestionCount: totalQuestions,
      config: config,
      thresholds: examProfile.thresholds,
      metadata: {
        'historicalConfidence': historicalConfidence,
        'distinctYears': distinctYears,
        'recentWindowYears': recentWindowYears,
      },
    );
  }

  /// Convenience entry point that computes P31 [ExamIntelligenceProfile] from
  /// questions and immediately evaluates the P32 [PyqLearningPriorityProfile].
  PyqLearningPriorityProfile evaluateFromQuestions({
    required List<NormalizedQuestion> questions,
    required String examId,
    List<String> frameworkObjectiveIds = const [],
    WeakSpotProfile? weakSpotProfile,
    List<LearnerProgress>? progressList,
    DateTime? evaluatedAt,
    int recentWindowYears = 3,
  }) {
    final eid = examId.trim().toLowerCase();
    final examProfile = p31Engine.buildExamProfile(
      questions,
      examId: eid,
      frameworkObjectiveIds: frameworkObjectiveIds,
    );

    return evaluateFromExamProfile(
      examProfile: examProfile,
      weakSpotProfile: weakSpotProfile,
      progressList: progressList,
      evaluatedAt: evaluatedAt,
      recentWindowYears: recentWindowYears,
    );
  }

  // --------------------------------------------------------------------------
  // PRIVATE HELPERS
  // --------------------------------------------------------------------------

  static Map<String, _LearnerEvidence> _indexLearnerEvidence({
    WeakSpotProfile? weakSpotProfile,
    List<LearnerProgress>? progressList,
  }) {
    final map = <String, _LearnerEvidence>{};

    if (weakSpotProfile != null) {
      for (final diag in weakSpotProfile.weakObjectives) {
        map[diag.objectiveId] = _LearnerEvidence(
          attemptCount: diag.attemptCount,
          accuracy: diag.observedAccuracy,
          deficiencyScore: diag.deficiencyScore,
        );
      }
    }

    if (progressList != null) {
      for (final p in progressList) {
        // If not already in weak spot profile, record observed accuracy
        if (!map.containsKey(p.objectiveId)) {
          final attempts = p.attemptCount;
          final acc = attempts > 0 ? (p.correctCount / attempts) : null;
          final deficiency = acc != null ? (1.0 - acc).clamp(0.0, 1.0) : 0.0;
          map[p.objectiveId] = _LearnerEvidence(
            attemptCount: attempts,
            accuracy: acc,
            deficiencyScore: deficiency,
          );
        }
      }
    }

    return map;
  }
}

class _LearnerEvidence {
  final int attemptCount;
  final double? accuracy;
  final double deficiencyScore;

  const _LearnerEvidence({
    required this.attemptCount,
    this.accuracy,
    required this.deficiencyScore,
  });
}
