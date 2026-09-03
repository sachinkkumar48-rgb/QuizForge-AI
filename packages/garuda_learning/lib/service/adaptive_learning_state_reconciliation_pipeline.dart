/// Adaptive Learning State Reconciliation & Persistence Pipeline (TITAN-KO-039.0 P39).
///
/// Production-grade pipeline integrating practice outcome evidence consolidation,
/// learning-state update proposal generation, P38 reconciliation, monotonic
/// revision tracking, concurrency conflict safety, and atomic persistence.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/entities/assessment_threshold_config.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/authoritative_persistence_error.dart';
import '../domain/entities/learner_progress.dart';
import '../domain/entities/learning_state_update_proposal.dart';
import '../domain/entities/persisted_authoritative_learner_state.dart';
import '../domain/entities/practice_execution_state.dart';
import '../domain/entities/practice_outcome_consolidation.dart';
import '../domain/entities/reconciliation_audit_trail.dart';
import '../domain/entities/reconciliation_decision.dart';
import '../domain/entities/reconciliation_pipeline_result.dart';
import '../repository/authoritative_learning_state_repository.dart';
import 'adaptive_learning_state_reconciler.dart';
import 'authoritative_learning_state_recovery_service.dart';
import 'learning_state_update_proposer.dart';
import 'practice_outcome_consolidator.dart';

/// Production pipeline orchestrating evidence -> consolidation -> proposal -> reconciliation -> persistence.
class AdaptiveLearningStateReconciliationPipeline {
  final AuthoritativeLearningStateRepository _repository;
  final AuthoritativeLearningStateRecoveryService _recoveryService;
  final AdaptiveLearningStateReconciler _reconciler;
  final LearningStateUpdateProposer _proposer;
  final PracticeOutcomeConsolidator _consolidator;

  const AdaptiveLearningStateReconciliationPipeline({
    required AuthoritativeLearningStateRepository repository,
    required AuthoritativeLearningStateRecoveryService recoveryService,
    AdaptiveLearningStateReconciler? reconciler,
    LearningStateUpdateProposer? proposer,
    PracticeOutcomeConsolidator? consolidator,
  })  : _repository = repository,
        _recoveryService = recoveryService,
        _reconciler = reconciler ?? const AdaptiveLearningStateReconciler(),
        _proposer = proposer ?? const LearningStateUpdateProposer(),
        _consolidator = consolidator ?? const PracticeOutcomeConsolidator();

  /// Executes the reconciliation pipeline starting from [ConsolidatedPracticeOutcome].
  Future<ReconciliationPipelineResult> reconcilePracticeOutcome({
    required AuthoritativeLearnerState baseState,
    required ConsolidatedPracticeOutcome outcome,
    int? expectedRevision,
    DateTime? timestamp,
    AssessmentThresholdConfig? thresholdConfig,
  }) async {
    final effectiveDate = (timestamp ?? outcome.completedAt).toUtc();
    final auditId = _generateAuditId(
      learnerId: baseState.learnerId,
      sessionId: outcome.sessionId,
      timestamp: effectiveDate,
    );

    // 1. Identity and Tenant Validation
    final outcomeLearner = outcome.learnerId?.trim();
    if (outcomeLearner != null &&
        outcomeLearner.isNotEmpty &&
        outcomeLearner != baseState.learnerId) {
      final auditTrail = _createFailureAudit(
        auditId: auditId,
        baseState: baseState,
        sessionId: outcome.sessionId,
        effectiveDate: effectiveDate,
        reason:
            'Learner mismatch: baseState (${baseState.learnerId}) != outcome ($outcomeLearner)',
      );
      return ReconciliationPipelineResult.failure(
        baseState: baseState,
        auditTrail: auditTrail,
        message:
            'Learner mismatch: baseState (${baseState.learnerId}) != outcome ($outcomeLearner)',
        persistenceError: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Learner mismatch: baseState (${baseState.learnerId}) != outcome ($outcomeLearner)',
        ),
      );
    }

    final outcomeExam = outcome.examId.trim().toLowerCase();
    if (outcomeExam != baseState.examId) {
      final auditTrail = _createFailureAudit(
        auditId: auditId,
        baseState: baseState,
        sessionId: outcome.sessionId,
        effectiveDate: effectiveDate,
        reason:
            'Exam mismatch: baseState (${baseState.examId}) != outcome ($outcomeExam)',
      );
      return ReconciliationPipelineResult.failure(
        baseState: baseState,
        auditTrail: auditTrail,
        message:
            'Exam mismatch: baseState (${baseState.examId}) != outcome ($outcomeExam)',
        persistenceError: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Exam mismatch: baseState (${baseState.examId}) != outcome ($outcomeExam)',
        ),
      );
    }

    // 2. Concurrency & Stale Revision Protection (Phase 5)
    if (expectedRevision != null && expectedRevision != baseState.revision) {
      final auditTrail = ReconciliationAuditTrail(
        auditId: auditId,
        learnerId: baseState.learnerId,
        examId: baseState.examId,
        sessionId: outcome.sessionId,
        baseRevision: baseState.revision,
        resultingRevision: baseState.revision,
        baseStateFingerprint: baseState.stateFingerprint,
        resultingStateFingerprint: baseState.stateFingerprint,
        decision: ReconciliationDecision.invalid,
        isConflict: true,
        notes: [
          'Stale base state detected: expected revision $expectedRevision != actual revision ${baseState.revision}',
        ],
        recordedAt: effectiveDate,
      );
      return ReconciliationPipelineResult.conflict(
        baseState: baseState,
        auditTrail: auditTrail,
        message:
            'Concurrency conflict: expected revision $expectedRevision does not match current state revision ${baseState.revision}',
        persistenceError: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.staleWrite,
          message:
              'Stale base state: expected revision $expectedRevision != current revision ${baseState.revision}',
        ),
      );
    }

    // 3. Mandatory Idempotency Guard (Phase 4)
    if (baseState.hasProcessedSession(outcome.sessionId)) {
      final auditTrail = ReconciliationAuditTrail(
        auditId: auditId,
        learnerId: baseState.learnerId,
        examId: baseState.examId,
        sessionId: outcome.sessionId,
        baseRevision: baseState.revision,
        resultingRevision: baseState.revision,
        baseStateFingerprint: baseState.stateFingerprint,
        resultingStateFingerprint: baseState.stateFingerprint,
        decision: ReconciliationDecision.unchanged,
        isIdempotentReplay: true,
        notes: [
          'Session "${outcome.sessionId}" was previously incorporated; idempotent no-op executed.',
        ],
        recordedAt: effectiveDate,
      );
      return ReconciliationPipelineResult.idempotent(
        baseState: baseState,
        auditTrail: auditTrail,
        message:
            'Session "${outcome.sessionId}" already applied at revision ${baseState.revision}',
      );
    }

    // 4. Formulate P37 LearningStateUpdateProposal
    final proposalResult = _proposer.proposeUpdate(
      outcome: outcome,
      proposedAt: effectiveDate,
    );

    if (proposalResult.isFailure) {
      final propError = proposalResult.error!;
      final auditTrail = _createFailureAudit(
        auditId: auditId,
        baseState: baseState,
        sessionId: outcome.sessionId,
        effectiveDate: effectiveDate,
        reason: 'Failed to formulate proposal: ${propError.message}',
      );
      return ReconciliationPipelineResult.failure(
        baseState: baseState,
        auditTrail: auditTrail,
        message: 'Failed to formulate update proposal: ${propError.message}',
      );
    }

    final proposal = proposalResult.valueOrThrow;

    // 5. Delegate to core proposal reconciler
    return reconcileProposal(
      baseState: baseState,
      proposal: proposal,
      expectedRevision: expectedRevision,
      timestamp: effectiveDate,
      thresholdConfig: thresholdConfig,
    );
  }

  /// Executes the pipeline starting from a [PracticeExecutionState].
  Future<ReconciliationPipelineResult> reconcileExecutionState({
    required AuthoritativeLearnerState baseState,
    required PracticeExecutionState executionState,
    int? expectedRevision,
    DateTime? timestamp,
    AssessmentThresholdConfig? thresholdConfig,
  }) async {
    final effectiveDate = timestamp?.toUtc();
    final consolidationResult = _consolidator.consolidate(
      state: executionState,
      consolidatedAt: effectiveDate,
    );

    if (consolidationResult.isFailure) {
      final conError = consolidationResult.error!;
      final auditId = _generateAuditId(
        learnerId: baseState.learnerId,
        sessionId: executionState.sessionId,
        timestamp: effectiveDate ?? DateTime.utc(2026, 1, 1),
      );
      final auditTrail = _createFailureAudit(
        auditId: auditId,
        baseState: baseState,
        sessionId: executionState.sessionId,
        effectiveDate: effectiveDate ?? DateTime.utc(2026, 1, 1),
        reason: 'Practice consolidation failed: ${conError.message}',
      );
      return ReconciliationPipelineResult.failure(
        baseState: baseState,
        auditTrail: auditTrail,
        message: 'Consolidation failure: ${conError.message}',
      );
    }

    return reconcilePracticeOutcome(
      baseState: baseState,
      outcome: consolidationResult.valueOrThrow,
      expectedRevision: expectedRevision,
      timestamp: effectiveDate,
      thresholdConfig: thresholdConfig,
    );
  }

  /// Reconciles a formulated [LearningStateUpdateProposal] with [baseState] and persists the result.
  Future<ReconciliationPipelineResult> reconcileProposal({
    required AuthoritativeLearnerState baseState,
    required LearningStateUpdateProposal proposal,
    int? expectedRevision,
    DateTime? timestamp,
    AssessmentThresholdConfig? thresholdConfig,
  }) async {
    final effectiveDate = (timestamp ?? proposal.proposedAt).toUtc();
    final auditId = _generateAuditId(
      learnerId: baseState.learnerId,
      sessionId: proposal.sessionId,
      timestamp: effectiveDate,
    );

    // 1. Identity & Concurrency Pre-checks
    final proposalLearner = proposal.learnerId?.trim() ?? baseState.learnerId;
    if (proposalLearner != baseState.learnerId) {
      final auditTrail = _createFailureAudit(
        auditId: auditId,
        baseState: baseState,
        sessionId: proposal.sessionId,
        proposalId: proposal.proposalId,
        effectiveDate: effectiveDate,
        reason:
            'Learner mismatch: baseState (${baseState.learnerId}) != proposal ($proposalLearner)',
      );
      return ReconciliationPipelineResult.failure(
        baseState: baseState,
        auditTrail: auditTrail,
        message:
            'Learner mismatch: baseState (${baseState.learnerId}) != proposal ($proposalLearner)',
        persistenceError: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Learner mismatch: baseState (${baseState.learnerId}) != proposal ($proposalLearner)',
        ),
      );
    }

    if (proposal.examId.trim().toLowerCase() != baseState.examId) {
      final auditTrail = _createFailureAudit(
        auditId: auditId,
        baseState: baseState,
        sessionId: proposal.sessionId,
        proposalId: proposal.proposalId,
        effectiveDate: effectiveDate,
        reason:
            'Exam mismatch: baseState (${baseState.examId}) != proposal (${proposal.examId})',
      );
      return ReconciliationPipelineResult.failure(
        baseState: baseState,
        auditTrail: auditTrail,
        message:
            'Exam mismatch: baseState (${baseState.examId}) != proposal (${proposal.examId})',
        persistenceError: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Exam mismatch: baseState (${baseState.examId}) != proposal (${proposal.examId})',
        ),
      );
    }

    // Expected revision concurrency validation
    if (expectedRevision != null && expectedRevision != baseState.revision) {
      final auditTrail = ReconciliationAuditTrail(
        auditId: auditId,
        learnerId: baseState.learnerId,
        examId: baseState.examId,
        sessionId: proposal.sessionId,
        proposalId: proposal.proposalId,
        baseRevision: baseState.revision,
        resultingRevision: baseState.revision,
        baseStateFingerprint: baseState.stateFingerprint,
        resultingStateFingerprint: baseState.stateFingerprint,
        decision: ReconciliationDecision.invalid,
        isConflict: true,
        notes: [
          'Stale base state: expected revision $expectedRevision != actual revision ${baseState.revision}',
        ],
        recordedAt: effectiveDate,
      );
      return ReconciliationPipelineResult.conflict(
        baseState: baseState,
        auditTrail: auditTrail,
        message:
            'Concurrency conflict: expected revision $expectedRevision != ${baseState.revision}',
        persistenceError: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.staleWrite,
          message:
              'Stale base revision $expectedRevision != ${baseState.revision}',
        ),
      );
    }

    // Idempotency check
    if (baseState.hasProcessedSession(proposal.sessionId)) {
      final auditTrail = ReconciliationAuditTrail(
        auditId: auditId,
        learnerId: baseState.learnerId,
        examId: baseState.examId,
        sessionId: proposal.sessionId,
        proposalId: proposal.proposalId,
        baseRevision: baseState.revision,
        resultingRevision: baseState.revision,
        baseStateFingerprint: baseState.stateFingerprint,
        resultingStateFingerprint: baseState.stateFingerprint,
        decision: ReconciliationDecision.unchanged,
        isIdempotentReplay: true,
        notes: [
          'Session "${proposal.sessionId}" already applied; idempotent no-op.',
        ],
        recordedAt: effectiveDate,
      );
      return ReconciliationPipelineResult.idempotent(
        baseState: baseState,
        auditTrail: auditTrail,
        message:
            'Session "${proposal.sessionId}" already applied at revision ${baseState.revision}',
      );
    }

    // 2. Delegate to P38 AdaptiveLearningStateReconciler
    final reconciliationResult = _reconciler.reconcile(
      authoritativeState: baseState,
      proposal: proposal,
      reconciledAt: effectiveDate,
      thresholdConfig: thresholdConfig,
    );

    if (reconciliationResult.isFailure) {
      final recError = reconciliationResult.error!;
      final auditTrail = _createFailureAudit(
        auditId: auditId,
        baseState: baseState,
        sessionId: proposal.sessionId,
        proposalId: proposal.proposalId,
        effectiveDate: effectiveDate,
        reason: 'P38 reconciliation error: ${recError.message}',
      );
      return ReconciliationPipelineResult.failure(
        baseState: baseState,
        auditTrail: auditTrail,
        message: 'P38 reconciliation rejected: ${recError.message}',
        reconciliationError: recError,
      );
    }

    final reconciledProposal = reconciliationResult.valueOrThrow;

    // 3. Rejection & Policy Check
    if (reconciledProposal.overallDecision == ReconciliationDecision.rejected ||
        reconciledProposal.overallDecision == ReconciliationDecision.invalid) {
      final auditTrail = ReconciliationAuditTrail(
        auditId: auditId,
        learnerId: baseState.learnerId,
        examId: baseState.examId,
        sessionId: proposal.sessionId,
        proposalId: proposal.proposalId,
        reconciliationId: reconciledProposal.reconciliationId,
        baseRevision: baseState.revision,
        resultingRevision: baseState.revision,
        baseStateFingerprint: baseState.stateFingerprint,
        resultingStateFingerprint: baseState.stateFingerprint,
        decision: reconciledProposal.overallDecision,
        notes: [
          'Proposal rejected by P38 reconciler policy: ${reconciledProposal.overallDecision.name}',
          ...reconciledProposal.conflicts
              .map((c) => 'Conflict: ${c.resolutionReason}'),
        ],
        recordedAt: effectiveDate,
      );
      return ReconciliationPipelineResult.rejected(
        baseState: baseState,
        reconciledProposal: reconciledProposal,
        auditTrail: auditTrail,
        message:
            'Proposal was rejected: ${reconciledProposal.overallDecision.name}',
      );
    }

    // 4. Compute updated authoritative state with monotonic revision increment
    final nextRevision = baseState.revision + 1;
    final updatedProgressMap =
        Map<String, LearnerProgress>.from(baseState.progressMap);
    final changedObjectiveIds = <String>[];

    for (final entry in reconciledProposal.reconciledProgress.entries) {
      final prev = baseState.progressMap[entry.key];
      if (prev == null ||
          prev.attemptCount != entry.value.attemptCount ||
          prev.correctCount != entry.value.correctCount ||
          prev.status != entry.value.status) {
        changedObjectiveIds.add(entry.key);
      }
      updatedProgressMap[entry.key] = entry.value;
    }

    final updatedSessions = <String>{
      ...baseState.processedSessionIds,
      proposal.sessionId,
    };

    final updatedState = AuthoritativeLearnerState(
      learnerId: baseState.learnerId,
      examId: baseState.examId,
      progressMap: updatedProgressMap,
      processedSessionIds: updatedSessions,
      lastUpdatedAt: effectiveDate,
      revision: nextRevision,
    );

    // 5. Atomically persist updated authoritative state
    final persisted = PersistedAuthoritativeLearnerState.fromAuthoritativeState(
      updatedState,
      revision: nextRevision,
    );

    try {
      await _repository.save(persisted);
    } on AuthoritativePersistenceException catch (e) {
      final auditTrail = _createFailureAudit(
        auditId: auditId,
        baseState: baseState,
        sessionId: proposal.sessionId,
        proposalId: proposal.proposalId,
        reconciliationId: reconciledProposal.reconciliationId,
        effectiveDate: effectiveDate,
        reason: 'Atomic save failure: ${e.message}',
      );
      return ReconciliationPipelineResult.failure(
        baseState: baseState,
        auditTrail: auditTrail,
        message: 'Persistence failure: ${e.message}',
        persistenceError: e,
      );
    }

    // 6. Build audit trail and return successful result
    final auditTrail = ReconciliationAuditTrail(
      auditId: auditId,
      learnerId: baseState.learnerId,
      examId: baseState.examId,
      sessionId: proposal.sessionId,
      proposalId: proposal.proposalId,
      reconciliationId: reconciledProposal.reconciliationId,
      baseRevision: baseState.revision,
      resultingRevision: nextRevision,
      baseStateFingerprint: baseState.stateFingerprint,
      resultingStateFingerprint: updatedState.stateFingerprint,
      decision: reconciledProposal.overallDecision,
      changedObjectiveIds: changedObjectiveIds,
      acceptedCount: changedObjectiveIds.length,
      rejectedCount: reconciledProposal.conflicts.length,
      notes: [
        'Applied ${changedObjectiveIds.length} objective changes.',
        'Revision advanced from ${baseState.revision} to $nextRevision.',
      ],
      recordedAt: effectiveDate,
    );

    return ReconciliationPipelineResult.applied(
      baseState: baseState,
      resultingState: updatedState,
      reconciledProposal: reconciledProposal,
      auditTrail: auditTrail,
      message: 'State reconciled and persisted at revision $nextRevision',
    );
  }

  /// High-level orchestration that loads or initializes state from repository,
  /// reconciles the outcome, and atomically persists the result.
  Future<ReconciliationPipelineResult> executeFromRepository({
    required String learnerId,
    required String examId,
    required ConsolidatedPracticeOutcome outcome,
    int? expectedRevision,
    DateTime? timestamp,
  }) async {
    final effectiveDate = (timestamp ?? outcome.completedAt).toUtc();
    final recoveryResult = await _recoveryService.recover(
      learnerId: learnerId,
      examId: examId,
      requestedAt: effectiveDate,
      persistInitialIfAbsent: true,
    );

    if (!recoveryResult.isSuccess || recoveryResult.state == null) {
      final auditId = _generateAuditId(
        learnerId: learnerId,
        sessionId: outcome.sessionId,
        timestamp: effectiveDate,
      );
      final emptyState = AuthoritativeLearnerState.empty(
        learnerId: learnerId,
        examId: examId,
        createdAt: effectiveDate,
      );
      final auditTrail = _createFailureAudit(
        auditId: auditId,
        baseState: emptyState,
        sessionId: outcome.sessionId,
        effectiveDate: effectiveDate,
        reason:
            'Recovery failed: ${recoveryResult.error?.message ?? "unknown error"}',
      );
      return ReconciliationPipelineResult.failure(
        baseState: emptyState,
        auditTrail: auditTrail,
        message:
            'Could not recover authoritative state: ${recoveryResult.error?.message}',
        persistenceError: recoveryResult.error,
      );
    }

    return reconcilePracticeOutcome(
      baseState: recoveryResult.state!,
      outcome: outcome,
      expectedRevision: expectedRevision,
      timestamp: effectiveDate,
    );
  }

  String _generateAuditId({
    required String learnerId,
    required String sessionId,
    required DateTime timestamp,
  }) {
    final raw = '$learnerId:$sessionId:${timestamp.toIso8601String()}';
    final hash = sha256.convert(utf8.encode(raw)).toString().substring(0, 16);
    return 'aud_$hash';
  }

  ReconciliationAuditTrail _createFailureAudit({
    required String auditId,
    required AuthoritativeLearnerState baseState,
    required String sessionId,
    String? proposalId,
    String? reconciliationId,
    required DateTime effectiveDate,
    required String reason,
  }) {
    return ReconciliationAuditTrail(
      auditId: auditId,
      learnerId: baseState.learnerId,
      examId: baseState.examId,
      sessionId: sessionId,
      proposalId: proposalId,
      reconciliationId: reconciliationId,
      baseRevision: baseState.revision,
      resultingRevision: baseState.revision,
      baseStateFingerprint: baseState.stateFingerprint,
      resultingStateFingerprint: baseState.stateFingerprint,
      decision: ReconciliationDecision.invalid,
      notes: [reason],
      recordedAt: effectiveDate,
    );
  }
}
