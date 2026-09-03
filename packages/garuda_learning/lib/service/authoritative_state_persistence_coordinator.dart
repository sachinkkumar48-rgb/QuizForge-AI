/// Authoritative State Persistence Coordinator (TITAN-KO-039.0 P39).
///
/// Coordinates end-to-end integration between P39 persistence/recovery and
/// P38 [AdaptiveLearningStateReconciler].
library;

import '../domain/entities/authoritative_learner_state.dart';
import '../domain/entities/authoritative_persistence_error.dart';
import '../domain/entities/learning_state_update_proposal.dart';
import '../domain/entities/persisted_authoritative_learner_state.dart';
import '../domain/entities/reconciled_learning_state_proposal.dart';
import '../domain/entities/reconciliation_decision.dart';
import '../repository/authoritative_learning_state_repository.dart';
import 'adaptive_learning_state_reconciler.dart';
import 'authoritative_learning_state_recovery_service.dart';

/// Result of an integrated reconcile-and-persist operation.
class AuthoritativePersistenceResult {
  final bool isSuccess;
  final bool isDuplicate;
  final String message;
  final AuthoritativeLearnerState previousState;
  final AuthoritativeLearnerState? updatedState;
  final ReconciledLearningStateProposal? proposal;
  final AuthoritativePersistenceException? error;

  const AuthoritativePersistenceResult({
    required this.isSuccess,
    this.isDuplicate = false,
    required this.message,
    required this.previousState,
    this.updatedState,
    this.proposal,
    this.error,
  });

  factory AuthoritativePersistenceResult.success({
    required AuthoritativeLearnerState previousState,
    required AuthoritativeLearnerState updatedState,
    required ReconciledLearningStateProposal proposal,
    required String message,
  }) {
    return AuthoritativePersistenceResult(
      isSuccess: true,
      message: message,
      previousState: previousState,
      updatedState: updatedState,
      proposal: proposal,
    );
  }

  factory AuthoritativePersistenceResult.duplicate({
    required AuthoritativeLearnerState state,
    required String message,
  }) {
    return AuthoritativePersistenceResult(
      isSuccess: true,
      isDuplicate: true,
      message: message,
      previousState: state,
      updatedState: state,
    );
  }

  factory AuthoritativePersistenceResult.rejected({
    required AuthoritativeLearnerState state,
    required ReconciledLearningStateProposal proposal,
    required String message,
  }) {
    return AuthoritativePersistenceResult(
      isSuccess: false,
      message: message,
      previousState: state,
      updatedState: state,
      proposal: proposal,
    );
  }

  factory AuthoritativePersistenceResult.failure({
    required AuthoritativeLearnerState state,
    required AuthoritativePersistenceException error,
  }) {
    return AuthoritativePersistenceResult(
      isSuccess: false,
      message: error.message,
      previousState: state,
      updatedState: state,
      error: error,
    );
  }
}

/// Bridges persistence, recovery, and P38 reconciliation.
class AuthoritativeStatePersistenceCoordinator {
  final AuthoritativeLearningStateRecoveryService _recoveryService;
  final AuthoritativeLearningStateRepository _repository;
  final AdaptiveLearningStateReconciler _reconciler;

  const AuthoritativeStatePersistenceCoordinator({
    required AuthoritativeLearningStateRecoveryService recoveryService,
    required AuthoritativeLearningStateRepository repository,
    AdaptiveLearningStateReconciler reconciler =
        const AdaptiveLearningStateReconciler(),
  })  : _recoveryService = recoveryService,
        _repository = repository,
        _reconciler = reconciler;

  AuthoritativeLearningStateRecoveryService get recoveryService =>
      _recoveryService;
  AuthoritativeLearningStateRepository get repository => _repository;
  AdaptiveLearningStateReconciler get reconciler => _reconciler;

  /// Loads or initializes authoritative learner state for [learnerId] and [examId].
  Future<AuthoritativeLearnerState> loadOrInitialize({
    required String learnerId,
    required String examId,
    required DateTime timestamp,
  }) async {
    final recoveryResult = await _recoveryService.recover(
      learnerId: learnerId,
      examId: examId,
      requestedAt: timestamp,
      persistInitialIfAbsent: false,
    );

    if (!recoveryResult.isSuccess || recoveryResult.state == null) {
      throw recoveryResult.error ??
          AuthoritativePersistenceException(
            code: AuthoritativePersistenceErrorCode.notFound,
            message: 'Failed to recover or initialize state',
          );
    }

    return recoveryResult.state!;
  }

  /// Applies an already-reconciled [reconciledProposal] against [baseState]
  /// and atomically persists the resulting state with monotonic revision increment.
  Future<AuthoritativePersistenceResult> applyReconciledProposal({
    required AuthoritativeLearnerState baseState,
    required ReconciledLearningStateProposal reconciledProposal,
    required DateTime timestamp,
  }) async {
    final effectiveDate = timestamp.toUtc();

    // 1. Tenant and identity validation
    if (reconciledProposal.learnerId != baseState.learnerId) {
      return AuthoritativePersistenceResult.failure(
        state: baseState,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Learner mismatch: baseState "${baseState.learnerId}" != proposal "${reconciledProposal.learnerId}"',
        ),
      );
    }
    if (reconciledProposal.examId != baseState.examId) {
      return AuthoritativePersistenceResult.failure(
        state: baseState,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Exam mismatch: baseState "${baseState.examId}" != proposal "${reconciledProposal.examId}"',
        ),
      );
    }

    // 2. Duplicate session detection
    final sessionId = reconciledProposal.provenance.sessionId;
    if (baseState.hasProcessedSession(sessionId)) {
      return AuthoritativePersistenceResult.duplicate(
        state: baseState,
        message: 'Session "$sessionId" already incorporated',
      );
    }

    // 3. Optimistic concurrency check
    if (reconciledProposal.baseStateFingerprint != baseState.stateFingerprint) {
      return AuthoritativePersistenceResult.failure(
        state: baseState,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Fingerprint mismatch: proposal base (${reconciledProposal.baseStateFingerprint}) != current (${baseState.stateFingerprint})',
        ),
      );
    }

    // 4. Reject invalid or rejected proposals
    if (reconciledProposal.overallDecision == ReconciliationDecision.rejected ||
        reconciledProposal.overallDecision == ReconciliationDecision.invalid) {
      return AuthoritativePersistenceResult.rejected(
        state: baseState,
        proposal: reconciledProposal,
        message:
            'Proposal rejected by P38 reconciler: ${reconciledProposal.overallDecision.name}',
      );
    }

    // 5. Compute updated authoritative state with revision increment
    final updatedProgressMap = Map<String, dynamic>.from(baseState.progressMap);
    for (final entry in reconciledProposal.reconciledProgress.entries) {
      updatedProgressMap[entry.key] = entry.value;
    }

    final updatedSessions = <String>{
      ...baseState.processedSessionIds,
      sessionId,
    };

    final nextRevision = baseState.revision + 1;
    final updatedState = AuthoritativeLearnerState(
      learnerId: baseState.learnerId,
      examId: baseState.examId,
      progressMap: updatedProgressMap.cast(),
      processedSessionIds: updatedSessions,
      lastUpdatedAt: effectiveDate,
      revision: nextRevision,
    );

    // 6. Atomically persist updated authoritative state
    final persisted = PersistedAuthoritativeLearnerState.fromAuthoritativeState(
      updatedState,
      revision: nextRevision,
    );

    try {
      await _repository.save(persisted);
    } on AuthoritativePersistenceException catch (e) {
      return AuthoritativePersistenceResult.failure(
        state: baseState,
        error: e,
      );
    }

    return AuthoritativePersistenceResult.success(
      previousState: baseState,
      updatedState: updatedState,
      proposal: reconciledProposal,
      message:
          'State reconciled and persisted successfully at rev $nextRevision',
    );
  }

  /// Reconciles a transient [proposal] against [baseState] using P38 rules,
  /// and atomically persists the resulting state with monotonic revision increment.
  Future<AuthoritativePersistenceResult> reconcileAndPersist({
    required AuthoritativeLearnerState baseState,
    required LearningStateUpdateProposal proposal,
    required DateTime timestamp,
  }) async {
    final effectiveDate = timestamp.toUtc();

    // 1. Tenant and identity validation
    final proposalLearner = proposal.learnerId ?? baseState.learnerId;
    if (proposalLearner != baseState.learnerId) {
      return AuthoritativePersistenceResult.failure(
        state: baseState,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Learner mismatch: baseState "${baseState.learnerId}" != proposal "$proposalLearner"',
        ),
      );
    }
    if (proposal.examId != baseState.examId) {
      return AuthoritativePersistenceResult.failure(
        state: baseState,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message:
              'Exam mismatch: baseState "${baseState.examId}" != proposal "${proposal.examId}"',
        ),
      );
    }

    // 2. Duplicate session detection (idempotent no-op)
    if (baseState.hasProcessedSession(proposal.sessionId)) {
      return AuthoritativePersistenceResult.duplicate(
        state: baseState,
        message: 'Session "${proposal.sessionId}" already incorporated',
      );
    }

    // 3. Delegate to P38 AdaptiveLearningStateReconciler
    final reconciliationResult = _reconciler.reconcile(
      authoritativeState: baseState,
      proposal: proposal,
      reconciledAt: effectiveDate,
    );

    if (reconciliationResult.isFailure) {
      final recError = reconciliationResult.error!;
      return AuthoritativePersistenceResult.failure(
        state: baseState,
        error: AuthoritativePersistenceException(
          code: AuthoritativePersistenceErrorCode.inconsistentState,
          message: recError.message,
          details: recError.toJson(),
        ),
      );
    }

    final reconciledProposal = reconciliationResult.valueOrThrow;

    // 4. Delegate to applyReconciledProposal
    return applyReconciledProposal(
      baseState: baseState,
      reconciledProposal: reconciledProposal,
      timestamp: effectiveDate,
    );
  }
}
