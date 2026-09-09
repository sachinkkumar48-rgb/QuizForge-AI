/// Enrollment Audit Record Domain Entity (TITAN-KO-052.0 P52).
///
/// Production domain models representing immutable audit logs of all enrollment
/// lifecycle state transitions, administrative actions, and reason tracking.
library;

import 'package:meta/meta.dart';
import 'enrollment.dart';

/// Supported lifecycle audit actions.
enum EnrollmentAuditAction {
  created,
  activated,
  suspended,
  reactivated,
  withdrawn,
  cancelled,
  completed,
  bulkEnrolled,
}

/// Immutable record capturing an enrollment state transition or lifecycle action.
@immutable
class EnrollmentAuditRecord {
  /// Unique audit record identifier.
  final String auditId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Associated enrollment identifier.
  final String enrollmentId;

  /// Associated learner identifier.
  final String learnerId;

  /// Associated course identifier.
  final String courseId;

  /// Associated cohort identifier where applicable.
  final String? cohortId;

  /// Specific lifecycle action performed.
  final EnrollmentAuditAction action;

  /// Identifier of the actor executing the action (e.g. facultyId, adminId).
  final String actorId;

  /// Role of the actor (e.g. 'faculty', 'admin', 'learner', 'system').
  final String actorRole;

  /// Enrollment status prior to this action.
  final EnrollmentStatus? previousStatus;

  /// Resulting enrollment status following this action.
  final EnrollmentStatus? newStatus;

  /// Justification or notes provided for the transition.
  final String? reason;

  /// UTC timestamp when the action occurred.
  final DateTime timestamp;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  EnrollmentAuditRecord({
    required this.auditId,
    this.tenantId = 'default_tenant',
    required this.enrollmentId,
    required this.learnerId,
    required this.courseId,
    this.cohortId,
    required this.action,
    required this.actorId,
    this.actorRole = 'system',
    this.previousStatus,
    this.newStatus,
    this.reason,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  })  : timestamp = (timestamp ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (auditId.trim().isEmpty) {
      throw ArgumentError('auditId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (courseId.trim().isEmpty) {
      throw ArgumentError('courseId cannot be empty');
    }
    if (actorId.trim().isEmpty) {
      throw ArgumentError('actorId cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'auditId': auditId,
        'tenantId': tenantId,
        'enrollmentId': enrollmentId,
        'learnerId': learnerId,
        'courseId': courseId,
        if (cohortId != null) 'cohortId': cohortId,
        'action': action.name,
        'actorId': actorId,
        'actorRole': actorRole,
        if (previousStatus != null) 'previousStatus': previousStatus!.name,
        if (newStatus != null) 'newStatus': newStatus!.name,
        if (reason != null) 'reason': reason,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory EnrollmentAuditRecord.fromJson(Map<String, dynamic> json) =>
      EnrollmentAuditRecord(
        auditId: json['auditId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        enrollmentId: json['enrollmentId'] as String? ?? '',
        learnerId: json['learnerId'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        cohortId: json['cohortId'] as String?,
        action: EnrollmentAuditAction.values.firstWhere(
          (a) => a.name == json['action'],
          orElse: () => EnrollmentAuditAction.created,
        ),
        actorId: json['actorId'] as String? ?? '',
        actorRole: json['actorRole'] as String? ?? 'system',
        previousStatus: json['previousStatus'] != null
            ? EnrollmentStatus.values.firstWhere(
                (s) => s.name == json['previousStatus'],
                orElse: () => EnrollmentStatus.pending,
              )
            : null,
        newStatus: json['newStatus'] != null
            ? EnrollmentStatus.values.firstWhere(
                (s) => s.name == json['newStatus'],
                orElse: () => EnrollmentStatus.active,
              )
            : null,
        reason: json['reason'] as String?,
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : null,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnrollmentAuditRecord &&
          auditId == other.auditId &&
          tenantId == other.tenantId &&
          enrollmentId == other.enrollmentId;

  @override
  int get hashCode => Object.hash(auditId, tenantId, enrollmentId);

  @override
  String toString() =>
      'EnrollmentAuditRecord(id: $auditId, action: ${action.name}, learner: $learnerId, course: $courseId, actor: $actorId)';
}
