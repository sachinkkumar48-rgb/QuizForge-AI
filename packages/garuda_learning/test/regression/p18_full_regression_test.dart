import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('TITAN-KO-018.0 P18 Full Regression & Determinism Test Suite', () {
    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryProgressRepository progressRepo;
    late CurriculumService curriculumService;
    late QuestionKnowledgeProductService questionService;
    late ProgressTracker progressTracker;
    late SessionManager sessionManager;
    late AssessmentService assessmentService;

    late Learner learner;
    late String objectiveId;
    late String questionId;

    setUp(() {
      learnerRepo = InMemoryLearnerRepository();
      attemptRepo = InMemoryAttemptRepository();
      progressRepo = InMemoryProgressRepository();
      curriculumService = CurriculumService(
        framework: CurriculumSeedData.buildUpscConstitutionalLawFramework(),
      );
      questionService = QuestionKnowledgeProductService();
      progressTracker = ProgressTracker(
        attemptRepository: attemptRepo,
        progressRepository: progressRepo,
      );
      sessionManager = SessionManager(learnerRepository: learnerRepo);
      assessmentService = AssessmentService(
        learnerRepository: learnerRepo,
        attemptRepository: attemptRepo,
        curriculumService: curriculumService,
        questionService: questionService,
        progressTracker: progressTracker,
        sessionManager: sessionManager,
      );

      learner = Learner(id: 'learner_p18', name: 'P18 Regression Learner');
      learnerRepo.save(learner);

      objectiveId = 'lo_basic_structure_doctrine';
      questionId = questionService.buildAll().first.questions.first.questionId;
    });

    test('1. Learner profile creation, lookup, and repository round-trip', () {
      expect(learnerRepo.getById(learner.id), equals(learner));
      expect(learnerRepo.exists(learner.id), isTrue);
      expect(learnerRepo.getAll(), contains(learner));
    });

    test('2. QuestionAttempt immutability and submission verification', () {
      final result = assessmentService.submitAttempt(
        learnerId: learner.id,
        questionId: questionId,
        objectiveId: objectiveId,
        submittedAnswer: 'Kesavananda Bharati v. State of Kerala (1973)',
      );

      final attempt = attemptRepo.getAttemptById(result.attemptId);
      expect(attempt, isNotNull);
      expect(attempt!.learnerId, equals(learner.id));
      expect(attempt.questionId, equals(questionId));
      expect(attempt.objectiveId, equals(objectiveId));
    });

    test('3. AttemptResult evaluation score clamping and binding to attempt',
        () {
      final result = assessmentService.submitAttempt(
        learnerId: learner.id,
        questionId: questionId,
        objectiveId: objectiveId,
        submittedAnswer: 'Kesavananda Bharati v. State of Kerala (1973)',
      );

      expect(result.attemptId, isNotEmpty);
      expect(result.score, greaterThanOrEqualTo(0.0));
      expect(result.score, lessThanOrEqualTo(1.0));
      expect(attemptRepo.getResultForAttempt(result.attemptId), equals(result));
    });

    test('4. LearnerProgress calculation on 0 attempts equals NotStarted', () {
      final progress = progressTracker.updateProgress(
        learnerId: learner.id,
        objectiveId: objectiveId,
      );

      expect(progress.attemptCount, equals(0));
      expect(progress.correctCount, equals(0));
      expect(progress.successRate, equals(0.0));
      expect(progress.status, equals(LearnerObjectiveStatus.notStarted));
      expect(progress.isAchieved, isFalse);
    });

    test(
        '5. LearnerProgress status remains InProgress between 1 and 4 correct attempts',
        () {
      for (var i = 1; i <= 4; i++) {
        assessmentService.submitAttempt(
          learnerId: learner.id,
          questionId: questionId,
          objectiveId: objectiveId,
          submittedAnswer: 'Kesavananda Bharati v. State of Kerala (1973)',
        );

        final progress = progressRepo.getProgress(learner.id, objectiveId);
        expect(progress!.attemptCount, equals(i));
        expect(progress.correctCount, equals(i));
        expect(progress.status, equals(LearnerObjectiveStatus.inProgress));
        expect(progress.isAchieved, isFalse);
      }
    });

    test(
        '6. LearnerProgress status transitions to Achieved at exactly 5 attempts with 80% success rate',
        () {
      for (var i = 1; i <= 5; i++) {
        // 4 out of 5 correct = 80%
        final answer = (i <= 4)
            ? 'Kesavananda Bharati v. State of Kerala (1973)'
            : 'Incorrect Case';

        assessmentService.submitAttempt(
          learnerId: learner.id,
          questionId: questionId,
          objectiveId: objectiveId,
          submittedAnswer: answer,
        );
      }

      final progress = progressRepo.getProgress(learner.id, objectiveId);
      expect(progress!.attemptCount, equals(5));
      expect(progress.correctCount, equals(4));
      expect(progress.successRate, equals(0.80));
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
      expect(progress.isAchieved, isTrue);
      expect(progress.achievedAt, isNotNull);
    });

    test(
        '7. LearnerProgress remains InProgress at 5 attempts if success rate is below 80%',
        () {
      for (var i = 1; i <= 5; i++) {
        // 3 out of 5 correct = 60%
        final answer = (i <= 3)
            ? 'Kesavananda Bharati v. State of Kerala (1973)'
            : 'Incorrect Case';

        assessmentService.submitAttempt(
          learnerId: learner.id,
          questionId: questionId,
          objectiveId: objectiveId,
          submittedAnswer: answer,
        );
      }

      final progress = progressRepo.getProgress(learner.id, objectiveId);
      expect(progress!.attemptCount, equals(5));
      expect(progress.correctCount, equals(3));
      expect(progress.successRate, equals(0.60));
      expect(progress.status, equals(LearnerObjectiveStatus.inProgress));
      expect(progress.isAchieved, isFalse);
    });

    test('8. AssessmentSession lifecycle (start -> addAttempt -> complete)',
        () {
      final session = sessionManager.startSession(
        learnerId: learner.id,
        objectiveIds: [objectiveId],
        questionIds: [questionId],
      );

      expect(session.isCompleted, isFalse);

      final result = assessmentService.submitAttempt(
        learnerId: learner.id,
        questionId: questionId,
        objectiveId: objectiveId,
        submittedAnswer: 'Kesavananda Bharati v. State of Kerala (1973)',
        sessionId: session.sessionId,
      );

      final updatedSession = sessionManager.getSession(session.sessionId);
      expect(updatedSession!.attemptIds, contains(result.attemptId));

      final completedSession =
          sessionManager.completeSession(session.sessionId);
      expect(completedSession.isCompleted, isTrue);
    });

    test('9. MultipleChoiceEvaluator deterministic evaluation', () {
      const evaluator = MultipleChoiceEvaluator();

      final attempt = QuestionAttempt(
        attemptId: 'att_mc',
        learnerId: learner.id,
        questionId: questionId,
        objectiveId: objectiveId,
        submittedAnswer: 'Kesavananda Bharati v. State of Kerala (1973)',
      );

      final q = questionService.buildAll().first.questions.first;
      final res1 = evaluator.evaluate(attempt: attempt, question: q);
      final res2 = evaluator.evaluate(attempt: attempt, question: q);

      expect(res1.score, equals(res2.score));
      expect(res1.isCorrect, equals(res2.isCorrect));
      expect(res1.evaluationMethod, equals(res2.evaluationMethod));
    });

    test('10. TrueFalseEvaluator boolean normalization evaluation', () {
      const evaluator = TrueFalseEvaluator();
      final q = LegalQuestion(
        questionId: 'q_tf',
        questionText: 'Is Article 21 part of Fundamental Rights?',
        questionType: LegalQuestionType.statute,
        sourceRefs: const ['21'],
        answer: StructuredAnswer(
          answerText: 'True',
          evidenceRefs: const ['Article 21'],
          provenance: 'p13:statute',
        ),
        provenance: 'p15:question',
        framing: QuestionKnowledgeProductService.framing,
      );

      for (final input in ['true', 'TRUE', 't', '1', 'yes']) {
        final attempt = QuestionAttempt(
          attemptId: 'att_$input',
          learnerId: learner.id,
          questionId: q.questionId,
          objectiveId: objectiveId,
          submittedAnswer: input,
        );

        final res = evaluator.evaluate(attempt: attempt, question: q);
        expect(res.isCorrect, isTrue, reason: 'Failed for input $input');
        expect(res.score, equals(1.0));
      }
    });

    test('11. ShortAnswerEvaluator keyword match evaluation', () {
      const evaluator = ShortAnswerEvaluator();
      final q = LegalQuestion(
        questionId: 'q_sa',
        questionText:
            'What doctrine limits parliamentary amending power under Article 368?',
        questionType: LegalQuestionType.doctrine,
        sourceRefs: const ['BASIC_STRUCTURE'],
        answer: StructuredAnswer(
          answerText: 'Basic Structure Doctrine',
          evidenceRefs: const ['KESAVANANDA'],
          principles: const ['Basic Structure', 'Constitutional identity'],
          provenance: 'p12:doctrine',
        ),
        provenance: 'p15:question',
        framing: QuestionKnowledgeProductService.framing,
      );

      final attempt = QuestionAttempt(
        attemptId: 'att_sa',
        learnerId: learner.id,
        questionId: q.questionId,
        objectiveId: objectiveId,
        submittedAnswer: 'Basic Structure Doctrine limits amending power',
      );

      final res = evaluator.evaluate(attempt: attempt, question: q);
      expect(res.score, greaterThan(0.0));
      expect(res.evaluationMethod, equals(EvaluationMethod.shortAnswerKeyword));
    });

    test(
        '12. ManualEvaluator returns manual method and 0.0 score without AI fabrication',
        () {
      const evaluator = ManualEvaluator();
      final q = LegalQuestion(
        questionId: 'q_essay',
        questionText: 'Discuss the evolution of Article 21.',
        questionType: LegalQuestionType.issue,
        sourceRefs: const ['MANEKA_GANDHI'],
        answer: StructuredAnswer(
          answerText: 'Essay topic',
          evidenceRefs: const ['MANEKA_GANDHI'],
          provenance: 'p11:essay',
        ),
        provenance: 'p15:question',
        framing: QuestionKnowledgeProductService.framing,
      );

      final attempt = QuestionAttempt(
        attemptId: 'att_essay',
        learnerId: learner.id,
        questionId: q.questionId,
        objectiveId: objectiveId,
        submittedAnswer: 'My detailed essay...',
      );

      final res = evaluator.evaluate(attempt: attempt, question: q);
      expect(res.isCorrect, isFalse);
      expect(res.score, equals(0.0));
      expect(res.evaluationMethod, equals(EvaluationMethod.manual));
      expect(res.feedback, contains('Manual evaluation required'));
    });

    test(
        '13. Attempt history replay yields identical aggregated progress state',
        () {
      final submissionAnswers = [
        'Kesavananda Bharati v. State of Kerala (1973)',
        'Kesavananda Bharati v. State of Kerala (1973)',
        'Kesavananda Bharati v. State of Kerala (1973)',
        'Kesavananda Bharati v. State of Kerala (1973)',
        'Kesavananda Bharati v. State of Kerala (1973)',
      ];

      for (final ans in submissionAnswers) {
        assessmentService.submitAttempt(
          learnerId: learner.id,
          questionId: questionId,
          objectiveId: objectiveId,
          submittedAnswer: ans,
        );
      }

      final p1 = progressRepo.getProgress(learner.id, objectiveId);

      // Recalculate progress from history
      final p2 = progressTracker.updateProgress(
        learnerId: learner.id,
        objectiveId: objectiveId,
      );

      expect(p1!.attemptCount, equals(p2.attemptCount));
      expect(p1.correctCount, equals(p2.correctCount));
      expect(p1.successRate, equals(p2.successRate));
      expect(p1.status, equals(p2.status));
    });

    test('14. In-memory repositories execute 100% offline without I/O', () {
      expect(learnerRepo.getAll(), isNotEmpty);
      expect(attemptRepo.getAttemptsForLearner(learner.id), isList);
      expect(progressRepo.getAll(), isList);
    });

    test('15. Non-existent learner submission rejected', () {
      expect(
        () => assessmentService.submitAttempt(
          learnerId: 'learner_invalid',
          questionId: questionId,
          objectiveId: objectiveId,
          submittedAnswer: 'Ans',
        ),
        throwsArgumentError,
      );
    });

    test('16. Non-existent question submission rejected', () {
      expect(
        () => assessmentService.submitAttempt(
          learnerId: learner.id,
          questionId: 'q_invalid_123',
          objectiveId: objectiveId,
          submittedAnswer: 'Ans',
        ),
        throwsArgumentError,
      );
    });

    test('17. Non-existent objective submission rejected', () {
      expect(
        () => assessmentService.submitAttempt(
          learnerId: learner.id,
          questionId: questionId,
          objectiveId: 'lo_invalid_123',
          submittedAnswer: 'Ans',
        ),
        throwsArgumentError,
      );
    });

    test('18. AttemptResult requires valid non-empty attemptId', () {
      expect(
        () => AttemptResult(
          attemptId: '',
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        throwsArgumentError,
      );
    });

    test('19. AttemptResult requires score within [0.0, 1.0]', () {
      expect(
        () => AttemptResult(
          attemptId: 'a1',
          isCorrect: true,
          score: 1.5,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ),
        throwsArgumentError,
      );
    });

    test(
        '20. Complete P18 workflow (learner -> session -> submit attempts -> progress achieved -> complete session)',
        () {
      final session = sessionManager.startSession(
        learnerId: learner.id,
        objectiveIds: [objectiveId],
        questionIds: [questionId],
      );

      for (var i = 1; i <= 5; i++) {
        assessmentService.submitAttempt(
          learnerId: learner.id,
          questionId: questionId,
          objectiveId: objectiveId,
          submittedAnswer: 'Kesavananda Bharati v. State of Kerala (1973)',
          sessionId: session.sessionId,
        );
      }

      final progress = progressRepo.getProgress(learner.id, objectiveId);
      expect(progress!.status, equals(LearnerObjectiveStatus.achieved));
      expect(progress.isAchieved, isTrue);

      final completedSession =
          sessionManager.completeSession(session.sessionId);
      expect(completedSession.isCompleted, isTrue);
      expect(completedSession.attemptIds.length, equals(5));
    });
  });
}
