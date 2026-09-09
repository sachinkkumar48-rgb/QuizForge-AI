/// Course Attendance & Academic Engagement Repository Contract (TITAN-KO-053.0 P53).
///
/// Abstract repository interface specifying storage, retrieval,
/// snapshot persistence, and audit logging for sessions, attendance records,
/// and academic intervention signals.
library;

import '../domain/entities/academic_intervention_signal.dart';
import '../domain/entities/attendance_audit_record.dart';
import '../domain/entities/attendance_record.dart';
import '../domain/entities/attendance_session.dart';

/// Base exception for attendance and academic engagement repository operations.
class AttendanceException implements Exception {
  final String message;
  final dynamic cause;
  AttendanceException(this.message, [this.cause]);
  @override
  String toString() => 'AttendanceException: $message';
}

/// Thrown when a requested attendance session, record, or signal is not found.
class AttendanceNotFoundException extends AttendanceException {
  AttendanceNotFoundException(super.message, [super.cause]);
  @override
  String toString() => 'AttendanceNotFoundException: $message';
}

/// Thrown when attendance data fails business rule validations.
class AttendanceValidationException extends AttendanceException {
  AttendanceValidationException(super.message, [super.cause]);
  @override
  String toString() => 'AttendanceValidationException: $message';
}

/// Thrown when unauthorized actors or cross-tenant operations are attempted.
class AttendanceSecurityException extends AttendanceException {
  AttendanceSecurityException(super.message, [super.cause]);
  @override
  String toString() => 'AttendanceSecurityException: $message';
}

/// Thrown when a duplicate attendance submission is attempted.
class DuplicateAttendanceException extends AttendanceException {
  DuplicateAttendanceException(super.message, [super.cause]);
  @override
  String toString() => 'DuplicateAttendanceException: $message';
}

/// Thrown when an illegal modification is attempted on finalized session attendance.
class SessionFinalizedException extends AttendanceException {
  SessionFinalizedException(super.message, [super.cause]);
  @override
  String toString() => 'SessionFinalizedException: $message';
}

/// Abstract contract for managing course sessions, attendance records, and intervention signals.
abstract class AttendanceRepository {
  // ---------------------------------------------------------------------------
  // Session Operations
  // ---------------------------------------------------------------------------
  Future<void> saveSession(AttendanceSession session);
  Future<AttendanceSession?> getSession(String sessionId, {String? tenantId});
  Future<List<AttendanceSession>> listSessionsForCourse({
    required String courseId,
    String? tenantId,
    AttendanceSessionStatus? status,
  });
  Future<List<AttendanceSession>> listSessionsForCohort({
    required String cohortId,
    String? tenantId,
    AttendanceSessionStatus? status,
  });
  Future<List<AttendanceSession>> listSessions({
    String? tenantId,
    String? courseId,
    String? cohortId,
    AttendanceSessionStatus? status,
  });

  // ---------------------------------------------------------------------------
  // Attendance Record Operations
  // ---------------------------------------------------------------------------
  Future<void> saveAttendanceRecord(AttendanceRecord record);
  Future<AttendanceRecord?> getAttendanceRecord(String attendanceId,
      {String? tenantId});
  Future<AttendanceRecord?> getAttendanceForSessionAndLearner({
    required String sessionId,
    required String learnerId,
    String? tenantId,
  });
  Future<List<AttendanceRecord>> listAttendanceForSession({
    required String sessionId,
    String? tenantId,
  });
  Future<List<AttendanceRecord>> listAttendanceForLearner({
    required String learnerId,
    String? courseId,
    String? tenantId,
  });
  Future<List<AttendanceRecord>> listAttendanceForCourse({
    required String courseId,
    String? tenantId,
  });

  // ---------------------------------------------------------------------------
  // Intervention Signal Operations
  // ---------------------------------------------------------------------------
  Future<void> saveSignal(AcademicInterventionSignal signal);
  Future<AcademicInterventionSignal?> getSignal(String signalId,
      {String? tenantId});
  Future<List<AcademicInterventionSignal>> listSignals({
    String? tenantId,
    String? courseId,
    String? cohortId,
    String? learnerId,
    SignalStatus? status,
  });

  // ---------------------------------------------------------------------------
  // Audit Trail Operations
  // ---------------------------------------------------------------------------
  Future<void> saveAuditRecord(AttendanceAuditRecord record);
  Future<List<AttendanceAuditRecord>> listAuditRecords({
    String? sessionId,
    String? learnerId,
    String? courseId,
    String? tenantId,
  });

  // ---------------------------------------------------------------------------
  // Persistence Snapshots & Maintenance
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> exportSnapshot();
  Future<void> importSnapshot(Map<String, dynamic> snapshot);
  Future<void> clear();
}
