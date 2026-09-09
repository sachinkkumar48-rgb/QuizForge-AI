/// In-Memory Learner Course Enrollment Repository Implementation (TITAN-KO-052.0 P52).
///
/// Thread-safe in-memory store supporting snapshots, restart persistence,
/// and failure simulation for unit testing, offline-first operation, and sync.
library;

import '../domain/entities/course.dart';
import '../domain/entities/enrollment.dart';
import '../domain/entities/enrollment_audit_record.dart';
import 'enrollment_repository.dart';

class InMemoryEnrollmentRepository implements EnrollmentRepository {
  final Map<String, Course> _courses = {};
  final Map<String, Enrollment> _enrollments = {};
  final List<EnrollmentAuditRecord> _auditRecords = [];

  bool _simulateFailure = false;

  void setSimulateFailure(bool simulate) {
    _simulateFailure = simulate;
  }

  void _checkFailure() {
    if (_simulateFailure) {
      throw EnrollmentException('Simulated repository storage failure');
    }
  }

  // ---------------------------------------------------------------------------
  // Course Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveCourse(Course course) async {
    _checkFailure();
    _courses[course.courseId] = course;
  }

  @override
  Future<Course?> getCourse(String courseId, {String? tenantId}) async {
    _checkFailure();
    final course = _courses[courseId];
    if (course == null) return null;
    if (tenantId != null && course.tenantId != tenantId) return null;
    return course;
  }

  @override
  Future<List<Course>> listCourses({
    String? tenantId,
    CourseStatus? status,
  }) async {
    _checkFailure();
    return _courses.values.where((c) {
      if (tenantId != null && c.tenantId != tenantId) return false;
      if (status != null && c.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> deleteCourse(String courseId, {String? tenantId}) async {
    _checkFailure();
    final course = _courses[courseId];
    if (course == null) return;
    if (tenantId != null && course.tenantId != tenantId) return;
    _courses.remove(courseId);
  }

  // ---------------------------------------------------------------------------
  // Enrollment Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveEnrollment(Enrollment enrollment) async {
    _checkFailure();
    _enrollments[enrollment.enrollmentId] = enrollment;
  }

  @override
  Future<Enrollment?> getEnrollment(
    String enrollmentId, {
    String? tenantId,
  }) async {
    _checkFailure();
    final enrollment = _enrollments[enrollmentId];
    if (enrollment == null) return null;
    if (tenantId != null && enrollment.tenantId != tenantId) return null;
    return enrollment;
  }

  @override
  Future<Enrollment?> getActiveEnrollmentForLearnerCourse({
    required String learnerId,
    required String courseId,
    String? tenantId,
  }) async {
    _checkFailure();
    for (final enr in _enrollments.values) {
      if (enr.learnerId == learnerId &&
          enr.courseId == courseId &&
          enr.status == EnrollmentStatus.active) {
        if (tenantId == null || enr.tenantId == tenantId) {
          return enr;
        }
      }
    }
    return null;
  }

  @override
  Future<List<Enrollment>> listEnrollmentsForLearner({
    required String learnerId,
    String? tenantId,
  }) async {
    _checkFailure();
    return _enrollments.values.where((e) {
      if (e.learnerId != learnerId) return false;
      if (tenantId != null && e.tenantId != tenantId) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<Enrollment>> listEnrollmentsForCourse({
    required String courseId,
    String? tenantId,
  }) async {
    _checkFailure();
    return _enrollments.values.where((e) {
      if (e.courseId != courseId) return false;
      if (tenantId != null && e.tenantId != tenantId) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<Enrollment>> listEnrollmentsForCohort({
    required String cohortId,
    String? tenantId,
  }) async {
    _checkFailure();
    return _enrollments.values.where((e) {
      if (e.cohortId != cohortId) return false;
      if (tenantId != null && e.tenantId != tenantId) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<Enrollment>> listEnrollments({
    String? tenantId,
    String? courseId,
    String? cohortId,
    String? learnerId,
    EnrollmentStatus? status,
  }) async {
    _checkFailure();
    return _enrollments.values.where((e) {
      if (tenantId != null && e.tenantId != tenantId) return false;
      if (courseId != null && e.courseId != courseId) return false;
      if (cohortId != null && e.cohortId != cohortId) return false;
      if (learnerId != null && e.learnerId != learnerId) return false;
      if (status != null && e.status != status) return false;
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Audit Trail Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAuditRecord(EnrollmentAuditRecord record) async {
    _checkFailure();
    _auditRecords.add(record);
  }

  @override
  Future<List<EnrollmentAuditRecord>> listAuditRecords({
    required String enrollmentId,
    String? tenantId,
  }) async {
    _checkFailure();
    final results = _auditRecords.where((a) {
      if (a.enrollmentId != enrollmentId) return false;
      if (tenantId != null && a.tenantId != tenantId) return false;
      return true;
    }).toList();
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  @override
  Future<List<EnrollmentAuditRecord>> listAuditRecordsForLearner({
    required String learnerId,
    String? tenantId,
  }) async {
    _checkFailure();
    final results = _auditRecords.where((a) {
      if (a.learnerId != learnerId) return false;
      if (tenantId != null && a.tenantId != tenantId) return false;
      return true;
    }).toList();
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  // ---------------------------------------------------------------------------
  // Persistence Snapshots & Maintenance
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> exportSnapshot() async {
    _checkFailure();
    return {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'courses': _courses.values.map((c) => c.toJson()).toList(growable: false),
      'enrollments':
          _enrollments.values.map((e) => e.toJson()).toList(growable: false),
      'auditRecords':
          _auditRecords.map((a) => a.toJson()).toList(growable: false),
    };
  }

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    _checkFailure();
    _courses.clear();
    _enrollments.clear();
    _auditRecords.clear();

    final coursesRaw = snapshot['courses'] as List<dynamic>? ?? [];
    for (final raw in coursesRaw) {
      final c = Course.fromJson(raw as Map<String, dynamic>);
      _courses[c.courseId] = c;
    }

    final enrollmentsRaw = snapshot['enrollments'] as List<dynamic>? ?? [];
    for (final raw in enrollmentsRaw) {
      final e = Enrollment.fromJson(raw as Map<String, dynamic>);
      _enrollments[e.enrollmentId] = e;
    }

    final auditRaw = snapshot['auditRecords'] as List<dynamic>? ?? [];
    for (final raw in auditRaw) {
      final a = EnrollmentAuditRecord.fromJson(raw as Map<String, dynamic>);
      _auditRecords.add(a);
    }
  }

  @override
  Future<void> clear() async {
    _courses.clear();
    _enrollments.clear();
    _auditRecords.clear();
  }
}
