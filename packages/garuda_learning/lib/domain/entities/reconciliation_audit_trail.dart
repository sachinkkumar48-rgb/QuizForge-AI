/// Reconciliation Audit Trail Domain Entity (TITAN-KO-039.0 P39).
///
/// Immutable, deterministic, and auditable record capturing the complete
/// lineage, input states, decisions, objective transitions, and cryptographic
/// fingerprints of an adaptive learning state reconciliation pipeline execution.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'reconciliation_decision.dart';

/// Immutable audit record documenting a learning-state reconciliation execution.
@immutable
class ReconciliationAuditTrail {
  /// Unique identifier for this audit entry.
  final String auditId;

  /// Identifier of the learner.
  final String learnerId;

  /// Target examination identifier (e.g., 'upsc', 'bpsc').
  final String examId;

  /// Session identifier supplying practice evidence.
  final String sessionId;

  /// Proposal identifier, if formulated.
  final String? proposalId;

  /// P38 reconciliation identifier, if performed.
  final String? reconciliationId;

  /// Revision number of the base authoritative state before reconciliation.
  final int baseRevision;

  /// Revision number of the resulting authoritative state after reconciliation.
  final int resultingRevision;

  /// SHA-256 fingerprint of the base state.
  final String baseStateFingerprint;

  /// SHA-256 fingerprint of the resulting state.
  final String resultingStateFingerprint;

  /// Explicit reconciliation decision produced by the pipeline.
  final ReconciliationDecision decision;

  /// Indicates if this execution was an idempotent replay of an already-applied session.
  final bool isIdempotentReplay;

  /// Indicates if a stale version or fingerprint conflict was encountered.
  final bool isConflict;

  /// Unmodifiable list of learning objective IDs whose progress changed.
  final List<String> changedObjectiveIds;

  /// Count of objective progress records accepted/updated.
  final int acceptedCount;

  /// Count of objective updates rejected.
  final int rejectedCount;

  /// Structured audit notes or justifications for accepted/rejected decisions.
  final List<String> notes;

  /// Caller-supplied UTC timestamp when this audit record was generated.
  final DateTime recordedAt;

  /// Deterministic SHA-256 fingerprint of this audit record.
  final String auditFingerprint;

  ReconciliationAuditTrail({
    required String auditId,
    required String learnerId,
    required String examId,
    required String sessionId,
    this.proposalId,
    this.reconciliationId,
    required this.baseRevision,
    required this.resultingRevision,
    required String baseStateFingerprint,
    required String resultingStateFingerprint,
    required this.decision,
    this.isIdempotentReplay = false,
    this.isConflict = false,
    List<String>? changedObjectiveIds,
    this.acceptedCount = 0,
    this.rejectedCount = 0,
    List<String>? notes,
    required DateTime recordedAt,
    String? auditFingerprint,
  })  : auditId = auditId.trim(),
        learnerId = learnerId.trim(),
        examId = examId.trim().toLowerCase(),
        sessionId = sessionId.trim(),
        baseStateFingerprint = baseStateFingerprint.trim(),
        resultingStateFingerprint = resultingStateFingerprint.trim(),
        changedObjectiveIds = List<String>.unmodifiable(
          List<String>.from(changedObjectiveIds ?? const [])..sort(),
        ),
        notes = List<String>.unmodifiable(notes ?? const []),
        recordedAt = recordedAt.toUtc(),
        auditFingerprint =
            (auditFingerprint != null && auditFingerprint.trim().isNotEmpty)
                ? auditFingerprint.trim()
                : _computeAuditFingerprint(
                    auditId: auditId.trim(),
                    learnerId: learnerId.trim(),
                    examId: examId.trim().toLowerCase(),
                    sessionId: sessionId.trim(),
                    proposalId: proposalId?.trim(),
                    reconciliationId: reconciliationId?.trim(),
                    baseRevision: baseRevision,
                    resultingRevision: resultingRevision,
                    baseStateFingerprint: baseStateFingerprint.trim(),
                    resultingStateFingerprint: resultingStateFingerprint.trim(),
                    decision: decision,
                    isIdempotentReplay: isIdempotentReplay,
                    isConflict: isConflict,
                    changedObjectiveIds:
                        List<String>.from(changedObjectiveIds ?? const [])
                          ..sort(),
                    acceptedCount: acceptedCount,
                    rejectedCount: rejectedCount,
                    recordedAt: recordedAt.toUtc(),
                  ) {
    if (this.auditId.isEmpty) {
      throw ArgumentError('auditId cannot be empty');
    }
    if (this.learnerId.isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (this.examId.isEmpty) {
      throw ArgumentError('examId cannot be empty');
    }
    if (this.sessionId.isEmpty) {
      throw ArgumentError('sessionId cannot be empty');
    }
    if (baseRevision < 1) {
      throw ArgumentError('baseRevision must be >= 1');
    }
    if (resultingRevision < baseRevision) {
      throw ArgumentError(
        'resultingRevision ($resultingRevision) cannot be less than baseRevision ($baseRevision)',
      );
    }
    if (this.baseStateFingerprint.isEmpty) {
      throw ArgumentError('baseStateFingerprint cannot be empty');
    }
    if (this.resultingStateFingerprint.isEmpty) {
      throw ArgumentError('resultingStateFingerprint cannot be empty');
    }
    if (acceptedCount < 0 || rejectedCount < 0) {
      throw ArgumentError('acceptedCount and rejectedCount cannot be negative');
    }
  }

  static String _computeAuditFingerprint({
    required String auditId,
    required String learnerId,
    required String examId,
    required String sessionId,
    String? proposalId,
    String? reconciliationId,
    required int baseRevision,
    required int resultingRevision,
    required String baseStateFingerprint,
    required String resultingStateFingerprint,
    required ReconciliationDecision decision,
    required bool isIdempotentReplay,
    required bool isConflict,
    required List<String> changedObjectiveIds,
    required int acceptedCount,
    required int rejectedCount,
    required DateTime recordedAt,
  }) {
    final buffer = StringBuffer()
      ..write('$auditId|$learnerId|$examId|$sessionId|')
      ..write('${proposalId ?? ""}|${reconciliationId ?? ""}|')
      ..write('$baseRevision|$resultingRevision|')
      ..write('$baseStateFingerprint|$resultingStateFingerprint|')
      ..write('${decision.name}|$isIdempotentReplay|$isConflict|')
      ..write('${changedObjectiveIds.join(",")}|$acceptedCount|$rejectedCount|')
      ..write(recordedAt.toIso8601String());
    return sha256.convert(utf8.encode(buffer.toString())).toString();
  }

  Map<String, dynamic> toJson() {
    final map = SplayTreeMap<String, dynamic>();
    map['acceptedCount'] = acceptedCount;
    map['auditFingerprint'] = auditFingerprint;
    map['auditId'] = auditId;
    map['baseRevision'] = baseRevision;
    map['baseStateFingerprint'] = baseStateFingerprint;
    map['changedObjectiveIds'] = changedObjectiveIds;
    map['decision'] = decision.name;
    map['examId'] = examId;
    map['isConflict'] = isConflict;
    map['isIdempotentReplay'] = isIdempotentReplay;
    map['learnerId'] = learnerId;
    map['notes'] = notes;
    if (proposalId != null) map['proposalId'] = proposalId;
    if (reconciliationId != null) map['reconciliationId'] = reconciliationId;
    map['recordedAt'] = recordedAt.toIso8601String();
    map['rejectedCount'] = rejectedCount;
    map['resultingRevision'] = resultingRevision;
    map['resultingStateFingerprint'] = resultingStateFingerprint;
    map['sessionId'] = sessionId;
    return map;
  }

  String toCanonicalJson() => jsonEncode(toJson());

  factory ReconciliationAuditTrail.fromJson(Map<String, dynamic> json) {
    return ReconciliationAuditTrail(
      auditId: json['auditId'] as String,
      learnerId: json['learnerId'] as String,
      examId: json['examId'] as String,
      sessionId: json['sessionId'] as String,
      proposalId: json['proposalId'] as String?,
      reconciliationId: json['reconciliationId'] as String?,
      baseRevision: json['baseRevision'] as int,
      resultingRevision: json['resultingRevision'] as int,
      baseStateFingerprint: json['baseStateFingerprint'] as String,
      resultingStateFingerprint: json['resultingStateFingerprint'] as String,
      decision:
          ReconciliationDecision.values.byName(json['decision'] as String),
      isIdempotentReplay: json['isIdempotentReplay'] as bool? ?? false,
      isConflict: json['isConflict'] as bool? ?? false,
      changedObjectiveIds:
          (json['changedObjectiveIds'] as List?)?.cast<String>(),
      acceptedCount: json['acceptedCount'] as int? ?? 0,
      rejectedCount: json['rejectedCount'] as int? ?? 0,
      notes: (json['notes'] as List?)?.cast<String>(),
      recordedAt: DateTime.parse(json['recordedAt'] as String).toUtc(),
      auditFingerprint: json['auditFingerprint'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReconciliationAuditTrail &&
          runtimeType == other.runtimeType &&
          auditId == other.auditId &&
          auditFingerprint == other.auditFingerprint;

  @override
  int get hashCode => Object.hash(auditId, auditFingerprint);

  @override
  String toString() =>
      'ReconciliationAuditTrail(id: $auditId, learner: $learnerId, exam: $examId, session: $sessionId, decision: ${decision.name}, rev: $baseRevision->$resultingRevision, fp: ${auditFingerprint.substring(0, 8)}...)';
}
