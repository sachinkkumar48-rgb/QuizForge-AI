/// P54 Institutional Communication & Notifications Acceptance Integration Test (TITAN-KO-054.0).
///
/// Complete end-to-end integration scenario verifying Section 18 mandatory lifecycle:
/// LEARNER ENROLLMENT -> ENROLLMENT NOTIFICATION ->
/// FACULTY GRADE PUBLICATION -> GRADE NOTIFICATION ->
/// LEARNER MARK READ & UNREAD COUNT DECREASE ->
/// FACULTY ATTENDANCE FINALIZATION & LOW ATTENDANCE SIGNAL -> FACULTY INTERVENTION NOTIFICATION ->
/// COURSE COMPLETION -> COMPLETION NOTIFICATION ->
/// TRANSCRIPT / CERTIFICATE ISSUANCE -> CREDENTIAL NOTIFICATIONS ->
/// PERSISTENCE SNAPSHOT & RESTART RECOVERY ->
/// REPEATED EVENT PROCESSING & STRICT DEDUPLICATION
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 26, 9, 0, 0);

  late InMemoryNotificationRepository notifRepo;
  late InMemoryEnrollmentRepository enrRepo;
  late InMemoryCohortRepository cohortRepo;
  late InMemoryAttendanceRepository attRepo;

  late NotificationService notifService;
  late EnrollmentService enrService;
  late AttendanceService attService;

  setUp(() {
    notifRepo = InMemoryNotificationRepository();
    enrRepo = InMemoryEnrollmentRepository();
    cohortRepo = InMemoryCohortRepository();
    attRepo = InMemoryAttendanceRepository();

    notifService = NotificationService(
      notificationRepository: notifRepo,
      clock: () => baseTime,
    );

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
      'Section 18: Mandatory Complete Academic Event & Notification End-to-End Scenario',
      () async {
    const tenantId = 'titan_institution_main';
    const facultyId = 'faculty_prof_deshmukh';
    const learnerId = 'learner_arjun_sharma';
    const courseId = 'course_crim_law_301';
    const courseTitle = 'Comparative Criminal Procedure';
    const cohortId = 'cohort_criminal_law_2026';

    // -------------------------------------------------------------------------
    // 1. Course & Cohort Setup
    // -------------------------------------------------------------------------
    await enrService.createCourse(
      courseId: courseId,
      title: courseTitle,
      examId: 'clat_pg_2026',
      tenantId: tenantId,
      facultyId: facultyId,
      cohortIds: [cohortId],
    );

    await cohortRepo.saveCohort(
      Cohort(
        cohortId: cohortId,
        tenantId: tenantId,
        name: 'Criminal Law Specialization 2026',
        examId: 'clat_pg_2026',
        primaryFacultyId: facultyId,
        learnerIds: {learnerId},
      ),
    );

    // -------------------------------------------------------------------------
    // 2. LEARNER -> ACTIVE ENROLLMENT
    // -------------------------------------------------------------------------
    final enrollment = await enrService.registerLearner(
      learnerId: learnerId,
      courseId: courseId,
      cohortId: cohortId,
      tenantId: tenantId,
      actorId: facultyId,
      autoActivate: true,
    );
    expect(enrollment.isActive, isTrue);

    // Event Hook: Enrollment Activated
    final enrNotif = await notifService.notifyEnrollmentActivated(
      tenantId: tenantId,
      learnerId: learnerId,
      courseId: courseId,
      courseTitle: courseTitle,
      actorId: facultyId,
    );

    // Verify ENROLLMENT notification exists
    expect(enrNotif.type, equals(NotificationType.enrollment));
    expect(enrNotif.recipientId, equals(learnerId));
    expect(enrNotif.isUnread, isTrue);

    var learnerUnreadCount = await notifService.getUnreadCount(
      recipientId: learnerId,
      tenantId: tenantId,
    );
    expect(learnerUnreadCount, equals(1));

    // -------------------------------------------------------------------------
    // 3. FACULTY -> PUBLISH RESULT / GRADE
    // -------------------------------------------------------------------------
    // Event Hook: Grade Published
    final gradeNotif = await notifService.notifyGradePublished(
      tenantId: tenantId,
      learnerId: learnerId,
      courseId: courseId,
      courseTitle: courseTitle,
      finalGrade: 'A+',
      actorId: facultyId,
    );

    // Verify LEARNER receives grade notification
    expect(gradeNotif.type, equals(NotificationType.grade));
    expect(gradeNotif.recipientId, equals(learnerId));
    expect(gradeNotif.isUnread, isTrue);

    learnerUnreadCount = await notifService.getUnreadCount(
      recipientId: learnerId,
      tenantId: tenantId,
    );
    expect(learnerUnreadCount, equals(2));

    // -------------------------------------------------------------------------
    // 4. LEARNER -> OPEN NOTIFICATIONS -> OPEN GRADE NOTIFICATION -> MARK READ
    // -------------------------------------------------------------------------
    final readGradeNotif = await notifService.markAsRead(
      notificationId: gradeNotif.notificationId,
      recipientId: learnerId,
      tenantId: tenantId,
    );
    expect(readGradeNotif.isRead, isTrue);

    // Verify unread count decreases
    learnerUnreadCount = await notifService.getUnreadCount(
      recipientId: learnerId,
      tenantId: tenantId,
    );
    expect(learnerUnreadCount, equals(1));

    // -------------------------------------------------------------------------
    // 5. FACULTY -> RECORD ATTENDANCE -> FINALIZE -> LOW ATTENDANCE SIGNAL
    // -------------------------------------------------------------------------
    final session = await attService.createSession(
      sessionId: 'sess_crim_01',
      tenantId: tenantId,
      courseId: courseId,
      cohortId: cohortId,
      title: 'Session 1: Judicial Precedents',
      scheduledAt: baseTime,
      facultyId: facultyId,
    );
    await attService.openSession(
        sessionId: session.sessionId, actorId: facultyId, tenantId: tenantId);

    // Record absent to trigger low attendance
    await attService.recordAttendance(
      sessionId: session.sessionId,
      learnerId: learnerId,
      status: AttendanceStatus.absent,
      actorId: facultyId,
      tenantId: tenantId,
    );
    await attService.finalizeSession(
        sessionId: session.sessionId, actorId: facultyId, tenantId: tenantId);

    // Query raised signal
    final signals = await attService.listSignals(
      learnerId: learnerId,
      courseId: courseId,
      tenantId: tenantId,
    );
    expect(signals.isNotEmpty, isTrue);
    final alert = signals.first;

    // Event Hook: Faculty Intervention Notification
    final interventionNotif =
        await notifService.notifyAttendanceInterventionCreated(
      tenantId: tenantId,
      facultyId: facultyId,
      learnerId: learnerId,
      courseId: courseId,
      signalId: alert.signalId,
      signalType: alert.signalType.name,
      triggerValue: alert.triggerValue,
      thresholdValue: alert.thresholdValue,
    );

    // Verify appropriate faculty notification exists
    expect(interventionNotif.type, equals(NotificationType.intervention));
    expect(interventionNotif.recipientId, equals(facultyId));
    expect(interventionNotif.recipientRole, equals('faculty'));
    expect(interventionNotif.priority, equals(NotificationPriority.urgent));

    final facultyUnreadCount = await notifService.getUnreadCount(
      recipientId: facultyId,
      tenantId: tenantId,
    );
    expect(facultyUnreadCount, equals(1));

    // Faculty acknowledges intervention alert
    final ackIntervention = await notifService.acknowledgeNotification(
      notificationId: interventionNotif.notificationId,
      recipientId: facultyId,
      tenantId: tenantId,
    );
    expect(ackIntervention.isAcknowledged, isTrue);

    // -------------------------------------------------------------------------
    // 6. LEARNER -> COMPLETES COURSE
    // -------------------------------------------------------------------------
    await enrService.markCompletion(
      enrollmentId: enrollment.enrollmentId,
      actorId: facultyId,
      tenantId: tenantId,
    );

    // Event Hook: Course Completed
    final completionNotif = await notifService.notifyCourseCompleted(
      tenantId: tenantId,
      learnerId: learnerId,
      courseId: courseId,
      courseTitle: courseTitle,
      actorId: facultyId,
    );

    // Verify completion-related notification
    expect(completionNotif.type, equals(NotificationType.completion));
    expect(completionNotif.recipientId, equals(learnerId));

    learnerUnreadCount = await notifService.getUnreadCount(
      recipientId: learnerId,
      tenantId: tenantId,
    );
    expect(learnerUnreadCount, equals(2)); // enr (unread) + completion (unread)

    const transcriptId = 'trans_crim_2026_arjun';
    const certificateId = 'cert_crim_2026_arjun';

    // Event Hooks: Transcript & Certificate
    final transcriptNotif = await notifService.notifyTranscriptIssued(
      tenantId: tenantId,
      learnerId: learnerId,
      transcriptId: transcriptId,
      actorId: facultyId,
    );

    final certNotif = await notifService.notifyCertificateIssued(
      tenantId: tenantId,
      learnerId: learnerId,
      certificateId: certificateId,
      courseTitle: courseTitle,
      actorId: facultyId,
    );

    // Verify learner receives credential notifications
    expect(transcriptNotif.type, equals(NotificationType.transcript));
    expect(certNotif.type, equals(NotificationType.certificate));

    learnerUnreadCount = await notifService.getUnreadCount(
      recipientId: learnerId,
      tenantId: tenantId,
    );
    expect(learnerUnreadCount,
        equals(4)); // enr, completion, transcript, certificate

    // -------------------------------------------------------------------------
    // 8. RESTART APPLICATION -> PERSISTENCE SNAPSHOT RECOVERY
    // -------------------------------------------------------------------------
    final snapshot = await notifRepo.exportSnapshot();
    expect(snapshot['notifications'], isNotEmpty);
    expect(snapshot['auditRecords'], isNotEmpty);

    // Simulate restart with fresh repo & service
    final restoredRepo = InMemoryNotificationRepository();
    await restoredRepo.importSnapshot(snapshot);

    final restoredService = NotificationService(
      notificationRepository: restoredRepo,
      clock: () => baseTime,
    );

    // Verify all notification history and read states survive restart
    final restoredLearnerNotifs = await restoredService.listNotifications(
      recipientId: learnerId,
      tenantId: tenantId,
    );
    expect(restoredLearnerNotifs.length,
        equals(5)); // enr, grade, comp, trans, cert

    // Grade notification was marked read prior to restart
    final restoredGrade = restoredLearnerNotifs
        .firstWhere((n) => n.type == NotificationType.grade);
    expect(restoredGrade.isRead, isTrue);

    // Faculty intervention was marked acknowledged prior to restart
    final restoredFacultyNotifs = await restoredService.listNotifications(
      recipientId: facultyId,
      tenantId: tenantId,
    );
    expect(restoredFacultyNotifs.length, equals(1));
    expect(restoredFacultyNotifs.first.isAcknowledged, isTrue);

    // -------------------------------------------------------------------------
    // 9. RUN EVENT PROCESSING AGAIN -> STRICT DEDUPLICATION
    // -------------------------------------------------------------------------
    // Repeat all events
    await restoredService.notifyEnrollmentActivated(
      tenantId: tenantId,
      learnerId: learnerId,
      courseId: courseId,
      courseTitle: courseTitle,
      actorId: facultyId,
    );
    await restoredService.notifyGradePublished(
      tenantId: tenantId,
      learnerId: learnerId,
      courseId: courseId,
      courseTitle: courseTitle,
      finalGrade: 'A+',
      actorId: facultyId,
    );
    await restoredService.notifyCourseCompleted(
      tenantId: tenantId,
      learnerId: learnerId,
      courseId: courseId,
      courseTitle: courseTitle,
      actorId: facultyId,
    );
    await restoredService.notifyTranscriptIssued(
      tenantId: tenantId,
      learnerId: learnerId,
      transcriptId: transcriptId,
      actorId: facultyId,
    );
    await restoredService.notifyCertificateIssued(
      tenantId: tenantId,
      learnerId: learnerId,
      certificateId: certificateId,
      courseTitle: courseTitle,
      actorId: facultyId,
    );
    await restoredService.notifyAttendanceInterventionCreated(
      tenantId: tenantId,
      facultyId: facultyId,
      learnerId: learnerId,
      courseId: courseId,
      signalId: alert.signalId,
      signalType: alert.signalType.name,
      triggerValue: alert.triggerValue,
      thresholdValue: alert.thresholdValue,
    );

    // Verify count remains IDENTICAL (no duplicates created!)
    final deduplicatedLearnerNotifs = await restoredService.listNotifications(
      recipientId: learnerId,
      tenantId: tenantId,
    );
    expect(deduplicatedLearnerNotifs.length, equals(5));

    final deduplicatedFacultyNotifs = await restoredService.listNotifications(
      recipientId: facultyId,
      tenantId: tenantId,
    );
    expect(deduplicatedFacultyNotifs.length, equals(1));
  });
}
