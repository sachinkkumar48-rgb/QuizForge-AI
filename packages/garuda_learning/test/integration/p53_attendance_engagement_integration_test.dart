/// P53 Attendance & Academic Engagement Acceptance Integration Test (TITAN-KO-053.0).
///
/// Complete end-to-end integration scenario verifying the full institutional
/// attendance and monitoring operational lifecycle:
/// ENROLLMENT -> SESSION SCHEDULING -> ROSTER GATING -> ATTENDANCE RECORDING ->
/// SESSION CLOSURE & FINALIZATION -> LOCKOUT & CORRECTION -> ATTENDANCE SUMMARY ->
/// ACADEMIC ENGAGEMENT MONITORING -> INTERVENTION ALERT -> ACKNOWLEDGE & RESOLVE ->
/// PERSISTENCE SNAPSHOT & RESTART RECOVERY -> MULTI-TENANT ISOLATION
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 10, 9, 0, 0);

  late InMemoryAttendanceRepository attRepo;
  late InMemoryEnrollmentRepository enrRepo;
  late InMemoryCohortRepository cohortRepo;
  late EnrollmentService enrService;
  late AttendanceService attService;

  setUp(() {
    attRepo = InMemoryAttendanceRepository();
    enrRepo = InMemoryEnrollmentRepository();
    cohortRepo = InMemoryCohortRepository();

    enrService = EnrollmentService(
      enrollmentRepository: enrRepo,
      cohortRepository: cohortRepo,
      clock: () => baseTime,
    );

    attService = AttendanceService(
      attendanceRepository: attRepo,
      enrollmentRepository: enrRepo,
      cohortRepository: cohortRepo,
      clock: () => baseTime,
    );
  });

  test(
      'Section 20: Complete Institutional Attendance & Academic Engagement Acceptance Scenario',
      () async {
    const tenantId = 'titan_institution_main';
    const facultyId = 'faculty_prof_deshmukh';
    const courseId = 'course_crim_201';
    const cohortId = 'cohort_criminal_law_2026';

    const learnerArjun = 'learner_arjun';
    const learnerPriya = 'learner_priya';
    const learnerKavita = 'learner_kavita';
    const learnerWithdrawn = 'learner_withdrawn';

    // -------------------------------------------------------------------------
    // 1. Establish Course & Cohort
    // -------------------------------------------------------------------------
    final course = await enrService.createCourse(
      courseId: courseId,
      title: 'Advanced Criminal Jurisprudence',
      examId: 'clat_pg_2026',
      tenantId: tenantId,
      facultyId: facultyId,
      cohortIds: [cohortId],
    );
    expect(course.courseId, equals(courseId));

    await cohortRepo.saveCohort(
      Cohort(
        cohortId: cohortId,
        tenantId: tenantId,
        name: 'Criminal Law Specialization 2026',
        examId: 'clat_pg_2026',
        primaryFacultyId: facultyId,
        learnerIds: {
          learnerArjun,
          learnerPriya,
          learnerKavita,
          learnerWithdrawn
        },
      ),
    );

    // -------------------------------------------------------------------------
    // 2. Authoritative Enrollment Roster Gating
    // -------------------------------------------------------------------------
    await enrService.registerLearner(
      learnerId: learnerArjun,
      courseId: courseId,
      cohortId: cohortId,
      tenantId: tenantId,
      actorId: facultyId,
      autoActivate: true,
    );
    await enrService.registerLearner(
      learnerId: learnerPriya,
      courseId: courseId,
      cohortId: cohortId,
      tenantId: tenantId,
      actorId: facultyId,
      autoActivate: true,
    );
    await enrService.registerLearner(
      learnerId: learnerKavita,
      courseId: courseId,
      cohortId: cohortId,
      tenantId: tenantId,
      actorId: facultyId,
      autoActivate: true,
    );

    // Register and then withdraw learnerWithdrawn
    final withdrawnEnr = await enrService.registerLearner(
      learnerId: learnerWithdrawn,
      courseId: courseId,
      cohortId: cohortId,
      tenantId: tenantId,
      actorId: facultyId,
      autoActivate: true,
    );
    await enrService.withdrawLearner(
      enrollmentId: withdrawnEnr.enrollmentId,
      actorId: facultyId,
      reason: 'Transferred to another program',
      tenantId: tenantId,
    );

    // Verify roster only returns active learners
    final activeRoster = await attService.getEnrolledRoster(
      courseId: courseId,
      cohortId: cohortId,
      tenantId: tenantId,
    );
    expect(activeRoster.length, equals(3));
    expect(activeRoster.map((e) => e.learnerId),
        containsAll([learnerArjun, learnerPriya, learnerKavita]));
    expect(activeRoster.map((e) => e.learnerId),
        isNot(contains(learnerWithdrawn)));

    // -------------------------------------------------------------------------
    // 3. Session 1 Lifecycle & Attendance Recording
    // -------------------------------------------------------------------------
    final session1 = await attService.createSession(
      sessionId: 'sess_crim_01',
      tenantId: tenantId,
      courseId: courseId,
      cohortId: cohortId,
      title: 'Session 1: Mens Rea & General Exceptions',
      scheduledAt: baseTime,
      facultyId: facultyId,
    );
    expect(session1.isScheduled, isTrue);

    // Non-enrolled learner cannot be recorded
    expect(
      () => attService.recordAttendance(
        sessionId: session1.sessionId,
        learnerId: 'learner_unknown_unregistered',
        status: AttendanceStatus.present,
        actorId: facultyId,
        tenantId: tenantId,
      ),
      throwsA(isA<AttendanceValidationException>()),
    );

    // Open session
    final openedSession1 = await attService.openSession(
      sessionId: session1.sessionId,
      actorId: facultyId,
      tenantId: tenantId,
    );
    expect(openedSession1.isOpen, isTrue);

    // Record attendance with duplicate prevention / update-in-place
    await attService.recordAttendance(
      sessionId: session1.sessionId,
      learnerId: learnerArjun,
      status: AttendanceStatus.present,
      actorId: facultyId,
      tenantId: tenantId,
    );

    // First mark Priya as present, then update to late
    await attService.recordAttendance(
      sessionId: session1.sessionId,
      learnerId: learnerPriya,
      status: AttendanceStatus.present,
      actorId: facultyId,
      tenantId: tenantId,
    );
    await attService.recordAttendance(
      sessionId: session1.sessionId,
      learnerId: learnerPriya,
      status: AttendanceStatus.late,
      remarks: 'Arrived 15 minutes late due to traffic',
      actorId: facultyId,
      tenantId: tenantId,
    );

    // Mark Kavita as absent
    await attService.recordAttendance(
      sessionId: session1.sessionId,
      learnerId: learnerKavita,
      status: AttendanceStatus.absent,
      actorId: facultyId,
      tenantId: tenantId,
    );

    // Verify session attendance records count
    final s1Records = await attRepo.listAttendanceForSession(
      sessionId: session1.sessionId,
      tenantId: tenantId,
    );
    expect(s1Records.length, equals(3));
    final priyaS1Rec = s1Records.firstWhere((r) => r.learnerId == learnerPriya);
    expect(priyaS1Rec.status, equals(AttendanceStatus.late));
    expect(
        priyaS1Rec.remarks, equals('Arrived 15 minutes late due to traffic'));

    // Finalize Session 1
    final finalizedS1 = await attService.finalizeSession(
      sessionId: session1.sessionId,
      actorId: facultyId,
      tenantId: tenantId,
    );
    expect(finalizedS1.isClosed, isTrue);
    expect(finalizedS1.isFinalized, isTrue);

    // -------------------------------------------------------------------------
    // 4. Finalization Lockout & Authorized Correction
    // -------------------------------------------------------------------------
    expect(
      () => attService.recordAttendance(
        sessionId: session1.sessionId,
        learnerId: learnerArjun,
        status: AttendanceStatus.absent,
        actorId: facultyId,
        tenantId: tenantId,
      ),
      throwsA(isA<SessionFinalizedException>()),
    );

    // Authorized Correction on Arjun's record
    final arjunS1Rec = await attRepo.getAttendanceForSessionAndLearner(
      sessionId: session1.sessionId,
      learnerId: learnerArjun,
      tenantId: tenantId,
    );
    expect(arjunS1Rec, isNotNull);

    final correctedArjun = await attService.correctFinalizedAttendance(
      attendanceId: arjunS1Rec!.attendanceId,
      newStatus: AttendanceStatus.late,
      actorId: facultyId,
      reason: 'Physical sign-in roster confirms late arrival',
      tenantId: tenantId,
    );
    expect(correctedArjun.status, equals(AttendanceStatus.late));
    expect(correctedArjun.corrections.length, equals(1));
    expect(correctedArjun.corrections.first.previousStatus,
        equals(AttendanceStatus.present));
    expect(correctedArjun.corrections.first.newStatus,
        equals(AttendanceStatus.late));
    expect(
        correctedArjun.corrections.first.reason, contains('Physical sign-in'));

    // -------------------------------------------------------------------------
    // 5. Session 2 Lifecycle & Excused Absence Handling
    // -------------------------------------------------------------------------
    final session2 = await attService.createSession(
      sessionId: 'sess_crim_02',
      tenantId: tenantId,
      courseId: courseId,
      cohortId: cohortId,
      title: 'Session 2: Culpable Homicide vs Murder',
      scheduledAt: baseTime.add(const Duration(days: 2)),
      facultyId: facultyId,
    );
    await attService.openSession(
        sessionId: session2.sessionId, actorId: facultyId, tenantId: tenantId);

    await attService.recordAttendance(
      sessionId: session2.sessionId,
      learnerId: learnerArjun,
      status: AttendanceStatus.present,
      actorId: facultyId,
      tenantId: tenantId,
    );
    await attService.recordAttendance(
      sessionId: session2.sessionId,
      learnerId: learnerPriya,
      status: AttendanceStatus.excused,
      remarks: 'Sanctioned medical leave by Dean of Students',
      actorId: facultyId,
      tenantId: tenantId,
    );
    await attService.recordAttendance(
      sessionId: session2.sessionId,
      learnerId: learnerKavita,
      status: AttendanceStatus.absent,
      actorId: facultyId,
      tenantId: tenantId,
    );

    await attService.finalizeSession(
        sessionId: session2.sessionId, actorId: facultyId, tenantId: tenantId);

    // -------------------------------------------------------------------------
    // 6. Session 3: Cancelled Session (Excluded from calculations)
    // -------------------------------------------------------------------------
    final session3 = await attService.createSession(
      sessionId: 'sess_crim_03',
      tenantId: tenantId,
      courseId: courseId,
      cohortId: cohortId,
      title: 'Session 3: Defences',
      scheduledAt: baseTime.add(const Duration(days: 4)),
      facultyId: facultyId,
    );
    final cancelledS3 = await attService.cancelSession(
      sessionId: session3.sessionId,
      actorId: facultyId,
      reason: 'Gazetted Institutional Holiday',
      tenantId: tenantId,
    );
    expect(cancelledS3.isCancelled, isTrue);

    // -------------------------------------------------------------------------
    // 7. Authoritative Attendance Summaries
    // -------------------------------------------------------------------------
    // Arjun: Session 1 (late = 0.5), Session 2 (present = 1.0)
    // Total applicable = 2, total attended = 1.5 -> 75.0%
    final arjunSummary = await attService.getLearnerAttendanceSummary(
      learnerId: learnerArjun,
      courseId: courseId,
      tenantId: tenantId,
    );
    expect(
        arjunSummary.totalSessionsScheduled, equals(2)); // cancelled excluded
    expect(arjunSummary.totalSessionsFinalized, equals(2));
    expect(arjunSummary.presentCount, equals(1));
    expect(arjunSummary.lateCount, equals(1));
    expect(arjunSummary.attendancePercentage, equals(75.0));
    expect(arjunSummary.meetsAttendanceThreshold, isTrue);

    // Priya: Session 1 (late = 0.5), Session 2 (excused = excluded from denom)
    // Applicable = 1, attended = 0.5 -> 50.0%
    final priyaSummary = await attService.getLearnerAttendanceSummary(
      learnerId: learnerPriya,
      courseId: courseId,
      tenantId: tenantId,
    );
    expect(priyaSummary.excusedCount, equals(1));
    expect(priyaSummary.attendancePercentage, equals(50.0));
    expect(priyaSummary.meetsAttendanceThreshold, isFalse);

    // Kavita: Session 1 (absent = 0.0), Session 2 (absent = 0.0) -> 0.0%
    final kavitaSummary = await attService.getLearnerAttendanceSummary(
      learnerId: learnerKavita,
      courseId: courseId,
      tenantId: tenantId,
    );
    expect(kavitaSummary.absentCount, equals(2));
    expect(kavitaSummary.attendancePercentage, equals(0.0));
    expect(kavitaSummary.meetsAttendanceThreshold, isFalse);

    // -------------------------------------------------------------------------
    // 8. Academic Engagement & Monitoring Interventions
    // -------------------------------------------------------------------------
    final kavitaEngagement = await attService.evaluateAcademicEngagement(
      learnerId: learnerKavita,
      courseId: courseId,
      tenantId: tenantId,
    );
    expect(kavitaEngagement.isAtRisk, isTrue);
    expect(kavitaEngagement.activeSignals.isNotEmpty, isTrue);

    // Verify low-attendance signal was raised for Kavita
    final kavitaSignals = await attService.listSignals(
      learnerId: learnerKavita,
      courseId: courseId,
      tenantId: tenantId,
    );
    expect(kavitaSignals.isNotEmpty, isTrue);
    final kavitaAlert = kavitaSignals
        .firstWhere((s) => s.signalType == AcademicSignalType.lowAttendance);
    expect(kavitaAlert.isOpen, isTrue);
    expect(kavitaAlert.triggerValue, equals(0.0));
    expect(kavitaAlert.thresholdValue, equals(75.0));

    // Faculty acknowledges intervention signal
    final ackAlert = await attService.acknowledgeSignal(
      signalId: kavitaAlert.signalId,
      actorId: facultyId,
      tenantId: tenantId,
    );
    expect(ackAlert.isAcknowledged, isTrue);
    expect(ackAlert.acknowledgedBy, equals(facultyId));

    // Faculty resolves intervention signal with counseling notes
    final resAlert = await attService.resolveSignal(
      signalId: kavitaAlert.signalId,
      actorId: facultyId,
      notes:
          'Met with student regarding health challenges; scheduled remedial reading assignments.',
      tenantId: tenantId,
    );
    expect(resAlert.isResolved, isTrue);
    expect(resAlert.resolvedBy, equals(facultyId));
    expect(resAlert.resolutionNotes, contains('remedial reading'));

    // -------------------------------------------------------------------------
    // 9. Audit Trail Verification
    // -------------------------------------------------------------------------
    final audits =
        await attRepo.listAuditRecords(tenantId: tenantId, courseId: courseId);
    expect(audits.any((a) => a.action == AttendanceAuditAction.sessionCreated),
        isTrue);
    expect(audits.any((a) => a.action == AttendanceAuditAction.sessionOpened),
        isTrue);
    expect(
        audits.any((a) => a.action == AttendanceAuditAction.attendanceRecorded),
        isTrue);
    expect(
        audits
            .any((a) => a.action == AttendanceAuditAction.attendanceFinalized),
        isTrue);
    expect(
        audits
            .any((a) => a.action == AttendanceAuditAction.attendanceCorrected),
        isTrue);
    expect(
        audits.any((a) => a.action == AttendanceAuditAction.sessionCancelled),
        isTrue);
    expect(audits.any((a) => a.action == AttendanceAuditAction.signalCreated),
        isTrue);
    expect(
        audits.any((a) => a.action == AttendanceAuditAction.signalAcknowledged),
        isTrue);
    expect(audits.any((a) => a.action == AttendanceAuditAction.signalResolved),
        isTrue);

    // -------------------------------------------------------------------------
    // 10. Persistence Snapshot, Simulated Restart & Recovery
    // -------------------------------------------------------------------------
    final snapshot = await attRepo.exportSnapshot();
    expect(snapshot['sessions'], isNotEmpty);
    expect(snapshot['records'], isNotEmpty);
    expect(snapshot['signals'], isNotEmpty);
    expect(snapshot['auditRecords'], isNotEmpty);

    final restoredRepo = InMemoryAttendanceRepository();
    await restoredRepo.importSnapshot(snapshot);

    final restoredService = AttendanceService(
      attendanceRepository: restoredRepo,
      enrollmentRepository: enrRepo,
      cohortRepository: cohortRepo,
      clock: () => baseTime,
    );

    final restoredKavitaSummary =
        await restoredService.getLearnerAttendanceSummary(
      learnerId: learnerKavita,
      courseId: courseId,
      tenantId: tenantId,
    );
    expect(restoredKavitaSummary.attendancePercentage, equals(0.0));
    expect(restoredKavitaSummary.absentCount, equals(2));

    final restoredSignals = await restoredRepo.listSignals(
      learnerId: learnerKavita,
      courseId: courseId,
      tenantId: tenantId,
    );
    expect(restoredSignals.first.isResolved, isTrue);

    // -------------------------------------------------------------------------
    // 11. Multi-Tenant Isolation
    // -------------------------------------------------------------------------
    final otherTenantSessions = await restoredRepo.listSessionsForCourse(
      courseId: courseId,
      tenantId: 'foreign_institution_tenant',
    );
    expect(otherTenantSessions, isEmpty);

    final otherTenantRecords = await restoredRepo.listAttendanceForCourse(
      courseId: courseId,
      tenantId: 'foreign_institution_tenant',
    );
    expect(otherTenantRecords, isEmpty);

    final otherTenantSignals = await restoredRepo.listSignals(
      courseId: courseId,
      tenantId: 'foreign_institution_tenant',
    );
    expect(otherTenantSignals, isEmpty);
  });
}
