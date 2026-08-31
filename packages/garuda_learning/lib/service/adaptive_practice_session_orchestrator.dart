/// Adaptive Practice Session Orchestrator Service (TITAN-KO-034.0 P34).
///
/// Converts P33-selected questions into an evidence-ready, structured practice
/// session specification with deterministic sequencing, section construction,
/// distribution analytics, and deterministic session identity.
///
/// Invariants:
/// - Zero attempt recording (owned by P18/P19).
/// - Zero cognitive/scientific prediction of future exam questions.
/// - Zero SM-2 review scheduling (owned by P20).
/// - Zero learner state mutation.
/// - $O(N)$ index-based execution with zero non-deterministic timestamps.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';

import '../domain/entities/adaptive_practice_session_config.dart';
import '../domain/entities/adaptive_practice_session_spec.dart';
import '../domain/entities/adaptive_question_candidate.dart';
import '../domain/entities/adaptive_question_selection_result.dart';

/// Pure deterministic orchestrator for practice session composition.
class AdaptivePracticeSessionOrchestrator {
  const AdaptivePracticeSessionOrchestrator();

  /// Orchestrates an evidence-ready practice session specification from P33 selection results.
  AdaptivePracticeSessionSpec orchestrateSession({
    required AdaptiveQuestionSelectionResult selectionResult,
    required AdaptivePracticeSessionConfig config,
    DateTime? orchestratedAt,
  }) {
    final targetExam = config.examId.trim().toLowerCase();

    // 1. Validate exam compatibility
    if (selectionResult.examId.toLowerCase() != targetExam) {
      return AdaptivePracticeSessionSpec.empty(
        sessionId: _generateSessionId(
          examId: targetExam,
          questionIds: const [],
          mode: config.sessionMode,
          config: config,
        ),
        examId: targetExam,
        config: config,
        selectionAudit: selectionResult,
        orchestratedAt: orchestratedAt,
        reason:
            'Exam ID mismatch: selectionResult is "${selectionResult.examId}" but config requested "$targetExam"',
      );
    }

    // 2. Validate selection result presence
    if (selectionResult.selectedCandidates.isEmpty) {
      return AdaptivePracticeSessionSpec.empty(
        sessionId: _generateSessionId(
          examId: targetExam,
          questionIds: const [],
          mode: config.sessionMode,
          config: config,
        ),
        examId: targetExam,
        config: config,
        selectionAudit: selectionResult,
        orchestratedAt: orchestratedAt,
        reason: 'Selection result contains zero selected questions',
      );
    }

    // 3. Candidate Deduplication & Exam Filtering
    final uniqueCandidates = <AdaptiveQuestionCandidate>[];
    final seenIds = <String>{};
    for (final candidate in selectionResult.selectedCandidates) {
      if (candidate.examId.toLowerCase() != targetExam) continue;
      if (seenIds.add(candidate.questionId)) {
        uniqueCandidates.add(candidate);
      }
    }

    if (uniqueCandidates.isEmpty) {
      return AdaptivePracticeSessionSpec.empty(
        sessionId: _generateSessionId(
          examId: targetExam,
          questionIds: const [],
          mode: config.sessionMode,
          config: config,
        ),
        examId: targetExam,
        config: config,
        selectionAudit: selectionResult,
        orchestratedAt: orchestratedAt,
        reason:
            'No questions matched target exam $targetExam after deduplication and filtering',
      );
    }

    // 4. Question Ordering based on Session Mode, Balancing, and Difficulty
    final orderedCandidates = _orderCandidates(
      candidates: uniqueCandidates,
      mode: config.sessionMode,
      difficultyProgression: config.difficultyProgression,
      objectiveBalancing: config.objectiveBalancing,
      topicBalancing: config.topicBalancing,
    );

    // 5. Session Truncation if maxQuestions is configured
    final List<AdaptiveQuestionCandidate> finalCandidates;
    final bool isTruncated;
    if (config.maxQuestions != null &&
        orderedCandidates.length > config.maxQuestions!) {
      finalCandidates = orderedCandidates.sublist(0, config.maxQuestions!);
      isTruncated = true;
    } else {
      finalCandidates = orderedCandidates;
      isTruncated = false;
    }

    final orderedQuestions = finalCandidates.map((c) => c.question).toList();
    final orderedQuestionIds =
        finalCandidates.map((c) => c.questionId).toList();

    // 6. Pedagogical Section Construction
    final sections = _buildSections(
      candidates: finalCandidates,
      mode: config.sessionMode,
      sectionSize: config.sectionSize,
      estimatedSecondsPerQuestion: config.estimatedSecondsPerQuestion,
    );

    // 7. Distribution Analytics Calculation
    final distribution = _computeDistribution(finalCandidates);

    // 8. Workload & Time Estimation
    final totalEstimatedSeconds =
        finalCandidates.length * config.estimatedSecondsPerQuestion;

    // 9. Deterministic Session Fingerprint Generation
    final sessionId = _generateSessionId(
      examId: targetExam,
      questionIds: orderedQuestionIds,
      mode: config.sessionMode,
      config: config,
    );

    final bool isConstraintLimited =
        isTruncated || selectionResult.isConstraintLimited;
    final String? limitReason;
    if (isTruncated) {
      limitReason =
          'Session question count capped at maxQuestions (${config.maxQuestions} of ${orderedCandidates.length} available)';
    } else if (selectionResult.isConstraintLimited) {
      limitReason = selectionResult.constraintLimitReason;
    } else {
      limitReason = null;
    }

    return AdaptivePracticeSessionSpec(
      sessionId: sessionId,
      examId: targetExam,
      learnerId: config.learnerId,
      sessionMode: config.sessionMode,
      completionPolicy: config.completionPolicy,
      orderedQuestions: orderedQuestions,
      orderedCandidates: finalCandidates,
      sections: sections,
      distribution: distribution,
      totalEstimatedSeconds: totalEstimatedSeconds,
      isConstraintLimited: isConstraintLimited,
      constraintLimitReason: limitReason,
      config: config,
      selectionAudit: selectionResult,
      orchestratedAt: orchestratedAt,
    );
  }

  // ==========================================================================
  // ORDERING & SEQUENCING PIPELINE
  // ==========================================================================

  static List<AdaptiveQuestionCandidate> _orderCandidates({
    required List<AdaptiveQuestionCandidate> candidates,
    required PracticeSessionMode mode,
    required PracticeDifficultyProgression difficultyProgression,
    required ObjectiveBalancingPolicy objectiveBalancing,
    required TopicBalancingPolicy topicBalancing,
  }) {
    List<AdaptiveQuestionCandidate> working = List.of(candidates);

    // Step A: Mode-specific sequencing
    switch (mode) {
      case PracticeSessionMode.standard:
        // Pedagogical 4-stage block sequencing:
        // 1. Warm-up (high freshness, low weakness)
        // 2. Core Weak Areas (high learner weakness)
        // 3. High-Yield PYQs (high historical priority)
        // 4. Reinforcement (remaining)
        final warmup = <AdaptiveQuestionCandidate>[];
        final coreWeak = <AdaptiveQuestionCandidate>[];
        final highPyq = <AdaptiveQuestionCandidate>[];
        final reinforcement = <AdaptiveQuestionCandidate>[];

        for (final c in working) {
          if (c.learnerWeakness >= 0.5) {
            coreWeak.add(c);
          } else if (c.historicalPriority >= 0.5) {
            highPyq.add(c);
          } else if (c.recencyScore >= 0.8 && c.learnerWeakness < 0.3) {
            warmup.add(c);
          } else {
            reinforcement.add(c);
          }
        }

        warmup.sort(_compareTieBreakers);
        coreWeak.sort(_compareTieBreakers);
        highPyq.sort(_compareTieBreakers);
        reinforcement.sort(_compareTieBreakers);

        working = [...warmup, ...coreWeak, ...highPyq, ...reinforcement];
        break;

      case PracticeSessionMode.weaknessFocused:
        // Sort primarily by learner weakness DESC
        working.sort((a, b) {
          final wCmp = b.learnerWeakness.compareTo(a.learnerWeakness);
          if (wCmp != 0) return wCmp;
          return _compareTieBreakers(a, b);
        });
        break;

      case PracticeSessionMode.pyqFocused:
        // Sort primarily by historical PYQ priority DESC
        working.sort((a, b) {
          final pCmp = b.historicalPriority.compareTo(a.historicalPriority);
          if (pCmp != 0) return pCmp;
          return _compareTieBreakers(a, b);
        });
        break;

      case PracticeSessionMode.balanced:
        // Interleave topics and objectives in round-robin sequence
        working = _interleaveTopicsAndObjectives(working);
        break;

      case PracticeSessionMode.remedialPractice:
        // Weak objectives first, then easy to hard
        working.sort((a, b) {
          final wCmp = b.learnerWeakness.compareTo(a.learnerWeakness);
          if (wCmp != 0) return wCmp;
          final dCmp = _difficultyRank(a.question.difficulty)
              .compareTo(_difficultyRank(b.question.difficulty));
          if (dCmp != 0) return dCmp;
          return _compareTieBreakers(a, b);
        });
        break;

      case PracticeSessionMode.mixedRevision:
        // Interleave across topics
        working = _roundRobinByTopic(working);
        break;
    }

    // Step B: Balancing Policy Adjustment
    if (objectiveBalancing == ObjectiveBalancingPolicy.balanced) {
      working = _roundRobinByObjective(working);
    } else if (topicBalancing == TopicBalancingPolicy.balanced) {
      working = _roundRobinByTopic(working);
    }

    // Step C: Difficulty Progression Ordering if requested
    if (difficultyProgression == PracticeDifficultyProgression.easyToHard) {
      working.sort((a, b) {
        final dCmp = _difficultyRank(a.question.difficulty)
            .compareTo(_difficultyRank(b.question.difficulty));
        if (dCmp != 0) return dCmp;
        return _compareTieBreakers(a, b);
      });
    } else if (difficultyProgression ==
        PracticeDifficultyProgression.mediumToHard) {
      working.sort((a, b) {
        final dCmp = _mediumToHardRank(a.question.difficulty)
            .compareTo(_mediumToHardRank(b.question.difficulty));
        if (dCmp != 0) return dCmp;
        return _compareTieBreakers(a, b);
      });
    }

    return working;
  }

  // ==========================================================================
  // SECTION CONSTRUCTION
  // ==========================================================================

  static List<PracticeSessionSection> _buildSections({
    required List<AdaptiveQuestionCandidate> candidates,
    required PracticeSessionMode mode,
    required int sectionSize,
    required int estimatedSecondsPerQuestion,
  }) {
    if (candidates.isEmpty) return const [];

    final sections = <PracticeSessionSection>[];
    final total = candidates.length;
    final totalSecCount = (total / sectionSize).ceil();

    int secNum = 1;
    for (int i = 0; i < total; i += sectionSize) {
      final end = math.min(i + sectionSize, total);
      final secCandidates = candidates.sublist(i, end);
      final secQuestions = secCandidates.map((c) => c.question).toList();
      final secQuestionIds = secCandidates.map((c) => c.questionId).toList();
      final estSec = secCandidates.length * estimatedSecondsPerQuestion;

      final (title, desc) = _getSectionTitleAndDesc(
        mode: mode,
        sectionIndex: secNum - 1,
        totalSections: totalSecCount,
      );

      sections.add(
        PracticeSessionSection(
          sectionId: 'sec_${secNum}_${_slugify(title)}',
          title: title,
          description: desc,
          questionIds: secQuestionIds,
          questions: secQuestions,
          candidateMetadata: secCandidates,
          estimatedSeconds: estSec,
        ),
      );
      secNum++;
    }

    return sections;
  }

  static (String title, String desc) _getSectionTitleAndDesc({
    required PracticeSessionMode mode,
    required int sectionIndex,
    required int totalSections,
  }) {
    switch (mode) {
      case PracticeSessionMode.standard:
        if (sectionIndex == 0) {
          return (
            'Section 1: Warm-up & Review',
            'Foundational review and active recall'
          );
        } else if (sectionIndex == 1) {
          return (
            'Section 2: Core Practice',
            'Focused practice on prioritized target areas'
          );
        } else if (sectionIndex == 2) {
          return (
            'Section 3: High-Yield Practice',
            'Deep practice with historical PYQ questions'
          );
        } else {
          return (
            'Section ${sectionIndex + 1}: Reinforcement',
            'Consolidation and mastery reinforcement'
          );
        }

      case PracticeSessionMode.weaknessFocused:
        if (sectionIndex == 0) {
          return (
            'Section 1: Critical Weak Spots',
            'Highest observed learner deficiency objectives'
          );
        } else if (sectionIndex == 1) {
          return (
            'Section 2: Secondary Weak Spots',
            'Moderate learner deficiency objectives'
          );
        } else {
          return (
            'Section ${sectionIndex + 1}: Core Reinforcement',
            'Targeted reinforcement practice'
          );
        }

      case PracticeSessionMode.pyqFocused:
        if (sectionIndex == 0) {
          return (
            'Section 1: High-Recurrence PYQs',
            'Most frequently repeated historical exam questions'
          );
        } else if (sectionIndex == 1) {
          return (
            'Section 2: Recent Historical PYQs',
            'Questions from recent examination cycles'
          );
        } else {
          return (
            'Section ${sectionIndex + 1}: Historical Corpus Practice',
            'Comprehensive historical examination questions'
          );
        }

      case PracticeSessionMode.balanced:
        return (
          'Section ${sectionIndex + 1}: Balanced Syllabus Module',
          'Equalized multi-topic practice block'
        );

      case PracticeSessionMode.remedialPractice:
        return (
          'Section ${sectionIndex + 1}: Remedial Practice Block',
          'Structured remediation on targeted weak areas'
        );

      case PracticeSessionMode.mixedRevision:
        return (
          'Section ${sectionIndex + 1}: Mixed Revision Module',
          'Interleaved multi-topic revision'
        );
    }
  }

  // ==========================================================================
  // DISTRIBUTION ANALYTICS
  // ==========================================================================

  static PracticeSessionDistribution _computeDistribution(
    List<AdaptiveQuestionCandidate> candidates,
  ) {
    if (candidates.isEmpty) {
      return PracticeSessionDistribution(
        historicalQuestionCount: 0,
        historicalQuestionRatio: 0.0,
        recentHistoricalQuestionCount: 0,
        nonHistoricalQuestionCount: 0,
        highWeaknessCount: 0,
        mediumWeaknessCount: 0,
        lowWeaknessCount: 0,
      );
    }

    final objCounts = <String, int>{};
    final topicCounts = <String, int>{};
    final yearCounts = <int, int>{};
    final diffCounts = <String, int>{};

    int pyqCount = 0;
    int recentPyqCount = 0;
    int highWeak = 0;
    int medWeak = 0;
    int lowWeak = 0;

    int maxYear = 0;
    for (final c in candidates) {
      if (c.year > maxYear) maxYear = c.year;
    }
    final recentCutoff = maxYear > 0 ? maxYear - 2 : 2022;

    for (final c in candidates) {
      // Objective counts
      for (final objId in c.question.objectiveIds) {
        objCounts[objId] = (objCounts[objId] ?? 0) + 1;
      }
      if (c.question.objectiveIds.isEmpty) {
        final fallback = c.primaryObjectiveId ?? 'lo_unassigned';
        objCounts[fallback] = (objCounts[fallback] ?? 0) + 1;
      }

      // Topic counts
      topicCounts[c.topic] = (topicCounts[c.topic] ?? 0) + 1;

      // Year counts
      yearCounts[c.year] = (yearCounts[c.year] ?? 0) + 1;

      // Difficulty counts
      final diff = c.question.difficulty.toLowerCase().trim();
      diffCounts[diff] = (diffCounts[diff] ?? 0) + 1;

      // PYQ counts
      if (c.isPyq) {
        pyqCount++;
        if (c.year >= recentCutoff) {
          recentPyqCount++;
        }
      }

      // Weakness counts
      if (c.learnerWeakness >= 0.6) {
        highWeak++;
      } else if (c.learnerWeakness >= 0.2) {
        medWeak++;
      } else {
        lowWeak++;
      }
    }

    final pyqRatio = candidates.isNotEmpty
        ? (pyqCount / candidates.length).clamp(0.0, 1.0)
        : 0.0;
    final nonPyqCount = candidates.length - pyqCount;

    return PracticeSessionDistribution(
      objectiveCounts: objCounts,
      topicCounts: topicCounts,
      yearCounts: yearCounts,
      difficultyCounts: diffCounts,
      historicalQuestionCount: pyqCount,
      historicalQuestionRatio: pyqRatio,
      recentHistoricalQuestionCount: recentPyqCount,
      nonHistoricalQuestionCount: nonPyqCount,
      highWeaknessCount: highWeak,
      mediumWeaknessCount: medWeak,
      lowWeaknessCount: lowWeak,
    );
  }

  // ==========================================================================
  // DETERMINISTIC SESSION FINGERPRINT
  // ==========================================================================

  static String _generateSessionId({
    required String examId,
    required List<String> questionIds,
    required PracticeSessionMode mode,
    required AdaptivePracticeSessionConfig config,
  }) {
    final payload =
        '$examId|${mode.name}|${questionIds.join(",")}|${config.sectionSize}|${config.completionPolicy.name}|${config.objectiveBalancing.name}|${config.topicBalancing.name}|${config.difficultyProgression.name}';
    final bytes = utf8.encode(payload);
    final digest = sha256.convert(bytes);
    return 'sess_${examId}_${digest.toString().substring(0, 16)}';
  }

  // ==========================================================================
  // HELPER ROUND-ROBIN & TIE-BREAKING ALGORITHMS
  // ==========================================================================

  static int _compareTieBreakers(
      AdaptiveQuestionCandidate a, AdaptiveQuestionCandidate b) {
    final sCmp = b.selectionScore.compareTo(a.selectionScore);
    if (sCmp != 0) return sCmp;

    final pCmp = b.historicalPriority.compareTo(a.historicalPriority);
    if (pCmp != 0) return pCmp;

    final wCmp = b.learnerWeakness.compareTo(a.learnerWeakness);
    if (wCmp != 0) return wCmp;

    final yCmp = b.year.compareTo(a.year);
    if (yCmp != 0) return yCmp;

    return a.questionId.compareTo(b.questionId);
  }

  static int _difficultyRank(String? diff) {
    if (diff == null) return 2; // neutral
    final d = diff.trim().toLowerCase();
    if (d == 'easy' || d == 'beginner') return 0;
    if (d == 'medium' || d == 'intermediate') return 1;
    if (d == 'hard' || d == 'advanced') return 3;
    return 2;
  }

  static int _mediumToHardRank(String? diff) {
    if (diff == null) return 2;
    final d = diff.trim().toLowerCase();
    if (d == 'medium' || d == 'intermediate') return 0;
    if (d == 'hard' || d == 'advanced') return 1;
    if (d == 'easy' || d == 'beginner') return 3;
    return 2;
  }

  static List<AdaptiveQuestionCandidate> _roundRobinByTopic(
      List<AdaptiveQuestionCandidate> list) {
    final topicGroups = <String, List<AdaptiveQuestionCandidate>>{};
    for (final c in list) {
      topicGroups.putIfAbsent(c.topic, () => []).add(c);
    }

    final sortedTopics = topicGroups.keys.toList()..sort();
    final result = <AdaptiveQuestionCandidate>[];
    bool hasMore = true;
    int index = 0;

    while (hasMore) {
      hasMore = false;
      for (final topic in sortedTopics) {
        final group = topicGroups[topic]!;
        if (index < group.length) {
          result.add(group[index]);
          hasMore = true;
        }
      }
      index++;
    }

    return result;
  }

  static List<AdaptiveQuestionCandidate> _roundRobinByObjective(
      List<AdaptiveQuestionCandidate> list) {
    final objGroups = <String, List<AdaptiveQuestionCandidate>>{};
    for (final c in list) {
      final primary = c.primaryObjectiveId ?? 'lo_unassigned';
      objGroups.putIfAbsent(primary, () => []).add(c);
    }

    final sortedObjs = objGroups.keys.toList()..sort();
    final result = <AdaptiveQuestionCandidate>[];
    bool hasMore = true;
    int index = 0;

    while (hasMore) {
      hasMore = false;
      for (final obj in sortedObjs) {
        final group = objGroups[obj]!;
        if (index < group.length) {
          result.add(group[index]);
          hasMore = true;
        }
      }
      index++;
    }

    return result;
  }

  static List<AdaptiveQuestionCandidate> _interleaveTopicsAndObjectives(
      List<AdaptiveQuestionCandidate> list) {
    final byTopic = _roundRobinByTopic(list);
    final byObj = _roundRobinByObjective(byTopic);
    return byObj;
  }

  static String _slugify(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}
