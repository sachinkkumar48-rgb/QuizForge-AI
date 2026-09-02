/// Practice Outcome Consolidator Service (TITAN-KO-036.0 P36).
///
/// Pure deterministic outcome consolidation and learning evidence bridge service.
/// Transforms runtime P35 execution state into immutable, validated, multi-exam isolated
/// learning evidence packages and P19-ready persistence handoff records.
///
/// Invariants:
/// - Zero attempt/database persistence ownership (owned by P19).
/// - Zero review scheduling or SM-2 calculations (owned by P20).
/// - Zero longitudinal predictions or cognitive trait inference (owned by P23).
/// - Zero DateTime.now() drift; caller-supplied timestamps only.
/// - Pure read-only transformation: zero mutation of upstream P35 state.
/// - O(n) linear performance with deterministic SHA-256 fingerprinting.
library;

import 'dart:collection';
import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../domain/entities/adaptive_practice_session_config.dart';
import '../domain/entities/evaluation_method.dart';
import '../domain/entities/practice_consolidation_error.dart';
import '../domain/entities/practice_execution_state.dart';
import '../domain/entities/practice_outcome_consolidation.dart';
import '../domain/entities/practice_outcome_evidence.dart';
import '../domain/entities/question_attempt.dart';

/// Pure deterministic outcome consolidator service for practice sessions.
class PracticeOutcomeConsolidator {
  const PracticeOutcomeConsolidator();

  /// Consolidates a completed, paused, or abandoned [PracticeExecutionState] into an immutable
  /// [ConsolidatedPracticeOutcome] with full evidence aggregations and P19 handoff records.
  PracticeConsolidationResult<ConsolidatedPracticeOutcome> consolidate({
    required PracticeExecutionState state,
    DateTime? consolidatedAt,
  }) {
    // ------------------------------------------------------------------------
    // 1. Session & State Invariant Validation
    // ------------------------------------------------------------------------
    final cleanSessionId = state.sessionId.trim();
    if (cleanSessionId.isEmpty) {
      return const PracticeConsolidationResult.failure(
        PracticeConsolidationError(
          code: PracticeConsolidationErrorCode.invalidSession,
          message:
              'sessionId cannot be empty for practice outcome consolidation.',
        ),
      );
    }

    final cleanExamId = state.examId.trim();
    if (cleanExamId.isEmpty) {
      return const PracticeConsolidationResult.failure(
        PracticeConsolidationError(
          code: PracticeConsolidationErrorCode.invalidSession,
          message: 'examId cannot be empty for practice outcome consolidation.',
        ),
      );
    }

    if (state.startedAt == null &&
        state.status != PracticeExecutionStatus.notStarted) {
      return PracticeConsolidationResult.failure(
        PracticeConsolidationError(
          code: PracticeConsolidationErrorCode.invalidExecutionState,
          message:
              'startedAt timestamp is missing for session in status "${state.status.name}".',
          details: {'sessionId': cleanSessionId},
        ),
      );
    }

    // Check duplicate question IDs in specification
    final seenQuestionIds = <String>{};
    for (final qId in state.spec.orderedQuestionIds) {
      if (!seenQuestionIds.add(qId)) {
        return PracticeConsolidationResult.failure(
          PracticeConsolidationError(
            code: PracticeConsolidationErrorCode.duplicateQuestion,
            message:
                'Duplicate question ID "$qId" detected in session specification.',
            details: {'duplicateQuestionId': qId, 'sessionId': cleanSessionId},
          ),
        );
      }
    }

    // Multi-Exam Isolation Validation: Ensure every question strictly belongs to session examId
    final normalizedSessionExam = cleanExamId.toLowerCase();
    for (final q in state.spec.orderedQuestions) {
      if (q.examId.toLowerCase().trim() != normalizedSessionExam) {
        return PracticeConsolidationResult.failure(
          PracticeConsolidationError(
            code: PracticeConsolidationErrorCode.examMismatch,
            message:
                'Cross-exam contamination detected: Question "${q.id}" has examId "${q.examId}", which does not match session examId "$cleanExamId".',
            details: {
              'questionId': q.id,
              'questionExamId': q.examId,
              'sessionExamId': cleanExamId,
            },
          ),
        );
      }
    }

    // Also check question results map for cross-exam questions
    for (final r in state.questionResults.values) {
      if (r.question.examId.toLowerCase().trim() != normalizedSessionExam) {
        return PracticeConsolidationResult.failure(
          PracticeConsolidationError(
            code: PracticeConsolidationErrorCode.examMismatch,
            message:
                'Cross-exam contamination in questionResults: Question "${r.questionId}" has examId "${r.question.examId}", which does not match session examId "$cleanExamId".',
            details: {
              'questionId': r.questionId,
              'questionExamId': r.question.examId,
              'sessionExamId': cleanExamId,
            },
          ),
        );
      }
    }

    // ------------------------------------------------------------------------
    // 2. Resolve Effective Timestamps
    // ------------------------------------------------------------------------
    final effectiveStartedAt =
        state.startedAt ?? consolidatedAt ?? DateTime.utc(2026, 9, 1);
    final effectiveCompletedAt = state.completedAt ??
        state.lastActionAt ??
        consolidatedAt ??
        effectiveStartedAt;

    // ------------------------------------------------------------------------
    // 3. Granular Question Evidence & P19 Handoff Compilation
    // ------------------------------------------------------------------------
    final questionEvidenceList = <PracticeQuestionEvidence>[];
    final handoffAttemptsList = <QuestionAttempt>[];

    int totalAttempted = 0;
    int totalCorrect = 0;
    int totalIncorrect = 0;
    int totalSkipped = 0;
    int totalElapsedSeconds = 0;

    int totalFeedbackCount = 0;
    int explanationsExposedCount = 0;
    int explanationsWithheldCount = 0;

    // Accumulator structures for dimensional evidence
    final topicAccMap = <String, _DimensionalAccumulator>{};
    final objectiveAccMap = <String, _DimensionalAccumulator>{};
    final sectionAccMap = <int, _DimensionalAccumulator>{};
    final difficultyAccMap = <String, _DimensionalAccumulator>{};

    // Pre-map section boundaries from P34 specification if present
    final questionIndexToSectionMap = <int, _SectionMetadata>{};
    if (state.spec.sections.isNotEmpty) {
      int cursor = 0;
      for (int sIdx = 0; sIdx < state.spec.sections.length; sIdx++) {
        final sec = state.spec.sections[sIdx];
        for (int qInSec = 0; qInSec < sec.questions.length; qInSec++) {
          questionIndexToSectionMap[cursor] = _SectionMetadata(
            sectionIndex: sIdx,
            sectionTitle: sec.title,
          );
          cursor++;
        }
      }
    }

    for (int i = 0; i < state.spec.orderedQuestions.length; i++) {
      final question = state.spec.orderedQuestions[i];
      final result = state.questionResults[question.id];
      final candidate = i < state.spec.orderedCandidates.length
          ? state.spec.orderedCandidates[i]
          : null;

      // Determine categorical status
      final PracticeQuestionStatus qStatus;
      if (result != null && result.isAnswered) {
        qStatus = result.isCorrect
            ? PracticeQuestionStatus.answeredCorrect
            : PracticeQuestionStatus.answeredIncorrect;
      } else if (result != null && result.isSkipped) {
        qStatus = PracticeQuestionStatus.skipped;
      } else {
        qStatus = PracticeQuestionStatus.unanswered;
      }

      final isAnswered = qStatus.isAnswered;
      final isCorrect = qStatus.isCorrect;
      final isSkipped = qStatus.isSkipped;
      final elapsedSec = result?.elapsedSeconds ?? 0;
      totalElapsedSeconds += elapsedSec;

      if (isAnswered) {
        totalAttempted++;
        if (isCorrect) {
          totalCorrect++;
        } else {
          totalIncorrect++;
        }
      } else if (isSkipped) {
        totalSkipped++;
      }

      // Authoritative correct answer representation
      final officialCorrect =
          question.officialAnswer.correctOptionKeys.isNotEmpty
              ? question.officialAnswer.correctOptionKeys.join(', ')
              : question.options
                  .where((o) => o.isCorrect)
                  .map((o) => o.key)
                  .join(', ');

      // Feedback exposure inspection
      final bool explanationExposed;
      if (result?.feedback != null) {
        totalFeedbackCount++;
        explanationExposed = result!.feedback!.isExplanationExposed;
        if (explanationExposed) {
          explanationsExposedCount++;
        } else {
          explanationsWithheldCount++;
        }
      } else {
        explanationExposed =
            state.feedbackPolicy == PracticeFeedbackPolicy.immediate;
      }

      // Construct question evidence
      final qEvidence = PracticeQuestionEvidence(
        questionId: question.id,
        examId: question.examId,
        year: question.year,
        paper: question.paper,
        subject: question.subject,
        topic: question.topic,
        objectiveIds: question.objectiveIds,
        difficulty: question.difficulty,
        questionIndex: i,
        status: qStatus,
        submittedAnswer: result?.submittedAnswer,
        correctAnswer: officialCorrect,
        isCorrect: isCorrect,
        isAnswered: isAnswered,
        isSkipped: isSkipped,
        elapsedSeconds: elapsedSec,
        presentedAt: result?.presentedAt,
        answeredAt: result?.answeredAt,
        feedbackPolicy: state.feedbackPolicy,
        isExplanationExposed: explanationExposed,
        evaluationMethod: EvaluationMethod.multipleChoice,
        candidateMetadata: candidate,
      );
      questionEvidenceList.add(qEvidence);

      // P19 Handoff record generation (only for answered questions)
      if (isAnswered && result?.submittedAnswer != null) {
        final primaryObjective = question.objectiveIds.isNotEmpty
            ? question.objectiveIds.first
            : 'lo_unassigned';

        handoffAttemptsList.add(QuestionAttempt(
          attemptId: 'att_${cleanSessionId}_${question.id}',
          learnerId: state.learnerId ?? 'anonymous_learner',
          questionId: question.id,
          objectiveId: primaryObjective,
          submittedAnswer: result!.submittedAnswer!,
          attemptedAt: result.answeredAt ?? effectiveStartedAt,
          sessionId: cleanSessionId,
        ));
      }

      // ----------------------------------------------------------------------
      // Accumulate Dimensional Evidence
      // ----------------------------------------------------------------------
      // Topic Accumulation
      final topicKey = question.topic.trim().isNotEmpty
          ? question.topic.trim()
          : 'Uncategorized';
      final topicAcc = topicAccMap.putIfAbsent(
        topicKey,
        () => _DimensionalAccumulator(
            label: topicKey, secondaryLabel: question.subject),
      );
      topicAcc.record(
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isSkipped: isSkipped,
          elapsed: elapsedSec);

      // Objective Accumulation
      final effectiveObjectives = question.objectiveIds.isNotEmpty
          ? question.objectiveIds
          : const ['lo_unassigned'];
      for (final objId in effectiveObjectives) {
        final objAcc = objectiveAccMap.putIfAbsent(
          objId,
          () => _DimensionalAccumulator(label: objId),
        );
        objAcc.record(
            isAnswered: isAnswered,
            isCorrect: isCorrect,
            isSkipped: isSkipped,
            elapsed: elapsedSec);
      }

      // Section Accumulation
      final secMeta = questionIndexToSectionMap[i] ??
          _SectionMetadata(sectionIndex: 0, sectionTitle: 'Section 1');
      final secAcc = sectionAccMap.putIfAbsent(
        secMeta.sectionIndex,
        () => _DimensionalAccumulator(
          label: 'Section ${secMeta.sectionIndex}',
          secondaryLabel: secMeta.sectionTitle,
        ),
      );
      secAcc.record(
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isSkipped: isSkipped,
          elapsed: elapsedSec);

      // Difficulty Accumulation
      final diffKey = question.difficulty.trim().isNotEmpty
          ? question.difficulty.trim()
          : 'Medium';
      final diffAcc = difficultyAccMap.putIfAbsent(
        diffKey,
        () => _DimensionalAccumulator(label: diffKey),
      );
      diffAcc.record(
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isSkipped: isSkipped,
          elapsed: elapsedSec);
    }

    // ------------------------------------------------------------------------
    // 4. Build Dimensional Aggregate Models (Deterministically Sorted)
    // ------------------------------------------------------------------------
    final sortedTopicEvidence = SplayTreeMap<String, PracticeTopicEvidence>();
    topicAccMap.forEach((key, acc) {
      sortedTopicEvidence[key] = acc.toTopicEvidence(key);
    });

    final sortedObjectiveEvidence =
        SplayTreeMap<String, PracticeObjectiveEvidence>();
    objectiveAccMap.forEach((key, acc) {
      sortedObjectiveEvidence[key] = acc.toObjectiveEvidence(key);
    });

    final sortedSectionEvidence =
        SplayTreeMap<String, PracticeSectionEvidence>();
    final sortedSectionIndices = sectionAccMap.keys.toList()..sort();
    for (final sIdx in sortedSectionIndices) {
      final acc = sectionAccMap[sIdx]!;
      sortedSectionEvidence['section_$sIdx'] = acc.toSectionEvidence(sIdx);
    }

    final sortedDifficultyEvidence =
        SplayTreeMap<String, PracticeDifficultyEvidence>();
    difficultyAccMap.forEach((key, acc) {
      sortedDifficultyEvidence[key] = acc.toDifficultyEvidence(key);
    });

    // ------------------------------------------------------------------------
    // 5. Compute Overall Bounded Descriptive Metrics
    // ------------------------------------------------------------------------
    final totalQuestions = state.totalQuestions;
    final processedCount = totalAttempted + totalSkipped;
    final unansweredCount =
        (totalQuestions - processedCount).clamp(0, totalQuestions);

    final double completionRate = totalQuestions > 0
        ? (processedCount / totalQuestions).clamp(0.0, 1.0)
        : 0.0;

    // Accuracy is defined strictly as correct / attempted; null when attempted == 0
    final double? accuracy = totalAttempted > 0
        ? (totalCorrect / totalAttempted).clamp(0.0, 1.0)
        : null;

    final double? accuracyPercentage =
        accuracy != null ? accuracy * 100.0 : null;

    final double scoreRatio = totalQuestions > 0
        ? (totalCorrect / totalQuestions).clamp(0.0, 1.0)
        : 0.0;

    final int finalDurationSeconds = totalElapsedSeconds > 0
        ? totalElapsedSeconds
        : effectiveCompletedAt
            .difference(effectiveStartedAt)
            .inSeconds
            .clamp(0, 86400);

    final double avgSecondsPerQuestion =
        totalAttempted > 0 ? finalDurationSeconds / totalAttempted : 0.0;

    final feedbackExposureRate = totalFeedbackCount > 0
        ? (explanationsExposedCount / totalFeedbackCount).clamp(0.0, 1.0)
        : 0.0;

    final feedbackSummary = PracticeFeedbackSummary(
      policy: state.feedbackPolicy,
      totalFeedbackGenerated: totalFeedbackCount,
      explanationsExposedCount: explanationsExposedCount,
      explanationsWithheldCount: explanationsWithheldCount,
      exposureRate: feedbackExposureRate,
    );

    // ------------------------------------------------------------------------
    // 6. Generate Deterministic SHA-256 Fingerprint
    // ------------------------------------------------------------------------
    final fingerprint = _computeDeterministicFingerprint(
      sessionId: cleanSessionId,
      examId: cleanExamId,
      learnerId: state.learnerId,
      sessionMode: state.spec.config.sessionMode,
      sessionStatus: state.status,
      startedAt: effectiveStartedAt,
      completedAt: effectiveCompletedAt,
      totalQuestions: totalQuestions,
      attemptedCount: totalAttempted,
      correctCount: totalCorrect,
      incorrectCount: totalIncorrect,
      skippedCount: totalSkipped,
      unansweredCount: unansweredCount,
      completionRate: completionRate,
      accuracy: accuracy,
      scoreRatio: scoreRatio,
      totalDurationSeconds: finalDurationSeconds,
      feedbackSummary: feedbackSummary,
      topicEvidence: sortedTopicEvidence,
      objectiveEvidence: sortedObjectiveEvidence,
      sectionEvidence: sortedSectionEvidence,
      difficultyEvidence: sortedDifficultyEvidence,
      questionEvidence: questionEvidenceList,
      handoffAttempts: handoffAttemptsList,
    );

    // ------------------------------------------------------------------------
    // 7. Assemble and Return Consolidated Outcome
    // ------------------------------------------------------------------------
    final outcome = ConsolidatedPracticeOutcome(
      sessionId: cleanSessionId,
      examId: cleanExamId,
      learnerId: state.learnerId,
      sessionMode: state.spec.config.sessionMode,
      sessionStatus: state.status,
      startedAt: effectiveStartedAt,
      completedAt: effectiveCompletedAt,
      totalQuestions: totalQuestions,
      attemptedCount: totalAttempted,
      correctCount: totalCorrect,
      incorrectCount: totalIncorrect,
      skippedCount: totalSkipped,
      unansweredCount: unansweredCount,
      completionRate: completionRate,
      accuracy: accuracy,
      accuracyPercentage: accuracyPercentage,
      scoreRatio: scoreRatio,
      totalDurationSeconds: finalDurationSeconds,
      averageSecondsPerQuestion: avgSecondsPerQuestion,
      feedbackSummary: feedbackSummary,
      topicEvidence: sortedTopicEvidence,
      objectiveEvidence: sortedObjectiveEvidence,
      sectionEvidence: sortedSectionEvidence,
      difficultyEvidence: sortedDifficultyEvidence,
      questionEvidence: questionEvidenceList,
      handoffAttempts: handoffAttemptsList,
      fingerprint: fingerprint,
    );

    return PracticeConsolidationResult.success(outcome);
  }

  // ==========================================================================
  // DETERMINISTIC HASHING HELPER
  // ==========================================================================

  /// Computes a deterministic SHA-256 fingerprint from the canonical string representation.
  String _computeDeterministicFingerprint({
    required String sessionId,
    required String examId,
    required String? learnerId,
    required PracticeSessionMode sessionMode,
    required PracticeExecutionStatus sessionStatus,
    required DateTime startedAt,
    required DateTime completedAt,
    required int totalQuestions,
    required int attemptedCount,
    required int correctCount,
    required int incorrectCount,
    required int skippedCount,
    required int unansweredCount,
    required double completionRate,
    required double? accuracy,
    required double scoreRatio,
    required int totalDurationSeconds,
    required PracticeFeedbackSummary feedbackSummary,
    required Map<String, PracticeTopicEvidence> topicEvidence,
    required Map<String, PracticeObjectiveEvidence> objectiveEvidence,
    required Map<String, PracticeSectionEvidence> sectionEvidence,
    required Map<String, PracticeDifficultyEvidence> difficultyEvidence,
    required List<PracticeQuestionEvidence> questionEvidence,
    required List<QuestionAttempt> handoffAttempts,
  }) {
    final buffer = StringBuffer();

    // Canonical Header
    buffer.write('examId=$examId|');
    buffer.write('sessionId=$sessionId|');
    buffer.write('learnerId=${learnerId ?? "null"}|');
    buffer.write('mode=${sessionMode.name}|');
    buffer.write('status=${sessionStatus.name}|');
    buffer.write('startedAt=${startedAt.toIso8601String()}|');
    buffer.write('completedAt=${completedAt.toIso8601String()}|');
    buffer.write(
        'metrics=$totalQuestions:$attemptedCount:$correctCount:$incorrectCount:$skippedCount:$unansweredCount|');
    buffer.write(
        'rates=${completionRate.toStringAsFixed(6)}:${accuracy != null ? accuracy.toStringAsFixed(6) : "null"}:${scoreRatio.toStringAsFixed(6)}|');
    buffer.write('duration=$totalDurationSeconds|');
    buffer.write(
        'feedback=${feedbackSummary.policy.name}:${feedbackSummary.explanationsExposedCount}:${feedbackSummary.explanationsWithheldCount}|');

    // Canonical Question Sequence
    buffer.write('questions=[');
    for (int i = 0; i < questionEvidence.length; i++) {
      final q = questionEvidence[i];
      buffer.write(
          '(${q.questionIndex}:${q.questionId}:${q.status.name}:${q.submittedAnswer ?? "none"}:${q.isCorrect}:${q.elapsedSeconds})');
      if (i < questionEvidence.length - 1) buffer.write(',');
    }
    buffer.write(']|');

    // Canonical Topic Evidence
    buffer.write('topics=[');
    final sortedTopicKeys = topicEvidence.keys.toList()..sort();
    for (int i = 0; i < sortedTopicKeys.length; i++) {
      final k = sortedTopicKeys[i];
      final t = topicEvidence[k]!;
      buffer.write(
          '($k:${t.totalQuestions}:${t.correctCount}:${t.attemptedCount}:${t.accuracy?.toStringAsFixed(6) ?? "null"})');
      if (i < sortedTopicKeys.length - 1) buffer.write(',');
    }
    buffer.write(']|');

    // Canonical Objective Evidence
    buffer.write('objectives=[');
    final sortedObjKeys = objectiveEvidence.keys.toList()..sort();
    for (int i = 0; i < sortedObjKeys.length; i++) {
      final k = sortedObjKeys[i];
      final o = objectiveEvidence[k]!;
      buffer.write(
          '($k:${o.totalQuestions}:${o.correctCount}:${o.attemptedCount}:${o.accuracy?.toStringAsFixed(6) ?? "null"})');
      if (i < sortedObjKeys.length - 1) buffer.write(',');
    }
    buffer.write(']|');

    // Canonical Section Evidence
    buffer.write('sections=[');
    final sortedSecKeys = sectionEvidence.keys.toList()..sort();
    for (int i = 0; i < sortedSecKeys.length; i++) {
      final k = sortedSecKeys[i];
      final s = sectionEvidence[k]!;
      buffer.write(
          '($k:${s.totalQuestions}:${s.correctCount}:${s.attemptedCount}:${s.accuracy?.toStringAsFixed(6) ?? "null"})');
      if (i < sortedSecKeys.length - 1) buffer.write(',');
    }
    buffer.write(']|');

    // Canonical Difficulty Evidence
    buffer.write('difficulties=[');
    final sortedDiffKeys = difficultyEvidence.keys.toList()..sort();
    for (int i = 0; i < sortedDiffKeys.length; i++) {
      final k = sortedDiffKeys[i];
      final d = difficultyEvidence[k]!;
      buffer.write(
          '($k:${d.totalQuestions}:${d.correctCount}:${d.attemptedCount}:${d.accuracy?.toStringAsFixed(6) ?? "null"})');
      if (i < sortedDiffKeys.length - 1) buffer.write(',');
    }
    buffer.write(']|');

    // Canonical Handoff Attempts
    buffer.write('handoff=[');
    for (int i = 0; i < handoffAttempts.length; i++) {
      final a = handoffAttempts[i];
      buffer.write(
          '(${a.attemptId}:${a.questionId}:${a.submittedAnswer}:${a.attemptedAt.toIso8601String()})');
      if (i < handoffAttempts.length - 1) buffer.write(',');
    }
    buffer.write(']');

    final canonicalBytes = utf8.encode(buffer.toString());
    return sha256.convert(canonicalBytes).toString();
  }
}

// ============================================================================
// PRIVATE HELPER CLASSES
// ============================================================================

class _SectionMetadata {
  final int sectionIndex;
  final String? sectionTitle;

  const _SectionMetadata({
    required this.sectionIndex,
    this.sectionTitle,
  });
}

class _DimensionalAccumulator {
  final String label;
  final String? secondaryLabel;
  int total = 0;
  int attempted = 0;
  int correct = 0;
  int incorrect = 0;
  int skipped = 0;
  int elapsed = 0;

  _DimensionalAccumulator({
    required this.label,
    this.secondaryLabel,
  });

  void record({
    required bool isAnswered,
    required bool isCorrect,
    required bool isSkipped,
    required int elapsed,
  }) {
    total++;
    this.elapsed += elapsed;
    if (isAnswered) {
      attempted++;
      if (isCorrect) {
        correct++;
      } else {
        incorrect++;
      }
    } else if (isSkipped) {
      skipped++;
    }
  }

  int get unanswered => (total - (attempted + skipped)).clamp(0, total);
  double get completionRate =>
      total > 0 ? ((attempted + skipped) / total).clamp(0.0, 1.0) : 0.0;
  double? get accuracy =>
      attempted > 0 ? (correct / attempted).clamp(0.0, 1.0) : null;
  double? get accuracyPercentage => accuracy != null ? accuracy! * 100.0 : null;
  double get skipRate => total > 0 ? (skipped / total).clamp(0.0, 1.0) : 0.0;
  double get avgSeconds => attempted > 0 ? elapsed / attempted : 0.0;

  PracticeTopicEvidence toTopicEvidence(String topic) => PracticeTopicEvidence(
        topic: topic,
        subject: secondaryLabel,
        totalQuestions: total,
        attemptedCount: attempted,
        correctCount: correct,
        incorrectCount: incorrect,
        skippedCount: skipped,
        unansweredCount: unanswered,
        completionRate: completionRate,
        accuracy: accuracy,
        accuracyPercentage: accuracyPercentage,
        skipRate: skipRate,
        totalElapsedSeconds: elapsed,
        averageSecondsPerAttempt: avgSeconds,
      );

  PracticeObjectiveEvidence toObjectiveEvidence(String objectiveId) =>
      PracticeObjectiveEvidence(
        objectiveId: objectiveId,
        totalQuestions: total,
        attemptedCount: attempted,
        correctCount: correct,
        incorrectCount: incorrect,
        skippedCount: skipped,
        unansweredCount: unanswered,
        completionRate: completionRate,
        accuracy: accuracy,
        accuracyPercentage: accuracyPercentage,
        skipRate: skipRate,
        totalElapsedSeconds: elapsed,
        averageSecondsPerAttempt: avgSeconds,
      );

  PracticeSectionEvidence toSectionEvidence(int sectionIndex) =>
      PracticeSectionEvidence(
        sectionIndex: sectionIndex,
        sectionTitle: secondaryLabel,
        totalQuestions: total,
        attemptedCount: attempted,
        correctCount: correct,
        incorrectCount: incorrect,
        skippedCount: skipped,
        unansweredCount: unanswered,
        completionRate: completionRate,
        accuracy: accuracy,
        accuracyPercentage: accuracyPercentage,
        skipRate: skipRate,
        totalElapsedSeconds: elapsed,
        averageSecondsPerAttempt: avgSeconds,
      );

  PracticeDifficultyEvidence toDifficultyEvidence(String difficulty) =>
      PracticeDifficultyEvidence(
        difficulty: difficulty,
        totalQuestions: total,
        attemptedCount: attempted,
        correctCount: correct,
        incorrectCount: incorrect,
        skippedCount: skipped,
        unansweredCount: unanswered,
        completionRate: completionRate,
        accuracy: accuracy,
        accuracyPercentage: accuracyPercentage,
        skipRate: skipRate,
        totalElapsedSeconds: elapsed,
        averageSecondsPerAttempt: avgSeconds,
      );
}
