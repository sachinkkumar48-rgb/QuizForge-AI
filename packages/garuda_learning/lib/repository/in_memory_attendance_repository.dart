/// In-Memory Course Attendance & Engagement Repository Implementation (TITAN-KO-053.0 P53).
///
/// Thread-safe in-memory store supporting snapshots, restart persistence,
/// and failure simulation for unit testing, offline-first execution, and sync.
library;

import '../domain/entities/academic_intervention_signal.dart';
import '../domain/entities/attendance_audit_record.dart';
import '../domain/entities/attendance_record.dart';
import '../domain/entities/attendance_session.dart';
import 'attendance_repository.dart';

class InMemoryAttendanceRepository implements AttendanceRepository {
  final Map<String, AttendanceSession> _sessions = {};
  final Map<String, AttendanceRecord> _records = {};
  final Map<String, AcademicInterventionSignal> _signals = {};
  final List<AttendanceAuditRecord> _auditRecords = [];

  bool _simulateFailure = false;

  void setSimulateFailure(bool simulate) {
    _simulateFailure = simulate;
  }

  void _checkFailure() {
    if (_simulateFailure) {
      throw AttendanceException('Simulated repository storage failure');
    }
  }

  // ---------------------------------------------------------------------------
  // Session Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveSession(AttendanceSession session) async {
    _checkFailure();
    _sessions[session.sessionId] = session;
  }

  @override
  Future<AttendanceSession?> getSession(String sessionId,
      {String? tenantId}) async {
    _checkFailure();
    final session = _sessions[sessionId];
    if (session == null) return null;
    if (tenantId != null && session.tenantId != tenantId) return null;
    return session;
  }

  @override
  Future<List<AttendanceSession>> listSessionsForCourse({
    required String courseId,
    String? tenantId,
    AttendanceSessionStatus? status,
  }) async {
    _checkFailure();
    return _sessions.values.where((s) {
      if (s.courseId != courseId) return false;
      if (tenantId != null && s.tenantId != tenantId) return false;
      if (status != null && s.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<AttendanceSession>> listSessionsForCohort({
    required String cohortId,
    String? tenantId,
    AttendanceSessionStatus? status,
  }) async {
    _checkFailure();
    return _sessions.values.where((s) {
      if (s.cohortId != cohortId) return false;
      if (tenantId != null && s.tenantId != tenantId) return false;
      if (status != null && s.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<AttendanceSession>> listSessions({
    String? tenantId,
    String? courseId,
    String? cohortId,
    AttendanceSessionStatus? status,
  }) async {
    _checkFailure();
    return _sessions.values.where((s) {
      if (tenantId != null && s.tenantId != tenantId) return false;
      if (courseId != null && s.courseId != courseId) return false;
      if (cohortId != null && s.cohortId != cohortId) return false;
      if (status != null && s.status != status) return false;
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Attendance Record Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAttendanceRecord(AttendanceRecord record) async {
    _checkFailure();
    _records[record.attendanceId] = record;
  }

  @override
  Future<AttendanceRecord?> getAttendanceRecord(String attendanceId,
      {String? tenantId}) async {
    _checkFailure();
    final record = _records[attendanceId];
    if (record == null) return null;
    if (tenantId != null && record.tenantId != tenantId) return null;
    return record;
  }

  @override
  Future<AttendanceRecord?> getAttendanceForSessionAndLearner({
    required String sessionId,
    required String learnerId,
    String? tenantId,
  }) async {
    _checkFailure();
    for (final r in _records.values) {
      if (r.sessionId == sessionId && r.learnerId == learnerId) {
        if (tenantId == null || r.tenantId == tenantId) {
          return r;
        }
      }
    }
    return null;
  }

  @override
  Future<List<AttendanceRecord>> listAttendanceForSession({
    required String sessionId,
    String? tenantId,
  }) async {
    _checkFailure();
    return _records.values.where((r) {
      if (r.sessionId != sessionId) return false;
      if (tenantId != null && r.tenantId != tenantId) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<AttendanceRecord>> listAttendanceForLearner({
    required String learnerId,
    String? courseId,
    String? tenantId,
  }) async {
    _checkFailure();
    return _records.values.where((r) {
      if (r.learnerId != learnerId) return false;
      if (courseId != null && r.courseId != courseId) return false;
      if (tenantId != null && r.tenantId != tenantId) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<AttendanceRecord>> listAttendanceForCourse({
    required String courseId,
    String? tenantId,
  }) async {
    _checkFailure();
    return _records.values.where((r) {
      if (r.courseId != courseId) return false;
      if (tenantId != null && r.tenantId != tenantId) return false;
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Intervention Signal Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveSignal(AcademicInterventionSignal signal) async {
    _checkFailure();
    _signals[signal.signalId] = signal;
  }

  @override
  Future<AcademicInterventionSignal?> getSignal(String signalId,
      {String? tenantId}) async {
    _checkFailure();
    final signal = _signals[signalId];
    if (signal == null) return null;
    if (tenantId != null && signal.tenantId != tenantId) return null;
    return signal;
  }

  @override
  Future<List<AcademicInterventionSignal>> listSignals({
    String? tenantId,
    String? courseId,
    String? cohortId,
    String? learnerId,
    SignalStatus? status,
  }) async {
    _checkFailure();
    return _signals.values.where((s) {
      if (tenantId != null && s.tenantId != tenantId) return false;
      if (courseId != null && s.courseId != courseId) return false;
      if (cohortId != null && s.cohortId != cohortId) return false;
      if (learnerId != null && s.learnerId != learnerId) return false;
      if (status != null && s.status != status) return false;
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Audit Trail Operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveAuditRecord(AttendanceAuditRecord record) async {
    _checkFailure();
    _auditRecords.add(record);
  }

  @override
  Future<List<AttendanceAuditRecord>> listAuditRecords({
    String? sessionId,
    String? learnerId,
    String? courseId,
    String? tenantId,
  }) async {
    _checkFailure();
    final results = _auditRecords.where((a) {
      if (sessionId != null && a.sessionId != sessionId) return false;
      if (learnerId != null && a.learnerId != learnerId) return false;
      if (courseId != null && a.courseId != courseId) return false;
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
      'sessions':
          _sessions.values.map((s) => s.toJson()).toList(growable: false),
      'records': _records.values.map((r) => r.toJson()).toList(growable: false),
      'signals':
          _signals.values.map((sig) => sig.toJson()).toList(growable: false),
      'auditRecords':
          _auditRecords.map((a) => a.toJson()).toList(growable: false),
    };
  }

  @override
  Future<void> importSnapshot(Map<String, dynamic> snapshot) async {
    _checkFailure();
    _sessions.clear();
    _records.clear();
    _signals.clear();
    _auditRecords.clear();

    final sessionsRaw = snapshot['sessions'] as List<dynamic>? ?? [];
    for (final raw in sessionsRaw) {
      final s = AttendanceSession.fromJson(raw as Map<String, dynamic>);
      _sessions[s.sessionId] = s;
    }

    final recordsRaw = snapshot['records'] as List<dynamic>? ?? [];
    for (final raw in recordsRaw) {
      final r = AttendanceRecord.fromJson(raw as Map<String, dynamic>);
      _records[r.attendanceId] = r;
    }

    final signalsRaw = snapshot['signals'] as List<dynamic>? ?? [];
    for (final raw in signalsRaw) {
      final sig =
          AcademicInterventionSignal.fromJson(raw as Map<String, dynamic>);
      _signals[sig.signalId] = sig;
    }

    final auditRaw = snapshot['auditRecords'] as List<dynamic>? ?? [];
    for (final raw in auditRaw) {
      final a = AttendanceAuditRecord.fromJson(raw as Map<String, dynamic>);
      _auditRecords.add(a);
    }
  }

  @override
  Future<void> clear() async {
    _sessions.clear();
    _records.clear();
    _signals.clear();
    _auditRecords.clear();
  }
}
