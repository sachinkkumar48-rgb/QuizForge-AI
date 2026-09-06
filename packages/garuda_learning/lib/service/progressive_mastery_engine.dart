/// Progressive Mastery Engine Service (TITAN-KO-040.0 P40).
///
/// Production deterministic mastery engine computing explainable, progressive topic
/// and concept mastery profiles and adaptive decision signals from authoritative
/// learner progress (P38/P39) and practice outcome evidence (P35/P36/P43).
library;

import 'dart:collection';
import 'dart:math' as math;

import '../domain/entities/adaptive_mastery_decision_output.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/learner_mastery_snapshot.dart';
import '../domain/entities/mastery_classification.dart';
import '../domain/entities/mastery_engine_config.dart';
import '../domain/entities/mastery_evidence.dart';
import '../domain/entities/mastery_exceptions.dart';
import '../domain/entities/practice_outcome_evidence.dart';
import '../domain/entities/topic_mastery_profile.dart';

/// Deterministic progressive mastery engine.
class ProgressiveMasteryEngine {
  final MasteryEngineConfig config;

  const ProgressiveMasteryEngine({
    this.config = const MasteryEngineConfig(),
  });

  // ---------------------------------------------------------------------------
  // 1. Core Incremental Update Algorithm
  // ---------------------------------------------------------------------------

  /// Updates a single topic's mastery profile incrementally from new evidence items.
  ///
  /// Mathematical Guarantees:
  /// - Deterministic: identical prior state + identical evidence = identical result.
  /// - Bounded: mastery score strictly within [config.minMastery, config.maxMastery].
  /// - Bounded: confidence strictly within [0.0, config.maxConfidence].
  /// - Asymptotic diminishing returns on mastery score growth near upper bound.
  /// - Educationally sound difficulty scaling: missing an Easy question penalizes more
  ///   than missing a Hard question; answering a Hard question yields higher gain.
  TopicMasteryProfile updateTopicMastery({
    required TopicMasteryProfile currentProfile,
    required List<MasteryEvidenceItem> evidenceItems,
    required DateTime evaluatedAt,
    required int revision,
  }) {
    final effectiveTs = evaluatedAt.toUtc();
    final topic = currentProfile.topicId;

    if (evidenceItems.isEmpty) {
      return currentProfile.copyWith(
        lastEvaluatedRevision: revision,
        lastEvaluatedAt: effectiveTs,
      );
    }

    // Tenant check
    for (final e in evidenceItems) {
      if (e.topicId != topic) {
        throw InvalidMasteryEvidenceException(
          message:
              'Evidence topic "${e.topicId}" does not match target profile topic "$topic"',
          details: {'evidenceId': e.evidenceId, 'targetTopic': topic},
        );
      }
    }

    // Sort evidence deterministically: timestamp ascending, then evidenceId ascending
    final sortedEvidence = List<MasteryEvidenceItem>.from(evidenceItems)
      ..sort((a, b) {
        final cmp = a.timestamp.compareTo(b.timestamp);
        if (cmp != 0) return cmp;
        return a.evidenceId.compareTo(b.evidenceId);
      });

    double currentScore = currentProfile.masteryScore;
    double currentConfidence = currentProfile.confidence;
    int totalEvidence = currentProfile.evidenceCount;
    int correct = currentProfile.correctCount;
    int incorrect = currentProfile.incorrectCount;

    final reasons = <String>[];
    final recentAttempts = <bool>[];

    // Seed recent attempts from previous accuracy if known
    if (currentProfile.recentAccuracy != null &&
        currentProfile.evidenceCount > 0) {
      final seedCount =
          math.min(currentProfile.evidenceCount, config.recentWindowSize);
      final correctSeed = (seedCount * currentProfile.recentAccuracy!).round();
      for (var i = 0; i < seedCount; i++) {
        recentAttempts.add(i < correctSeed);
      }
    }

    for (final item in sortedEvidence) {
      totalEvidence++;
      final diffWeight = config.getDifficultyWeight(item.difficulty);

      // Recency weighting
      double recencyFactor = 1.0;
      if (config.recencyHalfLifeDays > 0) {
        final daysElapsed =
            effectiveTs.difference(item.timestamp.toUtc()).inSeconds / 86400.0;
        if (daysElapsed > 0) {
          recencyFactor = math
              .pow(0.5, daysElapsed / config.recencyHalfLifeDays)
              .toDouble();
          recencyFactor = recencyFactor.clamp(0.20, 1.0);
        }
      }

      if (item.isSkipped) {
        reasons.add(
            'Question skipped (${item.difficulty}); evidence recorded without score penalty.');
      } else if (item.isCorrect) {
        correct++;
        recentAttempts.add(true);

        // Diminishing returns scaling factor as score approaches maxMastery
        final headroom = (config.maxMastery - currentScore).clamp(0.0, 1.0);
        final delta = config.correctIncrement *
            diffWeight *
            item.weight *
            recencyFactor *
            (0.5 + 0.5 * headroom);
        currentScore =
            (currentScore + delta).clamp(config.minMastery, config.maxMastery);

        // Confidence growth
        currentConfidence =
            (currentConfidence + config.confidenceGrowthRate * 0.8)
                .clamp(0.0, config.maxConfidence);

        reasons.add(
            '+${delta.toStringAsFixed(3)} for correct ${item.difficulty} response (weight ${diffWeight.toStringAsFixed(1)}).');
      } else {
        incorrect++;
        recentAttempts.add(false);

        // Harder questions penalize less when wrong; easier questions penalize more
        final severity = 1.0 / diffWeight;
        final delta =
            config.incorrectDecrement * severity * item.weight * recencyFactor;
        currentScore =
            (currentScore - delta).clamp(config.minMastery, config.maxMastery);

        // Confidence adjustment
        currentConfidence = (currentConfidence +
                config.confidenceGrowthRate * 0.3 -
                config.confidenceDecayRate)
            .clamp(0.0, config.maxConfidence);

        reasons.add(
            '-${delta.toStringAsFixed(3)} for incorrect ${item.difficulty} response (severity ${severity.toStringAsFixed(2)}).');
      }
    }

    // Calculate recent accuracy over sliding window
    while (recentAttempts.length > config.recentWindowSize) {
      recentAttempts.removeAt(0);
    }
    final recentAccuracy = recentAttempts.isNotEmpty
        ? recentAttempts.where((c) => c).length / recentAttempts.length
        : null;

    // Classification transition
    final newClassification = config.classify(
      score: currentScore,
      confidence: currentConfidence,
      evidenceCount: totalEvidence,
    );

    final transitionText = currentProfile.classification != newClassification
        ? 'Classification changed: ${currentProfile.classification.displayName} -> ${newClassification.displayName}.'
        : 'Classification maintained at ${newClassification.displayName}.';

    final explanation =
        'Mastery updated from ${currentProfile.masteryScore.toStringAsFixed(2)} to ${currentScore.toStringAsFixed(2)}. $transitionText ${reasons.take(3).join(' ')}';

    final summary = <String, dynamic>{
      'priorScore': currentProfile.masteryScore,
      'newScore': currentScore,
      'priorConfidence': currentProfile.confidence,
      'newConfidence': currentConfidence,
      'evaluatedEvidenceItems': sortedEvidence.length,
      'totalEvidence': totalEvidence,
      'correctCount': correct,
      'incorrectCount': incorrect,
      'recentAccuracy': recentAccuracy,
      'classificationTransition': {
        'from': currentProfile.classification.toJson(),
        'to': newClassification.toJson(),
      },
      'reasons': reasons,
    };

    return TopicMasteryProfile(
      learnerId: currentProfile.learnerId,
      examId: currentProfile.examId,
      topicId: topic,
      masteryScore: currentScore,
      confidence: currentConfidence,
      evidenceCount: totalEvidence,
      correctCount: correct,
      incorrectCount: incorrect,
      recentAccuracy: recentAccuracy,
      lastEvaluatedRevision: revision,
      lastEvaluatedAt: effectiveTs,
      classification: newClassification,
      explanation: explanation,
      contributingEvidenceSummary: summary,
      metadata: currentProfile.metadata,
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Authoritative State Integration
  // ---------------------------------------------------------------------------

  /// Evaluates and generates a complete [LearnerMasterySnapshot] directly from
  /// an [AuthoritativeLearnerState].
  ///
  /// Supports multi-topic mapping and preserves strict tenant isolation.
  LearnerMasterySnapshot evaluateFromAuthoritativeState({
    required AuthoritativeLearnerState authoritativeState,
    Map<String, List<String>>? objectiveToTopicsMap,
    DateTime? evaluatedAt,
    LearnerMasterySnapshot? previousSnapshot,
  }) {
    final effectiveTs =
        (evaluatedAt ?? authoritativeState.lastUpdatedAt).toUtc();
    final learnerId = authoritativeState.learnerId;
    final examId = authoritativeState.examId;

    if (previousSnapshot != null) {
      if (previousSnapshot.learnerId != learnerId ||
          previousSnapshot.examId != examId) {
        throw MasteryTenantMismatchException(
          message:
              'Previous snapshot tenant mismatch with authoritative learner state',
          expectedLearnerId: learnerId,
          actualLearnerId: previousSnapshot.learnerId,
          expectedExamId: examId,
          actualExamId: previousSnapshot.examId,
        );
      }
    }

    final objToTopics = objectiveToTopicsMap ?? const <String, List<String>>{};
    final topicEvidenceMap = <String, List<MasteryEvidenceItem>>{};

    // Convert authoritative progress into discrete evidence items
    for (final progress in authoritativeState.progressMap.values) {
      final objId = progress.objectiveId;
      final topics = objToTopics[objId] ?? [objId];

      for (final topic in topics) {
        final list = topicEvidenceMap.putIfAbsent(topic, () => []);

        // Produce evidence items for recorded progress
        final correctCount = progress.correctCount;
        final incorrectCount = progress.attemptCount - progress.correctCount;
        final ts = progress.lastAttemptAt ?? effectiveTs;

        for (var i = 0; i < correctCount; i++) {
          list.add(MasteryEvidenceItem(
            evidenceId: 'auth:$objId:c:$i',
            evidenceType: MasteryEvidenceType.practiceCorrect,
            topicId: topic,
            objectiveId: objId,
            isCorrect: true,
            difficulty: 'Medium',
            timestamp: ts,
            provenance:
                'authoritative_state_rev_${authoritativeState.revision}',
          ));
        }

        for (var i = 0; i < incorrectCount; i++) {
          list.add(MasteryEvidenceItem(
            evidenceId: 'auth:$objId:w:$i',
            evidenceType: MasteryEvidenceType.practiceIncorrect,
            topicId: topic,
            objectiveId: objId,
            isCorrect: false,
            difficulty: 'Medium',
            timestamp: ts,
            provenance:
                'authoritative_state_rev_${authoritativeState.revision}',
          ));
        }
      }
    }

    // Determine all topic keys
    final allTopics = SplayTreeSet<String>()..addAll(topicEvidenceMap.keys);
    if (previousSnapshot != null) {
      allTopics.addAll(previousSnapshot.topicProfiles.keys);
    }

    final updatedProfiles = SplayTreeMap<String, TopicMasteryProfile>();

    for (final topic in allTopics) {
      final prior = previousSnapshot?.topicProfiles[topic] ??
          TopicMasteryProfile.initial(
            learnerId: learnerId,
            examId: examId,
            topicId: topic,
            initialScore: config.initialMastery,
            evaluatedAt: effectiveTs,
            revision: authoritativeState.revision,
          );

      final evidence = topicEvidenceMap[topic] ?? const [];
      final updated = updateTopicMastery(
        currentProfile: prior,
        evidenceItems: evidence,
        evaluatedAt: effectiveTs,
        revision: authoritativeState.revision,
      );
      updatedProfiles[topic] = updated;
    }

    // Derive deterministic adaptive decision output
    final decision = deriveAdaptiveDecisions(updatedProfiles.values.toList());

    return LearnerMasterySnapshot(
      learnerId: learnerId,
      examId: examId,
      authoritativeRevision: authoritativeState.revision,
      topicProfiles: updatedProfiles,
      decisionOutput: decision,
      evaluatedAt: effectiveTs,
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Question-Level Evidence Evaluation
  // ---------------------------------------------------------------------------

  /// Evaluates and applies granular [PracticeQuestionEvidence] items directly to
  /// topic mastery profiles, preserving question provenance and preventing duplicate counting.
  LearnerMasterySnapshot evaluateFromQuestionEvidence({
    required String learnerId,
    required String examId,
    required List<PracticeQuestionEvidence> questionEvidence,
    required int authoritativeRevision,
    DateTime? evaluatedAt,
    LearnerMasterySnapshot? previousSnapshot,
  }) {
    final effectiveTs = (evaluatedAt ?? DateTime.now()).toUtc();
    final normalizedLearner = learnerId.trim();
    final normalizedExam = examId.trim().toLowerCase();

    if (normalizedLearner.isEmpty) {
      throw const InvalidMasteryLearnerStateException(
        message: 'learnerId cannot be empty in evaluateFromQuestionEvidence',
      );
    }
    if (normalizedExam.isEmpty) {
      throw const InvalidMasteryLearnerStateException(
        message: 'examId cannot be empty in evaluateFromQuestionEvidence',
      );
    }
    if (authoritativeRevision < 1) {
      throw ArgumentError('authoritativeRevision must be >= 1');
    }

    if (previousSnapshot != null) {
      if (previousSnapshot.learnerId != normalizedLearner ||
          previousSnapshot.examId != normalizedExam) {
        throw MasteryTenantMismatchException(
          message: 'Previous snapshot tenant mismatch with evaluation context',
          expectedLearnerId: normalizedLearner,
          actualLearnerId: previousSnapshot.learnerId,
          expectedExamId: normalizedExam,
          actualExamId: previousSnapshot.examId,
        );
      }
    }

    // Group evidence by topic deterministically
    final topicEvidenceMap = <String, List<MasteryEvidenceItem>>{};

    for (final q in questionEvidence) {
      // Validate tenant context of question
      if (q.examId.trim().toLowerCase() != normalizedExam) {
        throw MasteryTenantMismatchException(
          message:
              'Question examId "${q.examId}" mismatches evaluation examId "$normalizedExam"',
          expectedLearnerId: normalizedLearner,
          actualLearnerId: normalizedLearner,
          expectedExamId: normalizedExam,
          actualExamId: q.examId,
        );
      }

      final topic = q.topic.trim().isNotEmpty ? q.topic.trim() : 'General';
      final list = topicEvidenceMap.putIfAbsent(topic, () => []);

      final evidenceType = q.isSkipped
          ? MasteryEvidenceType.practiceSkipped
          : (q.isCorrect
              ? MasteryEvidenceType.practiceCorrect
              : MasteryEvidenceType.practiceIncorrect);

      final item = MasteryEvidenceItem(
        evidenceId: 'q:${q.questionId}:$topic',
        evidenceType: evidenceType,
        topicId: topic,
        objectiveId: q.objectiveIds.isNotEmpty ? q.objectiveIds.first : null,
        questionId: q.questionId,
        difficulty: q.difficulty,
        isCorrect: q.isCorrect,
        isSkipped: q.isSkipped,
        timestamp: q.answeredAt ?? effectiveTs,
        provenance: 'practice_q_${q.questionId}',
      );

      // Prevent duplicate evidence items within the same topic
      if (!list.any((existing) => existing.evidenceId == item.evidenceId)) {
        list.add(item);
      }
    }

    final allTopics = SplayTreeSet<String>()..addAll(topicEvidenceMap.keys);
    if (previousSnapshot != null) {
      allTopics.addAll(previousSnapshot.topicProfiles.keys);
    }

    final updatedProfiles = SplayTreeMap<String, TopicMasteryProfile>();

    for (final topic in allTopics) {
      final prior = previousSnapshot?.topicProfiles[topic] ??
          TopicMasteryProfile.initial(
            learnerId: normalizedLearner,
            examId: normalizedExam,
            topicId: topic,
            initialScore: config.initialMastery,
            evaluatedAt: effectiveTs,
            revision: authoritativeRevision,
          );

      final evidence = topicEvidenceMap[topic] ?? const [];
      final updated = updateTopicMastery(
        currentProfile: prior,
        evidenceItems: evidence,
        evaluatedAt: effectiveTs,
        revision: authoritativeRevision,
      );
      updatedProfiles[topic] = updated;
    }

    final decision = deriveAdaptiveDecisions(updatedProfiles.values.toList());

    return LearnerMasterySnapshot(
      learnerId: normalizedLearner,
      examId: normalizedExam,
      authoritativeRevision: authoritativeRevision,
      topicProfiles: updatedProfiles,
      decisionOutput: decision,
      evaluatedAt: effectiveTs,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Adaptive Decision Signals
  // ---------------------------------------------------------------------------

  /// Derives deterministic decision signals from a collection of topic profiles.
  AdaptiveMasteryDecisionOutput deriveAdaptiveDecisions(
      List<TopicMasteryProfile> profiles) {
    if (profiles.isEmpty) {
      return AdaptiveMasteryDecisionOutput(
        weakestTopics: const [],
        strongestTopics: const [],
        remediationRequiredTopics: const [],
        approachingMasteryTopics: const [],
        insufficientEvidenceTopics: const [],
        recommendedDifficultyBand: const {},
        masteryDistribution: const {},
        overallMasteryScore: 0.0,
        overallConfidence: 0.0,
      );
    }

    // Sort ascending for weakest
    final sortedAsc = List<TopicMasteryProfile>.from(profiles)
      ..sort((a, b) {
        final cmp = a.masteryScore.compareTo(b.masteryScore);
        if (cmp != 0) return cmp;
        return a.topicId.compareTo(b.topicId);
      });

    final weakest = sortedAsc.map((p) => p.topicId).toList();
    final strongest = sortedAsc.reversed.map((p) => p.topicId).toList();

    final remediation = <String>[];
    final approaching = <String>[];
    final insufficient = <String>[];
    final difficultyBand = <String, String>{};
    final distribution = <MasteryClassification, int>{};

    double totalScore = 0.0;
    double totalConf = 0.0;

    for (final p in profiles) {
      totalScore += p.masteryScore;
      totalConf += p.confidence;

      distribution[p.classification] =
          (distribution[p.classification] ?? 0) + 1;

      // Remediation: emerging or developing with poor recent accuracy
      if (p.classification == MasteryClassification.emerging ||
          (p.classification == MasteryClassification.developing &&
              (p.recentAccuracy ?? 0.0) < 0.50)) {
        remediation.add(p.topicId);
      }

      // Approaching mastery: proficient or high developing
      if (p.classification == MasteryClassification.proficient ||
          (p.classification == MasteryClassification.developing &&
              p.masteryScore >= config.developingThreshold + 0.15)) {
        approaching.add(p.topicId);
      }

      // Insufficient evidence
      if (p.evidenceCount < config.minEvidenceForProficiency ||
          p.confidence < 0.30) {
        insufficient.add(p.topicId);
      }

      // Recommended difficulty band
      if (p.masteryScore < config.emergingThreshold) {
        difficultyBand[p.topicId] = 'Easy';
      } else if (p.masteryScore >= config.proficientThreshold &&
          p.confidence >= 0.50) {
        difficultyBand[p.topicId] = 'Hard';
      } else {
        difficultyBand[p.topicId] = 'Medium';
      }
    }

    // Sort lists deterministically
    remediation.sort();
    approaching.sort();
    insufficient.sort();

    return AdaptiveMasteryDecisionOutput(
      weakestTopics: weakest,
      strongestTopics: strongest,
      remediationRequiredTopics: remediation,
      approachingMasteryTopics: approaching,
      insufficientEvidenceTopics: insufficient,
      recommendedDifficultyBand: difficultyBand,
      masteryDistribution: distribution,
      overallMasteryScore: totalScore / profiles.length,
      overallConfidence: totalConf / profiles.length,
    );
  }
}
