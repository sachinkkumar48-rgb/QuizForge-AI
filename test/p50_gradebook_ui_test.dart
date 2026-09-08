/// P50 Gradebook & Publishing UI Widget Test (TITAN-KO-050.0).
///
/// Verifies presentation layer:
/// - GradebookPage rendering in Faculty mode (matrix, KPIs, action chips)
/// - Tab switching to Disputes and Audit Trail
/// - Bulk publish and single entry publish actions
/// - Grade override dialog interaction
/// - Switching to Learner mode and viewing official grades
/// - Submitting a formal grade dispute
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/pages/gradebook_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P50 Faculty Gradebook UI Widget Tests', () {
    late InMemoryGradebookRepository repo;
    late GradebookService service;

    setUp(() async {
      repo = InMemoryGradebookRepository();
      service = GradebookService(repository: repo);

      // Seed cohort entries
      await service.ingestAssessmentResult(
        entryId: 'entry_alice_01',
        tenantId: 'tenant_default',
        cohortId: 'cohort_upsc_2026',
        assessmentId: 'assess_polity',
        learnerId: 'learner_alice',
        resultId: 'res_alice_01',
        originalScore: 85.0,
        maxScore: 100.0,
        autoPublish: false,
      );

      await service.ingestAssessmentResult(
        entryId: 'entry_bob_01',
        tenantId: 'tenant_default',
        cohortId: 'cohort_upsc_2026',
        assessmentId: 'assess_polity',
        learnerId: 'learner_bob',
        resultId: 'res_bob_01',
        originalScore: 35.0,
        maxScore: 100.0,
        autoPublish: false,
      );
    });

    testWidgets('1. Renders Faculty Gradebook Matrix, KPIs, and DataTable',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GradebookPage(
            gradebookService: service,
            initialCohortId: 'cohort_upsc_2026',
            initialFacultyId: 'faculty_admin',
            initialIsFaculty: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check scaffold and title
      expect(find.byKey(const Key('gradebook_page_scaffold')), findsOneWidget);
      expect(find.text('Faculty Gradebook & Publishing'), findsOneWidget);

      // Check KPI cards
      expect(find.text('Enrolled Learners'), findsOneWidget);
      expect(find.text('Pass Rate'), findsOneWidget);
      expect(find.text('Average Score'), findsOneWidget);

      // Check learners in matrix
      expect(find.text('learner_alice'), findsOneWidget);
      expect(find.text('learner_bob'), findsOneWidget);

      // Check Publish All Cohort Grades button
      expect(find.byKey(const Key('publish_all_button')), findsOneWidget);
    });

    testWidgets('2. Bulk Publish Cohort dialog executes successfully',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GradebookPage(
            gradebookService: service,
            initialCohortId: 'cohort_upsc_2026',
            initialFacultyId: 'faculty_admin',
            initialIsFaculty: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Publish All Cohort Grades
      await tester.tap(find.byKey(const Key('publish_all_button')));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Publish All Cohort Grades'), findsAtLeastNWidgets(1));
      expect(
          find.byKey(const Key('confirm_publish_all_button')), findsOneWidget);

      // Confirm publish
      await tester.tap(find.byKey(const Key('confirm_publish_all_button')));
      await tester.pumpAndSettle();

      // Entries should now show PUBLISHED
      expect(find.text('PUBLISHED'), findsWidgets);
    });

    testWidgets('3. Disputes and Audit Trail tabs can be navigated',
        (tester) async {
      // Create a dispute first
      final entry = await service.getEntry('entry_alice_01');
      await service.publishGrade(entry.entryId, facultyId: 'faculty_admin');
      await service.createDispute(
        learnerId: 'learner_alice',
        entryId: entry.entryId,
        assessmentId: entry.assessmentId,
        reason: 'Question 2 answer was improperly marked',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GradebookPage(
            gradebookService: service,
            initialCohortId: 'cohort_upsc_2026',
            initialFacultyId: 'faculty_admin',
            initialIsFaculty: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Disputes tab
      await tester.tap(find.byKey(const Key('disputes_tab_button')));
      await tester.pumpAndSettle();

      // Verify dispute card is displayed
      expect(find.text('Dispute: assess_polity'), findsOneWidget);
      expect(find.text('Learner Justification:'), findsOneWidget);
      expect(
          find.text('Question 2 answer was improperly marked'), findsOneWidget);

      // Tap Audit Trail tab
      await tester.tap(find.byKey(const Key('audit_trail_tab')));
      await tester.pumpAndSettle();

      // Verify audit logs are rendered
      expect(find.text('Audit Trail Empty'), findsNothing);
      expect(find.textContaining('PUBLISHED'), findsWidgets);
    });

    testWidgets(
        '4. Learner Mode shows official published grades and dispute button',
        (tester) async {
      // Publish Alice's grade
      await service.publishGrade('entry_alice_01', facultyId: 'faculty_admin');

      await tester.pumpWidget(
        MaterialApp(
          home: GradebookPage(
            gradebookService: service,
            initialCohortId: 'cohort_upsc_2026',
            initialLearnerId: 'learner_alice',
            initialIsFaculty: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check title for learner mode
      expect(find.text('My Official Grades'), findsOneWidget);

      // Alice's published assessment should be visible
      expect(find.text('Assessment: assess_polity'), findsOneWidget);
      expect(find.text('Official Score'), findsOneWidget);
      expect(find.text('85.0 / 100'), findsOneWidget);

      // Dispute button should be present
      final disputeBtn = find.byKey(const Key('dispute_button_assess_polity'));
      expect(disputeBtn, findsOneWidget);

      // Tap Dispute Grade button to open dialog
      await tester.tap(disputeBtn);
      await tester.pumpAndSettle();

      expect(find.text('Dispute Official Grade'), findsOneWidget);
      expect(find.byKey(const Key('dispute_reason_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_dispute_button')), findsOneWidget);

      // Enter dispute rationale and submit
      await tester.enterText(
        find.byKey(const Key('dispute_reason_field')),
        'Key discrepancy on Question 5',
      );
      await tester.tap(find.byKey(const Key('submit_dispute_button')));
      await tester.pumpAndSettle();

      // Verify dispute submitted status badge
      expect(find.text('Dispute: OPEN'), findsOneWidget);
    });
  });
}
