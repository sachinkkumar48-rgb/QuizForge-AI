import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/pages/notifications_page.dart';
import 'package:quizforge_upsc/pages/course_enrollment_page.dart';
import 'package:quizforge_upsc/pages/cohort_management_page.dart';

void main() {
  final baseTime = DateTime.utc(2026, 11, 20, 10, 0, 0);

  late InMemoryNotificationRepository notifRepo;
  late NotificationService notifService;

  setUp(() async {
    notifRepo = InMemoryNotificationRepository();
    notifService = NotificationService(
      notificationRepository: notifRepo,
      clock: () => baseTime,
    );

    // Seed learner notifications
    await notifService.notifyEnrollmentActivated(
      tenantId: 'tenant_default',
      learnerId: 'learner_arjun',
      courseId: 'course_law_101',
      courseTitle: 'Constitutional Law Foundations',
      actorId: 'faculty_sharma',
    );

    await notifService.notifyAssessmentPublished(
      tenantId: 'tenant_default',
      recipientId: 'learner_arjun',
      assessmentId: 'exam_const_midterm',
      assessmentTitle: 'Midterm Examination 2026',
      courseId: 'course_law_101',
      actorId: 'faculty_sharma',
    );

    await notifService.notifyGradePublished(
      tenantId: 'tenant_default',
      learnerId: 'learner_arjun',
      courseId: 'course_law_101',
      courseTitle: 'Constitutional Law Foundations',
      finalGrade: 'A',
      actorId: 'faculty_sharma',
    );

    // Seed faculty notifications
    await notifService.notifyAttendanceInterventionCreated(
      tenantId: 'tenant_default',
      facultyId: 'faculty_sharma',
      learnerId: 'learner_bob',
      courseId: 'course_law_101',
      signalId: 'sig_att_low_bob',
      signalType: 'low_attendance',
      triggerValue: 55.0,
      thresholdValue: 75.0,
    );
  });

  testWidgets(
    'Learner Perspective: Renders unread notifications, badge counter, tabs, and mark as read',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
          notificationService: notifService,
          initialFacultyId: 'faculty_sharma',
          initialLearnerId: 'learner_arjun',
          initialIsFaculty: false, // Learner Mode
        ),
      ));
      await tester.pumpAndSettle();

      // Verify Title & Header
      expect(find.text('My Notifications'), findsOneWidget);
      expect(find.text('Learner'), findsOneWidget);
      expect(find.text('Faculty'), findsOneWidget);

      // Verify Tabs
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Assessments'), findsOneWidget);
      expect(find.text('Grades'), findsOneWidget);

      // Verify unread badge counter in Unread tab (3 unread notifications)
      expect(find.byKey(const Key('unread_badge_counter')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Verify seeded notifications are displayed
      expect(find.textContaining('Enrollment Confirmed:'), findsOneWidget);
      expect(find.textContaining('Assessment Available:'), findsOneWidget);
      expect(find.textContaining('Official Grade Published:'), findsOneWidget);

      // Find mark read button on the first notification and tap it
      final list =
          await notifService.listNotifications(recipientId: 'learner_arjun');
      final firstNotifId = list.first.notificationId;

      expect(find.byKey(Key('mark_read_button_$firstNotifId')), findsOneWidget);
      await tester.tap(find.byKey(Key('mark_read_button_$firstNotifId')));
      await tester.pumpAndSettle();

      // Badge count should now be 2
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'Mark All Read: Button marks all pending notifications as read and clears badge',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
          notificationService: notifService,
          initialFacultyId: 'faculty_sharma',
          initialLearnerId: 'learner_arjun',
          initialIsFaculty: false,
        ),
      ));
      await tester.pumpAndSettle();

      // Verify mark_all_read_button exists
      expect(find.byKey(const Key('mark_all_read_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('mark_all_read_button')));
      await tester.pumpAndSettle();

      // After marking all as read, badge counter is no longer rendered
      expect(find.byKey(const Key('unread_badge_counter')), findsNothing);
      expect(find.text('READ'), findsNWidgets(3));
    },
  );

  testWidgets(
    'Faculty Perspective: Shows urgent interventions, allows acknowledge and dismiss',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: NotificationsPage(
          notificationService: notifService,
          initialFacultyId: 'faculty_sharma',
          initialLearnerId: 'learner_arjun',
          initialIsFaculty: true, // Faculty Mode
        ),
      ));
      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Faculty Academic Notifications'), findsOneWidget);

      // Verify Intervention notification displayed
      expect(find.textContaining('Academic Alert:'), findsOneWidget);
      expect(find.text('URGENT'), findsWidgets);

      final list =
          await notifService.listNotifications(recipientId: 'faculty_sharma');
      final facultyNotifId = list.first.notificationId;

      // Verify Acknowledge button
      expect(find.byKey(Key('ack_button_$facultyNotifId')), findsOneWidget);
      await tester.tap(find.byKey(Key('ack_button_$facultyNotifId')));
      await tester.pumpAndSettle();

      expect(find.text('ACKNOWLEDGED'), findsOneWidget);

      // Verify Dismiss button
      expect(find.byKey(Key('dismiss_button_$facultyNotifId')), findsOneWidget);
      await tester.tap(find.byKey(Key('dismiss_button_$facultyNotifId')));
      await tester.pumpAndSettle();

      // Notification is dismissed (status chip updated to DISMISSED)
      expect(find.text('DISMISSED'), findsOneWidget);
    },
  );

  testWidgets(
    'Navigation Integration: Launch Notifications from Course Enrollment Page',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CourseEnrollmentPage(
          enrollmentService: EnrollmentService(
            enrollmentRepository: InMemoryEnrollmentRepository(),
            cohortRepository: InMemoryCohortRepository(),
          ),
          initialFacultyId: 'faculty_sharma',
          initialLearnerId: 'learner_arjun',
          initialIsFaculty: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notifications_nav_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('notifications_nav_button')));
      await tester.pumpAndSettle();

      expect(find.text('Faculty Academic Notifications'), findsOneWidget);
    },
  );

  testWidgets(
    'Navigation Integration: Launch Notifications from Cohort Management Page',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CohortManagementPage(
          cohortService: CohortAssignmentService(
            cohortRepository: InMemoryCohortRepository(),
          ),
          initialFacultyId: 'faculty_sharma',
          initialLearnerId: 'learner_arjun',
          initialIsFaculty: true,
        ),
      ));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('cohort_notifications_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('cohort_notifications_button')));
      await tester.pumpAndSettle();

      expect(find.text('Faculty Academic Notifications'), findsOneWidget);
    },
  );
}
