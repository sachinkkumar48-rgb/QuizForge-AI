/// Learning State Update Proposer Service (TITAN-KO-037.0 P37).
///
/// Deterministically converts consolidated practice execution evidence (P36)
/// into structured learning-state update proposals with multi-tier evidence signals,
/// trajectory pattern analysis, calibrated evidence strength, and recommended actions.
///
/// Invariants:
/// - Zero persistence writes or mutations (owned by P19).
/// - Zero SM-2 scheduling or ease-factor calculations (owned by P20).
/// - Zero longitudinal analytics or cross-session decay modeling (owned by P23).
/// - Zero question ranking or session composition (owned by P33/P34).
/// - $O(N)$ single-pass evaluation with zero non-deterministic timestamps.
/// - Pure deterministic replay and canonical SHA-256 fingerprinting.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/entities/learning_evidence_signal.dart';
import '../domain/entities/learning_proposal_error.dart';
import '../domain/entities/learning_state_update_proposal.dart';
import '../domain/entities/practice_outcome_consolidation.dart';
import '../domain/entities/practice_outcome_evidence.dart';

/// Pure deterministic service generating learning-state update proposals.
class LearningStateUpdateProposer {
  const LearningStateUpdateProposer();

  /// Formulates a justified learning-state update proposal from a consolidated practice outcome.
  LearningProposalResult<LearningStateUpdateProposal> proposeUpdate({
    required ConsolidatedPracticeOutcome outcome,
    DateTime? proposedAt,
  }) {
    final cleanSessionId = outcome.sessionId.trim();
    final cleanExamId = outcome.examId.trim().toLowerCase();

    // 1. Session and Exam Identity Validation
    if (cleanSessionId.isEmpty) {
      return const LearningProposalResult.failure(LearningProposalError(
        code: LearningProposalErrorCode.invalidOutcome,
        message: 'ConsolidatedPracticeOutcome sessionId cannot be empty',
      ));
    }
    if (cleanExamId.isEmpty) {
      return const LearningProposalResult.failure(LearningProposalError(
        code: LearningProposalErrorCode.invalidOutcome,
        message: 'ConsolidatedPracticeOutcome examId cannot be empty',
      ));
    }

    // 2. Count Consistency and Invariant Validation
    if (outcome.totalQuestions < 0 ||
        outcome.attemptedCount < 0 ||
        outcome.correctCount < 0 ||
        outcome.incorrectCount < 0 ||
        outcome.skippedCount < 0 ||
        outcome.unansweredCount < 0) {
      return const LearningProposalResult.failure(LearningProposalError(
        code: LearningProposalErrorCode.invalidEvidence,
        message: 'Evidence counts cannot be negative',
      ));
    }

    if (outcome.correctCount + outcome.incorrectCount !=
        outcome.attemptedCount) {
      return LearningProposalResult.failure(LearningProposalError(
        code: LearningProposalErrorCode.calculationError,
        message:
            'Count mismatch: correctCount (${outcome.correctCount}) + incorrectCount (${outcome.incorrectCount}) != attemptedCount (${outcome.attemptedCount})',
      ));
    }

    if (outcome.attemptedCount +
            outcome.skippedCount +
            outcome.unansweredCount !=
        outcome.totalQuestions) {
      return LearningProposalResult.failure(LearningProposalError(
        code: LearningProposalErrorCode.calculationError,
        message:
            'Count mismatch: attempted (${outcome.attemptedCount}) + skipped (${outcome.skippedCount}) + unanswered (${outcome.unansweredCount}) != total (${outcome.totalQuestions})',
      ));
    }

    // 3. Multi-Exam Isolation & Duplicate Check
    final seenQuestionIds = <String>{};
    for (final qEv in outcome.questionEvidence) {
      if (qEv.examId.trim().toLowerCase() != cleanExamId) {
        return LearningProposalResult.failure(LearningProposalError(
          code: LearningProposalErrorCode.examMismatch,
          message:
              'Cross-exam question evidence detected: question "${qEv.questionId}" has examId "${qEv.examId}" but session is "$cleanExamId"',
          details: {'questionId': qEv.questionId, 'expectedExam': cleanExamId},
        ));
      }
      if (!seenQuestionIds.add(qEv.questionId)) {
        return LearningProposalResult.failure(LearningProposalError(
          code: LearningProposalErrorCode.duplicateSignal,
          message:
              'Duplicate question evidence ID detected: "${qEv.questionId}"',
        ));
      }
    }

    final effectiveProposedAt = (proposedAt ?? outcome.completedAt).toUtc();
    final proposalId = 'prop_${cleanSessionId}_$cleanExamId';

    // 4. Single-pass evaluation of question signals and dimensional sequences
    final questionSignals = <QuestionLearningSignal>[];
    final attemptedCorrectnessSequence = <bool>[];
    final topicSequences = <String, List<bool>>{};
    final objectiveSequences = <String, List<bool>>{};
    final difficultySequences = <String, List<bool>>{};

    for (final qEv in outcome.questionEvidence) {
      final isAnswered = qEv.status.isAnswered;
      final isCorrect = qEv.isCorrect;
      final isSkipped = qEv.isSkipped;
      final isUnanswered = qEv.status.isUnanswered;

      if (isAnswered) {
        attemptedCorrectnessSequence.add(isCorrect);
        (topicSequences[qEv.topic] ??= []).add(isCorrect);
        for (final objId in qEv.objectiveIds) {
          (objectiveSequences[objId] ??= []).add(isCorrect);
        }
        (difficultySequences[qEv.difficulty] ??= []).add(isCorrect);
      }

      final qStrength =
          isAnswered ? EvidenceStrength.insufficient : EvidenceStrength.none;

      final ProposedLearningAction qAction;
      if (isCorrect) {
        qAction = ProposedLearningAction.retainMastery;
      } else if (qEv.status == PracticeQuestionStatus.answeredIncorrect) {
        qAction = ProposedLearningAction.reviewRemediation;
      } else if (isSkipped) {
        qAction = ProposedLearningAction.continueExposure;
      } else {
        qAction = ProposedLearningAction.noAction;
      }

      questionSignals.add(QuestionLearningSignal(
        questionId: qEv.questionId,
        examId: cleanExamId,
        subject: qEv.subject,
        topic: qEv.topic,
        objectiveIds: qEv.objectiveIds,
        difficulty: qEv.difficulty,
        status: qEv.status,
        isAnswered: isAnswered,
        isCorrect: isCorrect,
        isSkipped: isSkipped,
        isUnanswered: isUnanswered,
        elapsedSeconds: qEv.elapsedSeconds,
        evidenceStrength: qStrength,
        proposedAction: qAction,
      ));
    }

    // 5. Evaluate Overall Evidence Strength, Trajectory Pattern, and Recommended Action
    final overallEvidenceStrength =
        EvidenceStrength.fromAttemptCount(outcome.attemptedCount);

    final overallPattern = _evaluatePattern(
      totalQuestions: outcome.totalQuestions,
      attemptedCount: outcome.attemptedCount,
      correctCount: outcome.correctCount,
      skippedCount: outcome.skippedCount,
      correctnessSequence: attemptedCorrectnessSequence,
    );

    final recommendedAction = _evaluateProposedAction(
      attemptedCount: outcome.attemptedCount,
      skippedCount: outcome.skippedCount,
      accuracy: outcome.accuracy,
      evidenceStrength: overallEvidenceStrength,
      pattern: overallPattern,
    );

    // 6. Evaluate Topic Signals (O(1) lookup per topic)
    final topicSignalsMap = SplayTreeMap<String, TopicLearningSignal>();
    for (final entry in outcome.topicEvidence.entries) {
      final topicName = entry.key;
      final tEv = entry.value;
      final tSeq = topicSequences[topicName] ?? const [];

      final tStrength = EvidenceStrength.fromAttemptCount(tEv.attemptedCount);
      final tPattern = _evaluatePattern(
        totalQuestions: tEv.totalQuestions,
        attemptedCount: tEv.attemptedCount,
        correctCount: tEv.correctCount,
        skippedCount: tEv.skippedCount,
        correctnessSequence: tSeq,
      );
      final tAction = _evaluateProposedAction(
        attemptedCount: tEv.attemptedCount,
        skippedCount: tEv.skippedCount,
        accuracy: tEv.accuracy,
        evidenceStrength: tStrength,
        pattern: tPattern,
      );

      topicSignalsMap[topicName] = TopicLearningSignal(
        topic: topicName,
        subject: tEv.subject ?? 'General Studies',
        totalQuestions: tEv.totalQuestions,
        attemptedCount: tEv.attemptedCount,
        correctCount: tEv.correctCount,
        incorrectCount: tEv.incorrectCount,
        skippedCount: tEv.skippedCount,
        unansweredCount: tEv.unansweredCount,
        accuracy: tEv.accuracy,
        accuracyPercentage: tEv.accuracyPercentage,
        completionRate: tEv.completionRate,
        evidenceStrength: tStrength,
        pattern: tPattern,
        proposedAction: tAction,
        averageSecondsPerAttempt: tEv.averageSecondsPerAttempt,
      );
    }

    // 7. Evaluate Objective Signals (O(1) lookup per objective)
    final objectiveSignalsMap = SplayTreeMap<String, ObjectiveLearningSignal>();
    for (final entry in outcome.objectiveEvidence.entries) {
      final objId = entry.key;
      final oEv = entry.value;
      final oSeq = objectiveSequences[objId] ?? const [];

      final oStrength = EvidenceStrength.fromAttemptCount(oEv.attemptedCount);
      final oPattern = _evaluatePattern(
        totalQuestions: oEv.totalQuestions,
        attemptedCount: oEv.attemptedCount,
        correctCount: oEv.correctCount,
        skippedCount: oEv.skippedCount,
        correctnessSequence: oSeq,
      );
      final oAction = _evaluateProposedAction(
        attemptedCount: oEv.attemptedCount,
        skippedCount: oEv.skippedCount,
        accuracy: oEv.accuracy,
        evidenceStrength: oStrength,
        pattern: oPattern,
      );

      objectiveSignalsMap[objId] = ObjectiveLearningSignal(
        objectiveId: objId,
        totalQuestions: oEv.totalQuestions,
        attemptedCount: oEv.attemptedCount,
        correctCount: oEv.correctCount,
        incorrectCount: oEv.incorrectCount,
        skippedCount: oEv.skippedCount,
        unansweredCount: oEv.unansweredCount,
        accuracy: oEv.accuracy,
        accuracyPercentage: oEv.accuracyPercentage,
        completionRate: oEv.completionRate,
        evidenceStrength: oStrength,
        pattern: oPattern,
        proposedAction: oAction,
      );
    }

    // 8. Evaluate Section Signals
    final sectionSignalsMap = SplayTreeMap<String, SectionLearningSignal>();
    for (final entry in outcome.sectionEvidence.entries) {
      final secId = entry.key;
      final sEv = entry.value;

      final sStrength = EvidenceStrength.fromAttemptCount(sEv.attemptedCount);
      final sPattern = _evaluatePattern(
        totalQuestions: sEv.totalQuestions,
        attemptedCount: sEv.attemptedCount,
        correctCount: sEv.correctCount,
        skippedCount: sEv.skippedCount,
        correctnessSequence: const [],
      );
      final sAction = _evaluateProposedAction(
        attemptedCount: sEv.attemptedCount,
        skippedCount: sEv.skippedCount,
        accuracy: sEv.accuracy,
        evidenceStrength: sStrength,
        pattern: sPattern,
      );

      sectionSignalsMap[secId] = SectionLearningSignal(
        sectionId: secId,
        sectionIndex: sEv.sectionIndex,
        totalQuestions: sEv.totalQuestions,
        attemptedCount: sEv.attemptedCount,
        correctCount: sEv.correctCount,
        incorrectCount: sEv.incorrectCount,
        skippedCount: sEv.skippedCount,
        unansweredCount: sEv.unansweredCount,
        accuracy: sEv.accuracy,
        accuracyPercentage: sEv.accuracyPercentage,
        completionRate: sEv.completionRate,
        evidenceStrength: sStrength,
        pattern: sPattern,
        proposedAction: sAction,
      );
    }

    // 9. Evaluate Difficulty Signals (O(1) lookup per difficulty tier)
    final difficultySignalsMap =
        SplayTreeMap<String, DifficultyLearningSignal>();
    for (final entry in outcome.difficultyEvidence.entries) {
      final diffLabel = entry.key;
      final dEv = entry.value;
      final dSeq = difficultySequences[diffLabel] ?? const [];

      final dStrength = EvidenceStrength.fromAttemptCount(dEv.attemptedCount);
      final dPattern = _evaluatePattern(
        totalQuestions: dEv.totalQuestions,
        attemptedCount: dEv.attemptedCount,
        correctCount: dEv.correctCount,
        skippedCount: dEv.skippedCount,
        correctnessSequence: dSeq,
      );
      final dAction = _evaluateProposedAction(
        attemptedCount: dEv.attemptedCount,
        skippedCount: dEv.skippedCount,
        accuracy: dEv.accuracy,
        evidenceStrength: dStrength,
        pattern: dPattern,
      );

      difficultySignalsMap[diffLabel] = DifficultyLearningSignal(
        difficulty: diffLabel,
        totalQuestions: dEv.totalQuestions,
        attemptedCount: dEv.attemptedCount,
        correctCount: dEv.correctCount,
        incorrectCount: dEv.incorrectCount,
        skippedCount: dEv.skippedCount,
        unansweredCount: dEv.unansweredCount,
        accuracy: dEv.accuracy,
        accuracyPercentage: dEv.accuracyPercentage,
        completionRate: dEv.completionRate,
        evidenceStrength: dStrength,
        pattern: dPattern,
        proposedAction: dAction,
      );
    }

    // 10. Generate Canonical SHA-256 Fingerprint
    final canonicalFingerprint = _generateCanonicalFingerprint(
      proposalId: proposalId,
      sessionId: cleanSessionId,
      examId: cleanExamId,
      learnerId: outcome.learnerId,
      sessionMode: outcome.sessionMode,
      sessionStatus: outcome.sessionStatus,
      sourceOutcomeFingerprint: outcome.fingerprint,
      proposedAt: effectiveProposedAt,
      overallEvidenceStrength: overallEvidenceStrength,
      overallPattern: overallPattern,
      recommendedAction: recommendedAction,
      totalQuestions: outcome.totalQuestions,
      attemptedCount: outcome.attemptedCount,
      correctCount: outcome.correctCount,
      incorrectCount: outcome.incorrectCount,
      skippedCount: outcome.skippedCount,
      unansweredCount: outcome.unansweredCount,
      completionRate: outcome.completionRate,
      accuracy: outcome.accuracy,
      scoreRatio: outcome.scoreRatio,
      questionSignals: questionSignals,
      topicKeys: topicSignalsMap.keys.toList(),
      objectiveKeys: objectiveSignalsMap.keys.toList(),
      sectionKeys: sectionSignalsMap.keys.toList(),
      difficultyKeys: difficultySignalsMap.keys.toList(),
    );

    final proposal = LearningStateUpdateProposal(
      proposalId: proposalId,
      sessionId: cleanSessionId,
      examId: cleanExamId,
      learnerId: outcome.learnerId,
      sessionMode: outcome.sessionMode,
      sessionStatus: outcome.sessionStatus,
      sourceOutcomeFingerprint: outcome.fingerprint,
      proposedAt: effectiveProposedAt,
      overallEvidenceStrength: overallEvidenceStrength,
      overallPattern: overallPattern,
      recommendedAction: recommendedAction,
      totalQuestions: outcome.totalQuestions,
      attemptedCount: outcome.attemptedCount,
      correctCount: outcome.correctCount,
      incorrectCount: outcome.incorrectCount,
      skippedCount: outcome.skippedCount,
      unansweredCount: outcome.unansweredCount,
      completionRate: outcome.completionRate,
      accuracy: outcome.accuracy,
      accuracyPercentage: outcome.accuracyPercentage,
      scoreRatio: outcome.scoreRatio,
      questionSignals: questionSignals,
      topicSignals: topicSignalsMap,
      objectiveSignals: objectiveSignalsMap,
      sectionSignals: sectionSignalsMap,
      difficultySignals: difficultySignalsMap,
      fingerprint: canonicalFingerprint,
    );

    return LearningProposalResult.success(proposal);
  }

  /// Determines the descriptive outcome pattern across an attempted sequence.
  static OutcomePattern _evaluatePattern({
    required int totalQuestions,
    required int attemptedCount,
    required int correctCount,
    required int skippedCount,
    required List<bool> correctnessSequence,
  }) {
    if (totalQuestions == 0) return OutcomePattern.insufficientEvidence;
    if (attemptedCount == 0) {
      if (skippedCount > 0) return OutcomePattern.skippedOnly;
      return OutcomePattern.unansweredOnly;
    }
    if (attemptedCount == 1) {
      return OutcomePattern.insufficientEvidence;
    }

    if (correctCount == attemptedCount) {
      return OutcomePattern.consistentlyCorrect;
    }
    if (correctCount == 0) {
      return OutcomePattern.consistentlyIncorrect;
    }

    // Chronological trajectory analysis for 3+ attempts
    if (correctnessSequence.length >= 3) {
      final halfLen = correctnessSequence.length ~/ 2;
      int firstHalfCorrect = 0;
      for (int i = 0; i < halfLen; i++) {
        if (correctnessSequence[i]) firstHalfCorrect++;
      }
      int secondHalfCorrect = 0;
      for (int i = correctnessSequence.length - halfLen;
          i < correctnessSequence.length;
          i++) {
        if (correctnessSequence[i]) secondHalfCorrect++;
      }

      final firstHalfAcc = firstHalfCorrect / halfLen;
      final secondHalfAcc = secondHalfCorrect / halfLen;

      if (secondHalfAcc >= firstHalfAcc + 0.35 && secondHalfAcc >= 0.50) {
        return OutcomePattern.improving;
      }
      if (firstHalfAcc >= secondHalfAcc + 0.35 && secondHalfAcc < 0.50) {
        return OutcomePattern.declining;
      }
    }

    return OutcomePattern.mixed;
  }

  /// Derives the recommended downstream learning action proposal.
  static ProposedLearningAction _evaluateProposedAction({
    required int attemptedCount,
    required int skippedCount,
    required double? accuracy,
    required EvidenceStrength evidenceStrength,
    required OutcomePattern pattern,
  }) {
    if (attemptedCount == 0) {
      if (skippedCount > 0) return ProposedLearningAction.continueExposure;
      return ProposedLearningAction.noAction;
    }

    if (evidenceStrength == EvidenceStrength.insufficient) {
      if (accuracy == 1.0) return ProposedLearningAction.retainMastery;
      return ProposedLearningAction.reinforceConcept;
    }

    if (pattern == OutcomePattern.consistentlyCorrect) {
      return ProposedLearningAction.retainMastery;
    }
    if (pattern == OutcomePattern.consistentlyIncorrect) {
      return ProposedLearningAction.reviewRemediation;
    }
    if (pattern == OutcomePattern.declining) {
      if (accuracy != null && accuracy >= 0.75) {
        return ProposedLearningAction.retainMastery;
      }
      return ProposedLearningAction.reviewRemediation;
    }
    if (pattern == OutcomePattern.improving) {
      if (accuracy != null && accuracy >= 0.70) {
        return ProposedLearningAction.retainMastery;
      }
      return ProposedLearningAction.reinforceConcept;
    }

    // Mixed pattern
    if (accuracy != null) {
      if (accuracy >= 0.75) return ProposedLearningAction.retainMastery;
      if (accuracy < 0.50) return ProposedLearningAction.reviewRemediation;
      return ProposedLearningAction.reinforceConcept;
    }

    return ProposedLearningAction.noAction;
  }

  /// Generates deterministic SHA-256 canonical hash of the proposal.
  static String _generateCanonicalFingerprint({
    required String proposalId,
    required String sessionId,
    required String examId,
    required String? learnerId,
    required dynamic sessionMode,
    required dynamic sessionStatus,
    required String sourceOutcomeFingerprint,
    required DateTime proposedAt,
    required EvidenceStrength overallEvidenceStrength,
    required OutcomePattern overallPattern,
    required ProposedLearningAction recommendedAction,
    required int totalQuestions,
    required int attemptedCount,
    required int correctCount,
    required int incorrectCount,
    required int skippedCount,
    required int unansweredCount,
    required double completionRate,
    required double? accuracy,
    required double scoreRatio,
    required List<QuestionLearningSignal> questionSignals,
    required List<String> topicKeys,
    required List<String> objectiveKeys,
    required List<String> sectionKeys,
    required List<String> difficultyKeys,
  }) {
    final sb = StringBuffer();
    sb.write('$proposalId|$sessionId|$examId|${learnerId ?? "anon"}|');
    sb.write('${sessionMode.toString()}|${sessionStatus.toString()}|');
    sb.write('$sourceOutcomeFingerprint|${proposedAt.toIso8601String()}|');
    sb.write(
        '${overallEvidenceStrength.name}|${overallPattern.name}|${recommendedAction.name}|');
    sb.write(
        '$totalQuestions|$attemptedCount|$correctCount|$incorrectCount|$skippedCount|$unansweredCount|');
    sb.write(
        '${completionRate.toStringAsFixed(4)}|${accuracy?.toStringAsFixed(4) ?? "null"}|${scoreRatio.toStringAsFixed(4)}|');
    sb.write(
        '${topicKeys.join(",")}|${objectiveKeys.join(",")}|${sectionKeys.join(",")}|${difficultyKeys.join(",")}|');

    for (final q in questionSignals) {
      sb.write(
          '${q.questionId}:${q.status.name}:${q.isCorrect}:${q.proposedAction.name};');
    }

    return sha256.convert(utf8.encode(sb.toString())).toString();
  }
}
