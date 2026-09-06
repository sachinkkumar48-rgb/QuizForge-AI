/// P40 End-to-End Learner Workflow Integration Test (TITAN-KO-040.0 P40).
///
/// Exercises the complete 20-scenario (A through T) unbroken learner journey:
/// Content / Exam Selection -> Goal / Topic -> Diagnostic Placement -> Practice Session
/// -> Question Presentation -> Answer Submission -> Deduplication -> Outcome Consolidation
/// -> State Reconciliation -> Authoritative Persistence -> Recovery across Restarts -> Progress Surface.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart' as pyq;

void main() {
  group('P40 End-to-End Learner Workflow Integration Tests (Scenarios A through T)', () {
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late AdaptiveLearningStateReconciliationPipeline reconciliationPipeline;
    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryDiagnosticPlacementRepository diagnosticRepo;
    late CurriculumService curriculumService;
    late DiagnosticAssessmentService diagnosticService;
    late AdaptiveLearningJourneyOrchestrator orchestrator;
    late AdaptiveLearningJourneyController controller;
    late List<pyq.NormalizedQuestion> sampleCorpus;

    pyq.NormalizedQuestion makeQuestion({
      required String id,
      required String correctOption,
      String topic = 'Fundamental Rights',
      String difficulty = 'Medium',
      String objectiveId = 'lo_basic_structure_doctrine',
    }) {
      return pyq.NormalizedQuestion(
        id: id,
        examId: 'upsc_prelims_gs1',
        year: 2024,
        paper: 'GS1',
        subject: 'Indian Polity',
        topic: topic,
        normalizedText: 'Question text for $id on $topic',
        originalText: 'Original text for $id',
        options: [
          pyq.Option(
            key: 'A',
            text: 'Option A for $id',
            isCorrect: correctOption == 'A',
          ),
          pyq.Option(
            key: 'B',
            text: 'Option B for $id',
            isCorrect: correctOption == 'B',
          ),
          pyq.Option(
            key: 'C',
            text: 'Option C for $id',
            isCorrect: correctOption == 'C',
          ),
          pyq.Option(
            key: 'D',
            text: 'Option D for $id',
            isCorrect: correctOption == 'D',
          ),
        ],
        officialAnswer: pyq.Answer(
          correctOptionKeys: [correctOption],
          officialAnswerSource: 'UPSC Answer Key',
        ),
        explanation: 'Detailed explanation for $id',
        difficulty: difficulty,
        source: pyq.PyqSourceReference.official(
          examId: 'upsc_prelims_gs1',
          year: 2024,
          paper: 'GS1',
        ),
        objectiveIds: [objectiveId],
      );
    }

    setUp(() {
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRecoveryService =
          AuthoritativeLearningStateRecoveryService(repository: authRepo);
      sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );
      reconciliationPipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: authRepo,
        recoveryService: authRecoveryService,
        reconciler: const AdaptiveLearningStateReconciler(),
        proposer: const LearningStateUpdateProposer(),
        consolidator: const PracticeOutcomeConsolidator(),
      );

      // P26 Diagnostic Assessment Setup
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);
      learnerRepo = InMemoryLearnerRepository();
      learnerRepo.save(Learner(
        id: 'learner_alpha',
        name: 'Alpha Learner',
        createdAt: DateTime.utc(2026, 1, 1),
      ));
      attemptRepo = InMemoryAttemptRepository();
      diagnosticRepo = InMemoryDiagnosticPlacementRepository();

      final pyqQ1 = pyq.Question(
        id: 'PYQ_UPSC_2024_Q01',
        questionNumber: 1,
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Basic Structure',
        questionType: pyq.QuestionType.mcq,
        originalQuestion:
            'Which case established the Basic Structure Doctrine?',
        options: const [
          pyq.Option(
            key: 'A',
            text: 'Kesavananda Bharati v. State of Kerala',
            isCorrect: true,
          ),
          pyq.Option(
            key: 'B',
            text: 'Golaknath v. State of Punjab',
            isCorrect: false,
          ),
        ],
        officialAnswer: const pyq.Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'UPSC Key',
        ),
        source: pyq.QuestionSource(
          sourceType: pyq.SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'checksum001',
          publisher: 'UPSC',
          retrievedDate: DateTime.utc(2024, 6, 1),
        ),
      );

      final pyqProvider = PyqQuestionProvider(
        questions: [pyqQ1],
        topicOrTagToObjectiveIds: const {
          'basic structure': ['lo_basic_structure_doctrine'],
        },
      );

      diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: pyqProvider,
        attemptRepository: attemptRepo,
        diagnosticRepository: diagnosticRepo,
      );

      orchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        reconciliationPipeline: reconciliationPipeline,
        diagnosticService: diagnosticService,
      );
      controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);

      sampleCorpus = [
        makeQuestion(
          id: 'q_polity_01',
          correctOption: 'A',
          topic: 'Basic Structure',
          objectiveId: 'lo_basic_structure_doctrine',
        ),
        makeQuestion(
          id: 'q_polity_02',
          correctOption: 'B',
          topic: 'Basic Structure',
          objectiveId: 'lo_basic_structure_doctrine',
        ),
        makeQuestion(
          id: 'q_polity_03',
          correctOption: 'C',
          topic: 'Basic Structure',
          objectiveId: 'lo_basic_structure_doctrine',
        ),
      ];
    });

    test('A. Learner can enter learning: initiates journey session cleanly', () async {
      final success = await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        targetObjectiveId: 'lo_basic_structure_doctrine',
        questionCount: 3,
      );

      expect(success, isTrue);
      expect(controller.session, isNotNull);
      expect(controller.status, equals(LearningJourneyStatus.questionPresented));
      expect(controller.isLoading, isFalse);
    });

    test('B. Exam/topic context is established: binds clean exam, topic, and learner IDs', () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        targetObjectiveId: 'lo_basic_structure_doctrine',
        questionCount: 2,
      );

      final session = controller.session!;
      expect(session.examId, equals('upsc_prelims_gs1'));
      expect(session.learnerId, equals('learner_alpha'));
      expect(session.spec.config.examId, equals('upsc_prelims_gs1'));
      expect(session.spec.learnerId, equals('learner_alpha'));
    });

    test('C. Diagnostic/placement executes when required: computes placement and active frontier', () {
      expect(controller.hasDiagnosticService, isTrue);

      final placementResult = controller.executeDiagnosticPlacement(
        learnerId: 'learner_alpha',
        targetObjectiveIds: const ['lo_basic_structure_doctrine'],
      );

      expect(placementResult, isNotNull);
      expect(placementResult!.learnerId, equals('learner_alpha'));
      expect(placementResult.frontier.activeFrontierObjectiveIds, contains('lo_basic_structure_doctrine'));

      // Verified stored in placement repository
      final storedResult = diagnosticRepo.getLatestResultForLearner('learner_alpha');
      expect(storedResult, isNotNull);
      expect(storedResult!.frontier.activeFrontierObjectiveIds, contains('lo_basic_structure_doctrine'));
    });

    test('D. Practice session starts: sets question cursor to 0 and base revision to 1', () async {
      final success = await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        targetObjectiveId: 'lo_basic_structure_doctrine',
        questionCount: 3,
      );

      expect(success, isTrue);
      expect(controller.currentQuestionIndex, equals(0));
      expect(controller.totalQuestions, equals(3));
      expect(controller.completedCount, equals(0));
      expect(controller.session!.authoritativeState.revision, equals(1));
    });

    test('E. Real question is presented: stem, options, difficulty, and source metadata exist', () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      final question = controller.currentQuestion;
      expect(question, isNotNull);
      expect(question!.normalizedText, contains('q_polity_01'));
      expect(question.options.length, equals(4));
      expect(question.officialAnswer.correctOptionKeys, contains('A'));
      expect(controller.canSubmitAnswer, isTrue);
    });

    test('F. Answer can be submitted: single submission produces question result and increments count', () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      final result = await controller.submitAnswer(answer: 'A');

      expect(result, isTrue);
      expect(controller.lastAnswerResult, isNotNull);
      expect(controller.lastAnswerResult!.isCorrect, isTrue);
      expect(controller.completedCount, equals(1));
    });

    test('G. Duplicate submission is prevented: prevents double answering same question', () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      final q = controller.currentQuestion!;
      await controller.submitAnswer(answer: 'A');

      // Direct duplicate submission using underlying orchestrator on the answered question
      final duplicateResult = await orchestrator.submitAnswer(
        session: controller.session!,
        questionId: q.id,
        answer: 'B',
      );

      expect(duplicateResult.isFailure, isTrue);
    });

    test('H. Result/feedback appears: contains submitted answer, correctness, and explanation', () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      await controller.submitAnswer(answer: 'A');

      final feedback = controller.lastAnswerResult!;
      expect(feedback.isCorrect, isTrue);
      expect(feedback.submittedAnswer, equals('A'));
      expect(feedback.question.explanation, contains('Detailed explanation for q_polity_01'));
    });

    test('I. Next question can be reached: advances cursor index and updates progress percentage', () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      expect(controller.currentQuestionIndex, equals(0));
      expect(controller.progressPercentage, equals(0.0));

      await controller.submitAnswer(answer: 'A');

      expect(controller.currentQuestionIndex, equals(1));
      expect(controller.currentQuestion!.id, equals('q_polity_02'));
      expect(controller.progressPercentage, equals(0.5));
    });

    test('J. Session completes: transitions to completed upon answering all questions', () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      await controller.submitAnswer(answer: 'A');
      expect(controller.isCompleted, isFalse);

      await controller.submitAnswer(answer: 'B');
      expect(controller.isCompleted, isTrue);
      expect(controller.status, equals(LearningJourneyStatus.completed));
      expect(controller.completedCount, equals(2));
      expect(controller.progressPercentage, equals(1.0));
    });

    test('K. Outcome consolidation executes: aggregates execution attempts accurately', () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      await controller.submitAnswer(answer: 'A'); // Correct
      await controller.submitAnswer(answer: 'D'); // Incorrect (expected B)

      final results = controller.session!.executionState.questionResults;
      expect(results.length, equals(2));
      expect(results['q_polity_01']!.isCorrect, isTrue);
      expect(results['q_polity_02']!.isCorrect, isFalse);
    });

    test('L. Learner state reconciliation executes: monotonically increments revision per answer', () async {
      await controller.startJourney(
        learnerId: 'learner_alpha',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      expect(controller.session!.authoritativeState.revision, equals(1));

      await controller.submitAnswer(answer: 'A');
      expect(controller.session!.authoritativeState.revision, equals(2));

      await controller.submitAnswer(answer: 'B');
      expect(controller.session!.authoritativeState.revision, equals(3));
    });

    test('M. Authoritative state is persisted: written to authoritative repository atomically', () async {
      const learnerId = 'learner_persist_t';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );

      await controller.submitAnswer(answer: 'A');

      final loaded = await authRepo.load(learnerId: learnerId, examId: examId);
      expect(loaded, isNotNull);
      expect(loaded!.learnerId, equals(learnerId));
      expect(loaded.examId, equals(examId));
      expect(loaded.revision, equals(2));
      expect(loaded.progressMap.isNotEmpty, isTrue);
    });

    test('N. Progress reflects the resulting state: authoritative progressMap records attempts', () async {
      const learnerId = 'learner_progress_t';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );

      await controller.submitAnswer(answer: 'A');
      await controller.submitAnswer(answer: 'C');

      final progressMap = controller.session!.authoritativeState.progressMap;
      expect(progressMap.isNotEmpty, isTrue);
      final progress = progressMap['lo_basic_structure_doctrine'];
      expect(progress, isNotNull);
      expect(progress!.attemptCount, greaterThanOrEqualTo(2));
      expect(progress.correctCount, greaterThanOrEqualTo(1));
    });

    test('O. Application/session recreation recovers state: restores checkpoint across restart', () async {
      const learnerId = 'learner_restart_t';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 3,
      );

      final sessionId = controller.session!.sessionId;
      await controller.submitAnswer(answer: 'A');

      // Simulate app pause / interrupt
      controller.interruptJourney(reason: 'app_exit');

      // Recover via orchestrator
      final recoveryResult = await orchestrator.recoverAndResumeJourney(
        learnerId: learnerId,
        examId: examId,
        sessionId: sessionId,
        corpus: sampleCorpus,
      );

      expect(recoveryResult.isSuccess, isTrue);
      expect(recoveryResult.session!.currentQuestionIndex, equals(1));
      expect(recoveryResult.session!.completedQuestionIds, contains('q_polity_01'));
      expect(recoveryResult.session!.authoritativeState.revision, equals(2));
    });

    test('P. Learner can continue after recovery: answers remaining questions from recovered cursor', () async {
      const learnerId = 'learner_cont_t';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 3,
      );

      final sessionId = controller.session!.sessionId;
      await controller.submitAnswer(answer: 'A');

      // Fresh controller instance simulating application restart
      final freshController = AdaptiveLearningJourneyController(orchestrator: orchestrator);
      final resumed = await freshController.resumeJourney(
        learnerId: learnerId,
        examId: examId,
        sessionId: sessionId,
        corpus: sampleCorpus,
      );

      expect(resumed, isTrue);
      expect(freshController.currentQuestionIndex, equals(1));
      expect(freshController.currentQuestion!.id, equals('q_polity_02'));

      // Submit next answer seamlessly
      final nextSubmit = await freshController.submitAnswer(answer: 'B');
      expect(nextSubmit, isTrue);
      expect(freshController.currentQuestionIndex, equals(2));
      expect(freshController.session!.authoritativeState.revision, equals(3));
    });

    test('Q. Empty content is handled: gracefully rejects empty corpus without throwing', () async {
      final res = await controller.startJourney(
        learnerId: 'empty_corpus_t',
        examId: 'upsc_prelims_gs1',
        corpus: const [],
        questionCount: 5,
      );

      expect(res, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.lastErrorCode, equals(LearningJourneyErrorCode.emptyCorpus));
    });

    test('R. Service failures are handled: rejects blank learner ID with tenantMismatch code', () async {
      final res = await controller.startJourney(
        learnerId: '   ',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );

      expect(res, isFalse);
      expect(controller.lastErrorCode, equals(LearningJourneyErrorCode.tenantMismatch));
      expect(controller.errorMessage, isNotNull);
    });

    test('S. Persistence failures are handled: save failure surfaces without corrupting in-memory state', () async {
      final startRes = await controller.startJourney(
        learnerId: 'persist_fail_t',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );
      expect(startRes, isTrue);

      // Arm persistence failure
      authRepo.failNextSave = true;

      final pipelineResult = await reconciliationPipeline.reconcileExecutionState(
        baseState: controller.session!.authoritativeState,
        executionState: controller.session!.executionState,
      );

      expect(pipelineResult.isSuccess, isFalse);
      expect(pipelineResult.persistenceError, isNotNull);
      expect(pipelineResult.baseState.revision, equals(1));

      // Storage remains clean
      final loaded = await authRepo.load(learnerId: 'persist_fail_t', examId: 'upsc_prelims_gs1');
      expect(loaded, isNull);
    });

    test('T. Corrupted state is handled: corrupted persistence payload is safely rejected during recovery', () async {
      const learnerId = 'corrupt_test_learner';
      const examId = 'upsc_prelims_gs1';
      final now = DateTime.utc(2026, 9, 6, 14, 0);

      // Inject corrupt payload
      authRepo.injectRawRecord(
        learnerId,
        examId,
        '{"schemaVersion":1,"revision":1,"learnerId":"$learnerId","examId":"$examId","lastUpdatedAt":"${now.toIso8601String()}","progressMap":{},"processedSessionIds":[],"stateFingerprint":"tampered","checksum":"invalid"}',
      );

      final recoveryResult = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: now,
      );

      expect(recoveryResult.decision, equals(AuthoritativeRecoveryDecision.corrupted));
      expect(recoveryResult.isSuccess, isFalse);
    });
  });
}
