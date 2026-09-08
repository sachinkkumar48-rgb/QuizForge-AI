/// P49 Assessment & Examination Management Closed-Loop Acceptance Scenario (Section 20).
///
/// Complete integration acceptance testing the full real lifecycle:
/// Faculty creates assessment with 5 questions -> configures marks & passing criteria ->
/// assigns to cohort -> publishes -> Learner discovers assessment -> starts attempt ->
/// answers 5 questions -> submits -> evaluated deterministically -> result generated ->
/// Learner inspects result -> Faculty views cohort results -> duplicate submission idempotency ->
/// offline snapshot persistence and synchronization.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart' show StructuredAnswer;
import 'package:garuda_learning/garuda_learning.dart';

class _AcceptanceQuestion implements IQuestionEntity {
  @override
  final String id;
  @override
  final String prompt;
  @override
  final List<String> options;
  @override
  final String expectedAnswer;
  const _AcceptanceQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.expectedAnswer,
  });

  @override
  String? get explanation => 'Constitutional law precedent';
  @override
  String get provenance => 'UPSC 2024 GS Paper 1';
  @override
  List<String> get objectiveIds => const ['obj_upsc_polity_core'];
  @override
  QuestionExamMetadata? get examMetadata => null;

  @override
  String get questionId => id;
  @override
  String get questionText => prompt;
  @override
  StructuredAnswer get answer => StructuredAnswer(
        answerText: expectedAnswer,
        evidenceRefs: const ['ev:acceptance:001'],
        principles: const ['constitutional_supremacy'],
        provenance: provenance,
      );
  @override
  String get framing => 'Direct Conceptual';
  @override
  List<String> get sourceRefs => const ['src:upsc:2024:polity'];
}

void main() {
  group('P49 Section 20: Mandatory Closed-Loop Acceptance Scenario', () {
    late InMemoryAssessmentRepository repo;
    late InMemoryCohortRepository cohortRepo;
    late InMemoryQuestionProvider questionProvider;
    late AssessmentManagementService service;

    final q1 = const _AcceptanceQuestion(
      id: 'acc_q1',
      prompt: 'Under Article 19, how many freedoms are guaranteed?',
      options: ['5', '6', '7', '8'],
      expectedAnswer: '6',
    );
    final q2 = const _AcceptanceQuestion(
      id: 'acc_q2',
      prompt: 'Which Article abolishes Untouchability?',
      options: ['Article 15', 'Article 16', 'Article 17', 'Article 18'],
      expectedAnswer: 'Article 17',
    );
    final q3 = const _AcceptanceQuestion(
      id: 'acc_q3',
      prompt:
          'Right to Education was inserted by which Constitutional Amendment?',
      options: [
        '86th Amendment',
        '44th Amendment',
        '42nd Amendment',
        '91st Amendment'
      ],
      expectedAnswer: '86th Amendment',
    );
    final q4 = const _AcceptanceQuestion(
      id: 'acc_q4',
      prompt:
          'The procedure for amendment of the Constitution is laid down in Article?',
      options: ['Article 356', 'Article 360', 'Article 368', 'Article 370'],
      expectedAnswer: 'Article 368',
    );
    final q5 = const _AcceptanceQuestion(
      id: 'acc_q5',
      prompt: 'Who is the guardian of Fundamental Rights in India?',
      options: [
        'The President',
        'The Prime Minister',
        'The Supreme Court',
        'The Parliament'
      ],
      expectedAnswer: 'The Supreme Court',
    );

    setUp(() {
      repo = InMemoryAssessmentRepository();
      cohortRepo = InMemoryCohortRepository();
      questionProvider = InMemoryQuestionProvider([q1, q2, q3, q4, q5]);

      service = AssessmentManagementService(
        repository: repo,
        questionProvider: questionProvider,
        cohortRepository: cohortRepo,
      );
    });

    test(
        'Full closed-loop acceptance workflow: Authoring -> Distribution -> Examination -> Evaluation -> Review -> Idempotency -> Durability',
        () async {
      const facultyId = 'prof_anand';
      const learnerId = 'student_aditi';
      const cohortId = 'cohort_upsc_polity_2026';
      const assessmentId = 'upsc_2026_polity_summative_01';

      // -----------------------------------------------------------------------
      // Step 1: Institutional Cohort Provisioning
      // -----------------------------------------------------------------------
      final cohort = Cohort(
        cohortId: cohortId,
        name: 'UPSC 2026 Polity Intensive Batch',
        description: 'Elite civil services preparation cohort',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: facultyId,
        learnerIds: [learnerId, 'student_rahul', 'student_meera'],
      );
      await cohortRepo.saveCohort(cohort);

      // -----------------------------------------------------------------------
      // Step 2: Faculty Creates Formal Summative Assessment with 5 Questions
      // -----------------------------------------------------------------------
      final draft = await service.createAssessment(
        assessmentId: assessmentId,
        title: 'Polity & Fundamental Rights Summative Examination',
        description:
            'High-stakes formal evaluation of constitutional core competencies.',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: facultyId,
        questionIds: ['acc_q1', 'acc_q2', 'acc_q3', 'acc_q4', 'acc_q5'],
        marksConfig: const AssessmentMarksConfig(
          marksPerQuestion: 2.0,
          negativeMarkRatio: 0.3333333333333333, // 1/3 penalty = 0.66667
          passingPercentage: 40.0,
        ),
        timingConfig: const AssessmentTimingConfig(
          durationMinutes: 45,
        ),
        maxAttempts: 1,
        status: AssessmentStatus.draft,
      );

      expect(draft.status, AssessmentStatus.draft);
      expect(draft.questionCount, 5);
      expect(draft.totalMarks, 10.0);
      expect(draft.isVisibleToLearners, false);

      // -----------------------------------------------------------------------
      // Step 3: Faculty Assigns Cohort and Publishes Assessment
      // -----------------------------------------------------------------------
      await service.assignCohort(assessmentId, cohortId, facultyId: facultyId);
      final published =
          await service.publishAssessment(assessmentId, facultyId: facultyId);

      expect(published.status, AssessmentStatus.published);
      expect(published.isVisibleToLearners, true);
      expect(published.hasCohort(cohortId), true);

      // -----------------------------------------------------------------------
      // Step 4: Learner Discovers Assessment
      // -----------------------------------------------------------------------
      final learnerAvailable =
          await service.getAvailableAssessments(learnerId: learnerId);
      expect(learnerAvailable.length, 1);
      expect(learnerAvailable.first.assessmentId, assessmentId);

      // Other learner outside cohort cannot see it
      final outsiderAvailable =
          await service.getAvailableAssessments(learnerId: 'outsider_learner');
      expect(outsiderAvailable.isEmpty, true);

      // -----------------------------------------------------------------------
      // Step 5: Learner Starts Attempt
      // -----------------------------------------------------------------------
      final attempt = await service.startAttempt(
        assessmentId: assessmentId,
        learnerId: learnerId,
      );

      expect(attempt.status, AssessmentAttemptStatus.inProgress);
      expect(attempt.learnerId, learnerId);
      expect(attempt.assessmentId, assessmentId);
      expect(attempt.answeredCount, 0);

      // -----------------------------------------------------------------------
      // Step 6: Learner Answers 5 Questions (4 Correct, 1 Incorrect)
      // -----------------------------------------------------------------------
      // Q1: Correct ('6')
      await service.recordAnswer(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
        questionId: 'acc_q1',
        answer: '6',
      );

      // Q2: Correct ('Article 17')
      await service.recordAnswer(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
        questionId: 'acc_q2',
        answer: 'Article 17',
      );

      // Q3: Correct ('86th Amendment')
      await service.recordAnswer(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
        questionId: 'acc_q3',
        answer: '86th Amendment',
      );

      // Q4: Correct ('Article 368')
      await service.recordAnswer(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
        questionId: 'acc_q4',
        answer: 'Article 368',
      );

      // Q5: Incorrect ('The Prime Minister' instead of 'The Supreme Court')
      await service.recordAnswer(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
        questionId: 'acc_q5',
        answer: 'The Prime Minister',
      );

      final inProgressAttempt = await repo.getAttemptById(attempt.attemptId);
      expect(inProgressAttempt!.answeredCount, 5);

      // -----------------------------------------------------------------------
      // Step 7: Learner Submits Attempt -> Deterministic Evaluation
      // -----------------------------------------------------------------------
      final result = await service.submitAttempt(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
      );

      // Evaluation Verification:
      // Total Questions = 5
      // Correct = 4, Incorrect = 1, Unanswered = 0
      // 4 * 2.0 = 8.0
      // 1 * -(2.0 * 1/3) = -0.66667
      // Net score = 7.33333
      // Max score = 10.0
      // Percentage = 73.333%
      // Passing threshold = 40.0% -> PASSED
      expect(result.attemptedCount, 5);
      expect(result.correctCount, 4);
      expect(result.incorrectCount, 1);
      expect(result.unansweredCount, 0);
      expect(result.maxScore, 10.0);
      expect(result.score, closeTo(7.33, 0.05));
      expect(result.percentage, closeTo(73.33, 0.05));
      expect(result.isPassed, true);
      expect(result.questionResults.length, 5);

      // Check specific question results
      final q5Result =
          result.questionResults.firstWhere((r) => r.questionId == 'acc_q5');
      expect(q5Result.isCorrect, false);
      expect(q5Result.submittedAnswer, 'The Prime Minister');
      expect(q5Result.expectedAnswer, 'The Supreme Court');
      expect(q5Result.marksAwarded, closeTo(-0.67, 0.05));

      // -----------------------------------------------------------------------
      // Step 8: Learner Inspects Result
      // -----------------------------------------------------------------------
      final viewedByLearner = await service.getResult(
        resultId: result.resultId,
        requesterId: learnerId,
        isFaculty: false,
      );
      expect(viewedByLearner.resultId, result.resultId);
      expect(viewedByLearner.score, result.score);

      // -----------------------------------------------------------------------
      // Step 9: Faculty Views Cohort Results
      // -----------------------------------------------------------------------
      final cohortSummary = await service.getAssessmentCohortSummary(
        assessmentId,
        cohortId,
        facultyId: facultyId,
      );

      expect(cohortSummary.totalLearners, 3);
      expect(cohortSummary.attemptedCount, 1);
      expect(cohortSummary.submittedCount, 1);
      expect(cohortSummary.passCount, 1);
      expect(cohortSummary.failCount, 0);
      expect(cohortSummary.averageScore, closeTo(7.33, 0.05));
      expect(cohortSummary.averagePercentage, closeTo(73.33, 0.05));
      expect(cohortSummary.results.length, 1);
      expect(cohortSummary.results.first.learnerId, learnerId);

      // -----------------------------------------------------------------------
      // Step 10: Idempotency Verification (Duplicate Submissions)
      // -----------------------------------------------------------------------
      final duplicateResult = await service.submitAttempt(
        attemptId: attempt.attemptId,
        learnerId: learnerId,
      );
      expect(duplicateResult.resultId, result.resultId);
      expect(duplicateResult.score, result.score);

      final allResults = await repo.listResults(assessmentId: assessmentId);
      expect(allResults.length, 1); // Strictly no duplicate records

      // Attempt limit prevents second attempt
      expect(
        () => service.startAttempt(
            assessmentId: assessmentId, learnerId: learnerId),
        throwsA(isA<AssessmentPolicyException>()),
      );

      // -----------------------------------------------------------------------
      // Step 11: Offline Synchronization & Snapshot Durability
      // -----------------------------------------------------------------------
      final exportedSnapshot = await repo.exportSnapshot();
      expect(exportedSnapshot['assessments'], isNotEmpty);
      expect(exportedSnapshot['attempts'], isNotEmpty);
      expect(exportedSnapshot['results'], isNotEmpty);

      final restoredRepo = InMemoryAssessmentRepository();
      await restoredRepo.importSnapshot(exportedSnapshot);

      final restoredResult = await restoredRepo.getResultById(result.resultId);
      expect(restoredResult, isNotNull);
      expect(restoredResult!.score, result.score);
      expect(restoredResult.percentage, result.percentage);
      expect(restoredResult.isPassed, true);
    });
  });
}
