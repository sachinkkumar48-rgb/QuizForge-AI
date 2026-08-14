import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('AssessmentService Tests (TITAN-KO-018.0 P18)', () {
    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryProgressRepository progressRepo;
    late CurriculumService curriculumService;
    late QuestionKnowledgeProductService questionService;
    late ProgressTracker progressTracker;
    late SessionManager sessionManager;
    late AssessmentService assessmentService;

    late Learner validLearner;
    late String validObjectiveId;
    late String validQuestionId;
    late String validCorrectAnswer;

    setUp(() {
      learnerRepo = InMemoryLearnerRepository();
      attemptRepo = InMemoryAttemptRepository();
      progressRepo = InMemoryProgressRepository();

      final seedFramework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: seedFramework);
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

      validLearner = Learner(id: 'learner_101', name: 'Alice');
      learnerRepo.save(validLearner);

      validObjectiveId = 'lo_basic_structure_doctrine';

      // Pick a valid P15 question ID from questionService
      final questionProducts = questionService.buildAll();
      final firstQuestion = questionProducts.first.questions.first;
      validQuestionId = firstQuestion.questionId;
      // The genuinely correct answer for the selected corpus question.
      validCorrectAnswer = firstQuestion.answer.answerText;
    });

    test('Valid attempt submission evaluates, persists, and updates progress',
        () {
      final result = assessmentService.submitAttempt(
        learnerId: validLearner.id,
        questionId: validQuestionId,
        objectiveId: validObjectiveId,
        submittedAnswer: 'Kesavananda Bharati v. State of Kerala (1973)',
      );

      expect(result, isNotNull);
      expect(result.attemptId, isNotEmpty);
      expect(result.score, greaterThanOrEqualTo(0.0));
      expect(result.score, lessThanOrEqualTo(1.0));

      // Verify stored attempt
      final storedAttempt = attemptRepo.getAttemptById(result.attemptId);
      expect(storedAttempt, isNotNull);
      expect(storedAttempt!.learnerId, equals(validLearner.id));
      expect(storedAttempt.questionId, equals(validQuestionId));
      expect(storedAttempt.objectiveId, equals(validObjectiveId));

      // Verify stored result
      final storedResult = attemptRepo.getResultForAttempt(result.attemptId);
      expect(storedResult, equals(result));

      // Verify progress updated
      final progress =
          progressRepo.getProgress(validLearner.id, validObjectiveId);
      expect(progress, isNotNull);
      expect(progress!.attemptCount, equals(1));
      expect(progress.status, equals(LearnerObjectiveStatus.inProgress));
    });

    test('submitAttempt rejects non-existent learner ID', () {
      expect(
        () => assessmentService.submitAttempt(
          learnerId: 'learner_missing',
          questionId: validQuestionId,
          objectiveId: validObjectiveId,
          submittedAnswer: 'Ans',
        ),
        throwsArgumentError,
      );
    });

    test('submitAttempt rejects non-existent objective ID', () {
      expect(
        () => assessmentService.submitAttempt(
          learnerId: validLearner.id,
          questionId: validQuestionId,
          objectiveId: 'lo_missing',
          submittedAnswer: 'Ans',
        ),
        throwsArgumentError,
      );
    });

    test('submitAttempt rejects non-existent question ID', () {
      expect(
        () => assessmentService.submitAttempt(
          learnerId: validLearner.id,
          questionId: 'q_missing_999',
          objectiveId: validObjectiveId,
          submittedAnswer: 'Ans',
        ),
        throwsArgumentError,
      );
    });

    test('submitAttempt updates session when valid sessionId is supplied', () {
      final session = sessionManager.startSession(
        learnerId: validLearner.id,
        objectiveIds: [validObjectiveId],
        questionIds: [validQuestionId],
      );

      final result = assessmentService.submitAttempt(
        learnerId: validLearner.id,
        questionId: validQuestionId,
        objectiveId: validObjectiveId,
        submittedAnswer: 'Ans',
        sessionId: session.sessionId,
      );

      final updatedSession = sessionManager.getSession(session.sessionId);
      expect(updatedSession!.attemptIds, contains(result.attemptId));
    });

    test('Repeated submissions update progress towards achievement', () {
      for (var i = 1; i <= 5; i++) {
        assessmentService.submitAttempt(
          learnerId: validLearner.id,
          questionId: validQuestionId,
          objectiveId: validObjectiveId,
          submittedAnswer: validCorrectAnswer,
        );
      }

      final progress =
          progressRepo.getProgress(validLearner.id, validObjectiveId);
      expect(progress, isNotNull);
      expect(progress!.attemptCount, equals(5));
      expect(progress.correctCount, equals(5));
      expect(progress.successRate, equals(1.0));
      expect(progress.status, equals(LearnerObjectiveStatus.achieved));
      expect(progress.isAchieved, isTrue);
    });
  });
}
