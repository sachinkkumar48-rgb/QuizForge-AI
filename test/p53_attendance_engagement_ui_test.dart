import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/pages/attendance_management_page.dart';
import 'package:quizforge_upsc/pages/course_enrollment_page.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 20, 10, 0, 0);

  late InMemoryAttendanceRepository attRepo;
  late InMemoryEnrollmentRepository enrRepo;
  late InMemoryCohortRepository cohortRepo;
  late EnrollmentService enrService;
  late AttendanceService attService;

  setUp(() async {
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

    // Seed Course
    await enrService.createCourse(
      courseId: 'course_law_101',
      title: 'Constitutional Law Foundations',
      examId: 'clat_pg_2026',
      facultyId: 'faculty_sharma',
    );

    // Seed Cohort
    await cohortRepo.saveCohort(
      Cohort(
        cohortId: 'cohort_djs_2026',
        name: 'Delhi Judicial Services 2026',
        examId: 'clat_pg_2026',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: {'learner_alice', 'learner_bob'},
      ),
    );

    // Seed Active Enrollments
    await enrService.registerLearner(
      learnerId: 'learner_alice',
      courseId: 'course_law_101',
      cohortId: 'cohort_djs_2026',
      actorId: 'faculty_sharma',
      autoActivate: true,
    );
    await enrService.registerLearner(
      learnerId: 'learner_bob',
      courseId: 'course_law_101',
      cohortId: 'cohort_djs_2026',
      actorId: 'faculty_sharma',
      autoActivate: true,
    );
  });

  testWidgets(
      'Faculty Perspective: Renders Sessions, opens attendance, records roster and finalizes',
      (WidgetTester tester) async {
    // 1. Create a scheduled session
    final s1 = await attService.createSession(
      sessionId: 'sess_const_01',
      courseId: 'course_law_101',
      title: 'Lecture 1: Preamble & Basic Structure',
      scheduledAt: baseTime,
      durationMinutes: 60,
      facultyId: 'faculty_sharma',
    );

    await tester.pumpWidget(MaterialApp(
      home: AttendanceManagementPage(
        attendanceService: attService,
        enrollmentService: enrService,
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialCourseId: 'course_law_101',
        initialIsFaculty: true,
      ),
    ));
    await tester.pumpAndSettle();

    // Verify AppBar & Tabs
    expect(
        find.text('Faculty Attendance & Academic Monitoring'), findsOneWidget);
    expect(find.text('Sessions & Roster'), findsOneWidget);
    expect(find.text('Academic Monitoring'), findsOneWidget);

    // Verify scheduled session card
    expect(find.text('Lecture 1: Preamble & Basic Structure'), findsOneWidget);
    expect(find.text('SCHEDULED'), findsOneWidget);
    expect(
        find.byKey(Key('open_session_button_${s1.sessionId}')), findsOneWidget);

    // Tap "Open Attendance"
    await tester.tap(find.byKey(Key('open_session_button_${s1.sessionId}')));
    await tester.pumpAndSettle();

    // Verify session state is now OPEN
    expect(find.text('OPEN'), findsOneWidget);
    expect(find.byKey(Key('record_roster_button_${s1.sessionId}')),
        findsOneWidget);
    expect(find.byKey(Key('finalize_session_button_${s1.sessionId}')),
        findsOneWidget);

    // Tap "Record Attendance" to open bottom sheet
    await tester.tap(find.byKey(Key('record_roster_button_${s1.sessionId}')));
    await tester.pumpAndSettle();

    // Verify roster shows enrolled learners
    expect(find.text('learner_alice'), findsOneWidget);
    expect(find.text('learner_bob'), findsOneWidget);

    // Tap "Save Attendance Roster"
    await tester.tap(find.byKey(const Key('save_roster_button')));
    await tester.pumpAndSettle();

    // Finalize session
    await tester
        .tap(find.byKey(Key('finalize_session_button_${s1.sessionId}')));
    await tester.pumpAndSettle();

    // Confirm finalization in dialog
    expect(find.byKey(const Key('confirm_finalize_session_button')),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm_finalize_session_button')));
    await tester.pumpAndSettle();

    // Session is now CLOSED
    expect(find.text('CLOSED'), findsOneWidget);
    expect(
        find.byKey(Key('view_roster_button_${s1.sessionId}')), findsOneWidget);
  });

  testWidgets(
      'Faculty Academic Monitoring Tab: Displays early-warning alerts, allows acknowledge & resolve',
      (WidgetTester tester) async {
    // Create session, record bob absent, finalize to trigger low-attendance alert
    final s1 = await attService.createSession(
      sessionId: 'sess_mon_01',
      courseId: 'course_law_101',
      title: 'Lecture 1: Emergency Provisions',
      scheduledAt: baseTime,
      facultyId: 'faculty_sharma',
    );
    await attService.openSession(
        sessionId: s1.sessionId, actorId: 'faculty_sharma');
    await attService.recordAttendance(
      sessionId: s1.sessionId,
      learnerId: 'learner_bob',
      status: AttendanceStatus.absent,
      actorId: 'faculty_sharma',
    );
    await attService.finalizeSession(
        sessionId: s1.sessionId, actorId: 'faculty_sharma');

    await tester.pumpWidget(MaterialApp(
      home: AttendanceManagementPage(
        attendanceService: attService,
        enrollmentService: enrService,
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_bob',
        initialCourseId: 'course_law_101',
        initialIsFaculty: true,
      ),
    ));
    await tester.pumpAndSettle();

    // Switch to Academic Monitoring tab
    await tester.tap(find.text('Academic Monitoring'));
    await tester.pumpAndSettle();

    // Verify alert metric and learner card
    expect(find.text('Academic Early-Warning Intervention Signals'),
        findsOneWidget);
    expect(find.text('learner_bob'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);

    final signals = await attService.listSignals(courseId: 'course_law_101');
    expect(signals.isNotEmpty, isTrue);
    final sigId = signals.first.signalId;

    // Acknowledge alert
    expect(find.byKey(Key('ack_signal_button_$sigId')), findsOneWidget);
    await tester.tap(find.byKey(Key('ack_signal_button_$sigId')));
    await tester.pumpAndSettle();

    expect(find.text('ACKNOWLEDGED'), findsOneWidget);

    // Resolve alert
    expect(find.byKey(Key('resolve_signal_button_$sigId')), findsOneWidget);
    await tester.tap(find.byKey(Key('resolve_signal_button_$sigId')));
    await tester.pumpAndSettle();

    // Enter resolution notes and submit
    await tester.enterText(
      find.byKey(const Key('signal_resolution_notes_input')),
      'Mentored learner; remedial sessions assigned.',
    );
    await tester.tap(find.byKey(const Key('confirm_resolve_signal_button')));
    await tester.pumpAndSettle();

    expect(find.text('RESOLVED'), findsOneWidget);
    expect(find.textContaining('Mentored learner'), findsOneWidget);
  });

  testWidgets(
      'Learner Perspective: Displays attendance percentage, compliant badge, breakdown & history',
      (WidgetTester tester) async {
    // 2 sessions: Alice present in both
    for (int i = 1; i <= 2; i++) {
      final s = await attService.createSession(
        sessionId: 'sess_alice_$i',
        courseId: 'course_law_101',
        title: 'Session $i: Core Concepts',
        scheduledAt: baseTime.add(Duration(days: i)),
        facultyId: 'faculty_sharma',
      );
      await attService.openSession(
          sessionId: s.sessionId, actorId: 'faculty_sharma');
      await attService.recordAttendance(
        sessionId: s.sessionId,
        learnerId: 'learner_alice',
        status: AttendanceStatus.present,
        actorId: 'faculty_sharma',
      );
      await attService.finalizeSession(
          sessionId: s.sessionId, actorId: 'faculty_sharma');
    }

    await tester.pumpWidget(MaterialApp(
      home: AttendanceManagementPage(
        attendanceService: attService,
        enrollmentService: enrService,
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialCourseId: 'course_law_101',
        initialIsFaculty: false, // Learner Mode
      ),
    ));
    await tester.pumpAndSettle();

    // Verify Learner Header
    expect(find.text('My Academic Attendance'), findsOneWidget);
    expect(find.text('100.0%'), findsOneWidget);
    expect(find.text('COMPLIANT'), findsOneWidget);
    expect(find.text('Authoritative Attendance Rate'), findsOneWidget);

    // Verify summary breakdown values
    expect(find.text('Present'), findsOneWidget);
    expect(find.text('Late (0.5x)'), findsOneWidget);
    expect(find.text('Absent'), findsOneWidget);
    expect(find.text('Excused'), findsOneWidget);

    // Verify recent session history
    expect(find.text('Recent Session Attendance History'), findsOneWidget);
    expect(find.text('Session: sess_alice_1'), findsOneWidget);
    expect(find.text('Session: sess_alice_2'), findsOneWidget);
  });

  testWidgets(
      'Navigation Integration: Launch Attendance from Course Enrollment Page',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CourseEnrollmentPage(
        enrollmentService: enrService,
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialCourseId: 'course_law_101',
        initialIsFaculty: true,
      ),
    ));
    await tester.pumpAndSettle();

    // Verify attendance button exists in AppBar
    expect(find.byKey(const Key('attendance_management_nav_button')),
        findsOneWidget);

    // Tap Attendance Button
    await tester.tap(find.byKey(const Key('attendance_management_nav_button')));
    await tester.pumpAndSettle();

    // Verify AttendanceManagementPage opened
    expect(
        find.text('Faculty Attendance & Academic Monitoring'), findsOneWidget);
  });
}
