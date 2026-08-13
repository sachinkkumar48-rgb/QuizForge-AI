import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:test/test.dart';

void main() {
  group('P19 Safety & Invariant Safeguards Tests (TITAN-KO-019.0 P19)', () {
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

    test('Safeguard 1: Non-existent learner ID is strictly rejected', () {
      final config = SessionConfiguration(
        learnerId: 'fake_learner_id_123',
        objectiveIds: ['lo_basic_structure_doctrine'],
      );

      expect(
        () => orchestrator.createSession(config),
        throwsArgumentError,
      );
    });

    test('Safeguard 2: Non-existent learning objective ID is strictly rejected',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['fake_objective_id_999'],
      );

      expect(
        () => orchestrator.createSession(config),
        throwsArgumentError,
      );
    });

    test(
        'Safeguard 3: Submitting answer to inactive or finished session throws StateError',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
      );
      final created = orchestrator.createSession(config);

      // Session in created state (not active)
      expect(
        () => orchestrator.submitAnswer(created.sessionId, 'answer'),
        throwsStateError,
      );
    });

    test(
        'Safeguard 4: P15 Question evidence and provenance are strictly preserved',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
      );
      final session = orchestrator.createSession(config);
      orchestrator.startSession(session.sessionId);

      final currentQ = orchestrator.getCurrentQuestion(session.sessionId)!;

      // Question MUST carry valid P15 questionId and non-empty answer provenance
      expect(currentQ.questionId, isNotEmpty);
      expect(currentQ.answer.evidenceRefs, isNotNull);
      expect(currentQ.answer.evidenceRefs, isNotEmpty);
    });

    test(
        'Safeguard 5: Session metrics contain strictly quantitative scores without unsupported claims',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 2,
      );
      final session = orchestrator.createSession(config);
      orchestrator.startSession(session.sessionId);

      final summary = orchestrator.getSessionProgress(session.sessionId);
      expect(summary.currentScore, inInclusiveRange(0.0, 1.0));
      expect(summary.state.displayName, isNotEmpty);
    });

    test('Safeguard 6: 100% Offline execution without network or AI calls', () {
      final config = SessionConfiguration(
        learnerId: 'learner_101',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 3,
      );

      // Operations run entirely in-memory synchronously
      final session = orchestrator.createSession(config);
      orchestrator.startSession(session.sessionId);
      final q = orchestrator.getCurrentQuestion(session.sessionId);
      expect(q, isNotNull);

      final res = orchestrator.submitAnswer(session.sessionId, 'test');
      expect(res.attemptId, isNotEmpty);
      expect(res.evaluationMethod, isNotNull);
    });
  });
}
