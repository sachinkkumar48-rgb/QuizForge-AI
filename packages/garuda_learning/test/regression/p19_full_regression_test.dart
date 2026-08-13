import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:test/test.dart';

void main() {
  group(
      'TITAN-KO-019.0 P19 Full Regression, Integration & Determinism Test Suite',
      () {
    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryProgressRepository progressRepo;
    late CurriculumService curriculumService;
    late QuestionKnowledgeProductService questionService;
    late ProgressTracker progressTracker;
    late SessionManager sessionManager;
    late AssessmentService assessmentService;
    late LearningSessionOrchestrator orchestrator;

    late Learner learnerA;
    late Learner learnerB;

    setUp(() {
      learnerRepo = InMemoryLearnerRepository();
      attemptRepo = InMemoryAttemptRepository();
      progressRepo = InMemoryProgressRepository();

      learnerA = Learner(id: 'learner_alpha', name: 'Alpha Student');
      learnerB = Learner(id: 'learner_beta', name: 'Beta Student');
      learnerRepo.save(learnerA);
      learnerRepo.save(learnerB);

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
        '1. Full End-to-End Session Orchestration (create -> start -> submit -> complete -> summary)',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_alpha',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 3,
        selectionPolicy: QuestionSelectionPolicy.allObjectiveQuestions,
        sequencerPolicy: QuestionSequencerPolicy.curriculumOrder,
      );

      // Create session
      final session =
          orchestrator.createSession(config, sessionId: 'lsess_e2e_101');
      expect(session.sessionId, 'lsess_e2e_101');
      expect(session.state, LearningSessionState.created);
      expect(session.totalQuestions, greaterThan(0));

      // Start session
      orchestrator.startSession(session.sessionId);
      expect(orchestrator.getSession(session.sessionId)!.state,
          LearningSessionState.active);

      // Iteratively answer all questions
      final total = session.totalQuestions;
      for (var i = 0; i < total; i++) {
        final currentQ = orchestrator.getCurrentQuestion(session.sessionId);
        expect(currentQ, isNotNull);
        final expectedAnswer = currentQ!.answer.answerText;

        final res =
            orchestrator.submitAnswer(session.sessionId, expectedAnswer);
        expect(res.isCorrect, isTrue);
        expect(res.score, 1.0);
      }

      // Verify session completed
      final completedSession = orchestrator.getSession(session.sessionId)!;
      expect(completedSession.state, LearningSessionState.completed);
      expect(completedSession.isFinished, isTrue);

      // Verify session progress summary
      final summary = orchestrator.getSessionProgress(session.sessionId);
      expect(summary.totalQuestions, total);
      expect(summary.answeredCount, total);
      expect(summary.correctCount, total);
      expect(summary.currentScore, 1.0);
      expect(summary.isCompleted, isTrue);

      // Verify P18 LearnerProgress record
      final progress = progressTracker.getProgress(
          'learner_alpha', 'lo_basic_structure_doctrine');
      expect(progress, isNotNull);
      expect(progress!.attemptCount, total);
      expect(progress.correctCount, total);
      expect(progress.successRate, 1.0);
    });

    test(
        '2. Determinism Verification: Identical session configurations produce byte-identical sequences',
        () {
      final configA = SessionConfiguration(
        learnerId: 'learner_alpha',
        objectiveIds: [
          'lo_basic_structure_doctrine',
          'lo_article_21_foundations'
        ],
        questionLimit: 5,
        selectionPolicy: QuestionSelectionPolicy.allObjectiveQuestions,
        sequencerPolicy: QuestionSequencerPolicy.deterministicShuffle,
      );

      final configB = SessionConfiguration(
        learnerId: 'learner_alpha',
        objectiveIds: [
          'lo_basic_structure_doctrine',
          'lo_article_21_foundations'
        ],
        questionLimit: 5,
        selectionPolicy: QuestionSelectionPolicy.allObjectiveQuestions,
        sequencerPolicy: QuestionSequencerPolicy.deterministicShuffle,
      );

      final sess1 =
          orchestrator.createSession(configA, sessionId: 'fixed_sess_id_100');
      final sess2 =
          orchestrator.createSession(configB, sessionId: 'fixed_sess_id_100');

      expect(sess1.orderedQuestionIds, equals(sess2.orderedQuestionIds));
    });

    test(
        '3. Learner Isolation: Attempts and sessions for Learner Alpha do not bleed into Learner Beta',
        () {
      final configA = SessionConfiguration(
        learnerId: 'learner_alpha',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 2,
      );
      final configB = SessionConfiguration(
        learnerId: 'learner_beta',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 2,
      );

      final sessA = orchestrator.createSession(configA);
      final sessB = orchestrator.createSession(configB);

      orchestrator.startSession(sessA.sessionId);
      orchestrator.startSession(sessB.sessionId);

      orchestrator.submitAnswer(sessA.sessionId, 'wrong answer');
      orchestrator.submitAnswer(sessB.sessionId, 'right answer');

      final progA = progressTracker.getProgress(
          'learner_alpha', 'lo_basic_structure_doctrine');
      final progB = progressTracker.getProgress(
          'learner_beta', 'lo_basic_structure_doctrine');

      expect(progA, isNotNull);
      expect(progB, isNotNull);
      expect(progA!.learnerId, 'learner_alpha');
      expect(progB!.learnerId, 'learner_beta');
      expect(progA.attemptCount, 1);
      expect(progB.attemptCount, 1);
    });

    test(
        '4. Multiple Sessions for Learner accumulate attempts and update progress status',
        () {
      final config1 = SessionConfiguration(
        learnerId: 'learner_alpha',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 3,
      );

      final sess1 = orchestrator.createSession(config1);
      orchestrator.startSession(sess1.sessionId);
      for (var i = 0; i < sess1.totalQuestions; i++) {
        final q = orchestrator.getCurrentQuestion(sess1.sessionId);
        if (q != null) {
          orchestrator.submitAnswer(sess1.sessionId, q.answer.answerText);
        }
      }

      final config2 = SessionConfiguration(
        learnerId: 'learner_alpha',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 3,
      );

      final sess2 = orchestrator.createSession(config2);
      orchestrator.startSession(sess2.sessionId);
      for (var i = 0; i < sess2.totalQuestions; i++) {
        final q = orchestrator.getCurrentQuestion(sess2.sessionId);
        if (q != null) {
          orchestrator.submitAnswer(sess2.sessionId, q.answer.answerText);
        }
      }

      final progress = progressTracker.getProgress(
          'learner_alpha', 'lo_basic_structure_doctrine');
      expect(progress, isNotNull);
      expect(progress!.attemptCount, greaterThanOrEqualTo(5));
      expect(progress.status, LearnerObjectiveStatus.achieved);
    });

    test(
        '5. Replay Determinism: Replaying session answers produces identical summary metrics',
        () {
      final config = SessionConfiguration(
        learnerId: 'learner_alpha',
        objectiveIds: ['lo_basic_structure_doctrine'],
        questionLimit: 3,
      );

      final sessA =
          orchestrator.createSession(config, sessionId: 'replay_sess_1');
      orchestrator.startSession(sessA.sessionId);

      final answers = <String>[];
      for (var i = 0; i < sessA.totalQuestions; i++) {
        final q = orchestrator.getCurrentQuestion(sessA.sessionId)!;
        final ans = q.answer.answerText;
        answers.add(ans);
        orchestrator.submitAnswer(sessA.sessionId, ans);
      }

      final summaryA = orchestrator.getSessionProgress(sessA.sessionId);

      // Replay in session B
      final sessB =
          orchestrator.createSession(config, sessionId: 'replay_sess_2');
      orchestrator.startSession(sessB.sessionId);

      for (var i = 0; i < answers.length; i++) {
        orchestrator.submitAnswer(sessB.sessionId, answers[i]);
      }

      final summaryB = orchestrator.getSessionProgress(sessB.sessionId);

      expect(summaryA.totalQuestions, summaryB.totalQuestions);
      expect(summaryA.answeredCount, summaryB.answeredCount);
      expect(summaryA.correctCount, summaryB.correctCount);
      expect(summaryA.currentScore, summaryB.currentScore);
    });
  });
}
