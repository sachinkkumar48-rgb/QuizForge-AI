/// Learner Course Enrollment Domain Entities (TITAN-KO-052.0 P52).
///
/// Production domain models representing learner enrollments in institutional
/// courses, strict lifecycle state machines (PENDING, ACTIVE, COMPLETED,
/// SUSPENDED, WITHDRAWN, CANCELLED), and transition auditing.
library;

import 'package:meta/meta.dart';

/// Explicit lifecycle states for a learner's course enrollment.
enum EnrollmentStatus {
  /// Registration received, pending faculty approval or prerequisite verification.
  pending,

  /// Officially enrolled, active, and course content is accessible.
  active,

  /// Requirements fulfilled, course completed with historical read-only access.
  completed,

  /// Temporarily suspended by faculty/admin; active learning access blocked.
  suspended,

  /// Formally withdrawn from course; new learning blocked, past records preserved.
  withdrawn,

  /// Cancelled prior to active enrollment; voided without access.
  cancelled,
}

/// Thrown when an illegal state transition is attempted on an enrollment.
class EnrollmentTransitionException implements Exception {
  final String message;
  final EnrollmentStatus fromStatus;
  final EnrollmentStatus toStatus;

  EnrollmentTransitionException(
    this.message, {
    required this.fromStatus,
    required this.toStatus,
  });

  @override
  String toString() =>
      'EnrollmentTransitionException: Cannot transition from ${fromStatus.name} to ${toStatus.name}: $message';
}

/// Immutable record capturing a learner's enrollment in a course/program.
@immutable
class Enrollment {
  /// Unique canonical enrollment identifier (e.g. 'enr_cohort1_course1_learner1').
  final String enrollmentId;

  /// Multi-tenant identifier.
  final String tenantId;

  /// Enrolled learner identifier.
  final String learnerId;

  /// Associated course/program identifier.
  final String courseId;

  /// Optional display title of the course.
  final String? courseTitle;

  /// Associated cohort identifier where applicable.
  final String? cohortId;

  /// Current formal enrollment status.
  final EnrollmentStatus status;

  /// UTC timestamp when registration occurred.
  final DateTime enrolledAt;

  /// UTC effective start date.
  final DateTime? effectiveDate;

  /// UTC completion timestamp if status is completed.
  final DateTime? completedAt;

  /// UTC withdrawal timestamp if status is withdrawn.
  final DateTime? withdrawnAt;

  /// UTC suspension timestamp if status is suspended.
  final DateTime? suspendedAt;

  /// UTC cancellation timestamp if status is cancelled.
  final DateTime? cancelledAt;

  /// Mandatory administrative justification if status is suspended, withdrawn, or cancelled.
  final String? statusReason;

  /// Actor who initiated the enrollment (e.g. facultyId, adminId, or learnerId).
  final String enrolledBy;

  /// Actor who last modified the enrollment status.
  final String? updatedBy;

  /// UTC creation timestamp.
  final DateTime createdAt;

  /// UTC last updated timestamp.
  final DateTime updatedAt;

  /// Extensible metadata.
  final Map<String, dynamic> metadata;

  Enrollment({
    required this.enrollmentId,
    this.tenantId = 'default_tenant',
    required this.learnerId,
    required this.courseId,
    this.courseTitle,
    this.cohortId,
    this.status = EnrollmentStatus.active,
    DateTime? enrolledAt,
    this.effectiveDate,
    this.completedAt,
    this.withdrawnAt,
    this.suspendedAt,
    this.cancelledAt,
    this.statusReason,
    required this.enrolledBy,
    this.updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  })  : enrolledAt = (enrolledAt ?? DateTime.now()).toUtc(),
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? createdAt ?? DateTime.now()).toUtc(),
        metadata = Map<String, dynamic>.unmodifiable(metadata ?? const {}) {
    if (enrollmentId.trim().isEmpty) {
      throw ArgumentError('enrollmentId cannot be empty');
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
    if (enrolledBy.trim().isEmpty) {
      throw ArgumentError('enrolledBy cannot be empty');
    }
  }

  bool get isActive => status == EnrollmentStatus.active;
  bool get isPending => status == EnrollmentStatus.pending;
  bool get isCompleted => status == EnrollmentStatus.completed;
  bool get isSuspended => status == EnrollmentStatus.suspended;
  bool get isWithdrawn => status == EnrollmentStatus.withdrawn;
  bool get isCancelled => status == EnrollmentStatus.cancelled;

  /// Canonical ID generator from coordinates.
  static String generateId({
    required String courseId,
    required String learnerId,
    String? cohortId,
  }) {
    final prefix = cohortId != null && cohortId.trim().isNotEmpty
        ? '${cohortId.trim()}_'
        : '';
    return 'enr_$prefix${courseId.trim()}_${learnerId.trim()}';
  }

  // ---------------------------------------------------------------------------
  // State Machine Transitions
  // ---------------------------------------------------------------------------

  /// Activates a pending enrollment (PENDING -> ACTIVE).
  Enrollment activate({required String actorId, DateTime? at}) {
    if (status != EnrollmentStatus.pending) {
      throw EnrollmentTransitionException(
        'Only pending enrollments can be activated.',
        fromStatus: status,
        toStatus: EnrollmentStatus.active,
      );
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: EnrollmentStatus.active,
      effectiveDate: effectiveDate ?? now,
      updatedBy: actorId.trim(),
      updatedAt: now,
    );
  }

  /// Marks an active enrollment as completed (ACTIVE -> COMPLETED).
  Enrollment complete({required String actorId, DateTime? at}) {
    if (status != EnrollmentStatus.active) {
      throw EnrollmentTransitionException(
        'Only active enrollments can be marked as completed.',
        fromStatus: status,
        toStatus: EnrollmentStatus.completed,
      );
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: EnrollmentStatus.completed,
      completedAt: now,
      updatedBy: actorId.trim(),
      updatedAt: now,
    );
  }

  /// Temporarily suspends an active enrollment (ACTIVE -> SUSPENDED).
  Enrollment suspend({
    required String actorId,
    required String reason,
    DateTime? at,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('Suspension reason cannot be empty');
    }
    if (status != EnrollmentStatus.active) {
      throw EnrollmentTransitionException(
        'Only active enrollments can be suspended.',
        fromStatus: status,
        toStatus: EnrollmentStatus.suspended,
      );
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: EnrollmentStatus.suspended,
      suspendedAt: now,
      statusReason: cleanReason,
      updatedBy: actorId.trim(),
      updatedAt: now,
    );
  }

  /// Reactivates a suspended enrollment (SUSPENDED -> ACTIVE).
  Enrollment reactivate({required String actorId, DateTime? at}) {
    if (status != EnrollmentStatus.suspended) {
      throw EnrollmentTransitionException(
        'Only suspended enrollments can be reactivated.',
        fromStatus: status,
        toStatus: EnrollmentStatus.active,
      );
    }
    final now = (at ?? DateTime.now()).toUtc();
    return Enrollment(
      enrollmentId: enrollmentId,
      tenantId: tenantId,
      learnerId: learnerId,
      courseId: courseId,
      courseTitle: courseTitle,
      cohortId: cohortId,
      status: EnrollmentStatus.active,
      enrolledAt: enrolledAt,
      effectiveDate: effectiveDate,
      completedAt: completedAt,
      withdrawnAt: withdrawnAt,
      suspendedAt: null,
      cancelledAt: cancelledAt,
      statusReason: null,
      enrolledBy: enrolledBy,
      updatedBy: actorId.trim(),
      createdAt: createdAt,
      updatedAt: now,
      metadata: metadata,
    );
  }

  /// Formally withdraws a learner from a course (ACTIVE or SUSPENDED -> WITHDRAWN).
  Enrollment withdraw({
    required String actorId,
    required String reason,
    DateTime? at,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('Withdrawal reason cannot be empty');
    }
    if (status != EnrollmentStatus.active &&
        status != EnrollmentStatus.suspended) {
      throw EnrollmentTransitionException(
        'Only active or suspended enrollments can be withdrawn.',
        fromStatus: status,
        toStatus: EnrollmentStatus.withdrawn,
      );
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: EnrollmentStatus.withdrawn,
      withdrawnAt: now,
      statusReason: cleanReason,
      updatedBy: actorId.trim(),
      updatedAt: now,
    );
  }

  /// Cancels a pending registration (PENDING -> CANCELLED).
  Enrollment cancel({
    required String actorId,
    required String reason,
    DateTime? at,
  }) {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ArgumentError('Cancellation reason cannot be empty');
    }
    if (status != EnrollmentStatus.pending) {
      throw EnrollmentTransitionException(
        'Only pending registrations can be cancelled.',
        fromStatus: status,
        toStatus: EnrollmentStatus.cancelled,
      );
    }
    final now = (at ?? DateTime.now()).toUtc();
    return copyWith(
      status: EnrollmentStatus.cancelled,
      cancelledAt: now,
      statusReason: cleanReason,
      updatedBy: actorId.trim(),
      updatedAt: now,
    );
  }

  Enrollment copyWith({
    String? enrollmentId,
    String? tenantId,
    String? learnerId,
    String? courseId,
    String? courseTitle,
    String? cohortId,
    EnrollmentStatus? status,
    DateTime? enrolledAt,
    DateTime? effectiveDate,
    DateTime? completedAt,
    DateTime? withdrawnAt,
    DateTime? suspendedAt,
    DateTime? cancelledAt,
    String? statusReason,
    String? enrolledBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Enrollment(
      enrollmentId: enrollmentId ?? this.enrollmentId,
      tenantId: tenantId ?? this.tenantId,
      learnerId: learnerId ?? this.learnerId,
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      cohortId: cohortId ?? this.cohortId,
      status: status ?? this.status,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      completedAt: completedAt ?? this.completedAt,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      statusReason: statusReason ?? this.statusReason,
      enrolledBy: enrolledBy ?? this.enrolledBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'enrollmentId': enrollmentId,
        'tenantId': tenantId,
        'learnerId': learnerId,
        'courseId': courseId,
        if (courseTitle != null) 'courseTitle': courseTitle,
        if (cohortId != null) 'cohortId': cohortId,
        'status': status.name,
        'enrolledAt': enrolledAt.toIso8601String(),
        if (effectiveDate != null)
          'effectiveDate': effectiveDate!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (withdrawnAt != null) 'withdrawnAt': withdrawnAt!.toIso8601String(),
        if (suspendedAt != null) 'suspendedAt': suspendedAt!.toIso8601String(),
        if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
        if (statusReason != null) 'statusReason': statusReason,
        'enrolledBy': enrolledBy,
        if (updatedBy != null) 'updatedBy': updatedBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'metadata': metadata,
      };

  factory Enrollment.fromJson(Map<String, dynamic> json) => Enrollment(
        enrollmentId: json['enrollmentId'] as String? ?? '',
        tenantId: json['tenantId'] as String? ?? 'default_tenant',
        learnerId: json['learnerId'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        courseTitle: json['courseTitle'] as String?,
        cohortId: json['cohortId'] as String?,
        status: EnrollmentStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => EnrollmentStatus.active,
        ),
        enrolledAt: json['enrolledAt'] != null
            ? DateTime.parse(json['enrolledAt'] as String).toUtc()
            : null,
        effectiveDate: json['effectiveDate'] != null
            ? DateTime.parse(json['effectiveDate'] as String).toUtc()
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String).toUtc()
            : null,
        withdrawnAt: json['withdrawnAt'] != null
            ? DateTime.parse(json['withdrawnAt'] as String).toUtc()
            : null,
        suspendedAt: json['suspendedAt'] != null
            ? DateTime.parse(json['suspendedAt'] as String).toUtc()
            : null,
        cancelledAt: json['cancelledAt'] != null
            ? DateTime.parse(json['cancelledAt'] as String).toUtc()
            : null,
        statusReason: json['statusReason'] as String?,
        enrolledBy: json['enrolledBy'] as String? ?? 'system',
        updatedBy: json['updatedBy'] as String?,
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
      other is Enrollment &&
          enrollmentId == other.enrollmentId &&
          tenantId == other.tenantId &&
          learnerId == other.learnerId &&
          courseId == other.courseId &&
          status == other.status;

  @override
  int get hashCode =>
      Object.hash(enrollmentId, tenantId, learnerId, courseId, status);

  @override
  String toString() =>
      'Enrollment(id: $enrollmentId, learner: $learnerId, course: $courseId, status: ${status.name})';
}
