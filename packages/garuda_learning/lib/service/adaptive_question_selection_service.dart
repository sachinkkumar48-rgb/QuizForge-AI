/// Adaptive Question Selection Service (TITAN-KO-033.0 P33).
///
/// Pure, deterministic selection engine synthesizing P32 PYQ Historical Priority,
/// P23/P18 Learner Evidence, and Practice Diversity Constraints to select practice questions.
///
/// Educational Safety & Ownership Invariants:
/// - Reuses canonical [NormalizedQuestion] directly — zero question fabrication.
/// - Pure quantitative scoring — zero predictive assertions ("likely to appear next year").
/// - Absence of learner attempts strictly yields a weakness score of 0.0.
/// - Deterministic tie-breaking: selectionScore DESC, historicalPriority DESC,
///   learnerWeakness DESC, year DESC, questionId ASC.
/// - Zero DateTime.now() — caller-supplied evaluation timestamps only.
library;

import 'package:garuda_pyq/garuda_pyq.dart';

import '../domain/entities/adaptive_question_candidate.dart';
import '../domain/entities/adaptive_question_selection_config.dart';
import '../domain/entities/adaptive_question_selection_result.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/pyq_learning_priority_profile.dart';
import '../domain/entities/question_attempt.dart';
import '../domain/entities/weak_spot_profile.dart';

class AdaptiveQuestionSelectionService {
  const AdaptiveQuestionSelectionService();

  /// Selects practice questions from the corpus according to [config] and upstream signals.
  AdaptiveQuestionSelectionResult selectQuestions({
    required List<NormalizedQuestion> corpus,
    required AdaptiveQuestionSelectionConfig config,
    PyqLearningPriorityProfile? pyqPriorityProfile,
    WeakSpotProfile? weakSpotProfile,
    List<LearnerProgress>? progressList,
    List<QuestionAttempt>? attemptHistory,
    DateTime? selectedAt,
    int minimumLearnerAttempts = 5,
  }) {
    final effectiveSelectedAt = selectedAt?.toUtc();
    final examId = config.examId.toLowerCase().trim();

    if (corpus.isEmpty || examId.isEmpty) {
      return AdaptiveQuestionSelectionResult.empty(
        examId: examId,
        config: config,
        selectedAt: effectiveSelectedAt,
        reason: corpus.isEmpty ? 'Corpus is empty' : 'examId cannot be empty',
      );
    }

    // 1. Index learner exposure history (questionId -> attempts & lastAttemptedAt)
    final exposureMap = <String, _ExposureRecord>{};
    if (attemptHistory != null) {
      for (final att in attemptHistory) {
        final existing = exposureMap[att.questionId];
        final count = (existing?.count ?? 0) + 1;
        final latestDate = existing != null &&
                existing.lastAttemptedAt.isAfter(att.attemptedAt)
            ? existing.lastAttemptedAt
            : att.attemptedAt;
        exposureMap[att.questionId] = _ExposureRecord(
          count: count,
          lastAttemptedAt: latestDate,
        );
      }
    }

    // 2. Index learner weakness signals from P23 WeakSpotProfile and P18 Progress
    final weaknessMap = <String, double>{};
    if (weakSpotProfile != null) {
      for (final diag in weakSpotProfile.weakObjectives) {
        if (diag.attemptCount >= minimumLearnerAttempts) {
          weaknessMap[diag.objectiveId] = diag.deficiencyScore;
        }
      }
    }
    if (progressList != null) {
      for (final p in progressList) {
        if (!weaknessMap.containsKey(p.objectiveId)) {
          if (p.attemptCount >= minimumLearnerAttempts) {
            final acc =
                p.attemptCount > 0 ? (p.correctCount / p.attemptCount) : 1.0;
            if (acc < 0.60) {
              weaknessMap[p.objectiveId] = (1.0 - acc).clamp(0.0, 1.0);
            }
          }
        }
      }
    }

    // 3. Prepare scope sets
    final scopedObjSet = config.scopedObjectiveIds != null &&
            config.scopedObjectiveIds!.isNotEmpty
        ? config.scopedObjectiveIds!.toSet()
        : null;
    final scopedTopicSet =
        config.scopedTopics != null && config.scopedTopics!.isNotEmpty
            ? config.scopedTopics!.map((t) => t.toLowerCase().trim()).toSet()
            : null;
    final scopedSubjectSet =
        config.scopedSubjects != null && config.scopedSubjects!.isNotEmpty
            ? config.scopedSubjects!.map((s) => s.toLowerCase().trim()).toSet()
            : null;

    final targetDiff = config.targetDifficulty?.toLowerCase().trim();

    // 4. Evaluate all candidates
    final allCandidates = <AdaptiveQuestionCandidate>[];
    final eligibleCandidates = <AdaptiveQuestionCandidate>[];

    for (final q in corpus) {
      bool isEligible = true;
      QuestionExclusionReason? exclusionReason;

      // Filter A: Exam Match
      if (q.examId.toLowerCase().trim() != examId) {
        isEligible = false;
        exclusionReason = QuestionExclusionReason.examMismatch;
      }

      // Filter B: Scope Match
      if (isEligible) {
        if (scopedObjSet != null) {
          final matchesObj = q.objectiveIds.any(scopedObjSet.contains);
          if (!matchesObj) {
            isEligible = false;
            exclusionReason = QuestionExclusionReason.scopeMismatch;
          }
        }
        if (isEligible && scopedTopicSet != null) {
          final matchesTopic =
              scopedTopicSet.contains(q.topic.toLowerCase().trim());
          if (!matchesTopic) {
            isEligible = false;
            exclusionReason = QuestionExclusionReason.scopeMismatch;
          }
        }
        if (isEligible && scopedSubjectSet != null) {
          final matchesSubj =
              scopedSubjectSet.contains(q.subject.toLowerCase().trim());
          if (!matchesSubj) {
            isEligible = false;
            exclusionReason = QuestionExclusionReason.scopeMismatch;
          }
        }
      }

      // Filter C: Exposure & Cooldown
      final exp = exposureMap[q.id];
      final expCount = exp?.count ?? 0;
      final lastExposedAt = exp?.lastAttemptedAt;

      if (isEligible) {
        if (config.excludePreviouslySeen && expCount > 0) {
          isEligible = false;
          exclusionReason = QuestionExclusionReason.previouslySeen;
        } else if (expCount >= config.maxExposureCount) {
          isEligible = false;
          exclusionReason = QuestionExclusionReason.excessExposure;
        } else if (config.cooldownPeriod != null &&
            lastExposedAt != null &&
            effectiveSelectedAt != null) {
          final elapsed = effectiveSelectedAt.difference(lastExposedAt);
          if (elapsed < config.cooldownPeriod!) {
            isEligible = false;
            exclusionReason = QuestionExclusionReason.cooldownActive;
          }
        }
      }

      // Compute Signals
      // Learner weakness
      double weakness = 0.0;
      for (final objId in q.objectiveIds) {
        final w = weaknessMap[objId];
        if (w != null && w > weakness) {
          weakness = w;
        }
      }
      if (weakness == 0.0 && weaknessMap.containsKey(q.topic)) {
        weakness = weaknessMap[q.topic] ?? 0.0;
      }

      // P32 Historical priority
      double historicalPriority = 0.0;
      if (pyqPriorityProfile != null &&
          pyqPriorityProfile.examId.toLowerCase().trim() == examId) {
        if (q.objectiveIds.isNotEmpty) {
          final sig = pyqPriorityProfile.getObjectiveSignal(
            q.objectiveIds.first,
            topic: q.topic,
            subject: q.subject,
          );
          historicalPriority = sig.priorityScore;
        } else {
          final sig = pyqPriorityProfile.getTopicSignal(
            q.topic,
            subject: q.subject,
          );
          historicalPriority = sig.priorityScore;
        }
      }

      // Freshness score (1.0 for never seen, decays with exposure)
      final double freshnessScore;
      if (config.maxExposureCount > 0) {
        freshnessScore =
            (1.0 - (expCount / config.maxExposureCount)).clamp(0.0, 1.0);
      } else {
        freshnessScore = expCount == 0 ? 1.0 : 0.0;
      }

      // Difficulty fit score
      final double difficultyFit;
      if (targetDiff == null) {
        difficultyFit = 1.0;
      } else {
        final qDiff = q.difficulty.toLowerCase().trim();
        if (qDiff == targetDiff) {
          difficultyFit = 1.0;
        } else if (qDiff.isEmpty || qDiff == 'medium') {
          difficultyFit = 0.5;
        } else {
          difficultyFit = 0.0;
        }
      }

      // Source quality score
      final double sourceQuality;
      if (q.source.sourceType == 'officialPdf' ||
          q.source.sourceType == 'officialKey' ||
          q.source.publisher.isNotEmpty) {
        sourceQuality = 1.0;
      } else {
        sourceQuality = 0.8;
      }

      // Composite Selection Score
      final weakContrib =
          (config.normalizedWeaknessWeight * weakness).clamp(0.0, 1.0);
      final pyqContrib =
          (config.normalizedPyqPriorityWeight * historicalPriority)
              .clamp(0.0, 1.0);
      final freshContrib =
          (config.normalizedFreshnessWeight * freshnessScore).clamp(0.0, 1.0);
      final diffContrib =
          (config.normalizedDifficultyWeight * difficultyFit).clamp(0.0, 1.0);
      final qualContrib =
          (config.normalizedQualityWeight * sourceQuality).clamp(0.0, 1.0);

      final totalScore =
          (weakContrib + pyqContrib + freshContrib + diffContrib + qualContrib)
              .clamp(0.0, 1.0);

      final candidate = AdaptiveQuestionCandidate(
        question: q,
        historicalPriority: historicalPriority,
        learnerWeakness: weakness,
        exposureCount: expCount,
        lastExposedAt: lastExposedAt,
        recencyScore: freshnessScore,
        difficultyFit: difficultyFit,
        sourceQualityScore: sourceQuality,
        selectionScore: totalScore,
        isEligible: isEligible,
        exclusionReason: exclusionReason,
        scoreBreakdown: {
          'learnerWeaknessContribution': weakContrib,
          'pyqPriorityContribution': pyqContrib,
          'freshnessContribution': freshContrib,
          'difficultyContribution': diffContrib,
          'qualityContribution': qualContrib,
        },
      );

      allCandidates.add(candidate);
      if (isEligible) {
        eligibleCandidates.add(candidate);
      }
    }

    // 5. Build candidate index map for O(1) exclusion updates
    final candidateIndexMap = <String, int>{
      for (int i = 0; i < allCandidates.length; i++)
        allCandidates[i].questionId: i,
    };

    // 6. Deterministic sort on eligible candidates
    eligibleCandidates.sort((a, b) {
      final sCmp = b.selectionScore.compareTo(a.selectionScore);
      if (sCmp != 0) return sCmp;

      final pCmp = b.historicalPriority.compareTo(a.historicalPriority);
      if (pCmp != 0) return pCmp;

      final wCmp = b.learnerWeakness.compareTo(a.learnerWeakness);
      if (wCmp != 0) return wCmp;

      final yCmp = b.year.compareTo(a.year);
      if (yCmp != 0) return yCmp;

      return a.questionId.compareTo(b.questionId);
    });

    // 7. Session Composition & Diversity Enforcement
    final selectedCandidates = <AdaptiveQuestionCandidate>[];
    final selectedQuestions = <NormalizedQuestion>[];

    final objectiveCounts = <String, int>{};
    final topicCounts = <String, int>{};
    final yearCounts = <int, int>{};

    for (final candidate in eligibleCandidates) {
      if (selectedCandidates.length >= config.targetQuestionCount) {
        break;
      }

      // Check diversity constraints
      final primaryObj = candidate.primaryObjectiveId;
      if (primaryObj != null && config.maxQuestionsPerObjective != null) {
        final currentCount = objectiveCounts[primaryObj] ?? 0;
        if (currentCount >= config.maxQuestionsPerObjective!) {
          _updateExclusion(
            allCandidates: allCandidates,
            candidateIndexMap: candidateIndexMap,
            candidateId: candidate.questionId,
            reason: QuestionExclusionReason.diversityObjectiveLimit,
          );
          continue;
        }
      }

      if (config.maxQuestionsPerTopic != null) {
        final currentCount = topicCounts[candidate.topic] ?? 0;
        if (currentCount >= config.maxQuestionsPerTopic!) {
          _updateExclusion(
            allCandidates: allCandidates,
            candidateIndexMap: candidateIndexMap,
            candidateId: candidate.questionId,
            reason: QuestionExclusionReason.diversityTopicLimit,
          );
          continue;
        }
      }

      if (config.maxQuestionsPerYear != null) {
        final currentCount = yearCounts[candidate.year] ?? 0;
        if (currentCount >= config.maxQuestionsPerYear!) {
          _updateExclusion(
            allCandidates: allCandidates,
            candidateIndexMap: candidateIndexMap,
            candidateId: candidate.questionId,
            reason: QuestionExclusionReason.diversityYearLimit,
          );
          continue;
        }
      }

      // Accept candidate into selection
      selectedCandidates.add(candidate);
      selectedQuestions.add(candidate.question);

      if (primaryObj != null) {
        objectiveCounts[primaryObj] = (objectiveCounts[primaryObj] ?? 0) + 1;
      }
      topicCounts[candidate.topic] = (topicCounts[candidate.topic] ?? 0) + 1;
      yearCounts[candidate.year] = (yearCounts[candidate.year] ?? 0) + 1;
    }

    // 8. Compile diversity breakdown summary
    final diversitySummary = <String, int>{};
    for (final t in topicCounts.entries) {
      diversitySummary['topic_${t.key}'] = t.value;
    }
    for (final y in yearCounts.entries) {
      diversitySummary['year_${y.key}'] = y.value;
    }
    for (final o in objectiveCounts.entries) {
      diversitySummary['obj_${o.key}'] = o.value;
    }

    final isLimited = selectedCandidates.length < config.targetQuestionCount;
    final String? limitReason;
    if (isLimited) {
      if (eligibleCandidates.isEmpty) {
        limitReason =
            'Zero questions in corpus met the filtering and eligibility criteria';
      } else if (eligibleCandidates.length < config.targetQuestionCount) {
        limitReason =
            'Eligible questions pool exhausted (${eligibleCandidates.length} eligible available for ${config.targetQuestionCount} requested)';
      } else {
        limitReason =
            'Diversity constraints prevented selecting full requested count (${selectedCandidates.length}/${config.targetQuestionCount} selected)';
      }
    } else {
      limitReason = null;
    }

    return AdaptiveQuestionSelectionResult(
      examId: examId,
      selectedQuestions: selectedQuestions,
      selectedCandidates: selectedCandidates,
      allCandidates: allCandidates,
      requestedCount: config.targetQuestionCount,
      eligibleCount: eligibleCandidates.length,
      config: config,
      selectedAt: effectiveSelectedAt,
      diversitySummary: diversitySummary,
      isConstraintLimited: isLimited,
      constraintLimitReason: limitReason,
    );
  }

  static void _updateExclusion({
    required List<AdaptiveQuestionCandidate> allCandidates,
    required Map<String, int> candidateIndexMap,
    required String candidateId,
    required QuestionExclusionReason reason,
  }) {
    final idx = candidateIndexMap[candidateId];
    if (idx != null) {
      allCandidates[idx] = allCandidates[idx].copyWith(
        isEligible: false,
        exclusionReason: reason,
      );
    }
  }
}

class _ExposureRecord {
  final int count;
  final DateTime lastAttemptedAt;

  const _ExposureRecord({
    required this.count,
    required this.lastAttemptedAt,
  });
}
