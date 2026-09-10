import 'package:garuda_learning/garuda_learning.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';

/// HTTP and offline-first implementation of [AttendanceRepository] (TITAN-KO P53 / P57).
/// Communicates with FastAPI backend `/api/v1/lms/attendance`.
class HttpAttendanceRepository implements AttendanceRepository {
  final ApiClient _apiClient;
  final InMemoryAttendanceRepository _local;

  HttpAttendanceRepository({
    ApiClient? apiClient,
    InMemoryAttendanceRepository? localStore,
  })  : _apiClient = apiClient ?? ApiClient(),
        _local = localStore ?? InMemoryAttendanceRepository();

  // ---------------------------------------------------------------------------
  // Session Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveSession(AttendanceSession session) async {
    await _local.saveSession(session);
    try {
      await _apiClient.post('/api/v1/lms/attendance/sessions', body: session.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveSession failed, cached locally: $e', tag: 'HttpAttendanceRepo');
    }
  }

  @override
  Future<AttendanceSession?> getSession(String sessionId, {String? tenantId}) async {
    try {
      final query = tenantId != null ? '?tenantId=${Uri.encodeComponent(tenantId)}' : '';
      final res = await _apiClient.get('/api/v1/lms/attendance/sessions/${Uri.encodeComponent(sessionId)}$query');
      if (res.isNotEmpty && (res['session'] != null || res['sessionId'] != null)) {
        final sMap = (res['session'] is Map)
            ? Map<String, dynamic>.from(res['session'] as Map)
            : Map<String, dynamic>.from(res);
        final session = AttendanceSession.fromJson(sMap);
        await _local.saveSession(session);
        return session;
      }
    } catch (e) {
      AppLogger.debug('Remote getSession fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.getSession(sessionId, tenantId: tenantId);
  }

  @override
  Future<List<AttendanceSession>> listSessionsForCourse({
    required String courseId,
    String? tenantId,
    AttendanceSessionStatus? status,
  }) {
    return listSessions(courseId: courseId, tenantId: tenantId, status: status);
  }

  @override
  Future<List<AttendanceSession>> listSessionsForCohort({
    required String cohortId,
    String? tenantId,
    AttendanceSessionStatus? status,
  }) {
    return listSessions(cohortId: cohortId, tenantId: tenantId, status: status);
  }

  @override
  Future<List<AttendanceSession>> listSessions({
    String? tenantId,
    String? courseId,
    String? cohortId,
    AttendanceSessionStatus? status,
  }) async {
    try {
      final params = <String>[];
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (courseId != null) params.add('courseId=${Uri.encodeComponent(courseId)}');
      if (cohortId != null) params.add('cohortId=${Uri.encodeComponent(cohortId)}');
      if (status != null) params.add('status=${Uri.encodeComponent(status.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/attendance/sessions$query');
      final dynamic listData = res['sessions'] ?? res['data'];
      if (listData is List) {
        final sessions = listData
            .map((s) => AttendanceSession.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList();
        for (final s in sessions) {
          await _local.saveSession(s);
        }
        return sessions;
      }
    } catch (e) {
      AppLogger.debug('Remote listSessions fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.listSessions(
      tenantId: tenantId,
      courseId: courseId,
      cohortId: cohortId,
      status: status,
    );
  }

  // ---------------------------------------------------------------------------
  // Attendance Record Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    await _local.saveAttendanceRecord(record);
    try {
      await _apiClient.post('/api/v1/lms/attendance/records', body: record.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveAttendanceRecord failed, cached locally: $e', tag: 'HttpAttendanceRepo');
    }
  }

  @override
  Future<AttendanceRecord?> getAttendanceRecord(String attendanceId, {String? tenantId}) async {
    try {
      final query = tenantId != null ? '?tenantId=${Uri.encodeComponent(tenantId)}' : '';
      final res = await _apiClient.get('/api/v1/lms/attendance/records/${Uri.encodeComponent(attendanceId)}$query');
      if (res.isNotEmpty && (res['record'] != null || res['attendanceId'] != null)) {
        final rMap = (res['record'] is Map)
            ? Map<String, dynamic>.from(res['record'] as Map)
            : Map<String, dynamic>.from(res);
        final rec = AttendanceRecord.fromJson(rMap);
        await _local.saveAttendanceRecord(rec);
        return rec;
      }
    } catch (e) {
      AppLogger.debug('Remote getAttendanceRecord fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.getAttendanceRecord(attendanceId, tenantId: tenantId);
  }

  @override
  Future<AttendanceRecord?> getAttendanceForSessionAndLearner({
    required String sessionId,
    required String learnerId,
    String? tenantId,
  }) async {
    try {
      final tParam = tenantId != null ? '&tenantId=${Uri.encodeComponent(tenantId)}' : '';
      final query =
          'sessionId=${Uri.encodeComponent(sessionId)}&learnerId=${Uri.encodeComponent(learnerId)}$tParam';
      final res = await _apiClient.get('/api/v1/lms/attendance/records/by-session-learner?$query');
      if (res.isNotEmpty && (res['record'] != null || res['attendanceId'] != null)) {
        final rMap = (res['record'] is Map)
            ? Map<String, dynamic>.from(res['record'] as Map)
            : Map<String, dynamic>.from(res);
        final rec = AttendanceRecord.fromJson(rMap);
        await _local.saveAttendanceRecord(rec);
        return rec;
      }
    } catch (e) {
      AppLogger.debug('Remote getAttendanceForSessionAndLearner fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.getAttendanceForSessionAndLearner(
      sessionId: sessionId,
      learnerId: learnerId,
      tenantId: tenantId,
    );
  }

  @override
  Future<List<AttendanceRecord>> listAttendanceForSession({
    required String sessionId,
    String? tenantId,
  }) async {
    try {
      final query = tenantId != null ? '?tenantId=${Uri.encodeComponent(tenantId)}' : '';
      final res = await _apiClient.get('/api/v1/lms/attendance/sessions/${Uri.encodeComponent(sessionId)}/records$query');
      final dynamic listData = res['records'] ?? res['data'];
      if (listData is List) {
        final records = listData
            .map((r) => AttendanceRecord.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        for (final r in records) {
          await _local.saveAttendanceRecord(r);
        }
        return records;
      }
    } catch (e) {
      AppLogger.debug('Remote listAttendanceForSession fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.listAttendanceForSession(sessionId: sessionId, tenantId: tenantId);
  }

  @override
  Future<List<AttendanceRecord>> listAttendanceForLearner({
    required String learnerId,
    String? courseId,
    String? tenantId,
  }) async {
    try {
      final params = [
        'learnerId=${Uri.encodeComponent(learnerId)}',
        if (courseId != null) 'courseId=${Uri.encodeComponent(courseId)}',
        if (tenantId != null) 'tenantId=${Uri.encodeComponent(tenantId)}',
      ];
      final res = await _apiClient.get('/api/v1/lms/attendance/records?${params.join('&')}');
      final dynamic listData = res['records'] ?? res['data'];
      if (listData is List) {
        final records = listData
            .map((r) => AttendanceRecord.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        for (final r in records) {
          await _local.saveAttendanceRecord(r);
        }
        return records;
      }
    } catch (e) {
      AppLogger.debug('Remote listAttendanceForLearner fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.listAttendanceForLearner(
      learnerId: learnerId,
      courseId: courseId,
      tenantId: tenantId,
    );
  }

  @override
  Future<List<AttendanceRecord>> listAttendanceForCourse({
    required String courseId,
    String? tenantId,
  }) async {
    try {
      final params = [
        'courseId=${Uri.encodeComponent(courseId)}',
        if (tenantId != null) 'tenantId=${Uri.encodeComponent(tenantId)}',
      ];
      final res = await _apiClient.get('/api/v1/lms/attendance/records?${params.join('&')}');
      final dynamic listData = res['records'] ?? res['data'];
      if (listData is List) {
        final records = listData
            .map((r) => AttendanceRecord.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList();
        for (final r in records) {
          await _local.saveAttendanceRecord(r);
        }
        return records;
      }
    } catch (e) {
      AppLogger.debug('Remote listAttendanceForCourse fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.listAttendanceForCourse(courseId: courseId, tenantId: tenantId);
  }

  // ---------------------------------------------------------------------------
  // Intervention Signal Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveSignal(AcademicInterventionSignal signal) async {
    await _local.saveSignal(signal);
    try {
      await _apiClient.post('/api/v1/lms/attendance/signals', body: signal.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveSignal failed: $e', tag: 'HttpAttendanceRepo');
    }
  }

  @override
  Future<AcademicInterventionSignal?> getSignal(String signalId, {String? tenantId}) async {
    try {
      final query = tenantId != null ? '?tenantId=${Uri.encodeComponent(tenantId)}' : '';
      final res = await _apiClient.get('/api/v1/lms/attendance/signals/${Uri.encodeComponent(signalId)}$query');
      if (res.isNotEmpty && (res['signal'] != null || res['signalId'] != null)) {
        final sMap = (res['signal'] is Map)
            ? Map<String, dynamic>.from(res['signal'] as Map)
            : Map<String, dynamic>.from(res);
        final sig = AcademicInterventionSignal.fromJson(sMap);
        await _local.saveSignal(sig);
        return sig;
      }
    } catch (e) {
      AppLogger.debug('Remote getSignal fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.getSignal(signalId, tenantId: tenantId);
  }

  @override
  Future<List<AcademicInterventionSignal>> listSignals({
    String? tenantId,
    String? courseId,
    String? cohortId,
    String? learnerId,
    SignalStatus? status,
  }) async {
    try {
      final params = <String>[];
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      if (courseId != null) params.add('courseId=${Uri.encodeComponent(courseId)}');
      if (cohortId != null) params.add('cohortId=${Uri.encodeComponent(cohortId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (status != null) params.add('status=${Uri.encodeComponent(status.name)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/attendance/signals$query');
      final dynamic listData = res['signals'] ?? res['data'];
      if (listData is List) {
        final signals = listData
            .map((s) => AcademicInterventionSignal.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList();
        for (final s in signals) {
          await _local.saveSignal(s);
        }
        return signals;
      }
    } catch (e) {
      AppLogger.debug('Remote listSignals fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.listSignals(
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
  Future<void> saveAuditRecord(AttendanceAuditRecord record) async {
    await _local.saveAuditRecord(record);
    try {
      await _apiClient.post('/api/v1/lms/attendance/audit', body: record.toJson());
    } catch (e) {
      AppLogger.debug('Remote saveAuditRecord failed: $e', tag: 'HttpAttendanceRepo');
    }
  }

  @override
  Future<List<AttendanceAuditRecord>> listAuditRecords({
    String? sessionId,
    String? learnerId,
    String? courseId,
    String? tenantId,
  }) async {
    try {
      final params = <String>[];
      if (sessionId != null) params.add('sessionId=${Uri.encodeComponent(sessionId)}');
      if (learnerId != null) params.add('learnerId=${Uri.encodeComponent(learnerId)}');
      if (courseId != null) params.add('courseId=${Uri.encodeComponent(courseId)}');
      if (tenantId != null) params.add('tenantId=${Uri.encodeComponent(tenantId)}');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      final res = await _apiClient.get('/api/v1/lms/attendance/audit$query');
      final dynamic listData = res['audits'] ?? res['data'];
      if (listData is List) {
        return listData
            .map((a) => AttendanceAuditRecord.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList();
      }
    } catch (e) {
      AppLogger.debug('Remote listAuditRecords fallback to local: $e', tag: 'HttpAttendanceRepo');
    }
    return _local.listAuditRecords(
      sessionId: sessionId,
      learnerId: learnerId,
      courseId: courseId,
      tenantId: tenantId,
    );
  }

  // ---------------------------------------------------------------------------
  // Snapshots & Maintenance
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> exportSnapshot() => _local.exportSnapshot();

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) => _local.importSnapshot(snapshot);

  @override
  Future<void> clear() => _local.clear();
}
