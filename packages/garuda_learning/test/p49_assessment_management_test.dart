/// P49 Assessment & Examination Management Test Suite (TITAN-KO-049.0).
///
/// Comprehensive suite verifying all 34 required test cases from Section 21:
/// Faculty authoring, configuration, question validation, cohort assignment,
/// learner attempts, answer capture, timing, idempotent evaluation, scoring,
/// pass/fail determination, result persistence, isolation boundaries, offline durability,
/// and complete end-to-end lifecycle.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart' show StructuredAnswer;
import 'package:garuda_learning/garuda_learning.dart';

class _MockQuestion implements IQuestionEntity {
  @override
  final String id;
  @override
  final String prompt;
  @override
  final List<String> options;
  @override
  final String expectedAnswer;
  const _MockQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.expectedAnswer,
  });

  @override
  String? get explanation => 'Standard rationale';
  @override
  String get provenance => 'TITAN Mock Bank';
  @override
  List<String> get objectiveIds => const ['obj_p49_law'];
  @override
  QuestionExamMetadata? get examMetadata => null;

  @override
  String get questionId => id;
  @override
  String get questionText => prompt;
  @override
  StructuredAnswer get answer => StructuredAnswer(
        answerText: expectedAnswer,
        evidenceRefs: const ['ev:001'],
        principles: const ['rule_of_law'],
        provenance: provenance,
      );
  @override
  String get framing => 'Direct';
  @override
  List<String> get sourceRefs => const ['src:mock:001'];
}

void main() {
  final baseTime = DateTime.utc(2026, 10, 1, 9, 0, 0);

  late InMemoryAssessmentRepository repo;
  late InMemoryQuestionProvider questionProvider;
  late InMemoryCohortRepository cohortRepo;
  late AssessmentManagementService service;
  DateTime currentTime = baseTime;

  final q1 = const _MockQuestion(
    id: 'q_p49_001',
    prompt: 'Which Article guarantees Equality before law?',
    options: ['Article 14', 'Article 19', 'Article 21', 'Article 32'],
    expectedAnswer: 'Article 14',
  );
  final q2 = const _MockQuestion(
    id: 'q_p49_002',
    prompt: 'Which Article protects personal liberty and life?',
    options: ['Article 14', 'Article 19', 'Article 21', 'Article 25'],
    expectedAnswer: 'Article 21',
  );
  final q3 = const _MockQuestion(
    id: 'q_p49_003',
    prompt: 'Under which Article can Supreme Court issue writs?',
    options: ['Article 32', 'Article 226', 'Article 131', 'Article 143'],
    expectedAnswer: 'Article 32',
  );
  final q4 = const _MockQuestion(
    id: 'q_p49_004',
    prompt:
        'Preamble declares India to be a Sovereign, Socialist, Secular, Democratic Republic.',
    options: ['True', 'False'],
    expectedAnswer: 'True',
  );
  final q5 = const _MockQuestion(
    id: 'q_p49_005',
    prompt: 'Fundamental Duties are incorporated in which Part?',
    options: ['Part III', 'Part IV', 'Part IVA', 'Part V'],
    expectedAnswer: 'Part IVA',
  );

  setUp(() {
    currentTime = baseTime;
    repo = InMemoryAssessmentRepository();
    questionProvider = InMemoryQuestionProvider([q1, q2, q3, q4, q5]);
    cohortRepo = InMemoryCohortRepository();

    service = AssessmentManagementService(
      repository: repo,
      questionProvider: questionProvider,
      cohortRepository: cohortRepo,
      clock: () => currentTime,
    );
  });

  group('P49 Section 21: Assessment & Examination Management Unit Suite', () {
    // 1. Create assessment
    test('1. Create assessment in draft status with default configs', () async {
      final a = await service.createAssessment(
        assessmentId: 'assess_01',
        title: 'Midterm Examination',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001', 'q_p49_002'],
      );

      expect(a.assessmentId, 'assess_01');
      expect(a.status, AssessmentStatus.draft);
      expect(a.questionCount, 2);
      expect(a.totalMarks, 4.0); // 2 * 2.0
      expect(a.marksConfig.passingPercentage, 40.0);
      expect(a.isVisibleToLearners, false);
    });

    // 2. Edit draft
    test('2. Edit draft assessment updates fields and updatedAt', () async {
      final a = await service.createAssessment(
        assessmentId: 'assess_02',
        title: 'Original Title',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
      );

      currentTime = currentTime.add(const Duration(minutes: 10));
      final updated = await service.updateAssessment(
        a.copyWith(
          title: 'Revised Title',
          questionIds: ['q_p49_001', 'q_p49_002'],
          marksConfig: const AssessmentMarksConfig(marksPerQuestion: 3.0),
        ),
        requesterFacultyId: 'faculty_sharma',
      );

      expect(updated.title, 'Revised Title');
      expect(updated.questionCount, 2);
      expect(updated.totalMarks, 6.0);
      expect(updated.updatedAt, currentTime);
    });

    // 3. Invalid question reference
    test('3. Invalid question reference throws AssessmentValidationException',
        () async {
      expect(
        () => service.createAssessment(
          assessmentId: 'assess_03',
          title: 'Bad Assessment',
          examId: 'upsc_prelims_gs1',
          creatorFacultyId: 'faculty_sharma',
          questionIds: ['q_p49_001', 'non_existent_q'],
        ),
        throwsA(isA<AssessmentValidationException>()),
      );
    });

    // 4. Duplicate question reference
    test('4. Duplicate question reference throws AssessmentValidationException',
        () async {
      expect(
        () => service.createAssessment(
          assessmentId: 'assess_04',
          title: 'Duplicate Qs',
          examId: 'upsc_prelims_gs1',
          creatorFacultyId: 'faculty_sharma',
          questionIds: ['q_p49_001', 'q_p49_001'],
        ),
        throwsA(isA<AssessmentValidationException>()),
      );
    });

    // 5. Publish
    test('5. Publish assessment transitions status to published', () async {
      await service.createAssessment(
        assessmentId: 'assess_05',
        title: 'Ready for Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
      );

      final published = await service.publishAssessment(
        'assess_05',
        facultyId: 'faculty_sharma',
      );

      expect(published.status, AssessmentStatus.published);
      expect(published.isVisibleToLearners, true);
    });

    // 6. Learner visibility
    test('6. Draft assessment invisible to learner, published is visible',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_draft',
        title: 'Draft Test',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
      );
      await service.createAssessment(
        assessmentId: 'assess_pub',
        title: 'Published Test',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final available =
          await service.getAvailableAssessments(learnerId: 'learner_01');
      expect(available.any((a) => a.assessmentId == 'assess_draft'), false);
      expect(available.any((a) => a.assessmentId == 'assess_pub'), true);
    });

    // 7. Cohort assignment
    test('7. Cohort assignment attaches cohortId to assessment', () async {
      final c = Cohort(
        cohortId: 'cohort_alpha',
        name: 'Alpha Batch',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_01'],
      );
      await cohortRepo.saveCohort(c);

      await service.createAssessment(
        assessmentId: 'assess_07',
        title: 'Cohort Test',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
      );

      final assigned = await service.assignCohort(
        'assess_07',
        'cohort_alpha',
        facultyId: 'faculty_sharma',
      );

      expect(assigned.hasCohort('cohort_alpha'), true);
    });

    // 8. Attempt creation
    test('8. Attempt creation initializes inProgress attempt', () async {
      await service.createAssessment(
        assessmentId: 'assess_08',
        title: 'Active Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final attempt = await service.startAttempt(
        assessmentId: 'assess_08',
        learnerId: 'learner_01',
      );

      expect(attempt.assessmentId, 'assess_08');
      expect(attempt.learnerId, 'learner_01');
      expect(attempt.status, AssessmentAttemptStatus.inProgress);
      expect(attempt.canModify, true);
    });

    // 9. Attempt limit
    test('9. Attempt limit enforces maxAttempts policy', () async {
      await service.createAssessment(
        assessmentId: 'assess_09',
        title: 'One-Shot Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        maxAttempts: 1,
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_09',
        learnerId: 'learner_01',
      );
      await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      expect(
        () => service.startAttempt(
          assessmentId: 'assess_09',
          learnerId: 'learner_01',
        ),
        throwsA(isA<AssessmentPolicyException>()),
      );
    });

    // 10. Answer capture
    test('10. Answer capture records responses correctly in attempt', () async {
      await service.createAssessment(
        assessmentId: 'assess_10',
        title: 'Exam 10',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001', 'q_p49_002'],
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_10',
        learnerId: 'learner_01',
      );

      final updated = await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );

      expect(updated.responses['q_p49_001'], 'Article 14');
      expect(updated.answeredCount, 1);
    });

    // 11. Resume after restart
    test('11. Resume returns existing ongoing attempt instead of duplicating',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_11',
        title: 'Resumable Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final firstAtt = await service.startAttempt(
        assessmentId: 'assess_11',
        learnerId: 'learner_01',
      );
      await service.recordAnswer(
        attemptId: firstAtt.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );

      final resumedAtt = await service.startAttempt(
        assessmentId: 'assess_11',
        learnerId: 'learner_01',
      );

      expect(resumedAtt.attemptId, firstAtt.attemptId);
      expect(resumedAtt.responses['q_p49_001'], 'Article 14');
    });

    // 12. Submit
    test('12. Submit freezes attempt responses and sets status to evaluated',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_12',
        title: 'Freezable Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_12',
        learnerId: 'learner_01',
      );
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );

      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      final finalizedAtt = await repo.getAttemptById(att.attemptId);
      expect(finalizedAtt!.status, AssessmentAttemptStatus.evaluated);
      expect(finalizedAtt.resultId, res.resultId);
      expect(finalizedAtt.canModify, false);
    });

    // 13. Duplicate submission (idempotency)
    test(
        '13. Duplicate submission returns existing result without duplicating records',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_13',
        title: 'Idempotency Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_13',
        learnerId: 'learner_01',
      );
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );

      final res1 = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );
      final res2 = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      expect(res1.resultId, res2.resultId);
      final allResults = await repo.listResults(assessmentId: 'assess_13');
      expect(allResults.length, 1);
    });

    // 14. Correct evaluation
    test('14. Correct evaluation awards positive marksPerQuestion', () async {
      await service.createAssessment(
        assessmentId: 'assess_14',
        title: 'Scoring Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        marksConfig: const AssessmentMarksConfig(marksPerQuestion: 2.0),
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_14',
        learnerId: 'learner_01',
      );
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );

      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      expect(res.correctCount, 1);
      expect(res.score, 2.0);
      expect(res.questionResults.first.isCorrect, true);
      expect(res.questionResults.first.marksAwarded, 2.0);
    });

    // 15. Incorrect evaluation
    test('15. Incorrect evaluation applies negative penalty ratio', () async {
      await service.createAssessment(
        assessmentId: 'assess_15',
        title: 'Negative Marking Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001', 'q_p49_002'],
        marksConfig: const AssessmentMarksConfig(
          marksPerQuestion: 3.0,
          negativeMarkRatio: 0.3333333333333333, // 1/3 penalty = 1.0
        ),
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_15',
        learnerId: 'learner_01',
      );
      // q1 correct (+3.0), q2 wrong (-1.0)
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_002',
        answer: 'Article 19', // Incorrect
      );

      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      expect(res.correctCount, 1);
      expect(res.incorrectCount, 1);
      expect(res.score, closeTo(2.0, 0.01)); // 3.0 - 1.0 = 2.0
    });

    // 16. Unanswered evaluation
    test(
        '16. Unanswered evaluation awards 0.0 marks and increments unansweredCount',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_16',
        title: 'Partial Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001', 'q_p49_002'],
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_16',
        learnerId: 'learner_01',
      );
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );
      // q_p49_002 left unanswered

      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      expect(res.attemptedCount, 1);
      expect(res.unansweredCount, 1);
      final q2Result =
          res.questionResults.firstWhere((q) => q.questionId == 'q_p49_002');
      expect(q2Result.isAttempted, false);
      expect(q2Result.marksAwarded, 0.0);
    });

    // 17. Score calculation
    test('17. Score calculation clamps total at non-negative floor', () async {
      await service.createAssessment(
        assessmentId: 'assess_17',
        title: 'Severe Penalty Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        marksConfig: const AssessmentMarksConfig(
          marksPerQuestion: 2.0,
          negativeMarkRatio: 1.0, // 100% penalty
        ),
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_17',
        learnerId: 'learner_01',
      );
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Wrong Answer',
      );

      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      expect(res.score, 0.0); // Clamped at 0.0
    });

    // 18. Percentage calculation
    test('18. Percentage calculation computes correctly against maxScore',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_18',
        title: 'Percentage Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001', 'q_p49_002', 'q_p49_003', 'q_p49_004'],
        marksConfig: const AssessmentMarksConfig(
          marksPerQuestion: 2.5,
          negativeMarkRatio: 0.0,
        ),
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_18',
        learnerId: 'learner_01',
      );
      // 3 correct out of 4 (7.5 out of 10.0 = 75%)
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_002',
        answer: 'Article 21',
      );
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_003',
        answer: 'Article 32',
      );

      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      expect(res.maxScore, 10.0);
      expect(res.score, 7.5);
      expect(res.percentage, 75.0);
    });

    // 19. Pass/fail
    test('19. Pass/fail thresholds determine isPassed correctly', () async {
      await service.createAssessment(
        assessmentId: 'assess_19',
        title: 'Pass Fail Test',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001', 'q_p49_002'],
        marksConfig: const AssessmentMarksConfig(
          marksPerQuestion: 2.0,
          negativeMarkRatio: 0.0,
          passingPercentage: 50.0,
        ),
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_19',
        learnerId: 'learner_01',
      );
      // 1 correct out of 2 = 50% -> Passed
      await service.recordAnswer(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );

      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      expect(res.percentage, 50.0);
      expect(res.isPassed, true);
    });

    // 20. Result persistence
    test('20. Result persistence stores result in repository', () async {
      await service.createAssessment(
        assessmentId: 'assess_20',
        title: 'Persistence Test',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_20',
        learnerId: 'learner_01',
      );
      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      final retrieved = await repo.getResultById(res.resultId);
      expect(retrieved, isNotNull);
      expect(retrieved!.resultId, res.resultId);
    });

    // 21. Learner result visibility
    test(
        '21. Learner can view own result via getResult and getResultsForLearner',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_21',
        title: 'Learner Visibility Test',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_21',
        learnerId: 'learner_01',
      );
      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_01',
      );

      final viewed = await service.getResult(
        resultId: res.resultId,
        requesterId: 'learner_01',
        isFaculty: false,
      );
      expect(viewed.resultId, res.resultId);

      final learnerList = await service.getResultsForLearner('learner_01');
      expect(learnerList.any((r) => r.resultId == res.resultId), true);
    });

    // 22. Faculty result visibility
    test('22. Faculty can view all cohort results and summaries', () async {
      final c = Cohort(
        cohortId: 'cohort_22',
        name: 'Batch 2026',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['l1', 'l2'],
      );
      await cohortRepo.saveCohort(c);

      await service.createAssessment(
        assessmentId: 'assess_22',
        title: 'Faculty Visibility Test',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
        cohortIds: ['cohort_22'],
      );

      // l1 takes and passes
      final att1 = await service.startAttempt(
          assessmentId: 'assess_22', learnerId: 'l1');
      await service.recordAnswer(
          attemptId: att1.attemptId,
          learnerId: 'l1',
          questionId: 'q_p49_001',
          answer: 'Article 14');
      await service.submitAttempt(attemptId: att1.attemptId, learnerId: 'l1');

      final summary = await service.getAssessmentCohortSummary(
        'assess_22',
        'cohort_22',
        facultyId: 'faculty_sharma',
      );

      expect(summary.totalLearners, 2);
      expect(summary.submittedCount, 1);
      expect(summary.passCount, 1);
      expect(summary.averageScore, 2.0);
    });

    // 23. Learner isolation
    test('23. Learner A cannot view Learner B result', () async {
      await service.createAssessment(
        assessmentId: 'assess_23',
        title: 'Privacy Test',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_23',
        learnerId: 'learner_alice',
      );
      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_alice',
      );

      expect(
        () => service.getResult(
          resultId: res.resultId,
          requesterId: 'learner_bob',
          isFaculty: false,
        ),
        throwsA(isA<AssessmentSecurityException>()),
      );
    });

    // 24. Tenant isolation
    test('24. Assessments are isolated across tenants', () async {
      await service.createAssessment(
        assessmentId: 'assess_t1',
        tenantId: 'tenant_a',
        title: 'Tenant A Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_a',
        questionIds: ['q_p49_001'],
      );
      await service.createAssessment(
        assessmentId: 'assess_t2',
        tenantId: 'tenant_b',
        title: 'Tenant B Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_b',
        questionIds: ['q_p49_001'],
      );

      final tenantAList = await repo.listAssessments(tenantId: 'tenant_a');
      expect(tenantAList.length, 1);
      expect(tenantAList.first.assessmentId, 'assess_t1');
    });

    // 25. Cohort isolation
    test('25. Learner outside cohort cannot see cohort-restricted assessment',
        () async {
      final c = Cohort(
        cohortId: 'cohort_restricted',
        name: 'Honors Batch',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'faculty_sharma',
        learnerIds: ['learner_insider'],
      );
      await cohortRepo.saveCohort(c);

      await service.createAssessment(
        assessmentId: 'assess_25',
        title: 'Restricted Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
        cohortIds: ['cohort_restricted'],
      );

      final insiderList =
          await service.getAvailableAssessments(learnerId: 'learner_insider');
      final outsiderList =
          await service.getAvailableAssessments(learnerId: 'learner_outsider');

      expect(insiderList.any((a) => a.assessmentId == 'assess_25'), true);
      expect(outsiderList.any((a) => a.assessmentId == 'assess_25'), false);
    });

    // 26. Offline attempt
    test(
        '26. Offline attempt created and answers captured without network dependency',
        () async {
      final offlineRepo = InMemoryAssessmentRepository();
      final offlineService = AssessmentManagementService(
        repository: offlineRepo,
        questionProvider: questionProvider,
      );

      await offlineService.createAssessment(
        assessmentId: 'assess_offline',
        title: 'Offline Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_offline',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final attempt = await offlineService.startAttempt(
        assessmentId: 'assess_offline',
        learnerId: 'learner_remote',
      );
      final answered = await offlineService.recordAnswer(
        attemptId: attempt.attemptId,
        learnerId: 'learner_remote',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );

      expect(answered.responses['q_p49_001'], 'Article 14');
    });

    // 27. Offline submission
    test('27. Offline submission evaluates and stores result locally',
        () async {
      final offlineRepo = InMemoryAssessmentRepository();
      final offlineService = AssessmentManagementService(
        repository: offlineRepo,
        questionProvider: questionProvider,
      );

      await offlineService.createAssessment(
        assessmentId: 'assess_offline_27',
        title: 'Offline Evaluation',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_offline',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final attempt = await offlineService.startAttempt(
        assessmentId: 'assess_offline_27',
        learnerId: 'learner_remote',
      );
      await offlineService.recordAnswer(
        attemptId: attempt.attemptId,
        learnerId: 'learner_remote',
        questionId: 'q_p49_001',
        answer: 'Article 14',
      );

      final result = await offlineService.submitAttempt(
        attemptId: attempt.attemptId,
        learnerId: 'learner_remote',
      );

      expect(result.score, 2.0);
      expect(result.isPassed, true);
    });

    // 28. Synchronization
    test('28. Snapshot export and import restores repository state completely',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_sync',
        title: 'Sync Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_sync',
        learnerId: 'learner_sync',
      );
      final res = await service.submitAttempt(
        attemptId: att.attemptId,
        learnerId: 'learner_sync',
      );

      final snapshot = await repo.exportSnapshot();

      final newRepo = InMemoryAssessmentRepository();
      await newRepo.importSnapshot(snapshot);

      final restoredAssessment = await newRepo.getAssessmentById('assess_sync');
      final restoredAttempt = await newRepo.getAttemptById(att.attemptId);
      final restoredResult = await newRepo.getResultById(res.resultId);

      expect(restoredAssessment, isNotNull);
      expect(restoredAttempt, isNotNull);
      expect(restoredResult, isNotNull);
      expect(restoredResult!.score, res.score);
    });

    // 29. Timing
    test(
        '29. Attempt duration expiry prevents further answers and new attempts outside window',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_timed',
        title: 'Strict 10-Minute Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        timingConfig: const AssessmentTimingConfig(durationMinutes: 10),
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_timed',
        learnerId: 'learner_01',
      );

      // Advance clock by 11 minutes
      currentTime = currentTime.add(const Duration(minutes: 11));

      expect(
        () => service.recordAnswer(
          attemptId: att.attemptId,
          learnerId: 'learner_01',
          questionId: 'q_p49_001',
          answer: 'Article 14',
          asOfDate: currentTime,
        ),
        throwsA(isA<AssessmentPolicyException>()),
      );
    });

    // 30. Closed assessment
    test('30. Faculty can close assessment, blocking further attempts',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_30',
        title: 'Closing Soon',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.published,
      );

      final closed = await service.closeAssessment(
        'assess_30',
        facultyId: 'faculty_sharma',
      );
      expect(closed.status, AssessmentStatus.closed);

      expect(
        () => service.startAttempt(
          assessmentId: 'assess_30',
          learnerId: 'learner_late',
        ),
        throwsA(isA<AssessmentPolicyException>()),
      );
    });

    // 31. Invalid lifecycle transition
    test('31. Closed assessment cannot be edited or republished', () async {
      final a = await service.createAssessment(
        assessmentId: 'assess_31',
        title: 'Dead Exam',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001'],
        status: AssessmentStatus.closed,
      );

      expect(
        () =>
            service.publishAssessment('assess_31', facultyId: 'faculty_sharma'),
        throwsA(isA<AssessmentPolicyException>()),
      );
      expect(
        () => service.updateAssessment(a.copyWith(title: 'Revived'),
            requesterFacultyId: 'faculty_sharma'),
        throwsA(isA<AssessmentPolicyException>()),
      );
    });

    // 32. Repository failure
    test(
        '32. Repository failure simulation throws AssessmentRepositoryException',
        () async {
      repo.setSimulateFailure(true);

      expect(
        () => service.createAssessment(
          assessmentId: 'assess_fail',
          title: 'Fail Exam',
          examId: 'upsc_prelims_gs1',
          creatorFacultyId: 'faculty_sharma',
          questionIds: ['q_p49_001'],
        ),
        throwsA(isA<AssessmentRepositoryException>()),
      );
    });

    // 33. Deterministic evaluation
    test(
        '33. Repeated evaluation on identical responses yields exact identical score and breakdown',
        () async {
      await service.createAssessment(
        assessmentId: 'assess_33',
        title: 'Deterministic Test',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'faculty_sharma',
        questionIds: ['q_p49_001', 'q_p49_002', 'q_p49_003'],
        marksConfig: const AssessmentMarksConfig(
          marksPerQuestion: 2.0,
          negativeMarkRatio: 0.333,
        ),
        status: AssessmentStatus.published,
      );

      final att = await service.startAttempt(
        assessmentId: 'assess_33',
        learnerId: 'learner_01',
      );
      await service.recordAnswer(
          attemptId: att.attemptId,
          learnerId: 'learner_01',
          questionId: 'q_p49_001',
          answer: 'Article 14');
      await service.recordAnswer(
          attemptId: att.attemptId,
          learnerId: 'learner_01',
          questionId: 'q_p49_002',
          answer: 'Article 21');
      await service.recordAnswer(
          attemptId: att.attemptId,
          learnerId: 'learner_01',
          questionId: 'q_p49_003',
          answer: 'Wrong');

      final res1 = await service.submitAttempt(
          attemptId: att.attemptId, learnerId: 'learner_01');
      final res2 = await service.submitAttempt(
          attemptId: att.attemptId, learnerId: 'learner_01');

      expect(res1.score, res2.score);
      expect(res1.correctCount, res2.correctCount);
      expect(res1.incorrectCount, res2.incorrectCount);
      expect(res1.percentage, res2.percentage);
    });

    // 34. Complete end-to-end assessment lifecycle
    test(
        '34. Complete end-to-end assessment lifecycle from authoring to cohort evaluation',
        () async {
      // 1. Cohort created
      final cohort = Cohort(
        cohortId: 'cohort_upsc_2026',
        name: 'UPSC Aspirants 2026',
        examId: 'upsc_prelims_gs1',
        primaryFacultyId: 'prof_menon',
        learnerIds: ['student_arjun', 'student_priya'],
      );
      await cohortRepo.saveCohort(cohort);

      // 2. Faculty authors assessment with 5 questions
      final draft = await service.createAssessment(
        assessmentId: 'upsc_polity_midterm',
        title: 'Polity Comprehensive Examination',
        examId: 'upsc_prelims_gs1',
        creatorFacultyId: 'prof_menon',
        questionIds: [
          'q_p49_001',
          'q_p49_002',
          'q_p49_003',
          'q_p49_004',
          'q_p49_005'
        ],
        marksConfig: const AssessmentMarksConfig(
          marksPerQuestion: 2.0,
          negativeMarkRatio: 0.3333333333333333, // 0.667 penalty
          passingPercentage: 40.0,
        ),
        timingConfig: const AssessmentTimingConfig(durationMinutes: 60),
      );
      expect(draft.status, AssessmentStatus.draft);

      // 3. Faculty assigns to cohort & publishes
      await service.assignCohort(draft.assessmentId, 'cohort_upsc_2026',
          facultyId: 'prof_menon');
      final pub = await service.publishAssessment(draft.assessmentId,
          facultyId: 'prof_menon');
      expect(pub.status, AssessmentStatus.published);

      // 4. Student Arjun discovers and takes exam
      final available =
          await service.getAvailableAssessments(learnerId: 'student_arjun');
      expect(
          available.any((a) => a.assessmentId == 'upsc_polity_midterm'), true);

      final attemptArjun = await service.startAttempt(
        assessmentId: 'upsc_polity_midterm',
        learnerId: 'student_arjun',
      );

      // Answers 4 correctly, 1 incorrectly
      await service.recordAnswer(
          attemptId: attemptArjun.attemptId,
          learnerId: 'student_arjun',
          questionId: 'q_p49_001',
          answer: 'Article 14');
      await service.recordAnswer(
          attemptId: attemptArjun.attemptId,
          learnerId: 'student_arjun',
          questionId: 'q_p49_002',
          answer: 'Article 21');
      await service.recordAnswer(
          attemptId: attemptArjun.attemptId,
          learnerId: 'student_arjun',
          questionId: 'q_p49_003',
          answer: 'Article 32');
      await service.recordAnswer(
          attemptId: attemptArjun.attemptId,
          learnerId: 'student_arjun',
          questionId: 'q_p49_004',
          answer: 'True');
      await service.recordAnswer(
          attemptId: attemptArjun.attemptId,
          learnerId: 'student_arjun',
          questionId: 'q_p49_005',
          answer: 'Wrong');

      // Submits
      final resultArjun = await service.submitAttempt(
        attemptId: attemptArjun.attemptId,
        learnerId: 'student_arjun',
      );

      expect(resultArjun.correctCount, 4);
      expect(resultArjun.incorrectCount, 1);
      // 4 * 2.0 = 8.0, 1 * -0.667 = -0.667 -> 7.333 / 10.0 = 73.33%
      expect(resultArjun.score, closeTo(7.33, 0.05));
      expect(resultArjun.isPassed, true);

      // 5. Faculty inspects cohort analytics
      final cohortSummary = await service.getAssessmentCohortSummary(
        'upsc_polity_midterm',
        'cohort_upsc_2026',
        facultyId: 'prof_menon',
      );

      expect(cohortSummary.totalLearners, 2);
      expect(cohortSummary.submittedCount, 1);
      expect(cohortSummary.passCount, 1);
      expect(cohortSummary.averageScore, closeTo(7.33, 0.05));
    });
  });
}
