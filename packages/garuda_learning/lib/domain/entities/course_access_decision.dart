/// Course Access Decision Domain Entities (TITAN-KO-052.0 P52).
///
/// Production domain models representing access decisions to course content,
/// distinguishing between FULL access, READ-ONLY historical access, and BLOCKED access.
library;

import 'package:meta/meta.dart';
import 'enrollment.dart';

/// Supported types of course access permission.
enum CourseAccessType {
  /// Full access to ongoing study materials, drills, attempts, and submissions.
  full,

  /// Historical read-only access to previously completed course material and outcomes.
  readOnly,

  /// Access disallowed or blocked.
  blocked,
}

/// Evaluated access decision determining whether a learner may access a course.
@immutable
class CourseAccessDecision {
  /// Whether the learner is permitted to enter the course in any capacity.
  final bool isAllowed;

  /// Specific tier of access permitted.
  final CourseAccessType accessType;

  /// Underlying enrollment status if an enrollment exists.
  final EnrollmentStatus? status;

  /// Target learner identifier.
  final String learnerId;

  /// Target course identifier.
  final String courseId;

  /// Human-readable explanation if access is blocked or restricted.
  final String? reason;

  /// UTC evaluation timestamp.
  final DateTime evaluatedAt;

  CourseAccessDecision({
    required this.isAllowed,
    required this.accessType,
    this.status,
    required this.learnerId,
    required this.courseId,
    this.reason,
    DateTime? evaluatedAt,
  }) : evaluatedAt = (evaluatedAt ?? DateTime.now()).toUtc();

  bool get isFull => accessType == CourseAccessType.full;
  bool get isReadOnly => accessType == CourseAccessType.readOnly;
  bool get isBlocked => accessType == CourseAccessType.blocked;

  /// Factory helper for active full access.
  factory CourseAccessDecision.full({
    required String learnerId,
    required String courseId,
    EnrollmentStatus status = EnrollmentStatus.active,
  }) =>
      CourseAccessDecision(
        isAllowed: true,
        accessType: CourseAccessType.full,
        status: status,
        learnerId: learnerId,
        courseId: courseId,
      );

  /// Factory helper for completed read-only access.
  factory CourseAccessDecision.readOnly({
    required String learnerId,
    required String courseId,
  }) =>
      CourseAccessDecision(
        isAllowed: true,
        accessType: CourseAccessType.readOnly,
        status: EnrollmentStatus.completed,
        learnerId: learnerId,
        courseId: courseId,
        reason: 'Course completed. Historical read-only access granted.',
      );

  /// Factory helper for blocked access.
  factory CourseAccessDecision.blocked({
    required String learnerId,
    required String courseId,
    EnrollmentStatus? status,
    required String reason,
  }) =>
      CourseAccessDecision(
        isAllowed: false,
        accessType: CourseAccessType.blocked,
        status: status,
        learnerId: learnerId,
        courseId: courseId,
        reason: reason,
      );

  Map<String, dynamic> toJson() => {
        'isAllowed': isAllowed,
        'accessType': accessType.name,
        if (status != null) 'status': status!.name,
        'learnerId': learnerId,
        'courseId': courseId,
        if (reason != null) 'reason': reason,
        'evaluatedAt': evaluatedAt.toIso8601String(),
      };

  factory CourseAccessDecision.fromJson(Map<String, dynamic> json) =>
      CourseAccessDecision(
        isAllowed: json['isAllowed'] as bool? ?? false,
        accessType: CourseAccessType.values.firstWhere(
          (t) => t.name == json['accessType'],
          orElse: () => CourseAccessType.blocked,
        ),
        status: json['status'] != null
            ? EnrollmentStatus.values.firstWhere(
                (s) => s.name == json['status'],
                orElse: () => EnrollmentStatus.cancelled,
              )
            : null,
        learnerId: json['learnerId'] as String? ?? '',
        courseId: json['courseId'] as String? ?? '',
        reason: json['reason'] as String?,
        evaluatedAt: json['evaluatedAt'] != null
            ? DateTime.parse(json['evaluatedAt'] as String).toUtc()
            : null,
      );

  @override
  String toString() =>
      'CourseAccessDecision(learner: $learnerId, course: $courseId, allowed: $isAllowed, type: ${accessType.name}, reason: $reason)';
}
