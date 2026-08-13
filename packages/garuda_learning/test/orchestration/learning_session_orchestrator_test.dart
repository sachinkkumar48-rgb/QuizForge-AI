import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:test/test.dart';

void main() {
  group('LearningSessionOrchestrator Tests (TITAN-KO-019.0 P19)', () {
    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryProgressRepository progressRepo;
    late CurriculumService curriculumService;
    late QuestionKnowledgeProductService questionService;
    late ProgressTracker progressTracker;
    late SessionManager sessionManager;
    late AssessmentService assessmentService;
    late LearningSessionOrchestrator orchestrator;

    late Learner testLearner;

    setUp(() {
      learnerRepo = InMemoryLearnerRepository();
      attemptRepo = InMemoryAttemptRepository();
      progressRepo = InMemoryProgressRepository();

      testLearner = Learner(id: 'learner_101', name: 'Law Student');
      learnerRepo.save(testLearner);

      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
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

      orchestrator = LearningSessionOrchestrator(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionService: questionService,
        assessmentService: assessmentService,
        sessionManager: sessionManager,
        attemptRepository: attemptRepo,
        progressTracker: progressTracker,
      );
    });

    test(
        'createSession initializes session for verified learner and valid objective',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 5,
      );

      final session = orchestrator.createSession(config);

      expect(session.sessionId, isNotEmpty);
      expect(session.learnerId, 'learner_101');
      expect(session.state, LearningSessionState.created);
      expect(session.orderedQuestionIds, isNotEmpty);
      expect(session.totalQuestions, lessThanOrEqualTo(5));
      expect(session.currentQuestionIndex, 0);
      expect(session.assessmentSessionId, isNotNull);
    });

    test('createSession rejects non-existent learner ID', () {
      final config = SessionConfiguration(
        learnerId: 'ghost_learner_999',
        objectiveIds: ['lo_basic_structure_doctrine'],
      );

      expect(
        () => orchestrator.createSession(config),
        throwsArgumentError,
      );
    });

    test('createSession rejects non-existent objective ID', () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_non_existent_objective'],
      );

      expect(
        () => orchestrator.createSession(config),
        throwsArgumentError,
      );
    });

    test('startSession transitions session to active state', () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
      );
      final created = orchestrator.createSession(config);
      expect(created.state, LearningSessionState.created);

      final active = orchestrator.startSession(created.sessionId);
      expect(active.state, LearningSessionState.active);

      final currentQ = orchestrator.getCurrentQuestion(created.sessionId);
      expect(currentQ, isNotNull);
      expect(currentQ!.questionId, active.currentQuestionId);
    });

    test('submitAnswer evaluates, advances index, and updates P18 progress',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 2,
      );
      final created = orchestrator.createSession(config);
      orchestrator.startSession(created.sessionId);

      final currentQ = orchestrator.getCurrentQuestion(created.sessionId)!;
      final expectedAns = currentQ.answer.answerText;

      final result = orchestrator.submitAnswer(
        created.sessionId,
        expectedAns,
      );

      expect(result.attemptId, isNotEmpty);
      expect(result.isCorrect, isTrue);

      final sessionAfterFirst = orchestrator.getSession(created.sessionId)!;
      expect(sessionAfterFirst.answeredCount, 1);

      // Verify P18 LearnerProgress was updated
      final progress = progressTracker.getProgress(
          'learner_101', 'lo_basic_structure_doctrine');
      expect(progress, isNotNull);
      expect(progress!.attemptCount, 1);
      expect(progress.correctCount, 1);
    });

    test(
        'submitAnswer automatically completes session when all questions answered',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 2,
      );
      final created = orchestrator.createSession(config);
      orchestrator.startSession(created.sessionId);

      final total = created.totalQuestions;

      for (var i = 0; i < total; i++) {
        final currentQ = orchestrator.getCurrentQuestion(created.sessionId);
        if (currentQ != null) {
          orchestrator.submitAnswer(created.sessionId, 'any answer');
        }
      }

      final session = orchestrator.getSession(created.sessionId)!;
      expect(session.state, LearningSessionState.completed);
      expect(session.isFinished, isTrue);
      expect(orchestrator.getCurrentQuestion(created.sessionId), isNull);
    });

    test('pauseSession, resumeSession, and getSessionProgress metrics work',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 3,
      );
      final session = orchestrator.createSession(config);
      orchestrator.startSession(session.sessionId);

      final paused = orchestrator.pauseSession(session.sessionId);
      expect(paused.state, LearningSessionState.paused);

      final resumed = orchestrator.resumeSession(session.sessionId);
      expect(resumed.state, LearningSessionState.active);

      final summary = orchestrator.getSessionProgress(session.sessionId);
      expect(summary.sessionId, session.sessionId);
      expect(summary.learnerId, 'learner_101');
      expect(summary.answeredCount, 0);
      expect(summary.currentScore, 0.0);
    });

    test('cancelSession transitions session state to cancelled', () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
      );
      final session = orchestrator.createSession(config);
      orchestrator.startSession(session.sessionId);

      final cancelled = orchestrator.cancelSession(session.sessionId);
      expect(cancelled.state, LearningSessionState.cancelled);
      expect(cancelled.isFinished, isTrue);
    });
  });
}
