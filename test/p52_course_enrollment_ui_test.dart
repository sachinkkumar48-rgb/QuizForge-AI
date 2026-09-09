import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/pages/course_enrollment_page.dart';

void main() {
  final now = DateTime.utc(2026, 11, 20, 10, 0, 0);

  late InMemoryEnrollmentRepository enrollmentRepo;
  late InMemoryCohortRepository cohortRepo;
  late EnrollmentService enrollmentService;
  late CohortAssignmentService cohortService;

  setUp(() async {
    enrollmentRepo = InMemoryEnrollmentRepository();
    cohortRepo = InMemoryCohortRepository();

    enrollmentService = EnrollmentService(
      enrollmentRepository: enrollmentRepo,
      cohortRepository: cohortRepo,
      clock: () => now,
    );

    cohortService = CohortAssignmentService(
      cohortRepository: cohortRepo,
    );

    // Seed Courses
    await enrollmentService.createCourse(
      courseId: 'course_ui_101',
      title: 'Constitutional Law & Governance Foundations',
      examId: 'clat_pg_2026',
      facultyId: 'faculty_sharma',
      estimatedHours: 40,
    );

    // Seed Cohort
    await cohortRepo.saveCohort(Cohort(
      cohortId: 'cohort_ui_alpha',
      name: 'Judicial Services Cohort Alpha',
      examId: 'clat_pg_2026',
      primaryFacultyId: 'faculty_sharma',
      learnerIds: {'learner_alice', 'learner_bob', 'learner_carol'},
    ));

    // Seed Active Enrollment for learner_alice
    await enrollmentService.registerLearner(
      learnerId: 'learner_alice',
      courseId: 'course_ui_101',
      cohortId: 'cohort_ui_alpha',
      actorId: 'faculty_sharma',
      autoActivate: true,
    );
  });

  testWidgets(
      'Faculty Perspective renders course selector, bulk enroll, and enrolled learners',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CourseEnrollmentPage(
        enrollmentService: enrollmentService,
        cohortService: cohortService,
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialCourseId: 'course_ui_101',
        initialCohortId: 'cohort_ui_alpha',
        initialIsFaculty: true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Course Enrollment & Access Control'), findsOneWidget);
    expect(find.byKey(const Key('course_selector')), findsOneWidget);
    expect(find.byKey(const Key('bulk_enroll_button')), findsOneWidget);
    expect(find.byKey(const Key('enroll_learner_button')), findsOneWidget);

    // Learner Alice row and status badge
    expect(find.text('learner_alice'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.byKey(const Key('suspend_learner_alice')), findsOneWidget);
    expect(find.byKey(const Key('withdraw_learner_alice')), findsOneWidget);
  });

  testWidgets(
      'Learner Perspective renders My Enrolled Courses and access banner',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CourseEnrollmentPage(
        enrollmentService: enrollmentService,
        cohortService: cohortService,
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialCourseId: 'course_ui_101',
        initialCohortId: 'cohort_ui_alpha',
        initialIsFaculty: false, // Learner view
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('My Enrolled Courses'), findsOneWidget);
    expect(find.text('Constitutional Law & Governance Foundations'),
        findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('Full Course Access Active'), findsOneWidget);
    expect(find.text('Enter Course'), findsOneWidget);
  });

  testWidgets(
      'Faculty can open Enroll Learner dialog and register a new learner',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CourseEnrollmentPage(
        enrollmentService: enrollmentService,
        cohortService: cohortService,
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialCourseId: 'course_ui_101',
        initialCohortId: 'cohort_ui_alpha',
        initialIsFaculty: true,
      ),
    ));
    await tester.pumpAndSettle();

    // Tap Floating Action Button
    await tester.tap(find.byKey(const Key('enroll_learner_button')));
    await tester.pumpAndSettle();

    expect(find.text('Enroll Learner in Course'), findsOneWidget);

    // Enter Learner ID
    await tester.enterText(
      find.byKey(const Key('enroll_learner_id_input')),
      'learner_carol',
    );
    await tester.pumpAndSettle();

    // Confirm
    await tester.tap(find.byKey(const Key('confirm_enroll_button')));
    await tester.pumpAndSettle();

    // Learner Carol is now visible in the list
    expect(find.text('learner_carol'), findsOneWidget);
  });

  testWidgets('Faculty can suspend enrollment with mandatory justification',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: CourseEnrollmentPage(
        enrollmentService: enrollmentService,
        cohortService: cohortService,
        initialFacultyId: 'faculty_sharma',
        initialLearnerId: 'learner_alice',
        initialCourseId: 'course_ui_101',
        initialCohortId: 'cohort_ui_alpha',
        initialIsFaculty: true,
      ),
    ));
    await tester.pumpAndSettle();

    // Tap Suspend on Alice
    await tester.tap(find.byKey(const Key('suspend_learner_alice')));
    await tester.pumpAndSettle();

    expect(find.text('SUSPEND Enrollment: learner_alice'), findsOneWidget);

    // Enter reason
    await tester.enterText(
      find.byKey(const Key('transition_reason_input')),
      'Administrative tuition clearance hold',
    );
    await tester.pumpAndSettle();

    // Confirm transition
    await tester.tap(find.byKey(const Key('confirm_transition_button')));
    await tester.pumpAndSettle();

    // Status chip now shows SUSPENDED
    expect(find.text('SUSPENDED'), findsOneWidget);
    expect(find.byKey(const Key('reactivate_learner_alice')), findsOneWidget);
  });
}
