/// Reconciliation Decision and Conflict Models (TITAN-KO-038.0 P38).
///
/// Encapsulates granular, explainable decision records, conflict resolutions,
/// and provenance references produced during learning state reconciliation.
///
/// Invariants:
/// - Pure descriptive decisions; zero cognitive/scientific predictions.
/// - Immutable domain models and deeply unmodifiable collections.
/// - Strict provenance tracking and explainable resolution rationale.
library;

import 'package:meta/meta.dart';

import 'learner_objective_status.dart';
import 'learning_evidence_signal.dart';

/// Categorical decision outcome for a reconciled state element.
enum ReconciliationDecision {
  /// Existing state and proposed update are identical or require no delta.
  unchanged,

  /// Proposal introduces valid new evidence absent from existing state.
  accepted,

  /// Existing state and proposal merged compatibly (additive progress).
  merged,

  /// Incompatible state detected and resolved deterministically via authoritative precedence.
  conflict,

  /// Proposal is stale relative to authoritative state last-updated timestamp or version.
  stale,

  /// Session evidence was already processed into authoritative state (idempotent no-op).
  duplicate,

  /// Proposal or state input failed semantic validation.
  invalid,

  /// Proposal was explicitly rejected due to unresolvable constraint.
  rejected;

  /// Whether this decision resulted in an active state mutation (accepted, merged, or conflict resolution).
  bool get hasStateChange =>
      this == ReconciliationDecision.accepted ||
      this == ReconciliationDecision.merged ||
      this == ReconciliationDecision.conflict;

  /// Whether the reconciliation was successful and safe.
  bool get isSuccessful =>
      this != ReconciliationDecision.invalid &&
      this != ReconciliationDecision.rejected &&
      this != ReconciliationDecision.stale;
}

/// Traceable provenance linking a reconciled proposal back to its input origins.
@immutable
class ReconciliationProvenance {
  /// Source proposal identifier from P37.
  final String proposalId;

  /// Practice session identifier from P34/P35/P36.
  final String sessionId;

  /// Cryptographic SHA-256 fingerprint of the source P37 proposal.
  final String sourceProposalFingerprint;

  /// Cryptographic SHA-256 fingerprint of the authoritative base state.
  final String baseStateFingerprint;

  /// Authoritative timestamp when reconciliation occurred.
  final DateTime reconciledAt;

  const ReconciliationProvenance({
    required this.proposalId,
    required this.sessionId,
    required this.sourceProposalFingerprint,
    required this.baseStateFingerprint,
    required this.reconciledAt,
  });

  Map<String, dynamic> toJson() => {
        'proposalId': proposalId,
        'sessionId': sessionId,
        'sourceProposalFingerprint': sourceProposalFingerprint,
        'baseStateFingerprint': baseStateFingerprint,
        'reconciledAt': reconciledAt.toUtc().toIso8601String(),
      };

  factory ReconciliationProvenance.fromJson(Map<String, dynamic> json) =>
      ReconciliationProvenance(
        proposalId: json['proposalId'] as String? ?? '',
        sessionId: json['sessionId'] as String? ?? '',
        sourceProposalFingerprint:
            json['sourceProposalFingerprint'] as String? ?? '',
        baseStateFingerprint: json['baseStateFingerprint'] as String? ?? '',
        reconciledAt: DateTime.parse(json['reconciledAt'] as String).toUtc(),
      );
}

/// Structured record describing a detected reconciliation conflict and its resolution.
@immutable
class ReconciliationConflict {
  /// Target dimension of the conflict (e.g. 'objective', 'question', 'topic', 'learner', 'exam').
  final String dimension;

  /// Target entity identifier (e.g. objectiveId or questionId).
  final String identifier;

  /// Category or type of conflict detected.
  final String conflictType;

  /// Value in the authoritative existing state.
  final dynamic authoritativeValue;

  /// Value in the proposed transient update.
  final dynamic proposedValue;

  /// Value selected / computed for the reconciled proposal.
  final dynamic resolvedValue;

  /// Deterministic explanation justifying the conflict resolution rule.
  final String resolutionReason;

  const ReconciliationConflict({
    required this.dimension,
    required this.identifier,
    required this.conflictType,
    this.authoritativeValue,
    this.proposedValue,
    this.resolvedValue,
    required this.resolutionReason,
  });

  Map<String, dynamic> toJson() => {
        'dimension': dimension,
        'identifier': identifier,
        'conflictType': conflictType,
        if (authoritativeValue != null)
          'authoritativeValue': authoritativeValue.toString(),
        if (proposedValue != null) 'proposedValue': proposedValue.toString(),
        if (resolvedValue != null) 'resolvedValue': resolvedValue.toString(),
        'resolutionReason': resolutionReason,
      };

  factory ReconciliationConflict.fromJson(Map<String, dynamic> json) =>
      ReconciliationConflict(
        dimension: json['dimension'] as String? ?? '',
        identifier: json['identifier'] as String? ?? '',
        conflictType: json['conflictType'] as String? ?? '',
        authoritativeValue: json['authoritativeValue'],
        proposedValue: json['proposedValue'],
        resolvedValue: json['resolvedValue'],
        resolutionReason: json['resolutionReason'] as String? ?? '',
      );

  @override
  String toString() =>
      'ReconciliationConflict($dimension:$identifier, type: $conflictType, reason: "$resolutionReason")';
}

/// Granular decision record for a single question evidence signal.
@immutable
class QuestionReconciliationDecision {
  /// Canonical question ID.
  final String questionId;

  /// Reconciled decision for this question.
  final ReconciliationDecision decision;

  /// Action proposed by P37 for this question.
  final ProposedLearningAction proposedAction;

  /// Human-readable explanation of the decision.
  final String explanation;

  const QuestionReconciliationDecision({
    required this.questionId,
    required this.decision,
    required this.proposedAction,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'decision': decision.name,
        'proposedAction': proposedAction.name,
        'explanation': explanation,
      };

  factory QuestionReconciliationDecision.fromJson(Map<String, dynamic> json) =>
      QuestionReconciliationDecision(
        questionId: json['questionId'] as String? ?? '',
        decision: ReconciliationDecision.values.firstWhere(
          (d) => d.name == json['decision'],
          orElse: () => ReconciliationDecision.unchanged,
        ),
        proposedAction: ProposedLearningAction.values.firstWhere(
          (a) => a.name == json['proposedAction'],
          orElse: () => ProposedLearningAction.noAction,
        ),
        explanation: json['explanation'] as String? ?? '',
      );
}

/// Granular decision record for an objective progress reconciliation.
@immutable
class ObjectiveReconciliationDecision {
  /// Canonical learning objective ID.
  final String objectiveId;

  /// Reconciled decision for this objective.
  final ReconciliationDecision decision;

  /// Attempt count prior to reconciliation.
  final int priorAttempts;

  /// New attempt count contributed by the proposal.
  final int newAttempts;

  /// Resulting attempt count in reconciled proposal.
  final int reconciledAttempts;

  /// Objective achievement status prior to reconciliation.
  final LearnerObjectiveStatus priorStatus;

  /// Resulting objective achievement status in reconciled proposal.
  final LearnerObjectiveStatus reconciledStatus;

  /// Human-readable explanation of the decision.
  final String explanation;

  const ObjectiveReconciliationDecision({
    required this.objectiveId,
    required this.decision,
    required this.priorAttempts,
    required this.newAttempts,
    required this.reconciledAttempts,
    required this.priorStatus,
    required this.reconciledStatus,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'objectiveId': objectiveId,
        'decision': decision.name,
        'priorAttempts': priorAttempts,
        'newAttempts': newAttempts,
        'reconciledAttempts': reconciledAttempts,
        'priorStatus': priorStatus.name,
        'reconciledStatus': reconciledStatus.name,
        'explanation': explanation,
      };

  factory ObjectiveReconciliationDecision.fromJson(Map<String, dynamic> json) =>
      ObjectiveReconciliationDecision(
        objectiveId: json['objectiveId'] as String? ?? '',
        decision: ReconciliationDecision.values.firstWhere(
          (d) => d.name == json['decision'],
          orElse: () => ReconciliationDecision.unchanged,
        ),
        priorAttempts: json['priorAttempts'] as int? ?? 0,
        newAttempts: json['newAttempts'] as int? ?? 0,
        reconciledAttempts: json['reconciledAttempts'] as int? ?? 0,
        priorStatus: LearnerObjectiveStatus.values.firstWhere(
          (s) => s.name == json['priorStatus'],
          orElse: () => LearnerObjectiveStatus.notStarted,
        ),
        reconciledStatus: LearnerObjectiveStatus.values.firstWhere(
          (s) => s.name == json['reconciledStatus'],
          orElse: () => LearnerObjectiveStatus.notStarted,
        ),
        explanation: json['explanation'] as String? ?? '',
      );
}

/// Granular decision record for a topic-level signal reconciliation.
@immutable
class TopicReconciliationDecision {
  /// Syllabus topic name.
  final String topic;

  /// Reconciled decision for this topic.
  final ReconciliationDecision decision;

  /// Proposed learning action from P37.
  final ProposedLearningAction proposedAction;

  /// Human-readable explanation of the decision.
  final String explanation;

  const TopicReconciliationDecision({
    required this.topic,
    required this.decision,
    required this.proposedAction,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'decision': decision.name,
        'proposedAction': proposedAction.name,
        'explanation': explanation,
      };

  factory TopicReconciliationDecision.fromJson(Map<String, dynamic> json) =>
      TopicReconciliationDecision(
        topic: json['topic'] as String? ?? '',
        decision: ReconciliationDecision.values.firstWhere(
          (d) => d.name == json['decision'],
          orElse: () => ReconciliationDecision.unchanged,
        ),
        proposedAction: ProposedLearningAction.values.firstWhere(
          (a) => a.name == json['proposedAction'],
          orElse: () => ProposedLearningAction.noAction,
        ),
        explanation: json['explanation'] as String? ?? '',
      );
}
