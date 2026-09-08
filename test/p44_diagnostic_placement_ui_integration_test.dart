import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:quizforge_upsc/pages/adaptive_practice_page.dart';
import 'package:quizforge_upsc/pages/content_learning_path_page.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P44 Diagnostic Assessment & Baseline Placement UI Integration Tests',
      () {
    const testLearner = 'learner_ui_diagnostic_01';
    const testExam = 'upsc_prelims_gs1';

    late InMemoryLearnerRepository learnerRepo;
    late InMemoryAttemptRepository attemptRepo;
    late InMemoryDiagnosticPlacementRepository diagnosticRepo;
    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late DiagnosticAssessmentService diagnosticService;
    late AdaptiveLearningJourneyOrchestrator orchestrator;
    late List<NormalizedQuestion> testCorpus;
    late ContentLearningPathService contentService;

    setUp(() {
      TitanServiceLocator.instance.reset();

      learnerRepo = InMemoryLearnerRepository();
      learnerRepo.save(Learner(
        id: testLearner,
        name: 'Diagnostic Test Learner',
        createdAt: DateTime.utc(2026, 8, 29),
      ));
      learnerRepo.save(Learner(
        id: 'default_learner',
        name: 'Default Learner',
        createdAt: DateTime.utc(2026, 8, 29),
      ));

      attemptRepo = InMemoryAttemptRepository();
      diagnosticRepo = InMemoryDiagnosticPlacementRepository();
      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();

      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );

      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);

      final questionProvider = CaseLawQuestionProvider();

      diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: questionProvider,
        attemptRepository: attemptRepo,
        diagnosticRepository: diagnosticRepo,
      );

      orchestrator = AdaptiveLearningJourneyOrchestrator(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        diagnosticService: diagnosticService,
      );

      testCorpus = [
        NormalizedQuestion(
          id: 'pyq_diag_bs_01',
          examId: testExam,
          year: 2024,
          paper: 'GS1',
          subject: 'Indian Polity',
          topic: 'Preamble & Basic Structure',
          normalizedText:
              'Which case established the Basic Structure Doctrine in India?',
          originalText:
              'Which case established the Basic Structure Doctrine in India?',
          options: const [
            Option(
                key: 'A',
                text: 'Kesavananda Bharati v. State of Kerala',
                isCorrect: true),
            Option(
                key: 'B',
                text: 'Golaknath v. State of Punjab',
                isCorrect: false),
            Option(
                key: 'C',
                text: 'Minerva Mills v. Union of India',
                isCorrect: false),
            Option(
                key: 'D',
                text: 'Maneka Gandhi v. Union of India',
                isCorrect: false),
          ],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          explanation: 'Kesavananda Bharati (1973) established the doctrine.',
          difficulty: 'Easy',
          source: PyqSourceReference.official(
            examId: testExam,
            year: 2024,
            paper: 'GS1',
          ),
          objectiveIds: const ['lo_preamble_identity'],
        ),
        NormalizedQuestion(
          id: 'pyq_diag_bs_02',
          examId: testExam,
          year: 2023,
          paper: 'GS1',
          subject: 'Indian Polity',
          topic: 'Preamble & Basic Structure',
          normalizedText:
              'Can the basic structure of the Constitution be amended under Article 368?',
          originalText:
              'Can the basic structure of the Constitution be amended under Article 368?',
          options: const [
            Option(
                key: 'A',
                text: 'No, it is beyond amending power',
                isCorrect: true),
            Option(
                key: 'B', text: 'Yes, with simple majority', isCorrect: false),
            Option(
                key: 'C',
                text: 'Yes, with special majority and state ratification',
                isCorrect: false),
            Option(
                key: 'D', text: 'Yes, during Emergency only', isCorrect: false),
          ],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          explanation: 'Basic structure cannot be altered.',
          difficulty: 'Medium',
          source: PyqSourceReference.official(
            examId: testExam,
            year: 2023,
            paper: 'GS1',
          ),
          objectiveIds: const ['lo_preamble_identity'],
        ),
        NormalizedQuestion(
          id: 'pyq_diag_bs_03',
          examId: testExam,
          year: 2022,
          paper: 'GS1',
          subject: 'Indian Polity',
          topic: 'Preamble & Basic Structure',
          normalizedText:
              'Which case reaffirmed judicial review as part of the Basic Structure?',
          originalText:
              'Which case reaffirmed judicial review as part of the Basic Structure?',
          options: const [
            Option(
                key: 'A',
                text: 'Minerva Mills and L. Chandra Kumar',
                isCorrect: true),
            Option(key: 'B', text: 'A.K. Gopalan case', isCorrect: false),
            Option(key: 'C', text: 'Shankari Prasad case', isCorrect: false),
            Option(key: 'D', text: 'Barela case', isCorrect: false),
          ],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          explanation: 'Judicial review is basic structure.',
          difficulty: 'Medium',
          source: PyqSourceReference.official(
            examId: testExam,
            year: 2022,
            paper: 'GS1',
          ),
          objectiveIds: const ['lo_preamble_identity'],
        ),
      ];

      contentService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        diagnosticService: diagnosticService,
        diagnosticPlacementRepository: diagnosticRepo,
        seedQuestions: testCorpus,
      );

      // Register into locator
      TitanServiceLocator.instance.registerLazySingleton<LearnerRepository>(
        () => learnerRepo,
        allowOverride: true,
      );
      TitanServiceLocator.instance.registerLazySingleton<AttemptRepository>(
        () => attemptRepo,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<DiagnosticPlacementRepository>(
        () => diagnosticRepo,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<DiagnosticAssessmentService>(
        () => diagnosticService,
        allowOverride: true,
      );
      TitanServiceLocator.instance.registerLazySingleton<CurriculumService>(
        () => curriculumService,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<AuthoritativeLearningStateRepository>(
        () => authRepo,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<SessionCheckpointRepository>(
        () => checkpointRepo,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<AuthoritativeLearningStateRecoveryService>(
        () => authRecoveryService,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<LearningSessionRecoveryService>(
        () => sessionRecoveryService,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<AdaptiveLearningJourneyOrchestrator>(
        () => orchestrator,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<ContentLearningPathService>(
        () => contentService,
        allowOverride: true,
      );
    });

    tearDown(() {
      TitanServiceLocator.instance.reset();
    });

    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: child,
      );
    }

    testWidgets(
        '1. Cold-start learner: Path recommends Diagnostic Assessment and launches with DIAGNOSTIC badge',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Verify that initially diagnostic repository has no results for testLearner
      expect(diagnosticRepo.getLatestResultForLearner(testLearner), isNull);

      await tester.pumpWidget(
        buildTestWidget(
          ContentLearningPathPage(
            service: contentService,
            learnerId: testLearner,
            initialExamId: testExam,
            initialSubjectId: 'indian_polity',
            corpus: testCorpus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step: Select Preamble & Basic Structure
      await tester.tap(find
          .byKey(const Key('content_path_topic_preamble_and_basic_structure')));
      await tester.pumpAndSettle();

      // Verify Cold-Start recommends Diagnostic Assessment
      expect(find.text('Take Diagnostic Assessment'), findsWidgets);
      expect(
        find.textContaining('baseline competency'),
        findsWidgets,
      );

      // Tap the action button to launch Diagnostic Assessment
      await tester.tap(find.byKey(const Key('content_path_action_button')));
      await tester.pumpAndSettle();

      // Verify that AdaptivePracticePage opened in DIAGNOSTIC mode
      expect(find.text('DIAGNOSTIC'), findsOneWidget);
      expect(
        find.textContaining('Diagnostic:'),
        findsOneWidget,
      );
    });

    testWidgets(
        '2. Diagnostic Session Execution: Submits answers, evaluates placement, and establishes frontier',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller =
          AdaptiveLearningJourneyController(orchestrator: orchestrator);

      await tester.pumpWidget(
        buildTestWidget(
          AdaptivePracticePage(
            controller: controller,
            targetTopic: 'Preamble & Basic Structure',
            targetObjectiveId: 'lo_preamble_identity',
            learnerId: testLearner,
            corpus: testCorpus,
            questionCount: 3,
            isDiagnosticMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify question 1 is presented with DIAGNOSTIC badge
      expect(find.text('DIAGNOSTIC'), findsOneWidget);
      expect(find.text('Question 1 of 3'), findsOneWidget);

      // Question 1: Select Option A (Kesavananda Bharati - Correct)
      await tester.tap(find.textContaining('Kesavananda Bharati'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      expect(find.text('Correct! Well done.'), findsOneWidget);
      await tester.tap(find.text('Continue to Next Question'));
      await tester.pumpAndSettle();

      // Question 2: Select Option A (No, it is beyond amending power - Correct)
      expect(find.text('Question 2 of 3'), findsOneWidget);
      await tester.tap(find.textContaining('beyond amending power'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();
      expect(find.text('Correct! Well done.'), findsOneWidget);
      await tester.tap(find.text('Continue to Next Question'));
      await tester.pumpAndSettle();

      // Question 3: Select Option A (Minerva Mills - Correct)
      expect(find.text('Question 3 of 3'), findsOneWidget);
      await tester.tap(find.textContaining('Minerva Mills'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit Answer'));
      await tester.pumpAndSettle();

      // Verify Diagnostic Placement Summary Card is displayed immediately upon completion
      expect(find.text('Diagnostic Placement Established!'), findsOneWidget);
      expect(find.text('Baseline Knowledge Frontier'), findsOneWidget);
      expect(find.text('Demonstrated'), findsOneWidget);
      expect(find.text('Frontier'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Verify diagnostic placement is durably persisted in repository
      final latestPlacement =
          diagnosticRepo.getLatestResultForLearner(testLearner);
      expect(latestPlacement, isNotNull);
      expect(latestPlacement!.demonstratedObjectivesCount, 1);
      expect(
        latestPlacement.frontier.demonstratedObjectiveIds,
        contains('lo_preamble_identity'),
      );
      expect(latestPlacement.totalAttemptsCount, 3);
      expect(latestPlacement.totalCorrectCount, 3);
      expect(latestPlacement.aggregateAccuracy, 1.0);
    });

    testWidgets(
        '3. Closed-Loop Progression: Learning Path refreshes with baseline placement established',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Cold-start resolution: diagnostic is required
      final initialPath = await contentService.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'preamble_and_basic_structure',
        corpus: testCorpus,
      );
      expect(initialPath.isDiagnosticRequired, isTrue);
      expect(initialPath.recommendedAction, AdaptiveActionType.takeDiagnostic);

      // Now run placement evaluation (simulating completed diagnostic)
      // Save 3 successful attempts in attemptRepo
      for (int i = 1; i <= 3; i++) {
        final attId = 'att_test_$i';
        attemptRepo.saveAttempt(QuestionAttempt(
          attemptId: attId,
          learnerId: testLearner,
          questionId: 'pyq_diag_bs_0$i',
          objectiveId: 'lo_preamble_identity',
          submittedAnswer: 'A',
        ));
        attemptRepo.saveResult(AttemptResult(
          attemptId: attId,
          isCorrect: true,
          score: 1.0,
          evaluationMethod: EvaluationMethod.multipleChoice,
        ));
      }

      final placementResult = orchestrator.executeDiagnosticPlacement(
        learnerId: testLearner,
        targetObjectiveIds: ['lo_preamble_identity'],
      );
      expect(placementResult, isNotNull);
      expect(placementResult!.demonstratedObjectivesCount, 1);

      // Re-resolve learning path: diagnostic is no longer required!
      final refreshedPath = await contentService.resolveLearningPath(
        learnerId: testLearner,
        examId: testExam,
        subjectId: 'indian_polity',
        topicId: 'preamble_and_basic_structure',
        corpus: testCorpus,
      );

      // Closed-loop verified: diagnostic requirement is cleared
      expect(refreshedPath.isDiagnosticRequired, isFalse);
      expect(refreshedPath.recommendedAction,
          isNot(AdaptiveActionType.takeDiagnostic));
    });
  });
}
