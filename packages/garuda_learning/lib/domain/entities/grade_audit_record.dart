/// Grade Audit Trail Domain Entities (TITAN-KO-050.0 P50).
///
/// Production immutable audit event records tracking all grade publishing,
/// disputes, overrides, and administrative modifications.
library;

import 'package:meta/meta.dart';

/// Explicit categorical action types for grade audit events.
enum GradeAuditAction {
  created,
  published,
  unpublished,
  disputed,
  disputeOpened,
  disputeUnderReview,
  disputeResolved,
  disputeRejected,
  overridden,
  gradePublished,
  gradeUnpublished,
  gradeOverridden,
  bulkPublished,
}

/// Immutable audit record capturing a single grade-changing or dispute event.
@immutable
class GradeAuditRecord {
  /// Unique canonical audit identifier.
  final String auditId;

  /// Nature of the action performed.
  final GradeAuditAction action;

  /// Actor who initiated the change (facultyId, learnerId, adminId).
  final String actorId;

  /// Role of the actor ('faculty', 'learner', 'admin', 'system').
  final String actorRole;

  /// Associated gradebook entry identifier.
  final String entryId;

  /// Associated institutional cohort identifier.
  final String cohortId;

  /// Associated formal assessment identifier.
  final String assessmentId;

  /// Target learner identifier.
  final String learnerId;

  /// Prior state snapshot before action execution.
  final Map<String, dynamic>? oldValue;

  /// Resulting state snapshot after action execution.
  final Map<String, dynamic>? newValue;

  /// Optional justification or explanation.
  final String? reason;

  /// UTC execution timestamp.
  final DateTime timestamp;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  GradeAuditRecord({
    required this.auditId,
    required this.action,
    required this.actorId,
    this.actorRole = 'faculty',
    required this.entryId,
    required this.cohortId,
    required this.assessmentId,
    required this.learnerId,
    this.oldValue,
    this.newValue,
    this.reason,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : timestamp = (timestamp ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (auditId.trim().isEmpty) {
      throw ArgumentError('auditId cannot be empty');
    }
    if (actorId.trim().isEmpty) {
      throw ArgumentError('actorId cannot be empty');
    }
    if (entryId.trim().isEmpty) {
      throw ArgumentError('entryId cannot be empty');
    }
    if (cohortId.trim().isEmpty) {
      throw ArgumentError('cohortId cannot be empty');
    }
    if (assessmentId.trim().isEmpty) {
      throw ArgumentError('assessmentId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
  }

  String get performedBy => actorId;
  Map<String, dynamic>? get oldValues => oldValue;
  Map<String, dynamic>? get newValues => newValue;

  Map<String, dynamic> toJson() => {
        'auditId': auditId,
        'action': action.name,
        'actorId': actorId,
        'actorRole': actorRole,
        'entryId': entryId,
        'cohortId': cohortId,
        'assessmentId': assessmentId,
        'learnerId': learnerId,
        if (oldValue != null) 'oldValue': oldValue,
        if (newValue != null) 'newValue': newValue,
        if (reason != null) 'reason': reason,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory GradeAuditRecord.fromJson(Map<String, dynamic> json) =>
      GradeAuditRecord(
        auditId: json['auditId'] as String? ?? '',
        action: GradeAuditAction.values.firstWhere(
          (a) => a.name == json['action'],
          orElse: () => GradeAuditAction.gradePublished,
        ),
        actorId: json['actorId'] as String? ?? '',
        actorRole: json['actorRole'] as String? ?? 'faculty',
        entryId: json['entryId'] as String? ?? '',
        cohortId: json['cohortId'] as String? ?? '',
        assessmentId: json['assessmentId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        oldValue: json['oldValue'] as Map<String, dynamic>?,
        newValue: json['newValue'] as Map<String, dynamic>?,
        reason: json['reason'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : null,
        metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      );

  @override
  String toString() =>
      'GradeAuditRecord(id: $auditId, action: ${action.name}, by: $actorId, entry: $entryId, at: ${timestamp.toIso8601String()})';
}
