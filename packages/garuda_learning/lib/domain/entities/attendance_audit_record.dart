/// Attendance & Academic Engagement Audit Record Domain Entity (TITAN-KO-053.0 P53).
///
/// Production domain models representing immutable audit trail events
/// for session lifecycle changes, attendance recordings, finalized corrections,
/// and intervention signal resolutions.
library;

import 'package:meta/meta.dart';

/// Supported attendance audit events.
enum AttendanceAuditAction {
  sessionCreated,
  sessionOpened,
  sessionCancelled,
  attendanceRecorded,
  attendanceFinalized,
  attendanceCorrected,
  signalCreated,
  signalAcknowledged,
  signalResolved,
}

/// Immutable record capturing an attendance, session, or engagement audit event.
@immutable
class AttendanceAuditRecord {
  /// Unique audit record identifier.
  final String auditId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Lifecycle action performed.
  final AttendanceAuditAction action;

  /// Identifier of the actor executing the action (facultyId, adminId, system).
  final String actorId;

  /// Role of the actor ('faculty', 'admin', 'system', 'learner').
  final String actorRole;

  /// Associated session identifier where applicable.
  final String? sessionId;

  /// Associated course identifier.
  final String courseId;

  /// Associated cohort identifier where applicable.
  final String? cohortId;

  /// Associated learner identifier where applicable.
  final String? learnerId;

  /// State prior to action where applicable.
  final String? previousState;

  /// State resulting from action where applicable.
  final String? newState;

  /// Justification or notes provided for the change.
  final String? reason;

  /// UTC timestamp when the action occurred.
  final DateTime timestamp;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  AttendanceAuditRecord({
    required this.auditId,
    this.tenantId = 'default_tenant',
    required this.action,
    required this.actorId,
    this.actorRole = 'faculty',
    this.sessionId,
    required this.courseId,
    this.cohortId,
    this.learnerId,
    this.previousState,
    this.newState,
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
    if (actorId.trim().isEmpty) {
      throw ArgumentError('actorId cannot be empty');
    }
    if (courseId.trim().isEmpty) {
      throw ArgumentError('courseId cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'auditId': auditId,
        'tenantId': tenantId,
        'action': action.name,
        'actorId': actorId,
        'actorRole': actorRole,
        if (sessionId != null) 'sessionId': sessionId,
        'courseId': courseId,
        if (cohortId != null) 'cohortId': cohortId,
        if (learnerId != null) 'learnerId': learnerId,
        if (previousState != null) 'previousState': previousState,
        if (newState != null) 'newState': newState,
        if (reason != null) 'reason': reason,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory AttendanceAuditRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceAuditRecord(
        auditId: json['auditId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        action: AttendanceAuditAction.values.firstWhere(
          (a) => a.name == json['action'],
          orElse: () => AttendanceAuditAction.attendanceRecorded,
        ),
        actorId: json['actorId'] as String? ?? '',
        actorRole: json['actorRole'] as String? ?? 'faculty',
        sessionId: json['sessionId'] as String?,
        courseId: json['courseId'] as String? ?? '',
        cohortId: json['cohortId'] as String?,
        learnerId: json['learnerId'] as String?,
        previousState: json['previousState'] as String?,
        newState: json['newState'] as String?,
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
      other is AttendanceAuditRecord &&
          auditId == other.auditId &&
          tenantId == other.tenantId;

  @override
  int get hashCode => Object.hash(auditId, tenantId);

  @override
  String toString() =>
      'AttendanceAuditRecord(id: $auditId, action: ${action.name}, course: $courseId, actor: $actorId)';
}
