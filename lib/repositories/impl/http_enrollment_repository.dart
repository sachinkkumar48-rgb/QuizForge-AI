import 'package:garuda_learning/garuda_learning.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';

/// HTTP and offline-first implementation of [EnrollmentRepository] (TITAN-KO P52 / P57).
/// Communicates with FastAPI backend `/api/v1/lms/courses` and `/api/v1/lms/enrollments`.
class HttpEnrollmentRepository implements EnrollmentRepository {
  final ApiClient _apiClient;
  final InMemoryEnrollmentRepository _local;

  HttpEnrollmentRepository({
    ApiClient? apiClient,
    InMemoryEnrollmentRepository? localStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _local = localStore ?? InMemoryEnrollmentRepository();

  // ---------------------------------------------------------------------------
  // Course Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveCourse(Course course) async {
    await _local.saveCourse(course);
    try {
      await _apiClient.post('/api/v1/lms/courses', body: course.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveCourse failed, cached locally: $e', tag: 'HttpEnrollmentRepo');
    }
  }

  @override
  Future<Course?> getCourse(String courseId, {String? tenantId}) async {
    try {
      final query = tenantId != null ? '?tenantId=${Uri.encodeComponent(tenantId)}' : '';
      final res = await _apiClient.get('/api/v1/lms/courses/${Uri.encodeComponent(courseId)}$query');
      if (res.isNotEmpty && (res['course'] != null || res['courseId'] != null)) {
        final courseMap = (res['course'] is Map)
            ? Map<String, dynamic>.from(res['course'] as Map)
            : Map<String, dynamic>.from(res);
        final course = Course.fromJson(courseMap);
        await _local.saveCourse(course);
        return course;
      }
    } catch (e) {
      AppLogger.debug('Remote getCourse fallback to local: $e', tag: 'HttpEnrollmentRepo');
    }
    return _local.getCourse(courseId, tenantId: tenantId);
  }

  @override
  Future<List<Course>> listCourses({String? tenantId, CourseStatus? status}) async {
    try {
      final params = <String>[];
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (status != null) params.add('status=${Uri.encodeComponent(status.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/courses$query');
      final dynamic listData = res['courses'] ?? res['data'];
      if (listData is List) {
        final courses = listData
            .map((c) => Course.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList();
        for (final c in courses) {
          await _local.saveCourse(c);
        }
        return courses;
      }
    } catch (e) {
      AppLogger.debug('Remote listCourses fallback to local: $e', tag: 'HttpEnrollmentRepo');
    }
    return _local.listCourses(tenantId: tenantId, status: status);
  }

  @override
  Future<void> deleteCourse(String courseId, {String? tenantId}) async {
    await _local.deleteCourse(courseId, tenantId: tenantId);
    try {
      final query = tenantId != null ? '?tenantId=${Uri.encodeComponent(tenantId)}' : '';
      await _apiClient.delete('/api/v1/lms/courses/${Uri.encodeComponent(courseId)}$query');
    } catch (e) {
      AppLogger.debug('Remote deleteCourse failed: $e', tag: 'HttpEnrollmentRepo');
    }
  }

  // ---------------------------------------------------------------------------
  // Enrollment Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveEnrollment(Enrollment enrollment) async {
    await _local.saveEnrollment(enrollment);
    try {
      await _apiClient.post('/api/v1/lms/enrollments', body: enrollment.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveEnrollment failed, cached locally: $e', tag: 'HttpEnrollmentRepo');
    }
  }

  @override
  Future<Enrollment?> getEnrollment(String enrollmentId, {String? tenantId}) async {
    try {
      final query = tenantId != null ? '?tenantId=${Uri.encodeComponent(tenantId)}' : '';
      final res = await _apiClient.get('/api/v1/lms/enrollments/${Uri.encodeComponent(enrollmentId)}$query');
      if (res.isNotEmpty && (res['enrollment'] != null || res['enrollmentId'] != null)) {
        final enrMap = (res['enrollment'] is Map)
            ? Map<String, dynamic>.from(res['enrollment'] as Map)
            : Map<String, dynamic>.from(res);
        final enrollment = Enrollment.fromJson(enrMap);
        await _local.saveEnrollment(enrollment);
        return enrollment;
      }
    } catch (e) {
      AppLogger.debug('Remote getEnrollment fallback to local: $e', tag: 'HttpEnrollmentRepo');
    }
    return _local.getEnrollment(enrollmentId, tenantId: tenantId);
  }

  @override
  Future<Enrollment?> getActiveEnrollmentForLearnerCourse({
    required String learnerId,
    required String courseId,
    String? tenantId,
  }) async {
    try {
      final params = [
        'learnerId=${Uri.encodeComponent(learnerId)}',
        'courseId=${Uri.encodeComponent(courseId)}',
        if (tenantId != null) 'tenantId=${Uri.encodeComponent(tenantId)}',
      ];
      final res = await _apiClient.get('/api/v1/lms/enrollments/active?${params.join('&')}');
      if (res.isNotEmpty && (res['enrollment'] != null || res['enrollmentId'] != null)) {
        final enrMap = (res['enrollment'] is Map)
            ? Map<String, dynamic>.from(res['enrollment'] as Map)
            : Map<String, dynamic>.from(res);
        final enrollment = Enrollment.fromJson(enrMap);
        await _local.saveEnrollment(enrollment);
        return enrollment;
      }
    } catch (e) {
      AppLogger.debug('Remote getActiveEnrollment fallback to local: $e', tag: 'HttpEnrollmentRepo');
    }
    return _local.getActiveEnrollmentForLearnerCourse(
      learnerId: learnerId,
      courseId: courseId,
      tenantId: tenantId,
    );
  }

  @override
  Future<List<Enrollment>> listEnrollmentsForLearner({
    required String learnerId,
    String? tenantId,
  }) async {
    return listEnrollments(learnerId: learnerId, tenantId: tenantId);
  }

  @override
  Future<List<Enrollment>> listEnrollmentsForCourse({
    required String courseId,
    String? tenantId,
  }) async {
    return listEnrollments(courseId: courseId, tenantId: tenantId);
  }

  @override
  Future<List<Enrollment>> listEnrollmentsForCohort({
    required String cohortId,
    String? tenantId,
  }) async {
    return listEnrollments(cohortId: cohortId, tenantId: tenantId);
  }

  @override
  Future<List<Enrollment>> listEnrollments({
    String? tenantId,
    String? courseId,
    String? cohortId,
    String? learnerId,
    EnrollmentStatus? status,
  }) async {
    try {
      final params = <String>[];
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (courseId != null) params.add('courseId=${Uri.encodeComponent(courseId)}');
      if (cohortId != null) params.add('cohortId=${Uri.encodeComponent(cohortId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (status != null) params.add('status=${Uri.encodeComponent(status.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/enrollments$query');
      final dynamic listData = res['enrollments'] ?? res['data'];
      if (listData is List) {
        final enrollments = listData
            .map((e) => Enrollment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        for (final e in enrollments) {
          await _local.saveEnrollment(e);
        }
        return enrollments;
      }
    } catch (e) {
      AppLogger.debug('Remote listEnrollments fallback to local: $e', tag: 'HttpEnrollmentRepo');
    }
    return _local.listEnrollments(
      tenantId: tenantId,
      courseId: courseId,
      cohortId: cohortId,
      learnerId: learnerId,
      status: status,
    );
  }

  // ---------------------------------------------------------------------------
  // Audit Trail Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAuditRecord(EnrollmentAuditRecord record) async {
    await _local.saveAuditRecord(record);
    try {
      await _apiClient.post('/api/v1/lms/enrollments/audit', body: record.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveAuditRecord failed: $e', tag: 'HttpEnrollmentRepo');
    }
  }

  @override
  Future<List<EnrollmentAuditRecord>> listAuditRecords({
    required String enrollmentId,
    String? tenantId,
  }) async {
    try {
      final params = [
        'enrollmentId=${Uri.encodeComponent(enrollmentId)}',
        if (tenantId != null) 'tenantId=${Uri.encodeComponent(tenantId)}',
      ];
      final res = await _apiClient.get('/api/v1/lms/enrollments/audit?${params.join('&')}');
      final dynamic listData = res['audits'] ?? res['data'];
      if (listData is List) {
        return listData
            .map((a) => EnrollmentAuditRecord.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
      }
    } catch (e) {
      AppLogger.debug('Remote listAuditRecords fallback to local: $e', tag: 'HttpEnrollmentRepo');
    }
    return _local.listAuditRecords(enrollmentId: enrollmentId, tenantId: tenantId);
  }

  @override
  Future<List<EnrollmentAuditRecord>> listAuditRecordsForLearner({
    required String learnerId,
    String? tenantId,
  }) async {
    try {
      final params = [
        'learnerId=${Uri.encodeComponent(learnerId)}',
        if (tenantId != null) 'tenantId=${Uri.encodeComponent(tenantId)}',
      ];
      final res = await _apiClient.get('/api/v1/lms/enrollments/audit?${params.join('&')}');
      final dynamic listData = res['audits'] ?? res['data'];
      if (listData is List) {
        return listData
            .map((a) => EnrollmentAuditRecord.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
      }
    } catch (e) {
      AppLogger.debug('Remote listAuditRecordsForLearner fallback to local: $e', tag: 'HttpEnrollmentRepo');
    }
    return _local.listAuditRecordsForLearner(learnerId: learnerId, tenantId: tenantId);
  }

  // ---------------------------------------------------------------------------
  // Persistence Snapshot & Maintenance
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> exportSnapshot() => _local.exportSnapshot();

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) => _local.importSnapshot(snapshot);

  @override
  Future<void> clear() => _local.clear();
}
