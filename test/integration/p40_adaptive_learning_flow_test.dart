import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:hive/hive.dart';
import 'package:quizforge_upsc/core/di/service_locator_init.dart';
import 'package:quizforge_upsc/services/pyq_corpus_adapter_service.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempHiveDir;

  setUpAll(() async {
    tempHiveDir = await Directory.systemTemp.createTemp('quizforge_p40_flow_test_');
    Hive.init(tempHiveDir.path);
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      if (tempHiveDir.existsSync()) {
        tempHiveDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('P40 Production Integration: Real End-to-End Learner Journey Flow', () {
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late AdaptiveLearningStateReconciliationPipeline reconciliationPipeline;
    late AdaptiveLearningJourneyOrchestrator orchestrator;
    late AdaptiveLearningJourneyController controller;
    late List<NormalizedQuestion> sampleCorpus;

    setUp(() {
      TitanServiceLocator.instance.reset();

      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRecoveryService = AuthoritativeLearningStateRecoveryService(repository: authRepo);
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
      orchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        reconciliationPipeline: reconciliationPipeline,
      );
      controller = AdaptiveLearningJourneyController(orchestrator: orchestrator);

      sampleCorpus = PyqCorpusAdapterService.getDefaultSeedCorpus();

      setupServiceLocator();
      TitanServiceLocator.instance.registerLazySingleton<AuthoritativeLearningStateRepository>(
        () => authRepo,
        allowOverride: true,
      );
      TitanServiceLocator.instance.registerLazySingleton<SessionCheckpointRepository>(
        () => checkpointRepo,
        allowOverride: true,
      );
      TitanServiceLocator.instance.registerLazySingleton<AdaptiveLearningJourneyOrchestrator>(
        () => orchestrator,
        allowOverride: true,
      );
    });

    test('1. Fresh Learner: start study -> receive question -> answer -> state updates -> next question', () async {
      const learnerId = 'fresh_candidate_01';
      const examId = 'upsc_prelims_gs1';

      final startSuccess = await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 3,
      );

      expect(startSuccess, isTrue);
      expect(controller.status, equals(LearningJourneyStatus.questionPresented));
      expect(controller.currentQuestionIndex, equals(0));
      expect(controller.currentQuestion, isNotNull);
      expect(controller.totalQuestions, equals(3));
      expect(controller.completedCount, equals(0));
      expect(controller.canSubmitAnswer, isTrue);

      final q1 = controller.currentQuestion!;
      final correctOption = q1.officialAnswer.correctOptionKeys.first;

      final submitSuccess = await controller.submitAnswer(answer: correctOption);

      expect(submitSuccess, isTrue);
      expect(controller.lastAnswerResult, isNotNull);
      expect(controller.lastAnswerResult!.isCorrect, isTrue);
      expect(controller.completedCount, equals(1));
      expect(controller.currentQuestionIndex, equals(1));
      expect(controller.status, equals(LearningJourneyStatus.questionPresented));
      expect(controller.session!.authoritativeState.revision, equals(2));
    });

    test('2. Correct Answer: attempt is recorded and consolidated correctly', () async {
      const learnerId = 'correct_eval_candidate';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );

      final q = controller.currentQuestion!;
      final correctKey = q.officialAnswer.correctOptionKeys.first;

      await controller.submitAnswer(answer: correctKey);

      final state = controller.session!.authoritativeState;
      expect(state.revision, equals(2));

      final topicKey = q.topic;
      expect(state.progressMap.containsKey(topicKey), isTrue);
      final prog = state.progressMap[topicKey]!;
      expect(prog.attemptCount, equals(1));
      expect(prog.correctCount, equals(1));
      expect(controller.lastAnswerResult!.isCorrect, isTrue);
    });

    test('3. Incorrect Answer: attempt is recorded and adaptive state changes correctly', () async {
      const learnerId = 'incorrect_eval_candidate';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );

      final q = controller.currentQuestion!;
      final wrongKey = q.officialAnswer.correctOptionKeys.contains('A') ? 'B' : 'A';

      await controller.submitAnswer(answer: wrongKey);

      final state = controller.session!.authoritativeState;
      expect(state.revision, equals(2));

      final topicKey = q.topic;
      expect(state.progressMap.containsKey(topicKey), isTrue);
      final prog = state.progressMap[topicKey]!;
      expect(prog.attemptCount, equals(1));
      expect(prog.correctCount, equals(0));
      expect(controller.lastAnswerResult!.isCorrect, isFalse);
    });

    test('4. Multiple Questions: state evolves across a complete practice session', () async {
      const learnerId = 'multi_step_candidate';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 3,
      );

      // Question 1: Answer correctly
      final q1 = controller.currentQuestion!;
      await controller.submitAnswer(answer: q1.officialAnswer.correctOptionKeys.first);
      expect(controller.session!.authoritativeState.revision, equals(2));
      expect(controller.currentQuestionIndex, equals(1));

      // Question 2: Answer incorrectly
      final q2 = controller.currentQuestion!;
      final wrongOpt = q2.officialAnswer.correctOptionKeys.contains('D') ? 'C' : 'D';
      await controller.submitAnswer(answer: wrongOpt);
      expect(controller.session!.authoritativeState.revision, equals(3));
      expect(controller.currentQuestionIndex, equals(2));

      // Question 3: Answer correctly
      final q3 = controller.currentQuestion!;
      await controller.submitAnswer(answer: q3.officialAnswer.correctOptionKeys.first);
      expect(controller.session!.authoritativeState.revision, equals(4));
    });

    test('5. Session Completion: final outcome is consolidated and persisted', () async {
      const learnerId = 'session_completion_candidate';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );

      // Answer Q1
      await controller.submitAnswer(answer: controller.currentQuestion!.officialAnswer.correctOptionKeys.first);
      expect(controller.isCompleted, isFalse);

      // Answer Q2
      await controller.submitAnswer(answer: controller.currentQuestion!.officialAnswer.correctOptionKeys.first);
      expect(controller.isCompleted, isTrue);
      expect(controller.status, equals(LearningJourneyStatus.completed));
      expect(controller.canSubmitAnswer, isFalse);

      // Verify persistence in AuthoritativeLearningStateRepository
      final savedState = await authRepo.load(learnerId: learnerId, examId: examId);
      expect(savedState, isNotNull);
      expect(savedState!.revision, equals(3));
    });

    test('6. Restart: persisted state is recovered and learning continues seamlessly', () async {
      const learnerId = 'restart_resumption_candidate';
      const examId = 'upsc_prelims_gs1';

      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 3,
      );

      final sessionId = controller.session!.sessionId;

      // Answer Question 1
      await controller.submitAnswer(answer: controller.currentQuestion!.officialAnswer.correctOptionKeys.first);
      expect(controller.currentQuestionIndex, equals(1));

      // Simulate App Restart: Create fresh controller & orchestrator using same persistent repo
      final restartRecovery = AuthoritativeLearningStateRecoveryService(repository: authRepo);
      final restartSessionRecovery = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: restartRecovery,
      );
      final restartOrchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: restartRecovery,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: restartSessionRecovery,
      );
      final restartController = AdaptiveLearningJourneyController(orchestrator: restartOrchestrator);

      final resumeSuccess = await restartController.resumeJourney(
        learnerId: learnerId,
        examId: examId,
        sessionId: sessionId,
        corpus: sampleCorpus,
      );

      expect(resumeSuccess, isTrue);
      expect(restartController.session, isNotNull);
      expect(restartController.currentQuestionIndex, equals(1)); // Resumed at question 2
      expect(restartController.completedCount, equals(1));
      expect(restartController.session!.authoritativeState.revision, equals(2));

      // Continue answering from resumed state
      final resumedQ = restartController.currentQuestion!;
      final contSuccess = await restartController.submitAnswer(
        answer: resumedQ.officialAnswer.correctOptionKeys.first,
      );
      expect(contSuccess, isTrue);
      expect(restartController.completedCount, equals(2));
      expect(restartController.session!.authoritativeState.revision, equals(3));
    });

    test('7. Corrupt State: application does not silently accept corrupted persistence', () async {
      const learnerId = 'corrupt_state_candidate';
      const examId = 'upsc_prelims_gs1';
      final now = DateTime.now().toUtc();

      // Inject corrupt JSON into storage directly
      authRepo.injectRawRecord(
        learnerId,
        examId,
        '{"schemaVersion":1,"revision":1,"learnerId":"$learnerId","examId":"$examId","lastUpdatedAt":"${now.toIso8601String()}","progressMap":{},"processedSessionIds":[],"stateFingerprint":"bad","checksum":"bad"}',
      );

      final recoveryResult = await authRecoveryService.recover(
        learnerId: learnerId,
        examId: examId,
        requestedAt: now,
      );

      expect(recoveryResult.decision, equals(AuthoritativeRecoveryDecision.corrupted));
      expect(recoveryResult.isSuccess, isFalse);
    });

    test('8. Multi-Context Isolation: one learner/exam context cannot overwrite another', () async {
      const examId = 'upsc_prelims_gs1';

      // Learner 1 (Alice)
      final aliceController = AdaptiveLearningJourneyController(orchestrator: orchestrator);
      await aliceController.startJourney(
        learnerId: 'learner_alice',
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );
      await aliceController.submitAnswer(
        answer: aliceController.currentQuestion!.officialAnswer.correctOptionKeys.first,
      );
      await aliceController.submitAnswer(
        answer: aliceController.currentQuestion!.officialAnswer.correctOptionKeys.first,
      );

      // Learner 2 (Bob)
      final bobController = AdaptiveLearningJourneyController(orchestrator: orchestrator);
      await bobController.startJourney(
        learnerId: 'learner_bob',
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );
      await bobController.submitAnswer(
        answer: bobController.currentQuestion!.officialAnswer.correctOptionKeys.first,
      );

      expect(bobController.session!.authoritativeState.revision, equals(2));
      expect(aliceController.session!.authoritativeState.revision, equals(3));

      final aliceState = await authRepo.load(learnerId: 'learner_alice', examId: examId);
      final bobState = await authRepo.load(learnerId: 'learner_bob', examId: examId);

      expect(aliceState!.revision, equals(3));
      expect(bobState!.revision, equals(2));
      expect(aliceState.learnerId, equals('learner_alice'));
      expect(bobState.learnerId, equals('learner_bob'));
    });

    test('9. Persistence Failure: failure is surfaced without corrupting in-memory state', () async {
      final startSuccess = await controller.startJourney(
        learnerId: 'learner_fail_test',
        examId: 'upsc_prelims_gs1',
        corpus: sampleCorpus,
        questionCount: 2,
      );
      expect(startSuccess, isTrue);

      // Arm failure on next save
      authRepo.failNextSave = true;

      // Reconciling state when save fails returns failure result
      final res = await reconciliationPipeline.reconcileExecutionState(
        baseState: controller.session!.authoritativeState,
        executionState: controller.session!.executionState,
      );

      expect(res.isSuccess, isFalse);
      expect(res.persistenceError, isNotNull);
      expect(res.baseState.revision, equals(1));

      // In-memory / storage remains clean and uncorrupted
      final loaded = await authRepo.load(
        learnerId: 'learner_fail_test',
        examId: 'upsc_prelims_gs1',
      );
      expect(loaded, isNull);
    });

    test('10. No-Question Edge Case: surfaces error gracefully rather than crashing', () async {
      final res = await controller.startJourney(
        learnerId: 'empty_corpus_candidate',
        examId: 'upsc_prelims_gs1',
        corpus: const [], // Empty corpus
        questionCount: 5,
      );

      expect(res, isFalse);
      expect(controller.errorMessage, isNotNull);
      expect(controller.lastErrorCode, equals(LearningJourneyErrorCode.emptyCorpus));
      expect(controller.status, equals(LearningJourneyStatus.created));
    });

    test('11. Existing Learner State: starting a new session uses existing authoritative state baseline', () async {
      const learnerId = 'veteran_aspirant_01';
      const examId = 'upsc_prelims_gs1';

      // 1. Session 1: Complete 1 question to advance state to revision 2
      await controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 1,
      );
      await controller.submitAnswer(answer: controller.currentQuestion!.officialAnswer.correctOptionKeys.first);
      expect(controller.session!.authoritativeState.revision, equals(2));

      // 2. Session 2: Start a brand new journey
      final session2Controller = AdaptiveLearningJourneyController(orchestrator: orchestrator);
      final start2Success = await session2Controller.startJourney(
        learnerId: learnerId,
        examId: examId,
        corpus: sampleCorpus,
        questionCount: 2,
      );

      expect(start2Success, isTrue);
      // New journey starts with the existing authoritative revision 2 as its base
      expect(session2Controller.session!.authoritativeState.revision, equals(2));
      expect(session2Controller.session!.authoritativeState.progressMap.isNotEmpty, isTrue);
    });
  });
}
