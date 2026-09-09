/// Credential Audit Trail Domain Entities (TITAN-KO-051.0 P51).
///
/// Production immutable audit event records tracking transcript issuance, reissuance,
/// voiding, certificate issuance, and certificate revocation.
library;

import 'package:meta/meta.dart';

/// Categorical actions for credential audit records.
enum CredentialAuditAction {
  transcriptIssued,
  transcriptReissued,
  transcriptVoided,
  certificateIssued,
  certificateRevoked,
}

/// Immutable audit record capturing a single credential lifecycle transition.
@immutable
class CredentialAuditRecord {
  /// Canonical audit identifier.
  final String auditId;

  /// Nature of the credential action.
  final CredentialAuditAction action;

  /// Actor who initiated the change (e.g. facultyId, adminId).
  final String actorId;

  /// Role of the actor ('faculty', 'admin', 'system').
  final String actorRole;

  /// Associated learner identifier.
  final String learnerId;

  /// Identifier of the affected transcript or certificate.
  final String targetId;

  /// Optional justification or administrative rationale.
  final String? reason;

  /// Prior state before action execution.
  final Map<String, dynamic>? oldValue;

  /// Resulting state after action execution.
  final Map<String, dynamic>? newValue;

  /// UTC execution timestamp.
  final DateTime timestamp;

  CredentialAuditRecord({
    required this.auditId,
    required this.action,
    required this.actorId,
    this.actorRole = 'faculty',
    required this.learnerId,
    required this.targetId,
    this.reason,
    this.oldValue,
    this.newValue,
    DateTime? timestamp,
  }) : timestamp = (timestamp ?? DateTime.now()).toUtc() {
    if (auditId.trim().isEmpty) {
      throw ArgumentError('auditId cannot be empty');
    }
    if (actorId.trim().isEmpty) {
      throw ArgumentError('actorId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (targetId.trim().isEmpty) {
      throw ArgumentError('targetId cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'auditId': auditId,
        'action': action.name,
        'actorId': actorId,
        'actorRole': actorRole,
        'learnerId': learnerId,
        'targetId': targetId,
        if (reason != null) 'reason': reason,
        if (oldValue != null) 'oldValue': oldValue,
        if (newValue != null) 'newValue': newValue,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CredentialAuditRecord.fromJson(Map<String, dynamic> json) =>
      CredentialAuditRecord(
        auditId: json['auditId'] as String? ?? '',
        action: CredentialAuditAction.values.firstWhere(
          (a) => a.name == json['action'],
          orElse: () => CredentialAuditAction.transcriptIssued,
        ),
        actorId: json['actorId'] as String? ?? '',
        actorRole: json['actorRole'] as String? ?? 'faculty',
        learnerId: json['learnerId'] as String? ?? '',
        targetId: json['targetId'] as String? ?? '',
        reason: json['reason'] as String?,
        oldValue: json['oldValue'] as Map<String, dynamic>?,
        newValue: json['newValue'] as Map<String, dynamic>?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : null,
      );
}
