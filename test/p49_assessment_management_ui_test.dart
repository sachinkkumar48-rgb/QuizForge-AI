/// P49 Assessment Management UI Widget Test.
///
/// Verifies presentation layer:
/// - Faculty assessment dashboard & cards
/// - Switching between Faculty and Learner modes via SegmentedButton
/// - Learner available assessments list
/// - Active examination test-taking workflow (questions, options, answer capture, submission)
/// - Examination result presentation dialog
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart' show StructuredAnswer;
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/pages/assessment_management_page.dart';

class _UiTestQuestion implements IQuestionEntity {
  @override
  final String id;
  @override
  final String prompt;
  @override
  final List<String> options;
  @override
  final String expectedAnswer;
  const _UiTestQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.expectedAnswer,
  });

  @override
  String? get explanation => 'UI Test Rationale';
  @override
  String get provenance => 'TITAN UI Test Bank';
  @override
  List<String> get objectiveIds => const ['obj_ui_01'];
  @override
  QuestionExamMetadata? get examMetadata => null;

  @override
  String get questionId => id;
  @override
  String get questionText => prompt;
  @override
  StructuredAnswer get answer => StructuredAnswer(
        answerText: expectedAnswer,
        evidenceRefs: const ['ev:ui:001'],
        principles: const ['rule_of_law'],
        provenance: provenance,
      );
  @override
  String get framing => 'Direct';
  @override
  List<String> get sourceRefs => const ['src:ui:001'];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P49 Assessment Management UI Tests', () {
    late InMemoryAssessmentRepository repo;
    late InMemoryQuestionProvider questionProvider;
    late AssessmentManagementService service;

    final q1 = const _UiTestQuestion(
      id: 'q_ui_01',
      prompt: 'What is the minimum age to be eligible for Lok Sabha?',
      options: ['21 years', '25 years', '30 years', '35 years'],
      expectedAnswer: '25 years',
    );
    final q2 = const _UiTestQuestion(
      id: 'q_ui_02',
      prompt: 'Who appoints the Chief Justice of India?',
      options: ['Prime Minister', 'President', 'Law Minister', 'Parliament'],
      expectedAnswer: 'President',
    );

    setUp(() async {
      repo = InMemoryAssessmentRepository();
      questionProvider = InMemoryQuestionProvider([q1, q2]);
      service = AssessmentManagementService(
        repository: repo,
        questionProvider: questionProvider,
      );

      // Seed a published assessment
      await service.createAssessment(
        assessmentId: 'assess_ui_01',
        title: 'Polity Preliminary Examination',
        description: 'Comprehensive test on Parliament & Judiciary.',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_admin',
        questionIds: ['q_ui_01', 'q_ui_02'],
        marksConfig: const AssessmentMarksConfig(
          marksPerQuestion: 2.0,
          negativeMarkRatio: 0.333,
          passingPercentage: 40.0,
        ),
        timingConfig: const AssessmentTimingConfig(durationMinutes: 30),
        status: AssessmentStatus.published,
      );
    });

    testWidgets('Renders Faculty View and displays created assessment card',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AssessmentManagementPage(
            service: service,
            initialIsFaculty: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text("Assessments & Exams"), findsOneWidget);
      expect(find.text("Faculty"), findsOneWidget);
      expect(find.text("Learner"), findsOneWidget);

      // Check assessment card
      expect(find.text("Polity Preliminary Examination"), findsOneWidget);
      expect(find.text("Comprehensive test on Parliament & Judiciary."),
          findsOneWidget);
      expect(find.textContaining("2 Questions"), findsOneWidget);
      expect(find.byKey(const Key('create_assessment_button')), findsOneWidget);
    });

    testWidgets('Switches to Learner View and displays available assessment',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AssessmentManagementPage(
            service: service,
            initialIsFaculty: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Available Assessments"), findsOneWidget);
      expect(find.text("Completed Results"), findsOneWidget);
      expect(find.text("Polity Preliminary Examination"), findsOneWidget);
      expect(find.byKey(const Key('start_assessment_button_assess_ui_01')),
          findsOneWidget);
    });

    testWidgets('Learner starts assessment, answers questions, and submits',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AssessmentManagementPage(
            service: service,
            initialIsFaculty: false,
            initialLearnerId: 'student_tester',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap start assessment
      final startBtn =
          find.byKey(const Key('start_assessment_button_assess_ui_01'));
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Active exam screen
      expect(find.text("Question 1 of 2"), findsOneWidget);
      expect(find.text("What is the minimum age to be eligible for Lok Sabha?"),
          findsOneWidget);
      expect(find.text("25 years"), findsOneWidget);

      // Select '25 years'
      final option = find.byKey(const Key('option_q_ui_01_25 years'));
      expect(option, findsOneWidget);
      await tester.tap(option);
      await tester.pumpAndSettle();

      // Navigate to next question
      final nextBtn = find.byKey(const Key('next_question_button'));
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Question 2
      expect(find.text("Question 2 of 2"), findsOneWidget);
      expect(find.text("Who appoints the Chief Justice of India?"),
          findsOneWidget);

      // Select 'President'
      final option2 = find.byKey(const Key('option_q_ui_02_President'));
      expect(option2, findsOneWidget);
      await tester.tap(option2);
      await tester.pumpAndSettle();

      // Submit button appears on last question
      final submitBtn = find.byKey(const Key('submit_assessment_button'));
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.text("Submit Assessment?"), findsOneWidget);
      final confirmBtn = find.byKey(const Key('confirm_submit_button'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Result modal bottom sheet
      expect(find.text("Assessment Passed!"), findsOneWidget);
      expect(find.textContaining("Score: 4.0/4.0 (100.0%)"), findsOneWidget);
      expect(find.text("Correct"), findsOneWidget);
      expect(find.text("Close"), findsOneWidget);

      // Close modal
      await tester.tap(find.text("Close"));
      await tester.pumpAndSettle();

      // Switch to completed results tab
      await tester.tap(find.text("Completed Results"));
      await tester.pumpAndSettle();

      // Verify result card on completed results tab
      expect(
          find.text("Score: 4.0/4.0 (100.0%) • Correct: 2/2"), findsOneWidget);
      expect(find.text("PASSED"), findsOneWidget);
    });
  });
}
