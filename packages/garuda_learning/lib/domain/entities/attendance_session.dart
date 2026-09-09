/// Course Attendance Session Domain Entity (TITAN-KO-053.0 P53).
///
/// Production domain models representing course and class attendance sessions,
/// session lifecycle (SCHEDULED, OPEN, CLOSED, CANCELLED), and finalization boundaries.
library;

import 'package:meta/meta.dart';

/// Explicit lifecycle states for a course attendance session.
enum AttendanceSessionStatus {
  /// Session scheduled in advance; attendance not yet open.
  scheduled,

  /// Session actively in progress; attendance can be recorded.
  open,

  /// Session closed and attendance finalized; modifications require formal correction.
  closed,

  /// Session cancelled; excluded from attendance calculations.
  cancelled,
}

/// Lightweight course/class session model for institutional attendance tracking.
@immutable
class AttendanceSession {
  /// Unique canonical session identifier (e.g. 'sess_const_101_20261015_01').
  final String sessionId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Target course identifier.
  final String courseId;

  /// Target cohort identifier where applicable.
  final String? cohortId;

  /// Topic or title of the session (e.g. 'Lecture 1: Preamble & Constitutional Identity').
  final String title;

  /// Syllabus notes or agenda for the session.
  final String description;

  /// UTC scheduled date and time.
  final DateTime scheduledAt;

  /// Planned or actual duration in minutes.
  final int durationMinutes;

  /// Current lifecycle status.
  final AttendanceSessionStatus status;

  /// Faculty member or instructor identifier conducting the session.
  final String facultyId;

  /// UTC timestamp when attendance was locked/finalized.
  final DateTime? finalizedAt;

  /// Actor ID who finalized the session attendance.
  final String? finalizedBy;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last update timestamp.
  final DateTime updatedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  AttendanceSession({
    required this.sessionId,
    this.tenantId = 'default_tenant',
    required this.courseId,
    this.cohortId,
    required this.title,
    this.description = '',
    required this.scheduledAt,
    this.durationMinutes = 60,
    this.status = AttendanceSessionStatus.scheduled,
    required this.facultyId,
    this.finalizedAt,
    this.finalizedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  })  : createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('sessionId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (courseId.trim().isEmpty) {
      throw ArgumentError('courseId cannot be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title cannot be empty');
    }
    if (facultyId.trim().isEmpty) {
      throw ArgumentError('facultyId cannot be empty');
    }
    if (durationMinutes <= 0) {
      throw ArgumentError('durationMinutes must be positive');
    }
  }

  bool get isScheduled => status == AttendanceSessionStatus.scheduled;
  bool get isOpen => status == AttendanceSessionStatus.open;
  bool get isClosed => status == AttendanceSessionStatus.closed;
  bool get isCancelled => status == AttendanceSessionStatus.cancelled;
  bool get isFinalized => finalizedAt != null;

  /// Transitions session to OPEN (can record attendance).
  AttendanceSession openSession({DateTime? at}) {
    if (status != AttendanceSessionStatus.scheduled &&
        status != AttendanceSessionStatus.open) {
      throw StateError(
          'Only scheduled sessions can be opened (current: ${status.name}).');
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: AttendanceSessionStatus.open,
      updatedAt: now,
    );
  }

  /// Closes and finalizes session attendance.
  AttendanceSession closeAndFinalize({
    required String actorId,
    DateTime? at,
  }) {
    if (status == AttendanceSessionStatus.cancelled) {
      throw StateError('Cannot finalize a cancelled session.');
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: AttendanceSessionStatus.closed,
      finalizedAt: now,
      finalizedBy: actorId.trim(),
      updatedAt: now,
    );
  }

  /// Cancels a session, excluding it from future attendance calculations.
  AttendanceSession cancelSession({
    required String reason,
    DateTime? at,
  }) {
    if (status == AttendanceSessionStatus.closed) {
      throw StateError('Cannot cancel a finalized/closed session.');
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: AttendanceSessionStatus.cancelled,
      metadata: {
        ...metadata,
        'cancelReason': reason.trim(),
        'cancelledAt': now.toIso8601String()
      },
      updatedAt: now,
    );
  }

  AttendanceSession copyWith({
    String? sessionId,
    String? tenantId,
    String? courseId,
    String? cohortId,
    String? title,
    String? description,
    DateTime? scheduledAt,
    int? durationMinutes,
    AttendanceSessionStatus? status,
    String? facultyId,
    DateTime? finalizedAt,
    String? finalizedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AttendanceSession(
      sessionId: sessionId ?? this.sessionId,
      tenantId: tenantId ?? this.tenantId,
      courseId: courseId ?? this.courseId,
      cohortId: cohortId ?? this.cohortId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      facultyId: facultyId ?? this.facultyId,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      finalizedBy: finalizedBy ?? this.finalizedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'tenantId': tenantId,
        'courseId': courseId,
        if (cohortId != null) 'cohortId': cohortId,
        'title': title,
        'description': description,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'status': status.name,
        'facultyId': facultyId,
        if (finalizedAt != null) 'finalizedAt': finalizedAt!.toIso8601String(),
        if (finalizedBy != null) 'finalizedBy': finalizedBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory AttendanceSession.fromJson(Map<String, dynamic> json) =>
      AttendanceSession(
        sessionId: json['sessionId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        courseId: json['courseId'] as String? ?? '',
        cohortId: json['cohortId'] as String?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        scheduledAt: json['scheduledAt'] != null
            ? DateTime.parse(json['scheduledAt'] as String).toUtc()
            : DateTime.now().toUtc(),
        durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 60,
        status: AttendanceSessionStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AttendanceSessionStatus.scheduled,
        ),
        facultyId: json['facultyId'] as String? ?? '',
        finalizedAt: json['finalizedAt'] != null
            ? DateTime.parse(json['finalizedAt'] as String).toUtc()
            : null,
        finalizedBy: json['finalizedBy'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String).toUtc()
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String).toUtc()
            : null,
        metadata: Map<String, dynamic>.from(
            json['metadata'] as Map? ?? const <String, dynamic>{}),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceSession &&
          sessionId == other.sessionId &&
          tenantId == other.tenantId;

  @override
  int get hashCode => Object.hash(sessionId, tenantId);

  @override
  String toString() =>
      'AttendanceSession(id: $sessionId, course: $courseId, status: ${status.name})';
}
