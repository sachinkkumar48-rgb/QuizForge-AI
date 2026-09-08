import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/pages/cohort_management_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final baseDate = DateTime.utc(2026, 9, 21, 10, 0, 0);

  late InMemoryCohortRepository cohortRepo;
  late CurriculumFramework framework;
  late CurriculumService curriculumService;
  late CohortAssignmentService cohortService;

  setUp(() {
    framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
    curriculumService = CurriculumService(framework: framework);
    cohortRepo = InMemoryCohortRepository();
    cohortService = CohortAssignmentService(
      cohortRepository: cohortRepo,
      curriculumService: curriculumService,
      clock: () => baseDate,
    );
  });

  Widget buildTestWidget({
    bool isFaculty = true,
    String facultyId = 'faculty_prof_sharma',
    String learnerId = 'learner_alpha_01',
  }) {
    return MaterialApp(
      home: CohortManagementPage(
        cohortService: cohortService,
        initialIsFaculty: isFaculty,
        initialFacultyId: facultyId,
        initialLearnerId: learnerId,
      ),
    );
  }

  group('P48 Cohort Management UI Widget Tests', () {
    testWidgets('1. Empty Faculty View displays prompt to create first cohort',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(isFaculty: true));
      await tester.pumpAndSettle();

      expect(find.text('Institutional Cohort Dashboard'), findsOneWidget);
      expect(find.text('No Institutional Cohorts Found'), findsOneWidget);
      expect(find.text('Create First Cohort'), findsOneWidget);
    });

    testWidgets(
        '2. Active Faculty View displays cohort details, metrics, and tabs',
        (tester) async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_batch_a',
        name: 'UPSC 2026 Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_prof_sharma',
        learnerIds: ['learner_alpha_01', 'learner_beta_02'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_01',
        cohortId: 'cohort_upsc_batch_a',
        title: 'Fundamental Rights Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_prof_sharma',
        dueDate: baseDate.add(const Duration(days: 3)),
        status: CohortAssignmentStatus.published,
      );

      await tester.pumpWidget(buildTestWidget(isFaculty: true));
      await tester.pumpAndSettle();

      expect(find.text('Active Cohort:'), findsOneWidget);
      expect(find.textContaining('UPSC 2026 Batch A'), findsWidgets);
      expect(find.text('Learners'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 2 learners
      expect(find.text('Assignments'), findsWidgets);
      expect(find.text('Fundamental Rights Drill'), findsOneWidget);
      expect(find.text('PUBLISHED'), findsOneWidget);
    });

    testWidgets(
        '3. Learner View displays enrolled assignments with start action',
        (tester) async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_batch_a',
        name: 'UPSC 2026 Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_prof_sharma',
        learnerIds: ['learner_alpha_01'],
      );

      await cohortService.createAssignment(
        assignmentId: 'assign_01',
        cohortId: 'cohort_upsc_batch_a',
        title: 'Article 21 Mastery Drill',
        targetId: 'lo_article_21_foundations',
        assignedByFacultyId: 'faculty_prof_sharma',
        dueDate: baseDate.add(const Duration(days: 3)),
        status: CohortAssignmentStatus.published,
      );

      await tester.pumpWidget(buildTestWidget(
        isFaculty: false,
        learnerId: 'learner_alpha_01',
      ));
      await tester.pumpAndSettle();

      expect(find.text('My Cohorts & Assignments'), findsOneWidget);
      expect(find.text('Article 21 Mastery Drill'), findsOneWidget);
      expect(find.text('Start Assignment'), findsOneWidget);
    });

    testWidgets(
        '4. Mode toggle switches seamlessly between Faculty and Learner views',
        (tester) async {
      await cohortService.createCohort(
        cohortId: 'cohort_upsc_batch_a',
        name: 'UPSC 2026 Batch A',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_prof_sharma',
        learnerIds: ['learner_alpha_01'],
      );

      await tester.pumpWidget(buildTestWidget(isFaculty: true));
      await tester.pumpAndSettle();

      expect(find.text('Institutional Cohort Dashboard'), findsOneWidget);

      // Tap Learner segment
      await tester.tap(find.text('Learner'));
      await tester.pumpAndSettle();

      expect(find.text('My Cohorts & Assignments'), findsOneWidget);
    });
  });
}
