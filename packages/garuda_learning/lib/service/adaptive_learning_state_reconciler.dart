/// Adaptive Learning State Reconciler Service (TITAN-KO-038.0 P38).
///
/// Deterministically reconciles an authoritative learner state with an evidence-derived
/// learning-state update proposal (P37) without mutating persistent storage.
///
/// Invariants:
/// - Pure deterministic proposal formulation; zero direct database writes or repository mutations (owned by P19).
/// - Zero SM-2 scheduling or ease-factor calculations (owned by P20).
/// - Zero longitudinal analytics or cross-session decay modeling (owned by P23).
/// - Zero question selection or session composition (owned by P33/P34).
/// - Strict multi-exam and learner isolation.
/// - Idempotent evaluation: repeated application of same proposal produces no-op (`duplicate`/`unchanged`).
/// - Canonical SHA-256 fingerprinting of reconciled proposal.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/entities/assessment_threshold_config.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/learner_objective_status.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_state_update_proposal.dart';
import '../domain/entities/reconciled_learning_state_proposal.dart';
import '../domain/entities/reconciliation_decision.dart';
import '../domain/entities/reconciliation_error.dart';

/// Pure deterministic service reconciling learner state with P37 update proposals.
class AdaptiveLearningStateReconciler {
  final AssessmentThresholdConfig _defaultThresholdConfig;

  const AdaptiveLearningStateReconciler({
    AssessmentThresholdConfig? defaultThresholdConfig,
  }) : _defaultThresholdConfig =
            defaultThresholdConfig ?? const AssessmentThresholdConfig();

  /// Reconciles an authoritative learner state with a P37 update proposal.
  ReconciliationResult<ReconciledLearningStateProposal> reconcile({
    required AuthoritativeLearnerState authoritativeState,
    required LearningStateUpdateProposal proposal,
    DateTime? reconciledAt,
    AssessmentThresholdConfig? thresholdConfig,
  }) {
    final effectiveThresholdConfig = thresholdConfig ?? _defaultThresholdConfig;
    final effectiveReconciledAt = (reconciledAt ?? proposal.proposedAt).toUtc();

    // 1. Identity & Isolation Validations
    if (authoritativeState.examId != proposal.examId) {
      return ReconciliationResult.failure(ReconciliationError(
        code: ReconciliationErrorCode.examMismatch,
        message:
            'Exam mismatch: Authoritative state is for "${authoritativeState.examId}" but proposal is for "${proposal.examId}"',
        details: {
          'authoritativeExam': authoritativeState.examId,
          'proposalExam': proposal.examId,
        },
      ));
    }

    if (proposal.learnerId != null &&
        proposal.learnerId!.trim().isNotEmpty &&
        authoritativeState.learnerId != proposal.learnerId!.trim()) {
      return ReconciliationResult.failure(ReconciliationError(
        code: ReconciliationErrorCode.learnerMismatch,
        message:
            'Learner mismatch: Authoritative state is for "${authoritativeState.learnerId}" but proposal is for "${proposal.learnerId}"',
        details: {
          'authoritativeLearner': authoritativeState.learnerId,
          'proposalLearner': proposal.learnerId,
        },
      ));
    }

    final cleanSessionId = proposal.sessionId.trim();
    final reconciliationId = 'rec_${cleanSessionId}_${proposal.examId}';
    final provenance = ReconciliationProvenance(
      proposalId: proposal.proposalId,
      sessionId: cleanSessionId,
      sourceProposalFingerprint: proposal.fingerprint,
      baseStateFingerprint: authoritativeState.stateFingerprint,
      reconciledAt: effectiveReconciledAt,
    );

    // 2. Session Idempotency Check (Duplicate Evidence)
    if (authoritativeState.hasProcessedSession(cleanSessionId)) {
      final noOpFingerprint = _generateCanonicalFingerprint(
        reconciliationId: reconciliationId,
        learnerId: authoritativeState.learnerId,
        examId: authoritativeState.examId,
        baseStateFingerprint: authoritativeState.stateFingerprint,
        sourceProposalFingerprint: proposal.fingerprint,
        reconciledAt: effectiveReconciledAt,
        overallDecision: ReconciliationDecision.duplicate,
        reconciledProgress: authoritativeState.progressMap,
        processedSessionIds: authoritativeState.processedSessionIds,
        questionDecisions: const [],
        objectiveDecisions: const {},
        topicDecisions: const {},
        conflicts: const [],
      );

      return ReconciliationResult.success(ReconciledLearningStateProposal(
        reconciliationId: reconciliationId,
        learnerId: authoritativeState.learnerId,
        examId: authoritativeState.examId,
        baseStateFingerprint: authoritativeState.stateFingerprint,
        sourceProposalFingerprint: proposal.fingerprint,
        reconciledAt: effectiveReconciledAt,
        overallDecision: ReconciliationDecision.duplicate,
        reconciledProgress: authoritativeState.progressMap,
        processedSessionIds: authoritativeState.processedSessionIds,
        questionDecisions: const [],
        objectiveDecisions: const {},
        topicDecisions: const {},
        conflicts: const [],
        provenance: provenance,
        fingerprint: noOpFingerprint,
      ));
    }

    // 3. Stale Proposal Detection
    final isStale =
        proposal.proposedAt.isBefore(authoritativeState.lastUpdatedAt);
    if (isStale) {
      final conflict = ReconciliationConflict(
        dimension: 'session',
        identifier: cleanSessionId,
        conflictType: 'staleProposal',
        authoritativeValue: authoritativeState.lastUpdatedAt.toIso8601String(),
        proposedValue: proposal.proposedAt.toIso8601String(),
        resolvedValue: 'rejected_as_stale',
        resolutionReason:
            'Proposal timestamp (${proposal.proposedAt.toIso8601String()}) is earlier than authoritative state update (${authoritativeState.lastUpdatedAt.toIso8601String()}). Authoritative state preserved.',
      );

      final staleFingerprint = _generateCanonicalFingerprint(
        reconciliationId: reconciliationId,
        learnerId: authoritativeState.learnerId,
        examId: authoritativeState.examId,
        baseStateFingerprint: authoritativeState.stateFingerprint,
        sourceProposalFingerprint: proposal.fingerprint,
        reconciledAt: effectiveReconciledAt,
        overallDecision: ReconciliationDecision.stale,
        reconciledProgress: authoritativeState.progressMap,
        processedSessionIds: authoritativeState.processedSessionIds,
        questionDecisions: const [],
        objectiveDecisions: const {},
        topicDecisions: const {},
        conflicts: [conflict],
      );

      return ReconciliationResult.success(ReconciledLearningStateProposal(
        reconciliationId: reconciliationId,
        learnerId: authoritativeState.learnerId,
        examId: authoritativeState.examId,
        baseStateFingerprint: authoritativeState.stateFingerprint,
        sourceProposalFingerprint: proposal.fingerprint,
        reconciledAt: effectiveReconciledAt,
        overallDecision: ReconciliationDecision.stale,
        reconciledProgress: authoritativeState.progressMap,
        processedSessionIds: authoritativeState.processedSessionIds,
        questionDecisions: const [],
        objectiveDecisions: const {},
        topicDecisions: const {},
        conflicts: [conflict],
        provenance: provenance,
        fingerprint: staleFingerprint,
      ));
    }

    // 4. Reconcile Objective Progress
    final Map<String, LearnerProgress> workingProgressMap =
        proposal.objectiveSignals.isEmpty
            ? authoritativeState.progressMap
            : Map<String, LearnerProgress>.from(authoritativeState.progressMap);
    final objectiveDecisions =
        SplayTreeMap<String, ObjectiveReconciliationDecision>();
    final conflicts = <ReconciliationConflict>[];
    int stateChangesCount = 0;
    bool newKeyInserted = false;

    for (final entry in proposal.objectiveSignals.entries) {
      final objId = entry.key;
      final oSig = entry.value;

      final existing = authoritativeState.getProgress(objId);

      if (oSig.attemptedCount == 0) {
        // Unattempted objective in this session -> unchanged
        objectiveDecisions[objId] = ObjectiveReconciliationDecision(
          objectiveId: objId,
          decision: ReconciliationDecision.unchanged,
          priorAttempts: existing?.attemptCount ?? 0,
          newAttempts: 0,
          reconciledAttempts: existing?.attemptCount ?? 0,
          priorStatus: existing?.status ?? LearnerObjectiveStatus.notStarted,
          reconciledStatus:
              existing?.status ?? LearnerObjectiveStatus.notStarted,
          explanation:
              'Objective was scheduled but had 0 attempts in practice session. Preserved existing progress without changes.',
        );
        continue;
      }

      if (existing == null) {
        // Additive evidence: New objective tracked for this learner
        final attemptCount = oSig.attemptedCount;
        final correctCount = oSig.correctCount;
        final successRate = (correctCount / attemptCount).clamp(0.0, 1.0);

        final isAchieved = effectiveThresholdConfig.isAchieved(
          attemptCount: attemptCount,
          successRate: successRate,
        );
        final status = isAchieved
            ? LearnerObjectiveStatus.achieved
            : LearnerObjectiveStatus.inProgress;
        final achievedAt = isAchieved ? effectiveReconciledAt : null;

        final newProgress = LearnerProgress(
          learnerId: authoritativeState.learnerId,
          objectiveId: objId,
          attemptCount: attemptCount,
          correctCount: correctCount,
          successRate: successRate,
          lastAttemptAt: effectiveReconciledAt,
          status: status,
          achievedAt: achievedAt,
        );

        workingProgressMap[objId] = newProgress;
        newKeyInserted = true;
        stateChangesCount++;

        objectiveDecisions[objId] = ObjectiveReconciliationDecision(
          objectiveId: objId,
          decision: ReconciliationDecision.accepted,
          priorAttempts: 0,
          newAttempts: attemptCount,
          reconciledAttempts: attemptCount,
          priorStatus: LearnerObjectiveStatus.notStarted,
          reconciledStatus: status,
          explanation:
              'Accepted initial evidence for previously untracked objective: $attemptCount attempts, $correctCount correct.',
        );
      } else {
        // Compatible update: Merge new session attempts into existing progress
        final priorAttempts = existing.attemptCount;
        final priorCorrect = existing.correctCount;
        final newAttempts = oSig.attemptedCount;
        final newCorrect = oSig.correctCount;

        final reconciledAttempts = priorAttempts + newAttempts;
        final reconciledCorrect = priorCorrect + newCorrect;
        final reconciledSuccessRate =
            (reconciledCorrect / reconciledAttempts).clamp(0.0, 1.0);

        // Achievement threshold evaluation
        final LearnerObjectiveStatus reconciledStatus;
        DateTime? achievedAt = existing.achievedAt;

        if (existing.status == LearnerObjectiveStatus.achieved) {
          // Invariant: Authoritative achieved status does not regress from practice evidence
          reconciledStatus = LearnerObjectiveStatus.achieved;
        } else if (effectiveThresholdConfig.isAchieved(
          attemptCount: reconciledAttempts,
          successRate: reconciledSuccessRate,
        )) {
          reconciledStatus = LearnerObjectiveStatus.achieved;
          achievedAt ??= effectiveReconciledAt;
        } else {
          reconciledStatus = LearnerObjectiveStatus.inProgress;
        }

        final updatedProgress = LearnerProgress(
          learnerId: authoritativeState.learnerId,
          objectiveId: objId,
          attemptCount: reconciledAttempts,
          correctCount: reconciledCorrect,
          successRate: reconciledSuccessRate,
          lastAttemptAt: effectiveReconciledAt,
          status: reconciledStatus,
          achievedAt: achievedAt,
        );

        workingProgressMap[objId] = updatedProgress;
        stateChangesCount++;

        objectiveDecisions[objId] = ObjectiveReconciliationDecision(
          objectiveId: objId,
          decision: ReconciliationDecision.merged,
          priorAttempts: priorAttempts,
          newAttempts: newAttempts,
          reconciledAttempts: reconciledAttempts,
          priorStatus: existing.status,
          reconciledStatus: reconciledStatus,
          explanation:
              'Merged practice session attempts: prior $priorAttempts + new $newAttempts = $reconciledAttempts attempts ($reconciledCorrect correct, successRate: ${(reconciledSuccessRate * 100).toStringAsFixed(1)}%).',
        );
      }
    }

    final Map<String, LearnerProgress> reconciledProgressMap = newKeyInserted
        ? SplayTreeMap<String, LearnerProgress>.from(workingProgressMap)
        : workingProgressMap;

    // 5. Reconcile Question Decisions
    final questionDecisions = <QuestionReconciliationDecision>[];
    for (final qSig in proposal.questionSignals) {
      final decision = qSig.isAnswered
          ? ReconciliationDecision.accepted
          : ReconciliationDecision.unchanged;

      final explanation = qSig.isAnswered
          ? 'Accepted observed question attempt evidence (${qSig.isCorrect ? "correct" : "incorrect"}). Proposed action: ${qSig.proposedAction.name}.'
          : 'Question was ${qSig.isSkipped ? "skipped" : "unanswered"}. No progress delta applied.';

      questionDecisions.add(QuestionReconciliationDecision(
        questionId: qSig.questionId,
        decision: decision,
        proposedAction: qSig.proposedAction,
        explanation: explanation,
      ));
    }

    // 6. Reconcile Topic Decisions
    final topicDecisions = SplayTreeMap<String, TopicReconciliationDecision>();
    for (final entry in proposal.topicSignals.entries) {
      final topic = entry.key;
      final tSig = entry.value;

      final decision = tSig.attemptedCount > 0
          ? ReconciliationDecision.accepted
          : ReconciliationDecision.unchanged;

      final explanation = tSig.attemptedCount > 0
          ? 'Reconciled topic performance evidence with ${tSig.attemptedCount} attempts (${tSig.accuracyPercentage?.toStringAsFixed(1) ?? "N/A"}% accuracy, pattern: ${tSig.pattern.name}).'
          : 'Topic had 0 attempts in this session. Unchanged.';

      topicDecisions[topic] = TopicReconciliationDecision(
        topic: topic,
        decision: decision,
        proposedAction: tSig.proposedAction,
        explanation: explanation,
      );
    }

    // 7. Determine Overall Macro Decision
    final ReconciliationDecision overallDecision;
    if (stateChangesCount == 0) {
      overallDecision = ReconciliationDecision.unchanged;
    } else {
      overallDecision = ReconciliationDecision.merged;
    }

    // 8. Cumulative Processed Sessions
    final updatedSessionIds =
        SplayTreeSet<String>.from(authoritativeState.processedSessionIds)
          ..add(cleanSessionId);

    // 9. Generate Canonical SHA-256 Fingerprint
    final canonicalFingerprint = _generateCanonicalFingerprint(
      reconciliationId: reconciliationId,
      learnerId: authoritativeState.learnerId,
      examId: authoritativeState.examId,
      baseStateFingerprint: authoritativeState.stateFingerprint,
      sourceProposalFingerprint: proposal.fingerprint,
      reconciledAt: effectiveReconciledAt,
      overallDecision: overallDecision,
      reconciledProgress: reconciledProgressMap,
      processedSessionIds: updatedSessionIds,
      questionDecisions: questionDecisions,
      objectiveDecisions: objectiveDecisions,
      topicDecisions: topicDecisions,
      conflicts: conflicts,
    );

    final reconciledProposal = ReconciledLearningStateProposal(
      reconciliationId: reconciliationId,
      learnerId: authoritativeState.learnerId,
      examId: authoritativeState.examId,
      baseStateFingerprint: authoritativeState.stateFingerprint,
      sourceProposalFingerprint: proposal.fingerprint,
      reconciledAt: effectiveReconciledAt,
      overallDecision: overallDecision,
      reconciledProgress: reconciledProgressMap,
      processedSessionIds: updatedSessionIds,
      questionDecisions: questionDecisions,
      objectiveDecisions: objectiveDecisions,
      topicDecisions: topicDecisions,
      conflicts: conflicts,
      provenance: provenance,
      fingerprint: canonicalFingerprint,
    );

    return ReconciliationResult.success(reconciledProposal);
  }

  static String _generateCanonicalFingerprint({
    required String reconciliationId,
    required String learnerId,
    required String examId,
    required String baseStateFingerprint,
    required String sourceProposalFingerprint,
    required DateTime reconciledAt,
    required ReconciliationDecision overallDecision,
    required Map<String, LearnerProgress> reconciledProgress,
    required Set<String> processedSessionIds,
    required List<QuestionReconciliationDecision> questionDecisions,
    required Map<String, ObjectiveReconciliationDecision> objectiveDecisions,
    required Map<String, TopicReconciliationDecision> topicDecisions,
    required List<ReconciliationConflict> conflicts,
  }) {
    final sb = StringBuffer();
    sb.write('$reconciliationId|$learnerId|$examId|');
    sb.write('$baseStateFingerprint|$sourceProposalFingerprint|');
    sb.write(
        '${reconciledAt.toUtc().toIso8601String()}|${overallDecision.name}|');

    final Iterable<MapEntry<String, LearnerProgress>> progressEntries;
    if (reconciledProgress is SplayTreeMap) {
      progressEntries = reconciledProgress.entries;
    } else {
      var isSorted = true;
      String? prevKey;
      for (final k in reconciledProgress.keys) {
        if (prevKey != null && prevKey.compareTo(k) > 0) {
          isSorted = false;
          break;
        }
        prevKey = k;
      }
      if (isSorted) {
        progressEntries = reconciledProgress.entries;
      } else {
        final sortedKeys = reconciledProgress.keys.toList()..sort();
        progressEntries =
            sortedKeys.map((k) => MapEntry(k, reconciledProgress[k]!));
      }
    }

    for (final entry in progressEntries) {
      final p = entry.value;
      sb.write(
          '${entry.key}:${p.attemptCount}:${p.correctCount}:${p.successRate.toStringAsFixed(4)}:${p.status.name};');
    }
    sb.write('|');

    final sortedSessions = processedSessionIds is SplayTreeSet
        ? processedSessionIds
        : (processedSessionIds.toList()..sort());
    sb.write(sortedSessions.join(','));
    sb.write('|');

    final sortedObjDecisionKeys = objectiveDecisions is SplayTreeMap
        ? objectiveDecisions.keys
        : (objectiveDecisions.keys.toList()..sort());
    for (final key in sortedObjDecisionKeys) {
      final d = objectiveDecisions[key]!;
      sb.write(
          '$key:${d.decision.name}:${d.reconciledAttempts}:${d.reconciledStatus.name};');
    }
    sb.write('|');

    final sortedTopicDecisionKeys = topicDecisions is SplayTreeMap
        ? topicDecisions.keys
        : (topicDecisions.keys.toList()..sort());
    for (final key in sortedTopicDecisionKeys) {
      final t = topicDecisions[key]!;
      sb.write('$key:${t.decision.name}:${t.proposedAction.name};');
    }
    sb.write('|');

    for (final q in questionDecisions) {
      sb.write('${q.questionId}:${q.decision.name}:${q.proposedAction.name};');
    }

    return sha256.convert(utf8.encode(sb.toString())).toString();
  }
}
