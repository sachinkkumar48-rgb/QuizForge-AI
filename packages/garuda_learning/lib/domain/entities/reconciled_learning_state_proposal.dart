/// Reconciled Learning State Proposal Domain Entity (TITAN-KO-038.0 P38).
///
/// Encapsulates the immutable, deterministic proposal representing the reconciled
/// learning state, explainable granular decisions, conflict resolution audit logs,
/// and provenance references after reconciling an authoritative state with a P37 proposal.
///
/// Invariants:
/// - Pure proposal formulation; zero direct database writes or repository mutations.
/// - Zero DateTime.now() drift; caller-supplied timestamps only.
/// - Deeply immutable domain models and unmodifiable collections.
/// - Strict multi-exam and learner isolation.
/// - Deterministic canonical SHA-256 fingerprinting.
library;

import 'dart:collection';

import 'package:meta/meta.dart';

import 'learner_progress.dart';
import 'reconciliation_decision.dart';

/// Immutable, deterministic proposal representing reconciled learning state.
@immutable
class ReconciledLearningStateProposal {
  /// Deterministic reconciliation identifier.
  final String reconciliationId;

  /// Target learner identifier.
  final String learnerId;

  /// Target examination identifier (e.g. 'upsc', 'bpsc', 'ssc').
  final String examId;

  /// Cryptographic SHA-256 fingerprint of the authoritative base state.
  final String baseStateFingerprint;

  /// Cryptographic SHA-256 fingerprint of the source P37 proposal.
  final String sourceProposalFingerprint;

  /// Authoritative timestamp when reconciliation occurred (caller-supplied).
  final DateTime reconciledAt;

  /// Overall macro decision outcome across the entire proposal.
  final ReconciliationDecision overallDecision;

  /// Reconciled progress records mapped by learning objective ID (keys sorted deterministically).
  final Map<String, LearnerProgress> reconciledProgress;

  /// Cumulative set of processed session IDs including the reconciled session.
  final Set<String> processedSessionIds;

  /// Granular reconciliation decisions for individual question evidence signals.
  final List<QuestionReconciliationDecision> questionDecisions;

  /// Granular reconciliation decisions for learning objectives (keys sorted deterministically).
  final Map<String, ObjectiveReconciliationDecision> objectiveDecisions;

  /// Granular reconciliation decisions for syllabus topics (keys sorted deterministically).
  final Map<String, TopicReconciliationDecision> topicDecisions;

  /// Audit log of detected conflicts and their deterministic resolution reasons.
  final List<ReconciliationConflict> conflicts;

  /// Detailed provenance metadata linking back to source session and proposal.
  final ReconciliationProvenance provenance;

  /// Deterministic SHA-256 fingerprint identifying this exact reconciled proposal.
  final String fingerprint;

  ReconciledLearningStateProposal({
    required this.reconciliationId,
    required String learnerId,
    required String examId,
    required this.baseStateFingerprint,
    required this.sourceProposalFingerprint,
    required this.reconciledAt,
    required this.overallDecision,
    required Map<String, LearnerProgress> reconciledProgress,
    required Set<String> processedSessionIds,
    required List<QuestionReconciliationDecision> questionDecisions,
    required Map<String, ObjectiveReconciliationDecision> objectiveDecisions,
    required Map<String, TopicReconciliationDecision> topicDecisions,
    required List<ReconciliationConflict> conflicts,
    required this.provenance,
    required this.fingerprint,
  })  : learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        reconciledProgress = Map<String, LearnerProgress>.unmodifiable(
          reconciledProgress is SplayTreeMap<String, LearnerProgress>
              ? reconciledProgress
              : SplayTreeMap<String, LearnerProgress>.from(reconciledProgress),
        ),
        processedSessionIds = Set<String>.unmodifiable(
          processedSessionIds is SplayTreeSet<String>
              ? processedSessionIds
              : SplayTreeSet<String>.from(processedSessionIds),
        ),
        questionDecisions = List<QuestionReconciliationDecision>.unmodifiable(
            questionDecisions),
        objectiveDecisions =
            Map<String, ObjectiveReconciliationDecision>.unmodifiable(
          objectiveDecisions
                  is SplayTreeMap<String, ObjectiveReconciliationDecision>
              ? objectiveDecisions
              : SplayTreeMap<String, ObjectiveReconciliationDecision>.from(
                  objectiveDecisions),
        ),
        topicDecisions = Map<String, TopicReconciliationDecision>.unmodifiable(
          topicDecisions is SplayTreeMap<String, TopicReconciliationDecision>
              ? topicDecisions
              : SplayTreeMap<String, TopicReconciliationDecision>.from(
                  topicDecisions),
        ),
        conflicts = List<ReconciliationConflict>.unmodifiable(conflicts) {
    if (reconciliationId.trim().isEmpty) {
      throw ArgumentError('reconciliationId cannot be empty');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (baseStateFingerprint.trim().isEmpty) {
      throw ArgumentError('baseStateFingerprint cannot be empty');
    }
    if (sourceProposalFingerprint.trim().isEmpty) {
      throw ArgumentError('sourceProposalFingerprint cannot be empty');
    }
    if (fingerprint.trim().isEmpty) {
      throw ArgumentError('fingerprint cannot be empty');
    }
  }

  /// Whether any state changes (accepted, merged, or resolved conflicts) are proposed.
  bool get hasStateChanges => overallDecision.hasStateChange;

  /// Whether the reconciliation completed successfully.
  bool get isSuccessful => overallDecision.isSuccessful;

  Map<String, dynamic> toJson() => {
        'reconciliationId': reconciliationId,
        'learnerId': learnerId,
        'examId': examId,
        'baseStateFingerprint': baseStateFingerprint,
        'sourceProposalFingerprint': sourceProposalFingerprint,
        'reconciledAt': reconciledAt.toUtc().toIso8601String(),
        'overallDecision': overallDecision.name,
        'reconciledProgress':
            reconciledProgress.map((k, v) => MapEntry(k, v.toJson())),
        'processedSessionIds': processedSessionIds.toList(),
        'questionDecisions': questionDecisions.map((q) => q.toJson()).toList(),
        'objectiveDecisions':
            objectiveDecisions.map((k, v) => MapEntry(k, v.toJson())),
        'topicDecisions': topicDecisions.map((k, v) => MapEntry(k, v.toJson())),
        'conflicts': conflicts.map((c) => c.toJson()).toList(),
        'provenance': provenance.toJson(),
        'fingerprint': fingerprint,
      };

  factory ReconciledLearningStateProposal.fromJson(Map<String, dynamic> json) =>
      ReconciledLearningStateProposal(
        reconciliationId: json['reconciliationId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        examId: json['examId'] as String? ?? '',
        baseStateFingerprint: json['baseStateFingerprint'] as String? ?? '',
        sourceProposalFingerprint:
            json['sourceProposalFingerprint'] as String? ?? '',
        reconciledAt: DateTime.parse(json['reconciledAt'] as String).toUtc(),
        overallDecision: ReconciliationDecision.values.firstWhere(
          (d) => d.name == json['overallDecision'],
          orElse: () => ReconciliationDecision.unchanged,
        ),
        reconciledProgress:
            (json['reconciledProgress'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(
                    k, LearnerProgress.fromJson(v as Map<String, dynamic>))),
        processedSessionIds:
            Set<String>.from(json['processedSessionIds'] as List? ?? const []),
        questionDecisions: (json['questionDecisions'] as List? ?? const [])
            .map((e) => QuestionReconciliationDecision.fromJson(
                e as Map<String, dynamic>))
            .toList(),
        objectiveDecisions:
            (json['objectiveDecisions'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(
                    k,
                    ObjectiveReconciliationDecision.fromJson(
                        v as Map<String, dynamic>))),
        topicDecisions:
            (json['topicDecisions'] as Map<String, dynamic>? ?? const {}).map(
                (k, v) => MapEntry(
                    k,
                    TopicReconciliationDecision.fromJson(
                        v as Map<String, dynamic>))),
        conflicts: (json['conflicts'] as List? ?? const [])
            .map((e) =>
                ReconciliationConflict.fromJson(e as Map<String, dynamic>))
            .toList(),
        provenance: ReconciliationProvenance.fromJson(
            json['provenance'] as Map<String, dynamic>? ?? const {}),
        fingerprint: json['fingerprint'] as String? ?? '',
      );

  @override
  String toString() =>
      'ReconciledLearningStateProposal(id: $reconciliationId, learner: $learnerId, exam: $examId, decision: ${overallDecision.name}, progress: ${reconciledProgress.length}, conflicts: ${conflicts.length})';
}
