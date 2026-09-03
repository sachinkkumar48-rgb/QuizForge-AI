/// Reconciliation Pipeline Result Domain Entity (TITAN-KO-039.0 P39).
///
/// Immutable domain outcome encapsulates the result of the adaptive
/// learning state reconciliation and persistence pipeline, exposing
/// explicit decisions, resulting revisions, audit trails, and typed errors.
library;

import 'package:meta/meta.dart';

import 'authoritative_learner_state.dart';
import 'authoritative_persistence_error.dart';
import 'reconciled_learning_state_proposal.dart';
import 'reconciliation_audit_trail.dart';
import 'reconciliation_decision.dart';
import 'reconciliation_error.dart';

/// Immutable result of executing the adaptive learning state reconciliation pipeline.
@immutable
class ReconciliationPipelineResult {
  /// Whether the pipeline successfully accepted, applied, or idempotently handled the input.
  final bool isSuccess;

  /// Whether the execution was recognized as an idempotent duplicate of an already-applied session.
  final bool isIdempotentReplay;

  /// Whether the execution detected a version or fingerprint concurrency conflict.
  final bool isConflict;

  /// High-level reconciliation decision produced by the pipeline.
  final ReconciliationDecision decision;

  /// The authoritative state supplied as the baseline for this execution.
  final AuthoritativeLearnerState baseState;

  /// The resulting authoritative learner state, or `null` if the pipeline failed or conflicted.
  final AuthoritativeLearnerState? resultingState;

  /// The intermediate P38 reconciled proposal, if formulated and reconciled.
  final ReconciledLearningStateProposal? reconciledProposal;

  /// Comprehensive cryptographic audit record documenting the execution.
  final ReconciliationAuditTrail auditTrail;

  /// Human-readable explanation of the pipeline outcome.
  final String message;

  /// Explicit typed persistence error, if a persistence or storage failure occurred.
  final AuthoritativePersistenceException? persistenceError;

  /// Explicit typed reconciliation error, if reconciliation was rejected.
  final ReconciliationError? reconciliationError;

  const ReconciliationPipelineResult({
    required this.isSuccess,
    this.isIdempotentReplay = false,
    this.isConflict = false,
    required this.decision,
    required this.baseState,
    this.resultingState,
    this.reconciledProposal,
    required this.auditTrail,
    required this.message,
    this.persistenceError,
    this.reconciliationError,
  });

  /// Base revision before reconciliation.
  int get previousRevision => baseState.revision;

  /// Resulting revision after reconciliation (equals base revision if no changes or failed).
  int get resultingRevision => resultingState?.revision ?? baseState.revision;

  /// Factory for successfully reconciled and persisted updates.
  factory ReconciliationPipelineResult.applied({
    required AuthoritativeLearnerState baseState,
    required AuthoritativeLearnerState resultingState,
    required ReconciledLearningStateProposal reconciledProposal,
    required ReconciliationAuditTrail auditTrail,
    required String message,
  }) {
    return ReconciliationPipelineResult(
      isSuccess: true,
      decision: reconciledProposal.overallDecision,
      baseState: baseState,
      resultingState: resultingState,
      reconciledProposal: reconciledProposal,
      auditTrail: auditTrail,
      message: message,
    );
  }

  /// Factory for idempotent replay of an already incorporated session.
  factory ReconciliationPipelineResult.idempotent({
    required AuthoritativeLearnerState baseState,
    required ReconciliationAuditTrail auditTrail,
    required String message,
    ReconciledLearningStateProposal? reconciledProposal,
  }) {
    return ReconciliationPipelineResult(
      isSuccess: true,
      isIdempotentReplay: true,
      decision: ReconciliationDecision.unchanged,
      baseState: baseState,
      resultingState: baseState,
      reconciledProposal: reconciledProposal,
      auditTrail: auditTrail,
      message: message,
    );
  }

  /// Factory for stale version or fingerprint concurrency conflicts.
  factory ReconciliationPipelineResult.conflict({
    required AuthoritativeLearnerState baseState,
    required ReconciliationAuditTrail auditTrail,
    required String message,
    AuthoritativePersistenceException? persistenceError,
    ReconciliationError? reconciliationError,
  }) {
    return ReconciliationPipelineResult(
      isSuccess: false,
      isConflict: true,
      decision: ReconciliationDecision.invalid,
      baseState: baseState,
      resultingState: baseState,
      auditTrail: auditTrail,
      message: message,
      persistenceError: persistenceError,
      reconciliationError: reconciliationError,
    );
  }

  /// Factory for rejected proposals (e.g. invalid evidence or P38 policy rejection).
  factory ReconciliationPipelineResult.rejected({
    required AuthoritativeLearnerState baseState,
    required ReconciledLearningStateProposal reconciledProposal,
    required ReconciliationAuditTrail auditTrail,
    required String message,
  }) {
    return ReconciliationPipelineResult(
      isSuccess: false,
      decision: reconciledProposal.overallDecision,
      baseState: baseState,
      resultingState: baseState,
      reconciledProposal: reconciledProposal,
      auditTrail: auditTrail,
      message: message,
    );
  }

  /// Factory for unexpected or infrastructure failures.
  factory ReconciliationPipelineResult.failure({
    required AuthoritativeLearnerState baseState,
    required ReconciliationAuditTrail auditTrail,
    required String message,
    AuthoritativePersistenceException? persistenceError,
    ReconciliationError? reconciliationError,
  }) {
    return ReconciliationPipelineResult(
      isSuccess: false,
      decision: ReconciliationDecision.invalid,
      baseState: baseState,
      resultingState: baseState,
      auditTrail: auditTrail,
      message: message,
      persistenceError: persistenceError,
      reconciliationError: reconciliationError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'isIdempotentReplay': isIdempotentReplay,
      'isConflict': isConflict,
      'decision': decision.name,
      'baseStateFingerprint': baseState.stateFingerprint,
      'resultingStateFingerprint': resultingState?.stateFingerprint,
      'previousRevision': previousRevision,
      'resultingRevision': resultingRevision,
      'message': message,
      'auditTrail': auditTrail.toJson(),
      if (reconciledProposal != null)
        'reconciledProposal': reconciledProposal!.toJson(),
      if (persistenceError != null)
        'persistenceError': {
          'code': persistenceError!.code.name,
          'message': persistenceError!.message,
        },
      if (reconciliationError != null)
        'reconciliationError': reconciliationError!.toJson(),
    };
  }

  @override
  String toString() =>
      'ReconciliationPipelineResult(success: $isSuccess, decision: ${decision.name}, rev: $previousRevision->$resultingRevision, idempotent: $isIdempotentReplay, conflict: $isConflict, msg: $message)';
}
