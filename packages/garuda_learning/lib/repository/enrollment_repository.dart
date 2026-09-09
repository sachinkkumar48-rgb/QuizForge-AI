/// Learner Course Enrollment Repository Contract (TITAN-KO-052.0 P52).
///
/// Abstract repository interface specifying storage, retrieval,
/// snapshot persistence, and audit logging for courses and enrollments.
library;

import '../domain/entities/course.dart';
import '../domain/entities/enrollment.dart';
import '../domain/entities/enrollment_audit_record.dart';

/// Base exception for learner enrollment storage and domain operations.
class EnrollmentException implements Exception {
  final String message;
  final dynamic cause;
  EnrollmentException(this.message, [this.cause]);
  @override
  String toString() => 'EnrollmentException: $message';
}

/// Thrown when a requested course or enrollment cannot be found.
class EnrollmentNotFoundException extends EnrollmentException {
  EnrollmentNotFoundException(super.message, [super.cause]);
  @override
  String toString() => 'EnrollmentNotFoundException: $message';
}

/// Thrown when enrollment data fails business rules or validation constraints.
class EnrollmentValidationException extends EnrollmentException {
  EnrollmentValidationException(super.message, [super.cause]);
  @override
  String toString() => 'EnrollmentValidationException: $message';
}

/// Thrown when an unauthorized actor attempts an action or tenant boundaries are violated.
class EnrollmentSecurityException extends EnrollmentException {
  EnrollmentSecurityException(super.message, [super.cause]);
  @override
  String toString() => 'EnrollmentSecurityException: $message';
}

/// Thrown when a duplicate active enrollment is attempted for a learner in the same course.
class DuplicateEnrollmentException extends EnrollmentException {
  DuplicateEnrollmentException(super.message, [super.cause]);
  @override
  String toString() => 'DuplicateEnrollmentException: $message';
}

/// Thrown when a learner does not meet prerequisite requirements for course enrollment.
class PrerequisiteNotMetException extends EnrollmentException {
  final List<String> missingPrerequisiteIds;
  PrerequisiteNotMetException(super.message,
      {this.missingPrerequisiteIds = const []});
  @override
  String toString() =>
      'PrerequisiteNotMetException: $message (Missing: ${missingPrerequisiteIds.join(', ')})';
}

/// Abstract contract for managing courses, enrollments, and lifecycle audit records.
abstract class EnrollmentRepository {
  // ---------------------------------------------------------------------------
  // Course Operations
  // ---------------------------------------------------------------------------
  Future<void> saveCourse(Course course);
  Future<Course?> getCourse(String courseId, {String? tenantId});
  Future<List<Course>> listCourses({String? tenantId, CourseStatus? status});
  Future<void> deleteCourse(String courseId, {String? tenantId});

  // ---------------------------------------------------------------------------
  // Enrollment Operations
  // ---------------------------------------------------------------------------
  Future<void> saveEnrollment(Enrollment enrollment);
  Future<Enrollment?> getEnrollment(String enrollmentId, {String? tenantId});
  Future<Enrollment?> getActiveEnrollmentForLearnerCourse({
    required String learnerId,
    required String courseId,
    String? tenantId,
  });
  Future<List<Enrollment>> listEnrollmentsForLearner({
    required String learnerId,
    String? tenantId,
  });
  Future<List<Enrollment>> listEnrollmentsForCourse({
    required String courseId,
    String? tenantId,
  });
  Future<List<Enrollment>> listEnrollmentsForCohort({
    required String cohortId,
    String? tenantId,
  });
  Future<List<Enrollment>> listEnrollments({
    String? tenantId,
    String? courseId,
    String? cohortId,
    String? learnerId,
    EnrollmentStatus? status,
  });

  // ---------------------------------------------------------------------------
  // Audit Trail Operations
  // ---------------------------------------------------------------------------
  Future<void> saveAuditRecord(EnrollmentAuditRecord record);
  Future<List<EnrollmentAuditRecord>> listAuditRecords({
    required String enrollmentId,
    String? tenantId,
  });
  Future<List<EnrollmentAuditRecord>> listAuditRecordsForLearner({
    required String learnerId,
    String? tenantId,
  });

  // ---------------------------------------------------------------------------
  // Persistence Snapshot & Maintenance
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> exportSnapshot();
  Future<void> importSnapshot(Map<String, dynamic> snapshot);
  Future<void> clear();
}
