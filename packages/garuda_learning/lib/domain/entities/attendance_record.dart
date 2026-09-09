/// Learner Attendance Record Domain Entity (TITAN-KO-053.0 P53).
///
/// Production domain models representing individual learner attendance records,
/// explicit attendance statuses (PRESENT, ABSENT, LATE, EXCUSED), finalization state,
/// and immutable authorized correction history.
library;

import 'package:meta/meta.dart';

/// Supported discrete attendance statuses for a learner.
enum AttendanceStatus {
  /// Learner attended the class/session on time.
  present,

  /// Learner failed to attend without prior institutional approval.
  absent,

  /// Learner attended after the formal start threshold.
  late,

  /// Learner absence excused by authorized faculty/medical leave.
  excused,
}

/// Immutable record capturing an authorized correction to finalized attendance.
@immutable
class AttendanceCorrection {
  /// Unique identifier of the correction event.
  final String correctionId;

  /// Status prior to correction.
  final AttendanceStatus previousStatus;

  /// Status resulting from correction.
  final AttendanceStatus newStatus;

  /// Authorized actor who performed the correction.
  final String actorId;

  /// Mandatory pedagogical/administrative justification.
  final String reason;

  /// UTC timestamp when the correction was executed.
  final DateTime timestamp;

  AttendanceCorrection({
    required this.correctionId,
    required this.previousStatus,
    required this.newStatus,
    required this.actorId,
    required this.reason,
    DateTime? timestamp,
  }) : timestamp = (timestamp ?? DateTime.now()).toUtc() {
    if (correctionId.trim().isEmpty) {
      throw ArgumentError('correctionId cannot be empty');
    }
    if (actorId.trim().isEmpty) {
      throw ArgumentError('actorId cannot be empty');
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('reason cannot be empty');
    }
  }

  Map<String, dynamic> toJson() => {
        'correctionId': correctionId,
        'previousStatus': previousStatus.name,
        'newStatus': newStatus.name,
        'actorId': actorId,
        'reason': reason,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AttendanceCorrection.fromJson(Map<String, dynamic> json) =>
      AttendanceCorrection(
        correctionId: json['correctionId'] as String? ?? '',
        previousStatus: AttendanceStatus.values.firstWhere(
          (s) => s.name == json['previousStatus'],
          orElse: () => AttendanceStatus.absent,
        ),
        newStatus: AttendanceStatus.values.firstWhere(
          (s) => s.name == json['newStatus'],
          orElse: () => AttendanceStatus.present,
        ),
        actorId: json['actorId'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        timestamp: json['timestamp'] != null
            ? DateTime.parse(json['timestamp'] as String).toUtc()
            : null,
      );

  @override
  String toString() =>
      'AttendanceCorrection(${previousStatus.name} -> ${newStatus.name} by $actorId)';
}

/// Immutable domain record capturing a learner's attendance in a course session.
@immutable
class AttendanceRecord {
  /// Unique canonical attendance identifier (e.g. 'att_sess01_learner01').
  final String attendanceId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Target session identifier.
  final String sessionId;

  /// Target course identifier.
  final String courseId;

  /// Target cohort identifier where applicable.
  final String? cohortId;

  /// Target enrolled learner identifier.
  final String learnerId;

  /// Scheduled or actual date/time of the session.
  final DateTime sessionDate;

  /// Current formal attendance status.
  final AttendanceStatus status;

  /// Identifier of the actor who recorded or last modified the status.
  final String recordedBy;

  /// UTC timestamp when status was recorded.
  final DateTime recordedAt;

  /// Optional contextual remarks or justification.
  final String? remarks;

  /// Whether attendance for this session has been locked/finalized.
  final bool isFinalized;

  /// Immutable audit history of authorized corrections made after finalization.
  final List<AttendanceCorrection> corrections;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last update timestamp.
  final DateTime updatedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  AttendanceRecord({
    required this.attendanceId,
    this.tenantId = 'default_tenant',
    required this.sessionId,
    required this.courseId,
    this.cohortId,
    required this.learnerId,
    required this.sessionDate,
    required this.status,
    required this.recordedBy,
    DateTime? recordedAt,
    this.remarks,
    this.isFinalized = false,
    Iterable<AttendanceCorrection>? corrections,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  })  : recordedAt = (recordedAt ?? DateTime.now()).toUtc(),
        corrections = List<AttendanceCorrection>.unmodifiable(
          corrections ?? const <AttendanceCorrection>[],
        ),
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (attendanceId.trim().isEmpty) {
      throw ArgumentError('attendanceId cannot be empty');
    }
    if (tenantId.trim().isEmpty) {
      throw ArgumentError('tenantId cannot be empty');
    }
    if (sessionId.trim().isEmpty) {
      throw ArgumentError('sessionId cannot be empty');
    }
    if (courseId.trim().isEmpty) {
      throw ArgumentError('courseId cannot be empty');
    }
    if (learnerId.trim().isEmpty) {
      throw ArgumentError('learnerId cannot be empty');
    }
    if (recordedBy.trim().isEmpty) {
      throw ArgumentError('recordedBy cannot be empty');
    }
  }

  bool get isPresent => status == AttendanceStatus.present;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isLate => status == AttendanceStatus.late;
  bool get isExcused => status == AttendanceStatus.excused;
  bool get hasCorrections => corrections.isNotEmpty;

  /// Canonical ID generator from coordinates.
  static String generateId({
    required String sessionId,
    required String learnerId,
  }) {
    return 'att_${sessionId.trim()}_${learnerId.trim()}';
  }

  /// Applies an authorized post-finalization correction, preserving history.
  AttendanceRecord applyCorrection({
    required AttendanceStatus newStatus,
    required String actorId,
    required String reason,
    DateTime? at,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('Correction reason cannot be empty');
    }
    final now = (at ?? DateTime.now()).toUtc();
    final correction = AttendanceCorrection(
      correctionId: 'corr_${attendanceId}_${now.millisecondsSinceEpoch}',
      previousStatus: status,
      newStatus: newStatus,
      actorId: actorId.trim(),
      reason: cleanReason,
      timestamp: now,
    );

    return copyWith(
      status: newStatus,
      recordedBy: actorId.trim(),
      remarks: 'Corrected: $cleanReason',
      corrections: [...corrections, correction],
      updatedAt: now,
    );
  }

  AttendanceRecord copyWith({
    String? attendanceId,
    String? tenantId,
    String? sessionId,
    String? courseId,
    String? cohortId,
    String? learnerId,
    DateTime? sessionDate,
    AttendanceStatus? status,
    String? recordedBy,
    DateTime? recordedAt,
    String? remarks,
    bool? isFinalized,
    List<AttendanceCorrection>? corrections,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return AttendanceRecord(
      attendanceId: attendanceId ?? this.attendanceId,
      tenantId: tenantId ?? this.tenantId,
      sessionId: sessionId ?? this.sessionId,
      courseId: courseId ?? this.courseId,
      cohortId: cohortId ?? this.cohortId,
      learnerId: learnerId ?? this.learnerId,
      sessionDate: sessionDate ?? this.sessionDate,
      status: status ?? this.status,
      recordedBy: recordedBy ?? this.recordedBy,
      recordedAt: recordedAt ?? this.recordedAt,
      remarks: remarks ?? this.remarks,
      isFinalized: isFinalized ?? this.isFinalized,
      corrections: corrections ?? this.corrections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'attendanceId': attendanceId,
        'tenantId': tenantId,
        'sessionId': sessionId,
        'courseId': courseId,
        if (cohortId != null) 'cohortId': cohortId,
        'learnerId': learnerId,
        'sessionDate': sessionDate.toIso8601String(),
        'status': status.name,
        'recordedBy': recordedBy,
        'recordedAt': recordedAt.toIso8601String(),
        if (remarks != null) 'remarks': remarks,
        'isFinalized': isFinalized,
        'corrections': corrections.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        attendanceId: json['attendanceId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        sessionId: json['sessionId'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        cohortId: json['cohortId'] as String?,
        learnerId: json['learnerId'] as String? ?? '',
        sessionDate: json['sessionDate'] != null
            ? DateTime.parse(json['sessionDate'] as String).toUtc()
            : DateTime.now().toUtc(),
        status: AttendanceStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AttendanceStatus.absent,
        ),
        recordedBy: json['recordedBy'] as String? ?? 'faculty',
        recordedAt: json['recordedAt'] != null
            ? DateTime.parse(json['recordedAt'] as String).toUtc()
            : null,
        remarks: json['remarks'] as String?,
        isFinalized: json['isFinalized'] as bool? ?? false,
        corrections: (json['corrections'] as List<dynamic>?)
                ?.map((c) =>
                    AttendanceCorrection.fromJson(c as Map<String, dynamic>))
                .toList() ??
            const [],
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
      other is AttendanceRecord &&
          attendanceId == other.attendanceId &&
          tenantId == other.tenantId &&
          sessionId == other.sessionId &&
          learnerId == other.learnerId;

  @override
  int get hashCode => Object.hash(attendanceId, tenantId, sessionId, learnerId);

  @override
  String toString() =>
      'AttendanceRecord(session: $sessionId, learner: $learnerId, status: ${status.name})';
}
