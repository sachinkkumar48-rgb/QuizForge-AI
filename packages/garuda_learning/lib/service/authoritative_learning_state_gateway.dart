/// Authoritative Learning-State Application Gateway (TITAN-KO-039.0 P39).
///
/// Controlled transaction gateway between P38 [ReconciledLearningStateProposal]
/// and P19 authoritative persistence ([ProgressRepository]).
library;

import '../domain/entities/authoritative_application_decision.dart';
import '../domain/entities/authoritative_application_error.dart';
import '../domain/entities/authoritative_application_result.dart';
import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/reconciled_learning_state_proposal.dart';
import '../domain/entities/reconciliation_decision.dart';
import '../repository/progress_repository.dart';

class AuthoritativeLearningStateGateway {
  final ProgressRepository _progressRepository;

  const AuthoritativeLearningStateGateway({
    required ProgressRepository progressRepository,
  }) : _progressRepository = progressRepository;

  /// Progress repository handle exposed strictly for read-only inspection.
  ProgressRepository get progressRepository => _progressRepository;

  /// Safely, idempotently, and atomically applies an already-reconciled [proposal]
  /// to P19 authoritative persistence.
  AuthoritativeApplicationResult applyProposal({
    required ReconciledLearningStateProposal proposal,
    AuthoritativeLearnerState? currentState,
    DateTime? appliedAt,
  }) {
    final effectiveAppliedAt = (appliedAt ?? proposal.reconciledAt).toUtc();

    // -------------------------------------------------------------------------
    // 1. Input & Identity Validation
    // -------------------------------------------------------------------------
    if (proposal.learnerId.trim().isEmpty) {
      return _buildErrorResult(
        proposal: proposal,
        previousFingerprint: 'none',
        resultingFingerprint: 'none',
        decision: AuthoritativeApplicationDecision.invalid,
        code: AuthoritativeApplicationErrorCode.invalidProposal,
        message: 'Proposal learnerId cannot be empty',
        appliedAt: effectiveAppliedAt,
      );
    }

    if (proposal.examId.trim().isEmpty) {
      return _buildErrorResult(
        proposal: proposal,
        previousFingerprint: 'none',
        resultingFingerprint: 'none',
        decision: AuthoritativeApplicationDecision.invalid,
        code: AuthoritativeApplicationErrorCode.invalidProposal,
        message: 'Proposal examId cannot be empty',
        appliedAt: effectiveAppliedAt,
      );
    }

    if (proposal.reconciliationId.trim().isEmpty ||
        proposal.fingerprint.trim().isEmpty) {
      return _buildErrorResult(
        proposal: proposal,
        previousFingerprint: 'none',
        resultingFingerprint: 'none',
        decision: AuthoritativeApplicationDecision.invalid,
        code: AuthoritativeApplicationErrorCode.invalidProposal,
        message: 'Proposal reconciliationId and fingerprint cannot be empty',
        appliedAt: effectiveAppliedAt,
      );
    }

    if (proposal.overallDecision == ReconciliationDecision.rejected ||
        proposal.overallDecision == ReconciliationDecision.invalid) {
      return _buildErrorResult(
        proposal: proposal,
        previousFingerprint: 'none',
        resultingFingerprint: 'none',
        decision: AuthoritativeApplicationDecision.rejected,
        code: AuthoritativeApplicationErrorCode.invalidProposal,
        message:
            'Cannot apply rejected or invalid reconciliation proposal (${proposal.overallDecision.name})',
        appliedAt: effectiveAppliedAt,
      );
    }

    // -------------------------------------------------------------------------
    // 2. Authoritative State Loading & Identity Verification
    // -------------------------------------------------------------------------
    final state = currentState ??
        AuthoritativeLearnerState.fromRepository(
          repository: _progressRepository,
          learnerId: proposal.learnerId,
          examId: proposal.examId,
          lastUpdatedAt: effectiveAppliedAt,
        );

    if (state.learnerId != proposal.learnerId) {
      return _buildErrorResult(
        proposal: proposal,
        previousFingerprint: state.stateFingerprint,
        resultingFingerprint: state.stateFingerprint,
        decision: AuthoritativeApplicationDecision.rejected,
        code: AuthoritativeApplicationErrorCode.learnerMismatch,
        message:
            'Learner mismatch: state learner "${state.learnerId}" != proposal learner "${proposal.learnerId}"',
        appliedAt: effectiveAppliedAt,
      );
    }

    if (state.examId != proposal.examId) {
      return _buildErrorResult(
        proposal: proposal,
        previousFingerprint: state.stateFingerprint,
        resultingFingerprint: state.stateFingerprint,
        decision: AuthoritativeApplicationDecision.rejected,
        code: AuthoritativeApplicationErrorCode.examMismatch,
        message:
            'Exam mismatch: state exam "${state.examId}" != proposal exam "${proposal.examId}"',
        appliedAt: effectiveAppliedAt,
      );
    }

    // -------------------------------------------------------------------------
    // 3. Idempotency & Duplicate Detection
    // -------------------------------------------------------------------------
    final sessionId = proposal.provenance.sessionId;
    final isAlreadyProcessed = state.hasProcessedSession(sessionId) ||
        _progressRepository.isSessionProcessed(proposal.learnerId, sessionId);

    if (isAlreadyProcessed) {
      final opId = AuthoritativeApplicationResult.computeOperationId(
        learnerId: proposal.learnerId,
        examId: proposal.examId,
        reconciliationId: proposal.reconciliationId,
        proposalFingerprint: proposal.fingerprint,
        previousStateFingerprint: proposal.baseStateFingerprint,
      );

      return AuthoritativeApplicationResult(
        operationId: opId,
        decision: AuthoritativeApplicationDecision.alreadyApplied,
        learnerId: proposal.learnerId,
        examId: proposal.examId,
        proposalFingerprint: proposal.fingerprint,
        previousStateFingerprint: state.stateFingerprint,
        resultingStateFingerprint: state.stateFingerprint,
        appliedChangesCount: 0,
        isDuplicate: true,
        isSuccess: true,
        appliedAt: effectiveAppliedAt,
        provenance: proposal.provenance,
        resultingState: state,
      );
    }

    // -------------------------------------------------------------------------
    // 4. Optimistic Concurrency Protection (F_expected == F_actual)
    // -------------------------------------------------------------------------
    if (proposal.baseStateFingerprint != state.stateFingerprint) {
      return _buildErrorResult(
        proposal: proposal,
        previousFingerprint: state.stateFingerprint,
        resultingFingerprint: state.stateFingerprint,
        decision: AuthoritativeApplicationDecision.stale,
        code: AuthoritativeApplicationErrorCode.fingerprintMismatch,
        message:
            'Optimistic concurrency violation: state fingerprint (${state.stateFingerprint}) does not match expected base fingerprint (${proposal.baseStateFingerprint})',
        appliedAt: effectiveAppliedAt,
        details: {
          'expectedBaseStateFingerprint': proposal.baseStateFingerprint,
          'actualStateFingerprint': state.stateFingerprint,
        },
      );
    }

    // -------------------------------------------------------------------------
    // 5. No-Op Application (Zero State Changes)
    // -------------------------------------------------------------------------
    if (!proposal.hasStateChanges) {
      // Ensure all prior sessions from currentState and new session are recorded
      for (final s in state.processedSessionIds) {
        _progressRepository.markSessionProcessed(proposal.learnerId, s);
      }
      _progressRepository.markSessionProcessed(proposal.learnerId, sessionId);

      final reloadedState = AuthoritativeLearnerState.fromRepository(
        repository: _progressRepository,
        learnerId: proposal.learnerId,
        examId: proposal.examId,
        lastUpdatedAt: effectiveAppliedAt,
      );

      final opId = AuthoritativeApplicationResult.computeOperationId(
        learnerId: proposal.learnerId,
        examId: proposal.examId,
        reconciliationId: proposal.reconciliationId,
        proposalFingerprint: proposal.fingerprint,
        previousStateFingerprint: proposal.baseStateFingerprint,
      );

      return AuthoritativeApplicationResult(
        operationId: opId,
        decision: AuthoritativeApplicationDecision.noOp,
        learnerId: proposal.learnerId,
        examId: proposal.examId,
        proposalFingerprint: proposal.fingerprint,
        previousStateFingerprint: state.stateFingerprint,
        resultingStateFingerprint: reloadedState.stateFingerprint,
        appliedChangesCount: 0,
        isDuplicate: false,
        isSuccess: true,
        appliedAt: effectiveAppliedAt,
        provenance: proposal.provenance,
        resultingState: reloadedState,
      );
    }

    // -------------------------------------------------------------------------
    // 6. Transactional Persistence via P19 Boundary
    // -------------------------------------------------------------------------
    final progressToPersist = proposal.reconciledProgress.values.toList()
      ..sort((a, b) => a.objectiveId.compareTo(b.objectiveId));

    try {
      // Ensure prior sessions from currentState are preserved
      for (final s in state.processedSessionIds) {
        _progressRepository.markSessionProcessed(proposal.learnerId, s);
      }

      _progressRepository.applyAtomicBatch(
        learnerId: proposal.learnerId,
        sessionId: sessionId,
        progressList: progressToPersist,
      );
    } catch (e) {
      return _buildErrorResult(
        proposal: proposal,
        previousFingerprint: state.stateFingerprint,
        resultingFingerprint: state.stateFingerprint,
        decision: AuthoritativeApplicationDecision.failed,
        code: AuthoritativeApplicationErrorCode.persistenceFailure,
        message: 'Failed to atomically persist progress batch: $e',
        appliedAt: effectiveAppliedAt,
      );
    }

    // -------------------------------------------------------------------------
    // 7. Post-Write Verification
    // -------------------------------------------------------------------------
    final reloadedState = AuthoritativeLearnerState.fromRepository(
      repository: _progressRepository,
      learnerId: proposal.learnerId,
      examId: proposal.examId,
      lastUpdatedAt: effectiveAppliedAt,
    );

    // Verify all proposed progress records are accurately persisted
    for (final expected in progressToPersist) {
      final actual = reloadedState.getProgress(expected.objectiveId);
      if (actual == null ||
          actual.attemptCount != expected.attemptCount ||
          actual.correctCount != expected.correctCount ||
          actual.status != expected.status) {
        return _buildErrorResult(
          proposal: proposal,
          previousFingerprint: state.stateFingerprint,
          resultingFingerprint: reloadedState.stateFingerprint,
          decision: AuthoritativeApplicationDecision.failed,
          code: AuthoritativeApplicationErrorCode.verificationFailure,
          message:
              'Post-write verification failed for objective "${expected.objectiveId}": expected attempts=${expected.attemptCount}, actual=${actual?.attemptCount}',
          appliedAt: effectiveAppliedAt,
        );
      }
    }

    // Verify session is marked processed
    if (!reloadedState.hasProcessedSession(sessionId)) {
      return _buildErrorResult(
        proposal: proposal,
        previousFingerprint: state.stateFingerprint,
        resultingFingerprint: reloadedState.stateFingerprint,
        decision: AuthoritativeApplicationDecision.failed,
        code: AuthoritativeApplicationErrorCode.verificationFailure,
        message:
            'Post-write verification failed: session "$sessionId" was not marked processed in reloaded state',
        appliedAt: effectiveAppliedAt,
      );
    }

    // -------------------------------------------------------------------------
    // 8. Result Compilation
    // -------------------------------------------------------------------------
    final opId = AuthoritativeApplicationResult.computeOperationId(
      learnerId: proposal.learnerId,
      examId: proposal.examId,
      reconciliationId: proposal.reconciliationId,
      proposalFingerprint: proposal.fingerprint,
      previousStateFingerprint: state.stateFingerprint,
    );

    return AuthoritativeApplicationResult(
      operationId: opId,
      decision: AuthoritativeApplicationDecision.applied,
      learnerId: proposal.learnerId,
      examId: proposal.examId,
      proposalFingerprint: proposal.fingerprint,
      previousStateFingerprint: state.stateFingerprint,
      resultingStateFingerprint: reloadedState.stateFingerprint,
      appliedChangesCount: progressToPersist.length,
      isDuplicate: false,
      isSuccess: true,
      appliedAt: effectiveAppliedAt,
      provenance: proposal.provenance,
      resultingState: reloadedState,
    );
  }

  AuthoritativeApplicationResult _buildErrorResult({
    required ReconciledLearningStateProposal proposal,
    required String previousFingerprint,
    required String resultingFingerprint,
    required AuthoritativeApplicationDecision decision,
    required AuthoritativeApplicationErrorCode code,
    required String message,
    required DateTime appliedAt,
    Map<String, dynamic>? details,
  }) {
    final opId = AuthoritativeApplicationResult.computeOperationId(
      learnerId: proposal.learnerId.isEmpty ? 'unknown' : proposal.learnerId,
      examId: proposal.examId.isEmpty ? 'unknown' : proposal.examId,
      reconciliationId: proposal.reconciliationId.isEmpty
          ? 'unknown'
          : proposal.reconciliationId,
      proposalFingerprint:
          proposal.fingerprint.isEmpty ? 'unknown' : proposal.fingerprint,
      previousStateFingerprint: previousFingerprint,
    );

    return AuthoritativeApplicationResult(
      operationId: opId,
      decision: decision,
      learnerId: proposal.learnerId,
      examId: proposal.examId,
      proposalFingerprint:
          proposal.fingerprint.isEmpty ? 'none' : proposal.fingerprint,
      previousStateFingerprint: previousFingerprint,
      resultingStateFingerprint: resultingFingerprint,
      appliedChangesCount: 0,
      isDuplicate: false,
      isSuccess: false,
      appliedAt: appliedAt,
      provenance: proposal.provenance,
      error: AuthoritativeApplicationError(
        code: code,
        message: message,
        details: details,
      ),
    );
  }
}
