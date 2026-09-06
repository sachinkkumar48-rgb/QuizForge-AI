import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:hive/hive.dart';
import 'package:quizforge_upsc/controllers/dashboard_controller.dart';
import 'package:quizforge_upsc/controllers/quiz_session_controller.dart';
import 'package:quizforge_upsc/core/di/service_locator_init.dart';
import 'package:quizforge_upsc/models/quiz_analytics.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:quizforge_upsc/services/active_learner_service.dart';
import 'package:quizforge_upsc/services/adaptive_learning_runtime_coordinator.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempHiveDir;

  setUpAll(() async {
    tempHiveDir = await Directory.systemTemp.createTemp('quizforge_p40_test_');
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

  group('P40 Production Integration: Adaptive Learning Runtime', () {
    late InMemoryAuthoritativeLearningStateRepository testRepository;
    late AuthoritativeLearningStateRecoveryService recoveryService;
    late AdaptiveLearningStateReconciliationPipeline reconciliationPipeline;
    late ProgressiveMasteryEngine masteryEngine;
    late AdaptiveLearningRuntimeCoordinator coordinator;

    setUp(() {
      TitanServiceLocator.instance.reset();
      testRepository = InMemoryAuthoritativeLearningStateRepository();
      recoveryService = AuthoritativeLearningStateRecoveryService(
        repository: testRepository,
      );
      reconciliationPipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: testRepository,
        recoveryService: recoveryService,
        reconciler: const AdaptiveLearningStateReconciler(),
        proposer: const LearningStateUpdateProposer(),
        consolidator: const PracticeOutcomeConsolidator(),
      );
      masteryEngine = const ProgressiveMasteryEngine();
      coordinator = AdaptiveLearningRuntimeCoordinator(
        repository: testRepository,
        recoveryService: recoveryService,
        reconciliationPipeline: reconciliationPipeline,
        masteryEngine: masteryEngine,
        activeLearnerService: ActiveLearnerService(),
        defaultExamId: 'upsc_prelims_gs1',
      );

      // Register in DI
      setupServiceLocator();
      TitanServiceLocator.instance.registerLazySingleton<
          AuthoritativeLearningStateRepository>(
        () => testRepository,
        allowOverride: true,
      );
      TitanServiceLocator.instance.registerLazySingleton<
          AuthoritativeLearningStateRecoveryService>(
        () => recoveryService,
        allowOverride: true,
      );
      TitanServiceLocator.instance.registerLazySingleton<
          AdaptiveLearningStateReconciliationPipeline>(
        () => reconciliationPipeline,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<ProgressiveMasteryEngine>(
        () => masteryEngine,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<AdaptiveLearningRuntimeCoordinator>(
        () => coordinator,
        allowOverride: true,
      );
    });

    test('1. DI Registration: resolves authoritative adaptive learning services',
        () {
      final locator = TitanServiceLocator.instance;
      expect(locator.isRegistered<AuthoritativeLearningStateRepository>(), isTrue);
      expect(
          locator.isRegistered<AuthoritativeLearningStateRecoveryService>(), isTrue);
      expect(
          locator.isRegistered<AdaptiveLearningStateReconciliationPipeline>(),
          isTrue);
      expect(locator.isRegistered<ProgressiveMasteryEngine>(), isTrue);
      expect(
          locator.isRegistered<AdaptiveLearningRuntimeCoordinator>(), isTrue);

      final resolvedCoordinator =
          locate<AdaptiveLearningRuntimeCoordinator>();
      expect(resolvedCoordinator, isNotNull);
      expect(resolvedCoordinator, equals(coordinator));
    });

    test(
        '2. Fresh Learner Initialization: establishes baseline state with revision 1',
        () async {
      const learnerId = 'fresh_aspirant_001';
      const examId = 'upsc_prelims_gs1';

      final recoveryResult = await coordinator.initialize(
        learnerId: learnerId,
        examId: examId,
      );

      expect(recoveryResult.isSuccess, isTrue);
      expect(recoveryResult.decision,
          equals(AuthoritativeRecoveryDecision.initialized));
      expect(recoveryResult.state, isNotNull);
      expect(recoveryResult.state!.learnerId, equals(learnerId));
      expect(recoveryResult.state!.examId, equals(examId));
      expect(recoveryResult.state!.revision, equals(1));
      expect(recoveryResult.state!.progressMap, isEmpty);

      final snapshot = await coordinator.getCurrentMasterySnapshot(
        learnerId: learnerId,
        examId: examId,
      );
      expect(snapshot, isNotNull);
      expect(snapshot!.authoritativeRevision, equals(1));
    });

    test(
        '3. End-to-End Quiz Completion: reconciles outcome, advances revision, and updates progressive mastery',
        () async {
      const learnerId = 'active_aspirant_p40';
      const examId = 'upsc_prelims_gs1';

      final questions = [
        QuizQuestion(
          question: 'Which Article guarantees Right to Equality?',
          options: ['Article 14', 'Article 19', 'Article 21', 'Article 32'],
          answer: 'Article 14',
          explanation: 'Article 14 guarantees equality before law.',
          subject: 'Indian Polity',
          difficulty: 'Medium',
        ),
        QuizQuestion(
          question: 'Which schedule contains Union and State lists?',
          options: ['5th Schedule', '7th Schedule', '8th Schedule', '10th Schedule'],
          answer: '7th Schedule',
          explanation: '7th schedule contains 3 lists.',
          subject: 'Indian Polity',
          difficulty: 'Easy',
        ),
        QuizQuestion(
          question: 'What is repo rate?',
          options: ['Lending rate', 'Borrowing rate', 'Tax rate', 'Tariff rate'],
          answer: 'Lending rate',
          explanation: 'Rate at which RBI lends to commercial banks.',
          subject: 'Economy',
          difficulty: 'Hard',
        ),
      ];

      QuizAnalytics? resultAnalytics;
      final controller = QuizSessionController(
        sourceName: 'UPSC Polity & Economy Drill',
        questions: questions,
        learningCoordinator: coordinator,
        learnerId: learnerId,
        examId: examId,
        onStateChanged: () {},
        onTimeUp: (_) {},
      );

      // Simulate learner answering
      controller.selectAnswer('Article 14'); // Correct (Polity)
      controller.nextQuestion(onFinished: (_) {});

      controller.selectAnswer('5th Schedule'); // Incorrect (Polity)
      controller.nextQuestion(onFinished: (_) {});

      controller.selectAnswer('Lending rate'); // Correct (Economy)

      // Finish quiz
      await controller.submitQuiz(
        onFinished: (analytics) {
          resultAnalytics = analytics;
        },
      );

      expect(resultAnalytics, isNotNull);
      expect(resultAnalytics!.score, equals(2));
      expect(resultAnalytics!.totalQuestions, equals(3));

      // Verify Authoritative Learner State
      final authState = await coordinator.getAuthoritativeState(
        learnerId: learnerId,
        examId: examId,
      );
      expect(authState, isNotNull);
      expect(authState!.revision, equals(2)); // Monotonically advanced 1 -> 2
      expect(authState.progressMap.isNotEmpty, isTrue);

      // Verify Progressive Mastery Snapshot
      final snapshot = await coordinator.getCurrentMasterySnapshot(
        learnerId: learnerId,
        examId: examId,
      );
      expect(snapshot, isNotNull);
      expect(snapshot!.authoritativeRevision, equals(2));
      expect(snapshot.topicProfiles.containsKey('Indian Polity'), isTrue);
      expect(snapshot.topicProfiles.containsKey('Economy'), isTrue);

      final polityProfile = snapshot.topicProfiles['Indian Polity']!;
      expect(polityProfile.evidenceCount, equals(2));
      expect(polityProfile.correctCount, equals(1));
      expect(polityProfile.incorrectCount, equals(1));

      final economyProfile = snapshot.topicProfiles['Economy']!;
      expect(economyProfile.evidenceCount, equals(1));
      expect(economyProfile.correctCount, equals(1));
      expect(economyProfile.incorrectCount, equals(0));

      // Verify Adaptive Mastery Decision Output
      final decision = snapshot.decisionOutput;
      expect(decision.recommendedDifficultyBand.isNotEmpty, isTrue);
      expect(decision.overallMasteryScore, greaterThan(0.0));
    });

    test(
        '4. Application Restart Recovery: deterministic state restore across sessions with zero loss',
        () async {
      const learnerId = 'persisted_aspirant_01';
      const examId = 'upsc_prelims_gs1';

      // 1. Session 1: complete quiz
      final questions = [
        QuizQuestion(
          question: 'Preamble question',
          options: ['A', 'B', 'C', 'D'],
          answer: 'A',
          explanation: 'Exp',
          subject: 'Indian Polity',
          difficulty: 'Medium',
        ),
      ];

      await coordinator.recordQuizCompletion(
        sessionId: 'session_restart_test_100',
        sourceName: 'Polity Basics',
        questions: questions,
        answers: {0: 'A'},
        learnerId: learnerId,
        examId: examId,
      );

      final stateBeforeRestart = await coordinator.getAuthoritativeState(
        learnerId: learnerId,
        examId: examId,
      );
      expect(stateBeforeRestart!.revision, equals(2));
      final fingerprintBeforeRestart = stateBeforeRestart.stateFingerprint;

      // 2. Simulate Application Restart: Instantiate brand new coordinator
      // backed by the same persistent repository
      final restartRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: testRepository,
      );
      final restartPipeline = AdaptiveLearningStateReconciliationPipeline(
        repository: testRepository,
        recoveryService: restartRecoveryService,
      );
      final restartedCoordinator = AdaptiveLearningRuntimeCoordinator(
        repository: testRepository,
        recoveryService: restartRecoveryService,
        reconciliationPipeline: restartPipeline,
        masteryEngine: masteryEngine,
      );

      final recoveryResult = await restartedCoordinator.initialize(
        learnerId: learnerId,
        examId: examId,
      );

      expect(recoveryResult.isSuccess, isTrue);
      expect(recoveryResult.decision,
          equals(AuthoritativeRecoveryDecision.restored));
      expect(recoveryResult.state!.revision, equals(2));
      expect(recoveryResult.state!.stateFingerprint,
          equals(fingerprintBeforeRestart));

      final restoredSnapshot =
          await restartedCoordinator.getCurrentMasterySnapshot(
        learnerId: learnerId,
        examId: examId,
      );
      expect(restoredSnapshot, isNotNull);
      expect(restoredSnapshot!.authoritativeRevision, equals(2));
      expect(restoredSnapshot.topicProfiles['Indian Polity']!.correctCount,
          equals(1));
    });

    test('5. Multi-Learner Isolation: separate state spaces per learner',
        () async {
      const examId = 'upsc_prelims_gs1';
      final questions = [
        QuizQuestion(
          question: 'Geography River Question',
          options: ['Ganga', 'Yamuna'],
          answer: 'Ganga',
          explanation: 'Ganga',
          subject: 'Geography',
          difficulty: 'Easy',
        ),
      ];

      // Learner 1 (Alice) answers correctly
      await coordinator.recordQuizCompletion(
        sessionId: 'session_alice_01',
        sourceName: 'Rivers of India',
        questions: questions,
        answers: {0: 'Ganga'},
        learnerId: 'learner_alice',
        examId: examId,
      );

      // Learner 2 (Bob) answers incorrectly
      await coordinator.recordQuizCompletion(
        sessionId: 'session_bob_01',
        sourceName: 'Rivers of India',
        questions: questions,
        answers: {0: 'Yamuna'},
        learnerId: 'learner_bob',
        examId: examId,
      );

      final aliceSnapshot = await coordinator.getCurrentMasterySnapshot(
        learnerId: 'learner_alice',
        examId: examId,
      );
      final bobSnapshot = await coordinator.getCurrentMasterySnapshot(
        learnerId: 'learner_bob',
        examId: examId,
      );

      expect(aliceSnapshot!.topicProfiles['Geography']!.correctCount, equals(1));
      expect(aliceSnapshot.topicProfiles['Geography']!.incorrectCount, equals(0));

      expect(bobSnapshot!.topicProfiles['Geography']!.correctCount, equals(0));
      expect(bobSnapshot.topicProfiles['Geography']!.incorrectCount, equals(1));

      expect(
        aliceSnapshot.topicProfiles['Geography']!.masteryScore,
        greaterThan(bobSnapshot.topicProfiles['Geography']!.masteryScore),
      );
    });

    test(
        '6. Idempotency Guard: duplicate session submission preserves state without double counting',
        () async {
      const learnerId = 'learner_idempotent_test';
      const examId = 'upsc_prelims_gs1';
      final questions = [
        QuizQuestion(
          question: 'Tax Question',
          options: ['GST', 'VAT'],
          answer: 'GST',
          explanation: 'GST',
          subject: 'Economy',
          difficulty: 'Medium',
        ),
      ];

      // First submission
      final res1 = await coordinator.recordQuizCompletion(
        sessionId: 'session_unique_42',
        sourceName: 'Taxation Drill',
        questions: questions,
        answers: {0: 'GST'},
        learnerId: learnerId,
        examId: examId,
      );
      expect(res1.isSuccess, isTrue);
      expect(res1.resultingState!.revision, equals(2));

      // Duplicate submission of exact same session
      final res2 = await coordinator.recordQuizCompletion(
        sessionId: 'session_unique_42',
        sourceName: 'Taxation Drill',
        questions: questions,
        answers: {0: 'GST'},
        learnerId: learnerId,
        examId: examId,
      );
      expect(res2.isIdempotentReplay, isTrue);

      final finalState = await coordinator.getAuthoritativeState(
        learnerId: learnerId,
        examId: examId,
      );
      expect(finalState!.revision, equals(2)); // Unchanged
    });

    test(
        '7. Dashboard Controller Integration: reflects authoritative stats and adaptive targets',
        () async {
      const examId = 'upsc_prelims_gs1';

      // Seed an authoritative quiz outcome with a weak topic
      final questions = [
        QuizQuestion(
          question: 'Difficult Article 356 Question',
          options: ['A', 'B', 'C', 'D'],
          answer: 'A',
          explanation: 'Exp',
          subject: 'Emergency Provisions',
          difficulty: 'Hard',
        ),
      ];

      await coordinator.recordQuizCompletion(
        sessionId: 'session_weak_spot_seed',
        sourceName: 'Emergency Provisions Drill',
        questions: questions,
        answers: {0: 'B'}, // Incorrect attempt
        learnerId: coordinator.activeLearnerId,
        examId: examId,
      );

      final dashboardController = DashboardController(
        learningCoordinator: coordinator,
      );

      await dashboardController.loadDashboardData();
      final state = dashboardController.state;

      expect(state.isReady, isTrue);
      expect(state.stats.totalQuestionsAnswered, greaterThanOrEqualTo(1));

      // Verify that adaptive target activity was added to recentActivities
      final hasAdaptiveActivity = state.recentActivities.any(
        (a) => a.categoryTag == 'Adaptive Mastery',
      );
      expect(hasAdaptiveActivity, isTrue);

      dashboardController.dispose();
    });
  });
}
