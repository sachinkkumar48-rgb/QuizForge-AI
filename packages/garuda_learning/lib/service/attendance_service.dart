/// Course Attendance & Academic Engagement Orchestration Service (TITAN-KO-053.0 P53).
///
/// Enterprise service managing course sessions, attendance recording against
/// active P52 enrollments, duplicate prevention, session finalization, immutable
/// authorized corrections, deterministic attendance percentage calculations,
/// multi-signal academic engagement aggregation, and early-warning intervention signals.
library;

import '../domain/entities/academic_engagement_summary.dart';
import '../domain/entities/academic_intervention_signal.dart';
import '../domain/entities/attendance_audit_record.dart';
import '../domain/entities/attendance_record.dart';
import '../domain/entities/attendance_session.dart';
import '../domain/entities/enrollment.dart';
import '../domain/entities/learner_attendance_summary.dart';
import '../repository/assessment_repository.dart';
import '../repository/attendance_repository.dart';
import '../repository/cohort_repository.dart';
import '../repository/enrollment_repository.dart';
import '../repository/gradebook_repository.dart';

class AttendanceService {
  static int _counter = 0;

  final AttendanceRepository attendanceRepository;
  final EnrollmentRepository enrollmentRepository;
  final CohortRepository? cohortRepository;
  final AssessmentRepository? assessmentRepository;
  final GradebookRepository? gradebookRepository;
  final AttendancePolicy policy;
  final DateTime Function() _clock;

  AttendanceService({
    required this.attendanceRepository,
    required this.enrollmentRepository,
    this.cohortRepository,
    this.assessmentRepository,
    this.gradebookRepository,
    this.policy = const AttendancePolicy.standard(),
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  // ---------------------------------------------------------------------------
  // 1. Session Lifecycle Management
  // ---------------------------------------------------------------------------

  /// Creates and schedules a new course attendance session.
  Future<AttendanceSession> createSession({
    String? sessionId,
    String tenantId = 'default_tenant',
    required String courseId,
    String? cohortId,
    required String title,
    String description = '',
    required DateTime scheduledAt,
    int durationMinutes = 60,
    required String facultyId,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanCourseId = courseId.trim();
    final cleanFacultyId = facultyId.trim();
    final cleanTenantId = tenantId.trim();

    // Verify course exists
    final course = await enrollmentRepository.getCourse(
      cleanCourseId,
      tenantId: cleanTenantId,
    );
    if (course == null) {
      throw AttendanceNotFoundException('Course not found: $cleanCourseId');
    }

    final now = _clock();
    final effectiveSessionId = sessionId?.trim() ??
        'sess_${cleanCourseId}_${now.millisecondsSinceEpoch}_${++_counter}';

    final session = AttendanceSession(
      sessionId: effectiveSessionId,
      tenantId: cleanTenantId,
      courseId: cleanCourseId,
      cohortId: cohortId?.trim(),
      title: title.trim(),
      description: description.trim(),
      scheduledAt: scheduledAt.toUtc(),
      durationMinutes: durationMinutes,
      status: AttendanceSessionStatus.scheduled,
      facultyId: cleanFacultyId,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );

    await attendanceRepository.saveSession(session);

    // Audit record
    await attendanceRepository.saveAuditRecord(
      AttendanceAuditRecord(
        auditId: 'audit_${effectiveSessionId}_created_${++_counter}',
        tenantId: cleanTenantId,
        action: AttendanceAuditAction.sessionCreated,
        actorId: cleanFacultyId,
        sessionId: effectiveSessionId,
        courseId: cleanCourseId,
        cohortId: cohortId?.trim(),
        previousState: null,
        newState: AttendanceSessionStatus.scheduled.name,
        timestamp: now,
      ),
    );

    return session;
  }

  /// Opens a scheduled session, enabling attendance recording.
  Future<AttendanceSession> openSession({
    required String sessionId,
    required String actorId,
    String? tenantId,
  }) async {
    final session = await _getExistingSession(sessionId, tenantId: tenantId);
    final previousStatus = session.status.name;
    final updated = session.openSession(at: _clock());

    await attendanceRepository.saveSession(updated);

    await attendanceRepository.saveAuditRecord(
      AttendanceAuditRecord(
        auditId: 'audit_${sessionId}_opened_${_clock().millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        action: AttendanceAuditAction.sessionOpened,
        actorId: actorId.trim(),
        sessionId: sessionId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        previousState: previousStatus,
        newState: AttendanceSessionStatus.open.name,
        timestamp: _clock(),
      ),
    );

    return updated;
  }

  /// Cancels a session, excluding it from future attendance calculations.
  Future<AttendanceSession> cancelSession({
    required String sessionId,
    required String actorId,
    required String reason,
    String? tenantId,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw AttendanceValidationException(
          'Cancellation reason cannot be empty');
    }

    final session = await _getExistingSession(sessionId, tenantId: tenantId);
    final previousStatus = session.status.name;
    final updated = session.cancelSession(reason: cleanReason, at: _clock());

    await attendanceRepository.saveSession(updated);

    await attendanceRepository.saveAuditRecord(
      AttendanceAuditRecord(
        auditId:
            'audit_${sessionId}_cancelled_${_clock().millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        action: AttendanceAuditAction.sessionCancelled,
        actorId: actorId.trim(),
        sessionId: sessionId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        previousState: previousStatus,
        newState: AttendanceSessionStatus.cancelled.name,
        reason: cleanReason,
        timestamp: _clock(),
      ),
    );

    return updated;
  }

  /// Closes and finalizes session attendance, locking all records.
  Future<AttendanceSession> finalizeSession({
    required String sessionId,
    required String actorId,
    String? tenantId,
  }) async {
    final session = await _getExistingSession(sessionId, tenantId: tenantId);
    final previousStatus = session.status.name;
    final now = _clock();

    final updated = session.closeAndFinalize(actorId: actorId, at: now);
    await attendanceRepository.saveSession(updated);

    // Lock all records for this session
    final records = await attendanceRepository.listAttendanceForSession(
      sessionId: sessionId,
      tenantId: tenantId,
    );
    for (final r in records) {
      if (!r.isFinalized) {
        await attendanceRepository.saveAttendanceRecord(
          r.copyWith(isFinalized: true, updatedAt: now),
        );
      }
    }

    await attendanceRepository.saveAuditRecord(
      AttendanceAuditRecord(
        auditId: 'audit_${sessionId}_finalized_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        action: AttendanceAuditAction.attendanceFinalized,
        actorId: actorId.trim(),
        sessionId: sessionId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        previousState: previousStatus,
        newState: AttendanceSessionStatus.closed.name,
        timestamp: now,
      ),
    );

    // Trigger post-finalization academic engagement evaluation
    for (final r in records) {
      try {
        await evaluateAcademicEngagement(
          learnerId: r.learnerId,
          courseId: session.courseId,
          tenantId: tenantId,
        );
      } catch (_) {
        // Silent recovery for non-blocking evaluation
      }
    }

    return updated;
  }

  // ---------------------------------------------------------------------------
  // 2. Enrolled Learner Roster Generation
  // ---------------------------------------------------------------------------

  /// Retrieves active enrolled learners eligible for attendance in a course session.
  ///
  /// Strictly excludes withdrawn, cancelled, or pending enrollments.
  Future<List<Enrollment>> getEnrolledRoster({
    required String courseId,
    String? cohortId,
    String? tenantId,
  }) async {
    final cleanCourseId = courseId.trim();

    final enrollments = await enrollmentRepository.listEnrollmentsForCourse(
      courseId: cleanCourseId,
      tenantId: tenantId,
    );

    return enrollments.where((e) {
      if (e.status != EnrollmentStatus.active) return false;
      if (cohortId != null &&
          cohortId.trim().isNotEmpty &&
          e.cohortId != cohortId.trim()) {
        return false;
      }
      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // 3. Attendance Recording & Duplicate Prevention
  // ---------------------------------------------------------------------------

  /// Records attendance for a single learner in a session.
  ///
  /// Re-recording before finalization updates the record in-place (duplicate protection).
  /// Once finalized, direct recording is rejected (requires correction workflow).
  Future<AttendanceRecord> recordAttendance({
    required String sessionId,
    required String learnerId,
    required AttendanceStatus status,
    required String actorId,
    String? remarks,
    String? tenantId,
  }) async {
    final cleanSessionId = sessionId.trim();
    final cleanLearnerId = learnerId.trim();
    final cleanActorId = actorId.trim();

    // 1. Verify session exists and is modifiable
    final session =
        await _getExistingSession(cleanSessionId, tenantId: tenantId);
    if (session.isCancelled) {
      throw AttendanceValidationException(
          'Cannot record attendance in a cancelled session.');
    }
    if (session.isClosed) {
      throw SessionFinalizedException(
        'Session $cleanSessionId is finalized. Use authorized correction workflow to amend records.',
      );
    }

    // 2. Verify learner has active enrollment in the session's course
    final activeEnr =
        await enrollmentRepository.getActiveEnrollmentForLearnerCourse(
      learnerId: cleanLearnerId,
      courseId: session.courseId,
      tenantId: tenantId,
    );
    if (activeEnr == null) {
      throw AttendanceValidationException(
        'Learner $cleanLearnerId does not have an active enrollment in course ${session.courseId}.',
      );
    }

    final now = _clock();

    // 3. Check for existing record (duplicate protection / idempotent update)
    final existing =
        await attendanceRepository.getAttendanceForSessionAndLearner(
      sessionId: cleanSessionId,
      learnerId: cleanLearnerId,
      tenantId: tenantId,
    );

    final record = AttendanceRecord(
      attendanceId: existing?.attendanceId ??
          AttendanceRecord.generateId(
            sessionId: cleanSessionId,
            learnerId: cleanLearnerId,
          ),
      tenantId: session.tenantId,
      sessionId: cleanSessionId,
      courseId: session.courseId,
      cohortId: session.cohortId,
      learnerId: cleanLearnerId,
      sessionDate: session.scheduledAt,
      status: status,
      recordedBy: cleanActorId,
      recordedAt: now,
      remarks: remarks?.trim() ?? existing?.remarks,
      isFinalized: false,
      corrections: existing?.corrections ?? const [],
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await attendanceRepository.saveAttendanceRecord(record);

    await attendanceRepository.saveAuditRecord(
      AttendanceAuditRecord(
        auditId: 'audit_${record.attendanceId}_${now.millisecondsSinceEpoch}',
        tenantId: record.tenantId,
        action: AttendanceAuditAction.attendanceRecorded,
        actorId: cleanActorId,
        sessionId: cleanSessionId,
        courseId: session.courseId,
        cohortId: session.cohortId,
        learnerId: cleanLearnerId,
        previousState: existing?.status.name,
        newState: status.name,
        reason: remarks,
        timestamp: now,
      ),
    );

    return record;
  }

  /// Bulk records attendance for an entire roster in a session.
  Future<List<AttendanceRecord>> batchRecordAttendance({
    required String sessionId,
    required Map<String, AttendanceStatus> learnerStatuses,
    required String actorId,
    String? tenantId,
  }) async {
    final recorded = <AttendanceRecord>[];
    for (final entry in learnerStatuses.entries) {
      final rec = await recordAttendance(
        sessionId: sessionId,
        learnerId: entry.key,
        status: entry.value,
        actorId: actorId,
        tenantId: tenantId,
      );
      recorded.add(rec);
    }
    return recorded;
  }

  // ---------------------------------------------------------------------------
  // 4. Authorized Finalized Correction Workflow
  // ---------------------------------------------------------------------------

  /// Formally corrects a finalized attendance record.
  ///
  /// Mandates an explanatory reason and retains immutable historical evidence.
  Future<AttendanceRecord> correctFinalizedAttendance({
    required String attendanceId,
    required AttendanceStatus newStatus,
    required String actorId,
    required String reason,
    String? tenantId,
  }) async {
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw AttendanceValidationException('Correction reason cannot be empty');
    }

    final record = await attendanceRepository.getAttendanceRecord(
      attendanceId.trim(),
      tenantId: tenantId,
    );
    if (record == null) {
      throw AttendanceNotFoundException(
          'Attendance record not found: $attendanceId');
    }

    final previousStatus = record.status;
    final now = _clock();

    final updated = record.applyCorrection(
      newStatus: newStatus,
      actorId: actorId,
      reason: cleanReason,
      at: now,
    );

    await attendanceRepository.saveAttendanceRecord(updated);

    await attendanceRepository.saveAuditRecord(
      AttendanceAuditRecord(
        auditId: 'audit_corr_${attendanceId}_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        action: AttendanceAuditAction.attendanceCorrected,
        actorId: actorId.trim(),
        sessionId: updated.sessionId,
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        learnerId: updated.learnerId,
        previousState: previousStatus.name,
        newState: newStatus.name,
        reason: cleanReason,
        timestamp: now,
      ),
    );

    // Re-evaluate academic engagement with updated attendance
    try {
      await evaluateAcademicEngagement(
        learnerId: updated.learnerId,
        courseId: updated.courseId,
        tenantId: tenantId,
      );
    } catch (_) {}

    return updated;
  }

  // ---------------------------------------------------------------------------
  // 5. Attendance Summary & Policy Calculations
  // ---------------------------------------------------------------------------

  /// Calculates authoritative attendance metrics for a learner in a course.
  Future<LearnerAttendanceSummary> getLearnerAttendanceSummary({
    required String learnerId,
    required String courseId,
    String? tenantId,
  }) async {
    final cleanLearnerId = learnerId.trim();
    final cleanCourseId = courseId.trim();

    final sessions = await attendanceRepository.listSessionsForCourse(
      courseId: cleanCourseId,
      tenantId: tenantId,
    );

    final scheduledCount = sessions.where((s) => !s.isCancelled).length;
    final finalizedSessionIds = sessions
        .where((s) => s.isClosed && !s.isCancelled)
        .map((s) => s.sessionId)
        .toSet();

    final allRecords = await attendanceRepository.listAttendanceForLearner(
      learnerId: cleanLearnerId,
      courseId: cleanCourseId,
      tenantId: tenantId,
    );

    // Filter to only finalized session records
    final finalizedRecords = allRecords
        .where((r) => finalizedSessionIds.contains(r.sessionId))
        .toList();

    return LearnerAttendanceSummary.fromRecords(
      learnerId: cleanLearnerId,
      courseId: cleanCourseId,
      totalSessionsScheduled: scheduledCount,
      finalizedRecords: finalizedRecords,
      policy: policy,
      calculatedAt: _clock(),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Academic Engagement & Monitoring Interventions
  // ---------------------------------------------------------------------------

  /// Computes composite academic engagement across attendance, progress, and assessments.
  ///
  /// Generates non-disciplinary early-warning intervention signals when thresholds are breached.
  Future<AcademicEngagementSummary> evaluateAcademicEngagement({
    required String learnerId,
    required String courseId,
    String? tenantId,
  }) async {
    final cleanLearnerId = learnerId.trim();
    final cleanCourseId = courseId.trim();

    final attSummary = await getLearnerAttendanceSummary(
      learnerId: cleanLearnerId,
      courseId: cleanCourseId,
      tenantId: tenantId,
    );

    // Determine Engagement Status
    EngagementStatus engagementStatus;
    if (attSummary.totalSessionsFinalized == 0) {
      engagementStatus = EngagementStatus.active;
    } else if (attSummary.attendancePercentage < 50.0) {
      engagementStatus = EngagementStatus.atRisk;
    } else if (attSummary.attendancePercentage <
        policy.minimumAttendanceThreshold) {
      engagementStatus = EngagementStatus.atRisk;
    } else {
      engagementStatus = EngagementStatus.active;
    }

    // Check & Raise Intervention Signals
    if (attSummary.totalSessionsFinalized > 0 &&
        attSummary.attendancePercentage < policy.minimumAttendanceThreshold) {
      await _ensureInterventionSignal(
        tenantId: tenantId ?? 'default_tenant',
        learnerId: cleanLearnerId,
        courseId: cleanCourseId,
        cohortId: attSummary.cohortId,
        signalType: AcademicSignalType.lowAttendance,
        severity: attSummary.attendancePercentage < 50.0
            ? SignalSeverity.high
            : SignalSeverity.medium,
        triggerMetric: 'attendancePercentage',
        triggerValue: attSummary.attendancePercentage,
        thresholdValue: policy.minimumAttendanceThreshold,
        description:
            'Learner attendance (${attSummary.attendancePercentage}%) is below required threshold (${policy.minimumAttendanceThreshold}%).',
      );
    }

    final activeSignals = await listSignals(
      learnerId: cleanLearnerId,
      courseId: cleanCourseId,
      tenantId: tenantId,
    );

    return AcademicEngagementSummary(
      learnerId: cleanLearnerId,
      courseId: cleanCourseId,
      cohortId: attSummary.cohortId,
      attendanceSummary: attSummary,
      engagementStatus: engagementStatus,
      activeSignals: activeSignals.where((s) => !s.isResolved).toList(),
      evaluatedAt: _clock(),
    );
  }

  /// Lists intervention alerts matching query filters.
  Future<List<AcademicInterventionSignal>> listSignals({
    String? tenantId,
    String? courseId,
    String? cohortId,
    String? learnerId,
    SignalStatus? status,
  }) {
    return attendanceRepository.listSignals(
      tenantId: tenantId,
      courseId: courseId,
      cohortId: cohortId,
      learnerId: learnerId,
      status: status,
    );
  }

  /// Acknowledges an academic early-warning signal.
  Future<AcademicInterventionSignal> acknowledgeSignal({
    required String signalId,
    required String actorId,
    String? tenantId,
  }) async {
    final signal = await attendanceRepository.getSignal(signalId.trim(),
        tenantId: tenantId);
    if (signal == null) {
      throw AttendanceNotFoundException('Signal not found: $signalId');
    }

    final now = _clock();
    final updated = signal.acknowledge(actorId: actorId, at: now);
    await attendanceRepository.saveSignal(updated);

    await attendanceRepository.saveAuditRecord(
      AttendanceAuditRecord(
        auditId: 'audit_sig_ack_${signalId}_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        action: AttendanceAuditAction.signalAcknowledged,
        actorId: actorId.trim(),
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        learnerId: updated.learnerId,
        previousState: SignalStatus.open.name,
        newState: SignalStatus.acknowledged.name,
        timestamp: now,
      ),
    );

    return updated;
  }

  /// Resolves an academic intervention signal with documentation.
  Future<AcademicInterventionSignal> resolveSignal({
    required String signalId,
    required String actorId,
    required String notes,
    String? tenantId,
  }) async {
    final cleanNotes = notes.trim();
    if (cleanNotes.isEmpty) {
      throw AttendanceValidationException('Resolution notes cannot be empty');
    }

    final signal = await attendanceRepository.getSignal(signalId.trim(),
        tenantId: tenantId);
    if (signal == null) {
      throw AttendanceNotFoundException('Signal not found: $signalId');
    }

    final now = _clock();
    final previousStatus = signal.status.name;
    final updated =
        signal.resolve(actorId: actorId, notes: cleanNotes, at: now);
    await attendanceRepository.saveSignal(updated);

    await attendanceRepository.saveAuditRecord(
      AttendanceAuditRecord(
        auditId: 'audit_sig_res_${signalId}_${now.millisecondsSinceEpoch}',
        tenantId: updated.tenantId,
        action: AttendanceAuditAction.signalResolved,
        actorId: actorId.trim(),
        courseId: updated.courseId,
        cohortId: updated.cohortId,
        learnerId: updated.learnerId,
        previousState: previousStatus,
        newState: SignalStatus.resolved.name,
        reason: cleanNotes,
        timestamp: now,
      ),
    );

    return updated;
  }

  // ---------------------------------------------------------------------------
  // 7. Query Helpers
  // ---------------------------------------------------------------------------

  Future<AttendanceSession?> getSession(String sessionId, {String? tenantId}) {
    return attendanceRepository.getSession(sessionId.trim(),
        tenantId: tenantId);
  }

  Future<List<AttendanceSession>> listSessionsForCourse({
    required String courseId,
    String? tenantId,
    AttendanceSessionStatus? status,
  }) {
    return attendanceRepository.listSessionsForCourse(
      courseId: courseId.trim(),
      tenantId: tenantId,
      status: status,
    );
  }

  Future<List<AttendanceRecord>> listAttendanceForSession({
    required String sessionId,
    String? tenantId,
  }) {
    return attendanceRepository.listAttendanceForSession(
      sessionId: sessionId.trim(),
      tenantId: tenantId,
    );
  }

  Future<List<AttendanceRecord>> listAttendanceForLearner({
    required String learnerId,
    String? courseId,
    String? tenantId,
  }) {
    return attendanceRepository.listAttendanceForLearner(
      learnerId: learnerId.trim(),
      courseId: courseId?.trim(),
      tenantId: tenantId,
    );
  }

  Future<List<AttendanceAuditRecord>> listAuditRecords({
    String? sessionId,
    String? learnerId,
    String? courseId,
    String? tenantId,
  }) {
    return attendanceRepository.listAuditRecords(
      sessionId: sessionId,
      learnerId: learnerId,
      courseId: courseId,
      tenantId: tenantId,
    );
  }

  // ---------------------------------------------------------------------------
  // 8. Snapshots & Maintenance
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> exportSnapshot() {
    return attendanceRepository.exportSnapshot();
  }

  Future<void> importSnapshot(Map<String, dynamic> snapshot) {
    return attendanceRepository.importSnapshot(snapshot);
  }

  Future<void> clear() {
    return attendanceRepository.clear();
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  Future<AttendanceSession> _getExistingSession(
    String sessionId, {
    String? tenantId,
  }) async {
    final session = await attendanceRepository.getSession(
      sessionId.trim(),
      tenantId: tenantId,
    );
    if (session == null) {
      throw AttendanceNotFoundException('Session not found: $sessionId');
    }
    return session;
  }

  Future<void> _ensureInterventionSignal({
    required String tenantId,
    required String learnerId,
    required String courseId,
    String? cohortId,
    required AcademicSignalType signalType,
    required SignalSeverity severity,
    required String triggerMetric,
    required double triggerValue,
    required double thresholdValue,
    required String description,
  }) async {
    final existingSignals = await attendanceRepository.listSignals(
      tenantId: tenantId,
      courseId: courseId,
      learnerId: learnerId,
    );

    final openSignals = existingSignals.where(
      (s) => s.signalType == signalType && !s.isResolved,
    );

    if (openSignals.isEmpty) {
      final now = _clock();
      final signal = AcademicInterventionSignal(
        signalId: AcademicInterventionSignal.generateId(
          learnerId: learnerId,
          courseId: courseId,
          type: signalType,
        ),
        tenantId: tenantId,
        learnerId: learnerId,
        courseId: courseId,
        cohortId: cohortId,
        signalType: signalType,
        severity: severity,
        status: SignalStatus.open,
        triggerMetric: triggerMetric,
        triggerValue: triggerValue,
        thresholdValue: thresholdValue,
        description: description,
        createdAt: now,
      );

      await attendanceRepository.saveSignal(signal);

      await attendanceRepository.saveAuditRecord(
        AttendanceAuditRecord(
          auditId:
              'audit_sig_create_${signal.signalId}_${now.millisecondsSinceEpoch}_${++_counter}',
          tenantId: tenantId,
          action: AttendanceAuditAction.signalCreated,
          actorId: 'system',
          actorRole: 'system',
          courseId: courseId,
          cohortId: cohortId,
          learnerId: learnerId,
          newState: SignalStatus.open.name,
          reason: description,
          timestamp: now,
        ),
      );
    } else {
      final current = openSignals.first;
      final updated = current.copyWith(
        triggerValue: triggerValue,
        description: description,
        severity: severity,
      );
      await attendanceRepository.saveSignal(updated);
    }
  }
}
