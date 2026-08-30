import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/models/answer_model.dart';
import 'package:garuda_pyq/models/option_model.dart';
import 'package:garuda_pyq/models/question_model.dart' as pyq;
import 'package:garuda_pyq/models/source_model.dart';
import 'package:hive/hive.dart';
import 'package:quizforge_upsc/controllers/garuda_dashboard_viewmodel.dart';
import 'package:quizforge_upsc/controllers/pyq_controller.dart';
import 'package:quizforge_upsc/core/di/service_locator_init.dart';
import 'package:quizforge_upsc/features/learning/presentation/knowledge_map_page.dart';
import 'package:quizforge_upsc/features/learning/widgets/knowledge_node.dart';
import 'package:quizforge_upsc/models/pyq_question_model.dart';
import 'package:quizforge_upsc/pages/garuda_dashboard_page.dart';
import 'package:quizforge_upsc/pages/pyq/pyq_attempt_page.dart';
import 'package:quizforge_upsc/repositories/impl/garuda_learning_dashboard_repository.dart';
import 'package:quizforge_upsc/repositories/impl/hive_pyq_repository.dart';
import 'package:quizforge_upsc/repositories/pyq_repository.dart';
import 'package:quizforge_upsc/services/active_learner_service.dart';
import 'package:quizforge_upsc/widgets/garuda_dashboard_widgets.dart';
import 'package:titan_core/titan_core.dart';

class _MockPyqRepository implements PyqRepository {
  bool attemptRecorded = false;
  String? lastLearnerId;
  String? lastObjectiveId;

  @override
  Future<void> recordAttempt({
    required String questionId,
    required String selectedAnswer,
    String? learnerId,
    String? objectiveId,
  }) async {
    attemptRecorded = true;
    lastLearnerId = learnerId;
    lastObjectiveId = objectiveId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final fixedDate = DateTime.utc(2026, 8, 29, 12, 0);

  setUp(() async {
    TitanServiceLocator.instance.reset();
    tempDir = await Directory.systemTemp.createTemp('p27_integration_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    TitanServiceLocator.instance.reset();
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('P27 Application Integration Tests', () {
    test(
        'A. Dependency Graph: Service locator registers all authoritative singletons',
        () {
      setupServiceLocator();
      final locator = TitanServiceLocator.instance;

      expect(locator.isRegistered<ActiveLearnerService>(), isTrue);
      expect(locator.isRegistered<CurriculumFramework>(), isTrue);
      expect(locator.isRegistered<CurriculumService>(), isTrue);
      expect(locator.isRegistered<LearnerRepository>(), isTrue);
      expect(locator.isRegistered<AttemptRepository>(), isTrue);
      expect(locator.isRegistered<ProgressRepository>(), isTrue);
      expect(locator.isRegistered<ProgressTracker>(), isTrue);
      expect(locator.isRegistered<QuestionProvider>(), isTrue);
      expect(locator.isRegistered<AssessmentService>(), isTrue);
      expect(locator.isRegistered<DiagnosticPlacementRepository>(), isTrue);
      expect(locator.isRegistered<DiagnosticAssessmentService>(), isTrue);
      expect(locator.isRegistered<DeterministicStudyPlannerService>(), isTrue);
      expect(locator.isRegistered<RemedialLessonRepository>(), isTrue);
      expect(
          locator.isRegistered<DeterministicRemedialLessonService>(), isTrue);
      expect(locator.isRegistered<PyqRepository>(), isTrue);
      expect(locator.isRegistered<GarudaDashboardRepository>(), isTrue);
      expect(locator.isRegistered<DashboardViewModel>(), isTrue);

      final activeLearner = locate<ActiveLearnerService>();
      expect(activeLearner.activeLearnerId, isNotEmpty);
    });

    test(
        'B-G. Full User Lifecycle: PYQ -> P18 -> P26 -> P23 -> P24 -> P25 -> Dashboard -> Reassessment',
        () async {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);
      final learnerRepo = InMemoryLearnerRepository();
      final attemptRepo = InMemoryAttemptRepository();
      final progressRepo = InMemoryProgressRepository();
      final diagnosticRepo = InMemoryDiagnosticPlacementRepository();
      final remedialRepo = InMemoryRemedialLessonRepository();

      const learnerId = 'learner_titan_p27_user';
      learnerRepo.save(Learner(
        id: learnerId,
        name: 'TITAN P27 Aspirant',
        createdAt: fixedDate,
      ));

      // Setup canonical PYQs
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
          Option(key: 'A', text: 'Kesavananda Bharati', isCorrect: true),
          Option(key: 'B', text: 'Golaknath', isCorrect: false),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['A'],
          officialAnswerSource: 'UPSC Key',
        ),
        garudaExplanation: 'Kesavananda Bharati (1973).',
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'chk1',
          publisher: 'UPSC',
          retrievedDate: fixedDate,
        ),
      );

      final pyqQ2 = pyq.Question(
        id: 'PYQ_UPSC_2024_Q02',
        questionNumber: 2,
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Article 21',
        questionType: pyq.QuestionType.mcq,
        originalQuestion:
            'Due process in Article 21 was judicially established in:',
        options: const [
          Option(key: 'A', text: 'A.K. Gopalan', isCorrect: false),
          Option(key: 'B', text: 'Maneka Gandhi', isCorrect: true),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['B'],
          officialAnswerSource: 'UPSC Key',
        ),
        garudaExplanation: 'Maneka Gandhi (1978).',
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'chk2',
          publisher: 'UPSC',
          retrievedDate: fixedDate,
        ),
      );

      final questionProvider = PyqQuestionProvider(
        questions: [pyqQ1, pyqQ2],
        topicOrTagToObjectiveIds: {
          'basic structure': ['lo_basic_structure_doctrine'],
          'article 21': ['lo_article_21_foundations'],
        },
      );

      final assessmentService = AssessmentService(
        learnerRepository: learnerRepo,
        attemptRepository: attemptRepo,
        curriculumService: curriculumService,
        questionProvider: questionProvider,
        progressTracker: ProgressTracker(
          attemptRepository: attemptRepo,
          progressRepository: progressRepo,
        ),
      );

      final diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: questionProvider,
        attemptRepository: attemptRepo,
        diagnosticRepository: diagnosticRepo,
      );

      await remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'rem_art21_p27',
        objectiveId: 'lo_article_21_foundations',
        title: 'Article 21: Due Process Foundations',
        summary: 'Targeted remediation for Article 21 interpretation.',
        learningPoints: const ['Substantive due process', 'Fair procedure'],
        explanation: 'Detailed legal breakdown.',
        estimatedMinutes: 15,
        authoredAt: fixedDate,
      ));

      final remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      final pyqRepo = HivePyqRepository(
        assessmentService: assessmentService,
        curriculumService: curriculumService,
        defaultLearnerId: learnerId,
        objectiveResolver: (q) => q.id == 'PYQ_UPSC_2024_Q01'
            ? 'lo_basic_structure_doctrine'
            : 'lo_article_21_foundations',
      );

      final dashboardRepo = GarudaLearningDashboardRepository(
        curriculumService: curriculumService,
        progressRepository: progressRepo,
        attemptRepository: attemptRepo,
        diagnosticService: diagnosticService,
        remedialService: remedialService,
      );

      final dashboardViewModel = DashboardViewModel(repository: dashboardRepo);

      // 1. Initial State: Dashboard shows zero attempts without crash
      await dashboardViewModel.loadDashboardData(learnerId);
      expect(dashboardViewModel.summary?.questionsAttempted, 0);
      expect(dashboardViewModel.summary?.overallAccuracy, 0.0);
      expect(dashboardViewModel.topicAnalytics?.strongTopics, isEmpty);
      expect(dashboardViewModel.topicAnalytics?.weakTopics, isEmpty);

      // 2. Step B: Learner attempts Q1 correctly through HivePyqRepository
      final box = await Hive.openBox<String>('pyq_questions');
      final modelQ1 = PyqQuestionModel(
        id: 'PYQ_UPSC_2024_Q01',
        year: 2024,
        exam: 'UPSC CSE Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Basic Structure',
        difficulty: 'Medium',
        question: 'Which case established the Basic Structure Doctrine?',
        options: const ['A', 'B'],
        correctAnswer: 'A',
        officialAnswer: 'A',
        explanation: PyqExplanation(official: 'Kesavananda Bharati (1973).'),
        reference: 'Constitution',
      );
      await box.put(modelQ1.id, jsonEncode(modelQ1.toJson()));

      await pyqRepo.recordAttempt(
        questionId: 'PYQ_UPSC_2024_Q01',
        selectedAnswer: 'A',
        learnerId: learnerId,
        objectiveId: 'lo_basic_structure_doctrine',
      );

      // Verify P18 evidence is recorded
      final attemptsQ1 = attemptRepo.getAttemptsForLearner(learnerId);
      expect(attemptsQ1.length, 1);
      expect(
          attemptRepo
              .getResultForAttempt(attemptsQ1.first.attemptId)
              ?.isCorrect,
          isTrue);

      // 3. Step C & E: Dashboard reflects real P18 evidence & P24 study plan
      await dashboardViewModel.loadDashboardData(learnerId);
      expect(dashboardViewModel.summary?.questionsAttempted, 1);
      expect(dashboardViewModel.summary?.correctAnswers, 1);
      expect(dashboardViewModel.summary?.overallAccuracy, 1.0);
      expect(dashboardViewModel.studyPlan?.taskCount, greaterThanOrEqualTo(1));

      // 4. Step F: Learner fails Q2 three times -> triggers P26 developing & P25 remediation target
      final modelQ2 = PyqQuestionModel(
        id: 'PYQ_UPSC_2024_Q02',
        year: 2024,
        exam: 'UPSC CSE Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Article 21',
        difficulty: 'Hard',
        question: 'Due process in Article 21 was judicially established in:',
        options: const ['A', 'B'],
        correctAnswer: 'B',
        officialAnswer: 'B',
        explanation: PyqExplanation(official: 'Maneka Gandhi (1978).'),
        reference: 'Constitution',
      );
      await box.put(modelQ2.id, jsonEncode(modelQ2.toJson()));

      for (int i = 0; i < 3; i++) {
        await pyqRepo.recordAttempt(
          questionId: 'PYQ_UPSC_2024_Q02',
          selectedAnswer: 'A', // Incorrect
          learnerId: learnerId,
          objectiveId: 'lo_article_21_foundations',
        );
      }

      await dashboardViewModel.loadDashboardData(learnerId);
      expect(dashboardViewModel.summary?.questionsAttempted, 4);
      expect(dashboardViewModel.summary?.correctAnswers, 1);
      expect(dashboardViewModel.summary?.overallAccuracy, 0.25);
      expect(dashboardViewModel.topicAnalytics?.weakTopics,
          contains('Evaluate the Expansion of Article 21 Rights'));
      expect(dashboardViewModel.recommendations?.nextBestAction,
          contains('Remedial Review: Article 21: Due Process Foundations'));

      // 5. Step G: Reassessment - Learner completes remedial study and submits 3 correct attempts
      for (int i = 0; i < 5; i++) {
        await pyqRepo.recordAttempt(
          questionId: 'PYQ_UPSC_2024_Q02',
          selectedAnswer: 'B', // Correct!
          learnerId: learnerId,
          objectiveId: 'lo_article_21_foundations',
        );
      }

      // Re-evaluate dashboard state
      await dashboardViewModel.loadDashboardData(learnerId);
      expect(dashboardViewModel.summary?.questionsAttempted, 9);
      expect(dashboardViewModel.summary?.correctAnswers, 6);
      // Accuracy on Q2 is now 5/8 = 62.5% (> 60% threshold), no longer in weak topics!
      expect(dashboardViewModel.topicAnalytics?.weakTopics, isEmpty);
    });

    testWidgets(
        'D. KnowledgeMapPage consumes DiagnosticPlacementFrontier correctly',
        (WidgetTester tester) async {
      final frontier = DiagnosticPlacementFrontier(
        activeFrontierObjectiveIds: const ['lo_basic_structure_doctrine'],
        demonstratedObjectiveIds: const ['pol_fr_001'],
        developingObjectiveIds: const ['lo_article_21_foundations'],
        unassessedObjectiveIds: const ['pol_fr_003'],
        remediationTargetObjectiveIds: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KnowledgeMapPage(
            diagnosticFrontier: frontier,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Knowledge Map'), findsOneWidget);
      expect(find.text('Module 7: Fundamental Rights'), findsOneWidget);
      // Demonstrates that nodes render based on real diagnostic frontier
      expect(find.byType(KnowledgeNode), findsWidgets);
    });

    test(
        'E. Remedial Practice Flow: Dashboard identifies target -> launches objective-filtered session -> attempts reach P18 -> P26 reassessment -> Dashboard refresh',
        () async {
      // 1. Initialize Seed Data & Engine
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);
      final learnerRepo = InMemoryLearnerRepository();
      final attemptRepo = InMemoryAttemptRepository();
      final progressRepo = InMemoryProgressRepository();
      final diagnosticRepo = InMemoryDiagnosticPlacementRepository();
      final remedialRepo = InMemoryRemedialLessonRepository();

      const learnerId = 'learner_titan_remedial_flow_user';
      learnerRepo.save(Learner(
        id: learnerId,
        name: 'TITAN Remedial Aspirant',
        createdAt: fixedDate,
      ));

      final activeLearnerService = ActiveLearnerService();
      activeLearnerService.setActiveLearnerId(learnerId);

      // Register seed remedial micro-lesson for Article 21
      await remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'rem_art21_flow',
        objectiveId: 'lo_article_21_foundations',
        title: 'Article 21: Due Process Foundations',
        summary: 'Targeted remediation for Article 21 interpretation.',
        learningPoints: const ['Substantive due process', 'Fair procedure'],
        explanation: 'Detailed legal breakdown.',
        estimatedMinutes: 15,
        authoredAt: fixedDate,
      ));

      // Setup question in Pyq repository
      final pyqQ2 = pyq.Question(
        id: 'PYQ_UPSC_2024_Q02',
        questionNumber: 2,
        examId: 'upsc_cse',
        year: 2024,
        stage: 'Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Article 21',
        questionType: pyq.QuestionType.mcq,
        originalQuestion:
            'Due process in Article 21 was judicially established in:',
        options: const [
          Option(key: 'A', text: 'A.K. Gopalan', isCorrect: false),
          Option(key: 'B', text: 'Maneka Gandhi', isCorrect: true),
        ],
        officialAnswer: const Answer(
          correctOptionKeys: ['B'],
          officialAnswerSource: 'UPSC Key',
        ),
        garudaExplanation: 'Maneka Gandhi (1978).',
        source: QuestionSource(
          sourceType: SourceType.officialWebsite,
          url: 'https://upsc.gov.in',
          checksum: 'chk2',
          publisher: 'UPSC',
          retrievedDate: fixedDate,
        ),
      );

      final questionProvider = PyqQuestionProvider(
        questions: [pyqQ2],
        topicOrTagToObjectiveIds: {
          'article 21': ['lo_article_21_foundations'],
        },
      );

      final assessmentService = AssessmentService(
        learnerRepository: learnerRepo,
        attemptRepository: attemptRepo,
        curriculumService: curriculumService,
        questionProvider: questionProvider,
        progressTracker: ProgressTracker(
          attemptRepository: attemptRepo,
          progressRepository: progressRepo,
        ),
      );

      final diagnosticService = DiagnosticAssessmentService(
        learnerRepository: learnerRepo,
        curriculumService: curriculumService,
        questionProvider: questionProvider,
        attemptRepository: attemptRepo,
        diagnosticRepository: diagnosticRepo,
      );

      final remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      final pyqRepo = HivePyqRepository(
        assessmentService: assessmentService,
        curriculumService: curriculumService,
        defaultLearnerId: learnerId,
        objectiveResolver: (q) => 'lo_article_21_foundations',
      );

      final pyqModel = PyqQuestionModel(
        id: 'PYQ_UPSC_2024_Q02',
        year: 2024,
        exam: 'UPSC CSE Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Article 21',
        difficulty: 'Hard',
        question: 'Due process in Article 21 was judicially established in:',
        options: const [
          'A.K. Gopalan',
          'Maneka Gandhi',
        ],
        correctAnswer: 'B',
        officialAnswer: 'B',
        explanation: PyqExplanation(official: 'Maneka Gandhi (1978).'),
        reference: 'Constitution',
      );

      final box = await Hive.openBox<String>('pyq_questions');
      await box.put(
        'PYQ_UPSC_2024_Q02',
        jsonEncode(pyqModel.toJson()),
      );

      // Register authoritative singletons in TitanServiceLocator
      final locator = TitanServiceLocator.instance;
      locator.registerLazySingleton<ActiveLearnerService>(
          () => activeLearnerService,
          allowOverride: true);
      locator.registerLazySingleton<CurriculumService>(() => curriculumService,
          allowOverride: true);
      locator.registerLazySingleton<AssessmentService>(() => assessmentService,
          allowOverride: true);
      locator.registerLazySingleton<DiagnosticAssessmentService>(
          () => diagnosticService,
          allowOverride: true);
      locator.registerLazySingleton<PyqRepository>(() => pyqRepo,
          allowOverride: true);

      final dashboardRepo = GarudaLearningDashboardRepository(
        curriculumService: curriculumService,
        progressRepository: progressRepo,
        attemptRepository: attemptRepo,
        diagnosticService: diagnosticService,
        remedialService: remedialService,
      );

      final dashboardViewModel = DashboardViewModel(repository: dashboardRepo);

      // 2. Simulate poor initial evidence on Article 21 (3 incorrect attempts)
      for (int i = 0; i < 3; i++) {
        await pyqRepo.recordAttempt(
          questionId: 'PYQ_UPSC_2024_Q02',
          selectedAnswer: 'A', // Incorrect
          learnerId: learnerId,
          objectiveId: 'lo_article_21_foundations',
        );
      }

      await dashboardViewModel.loadDashboardData(learnerId);

      // Verify Test 1: Remedial action availability
      expect(dashboardViewModel.hasRemedialTarget, isTrue);
      expect(dashboardViewModel.activeRemediationObjectiveId,
          'lo_article_21_foundations');
      expect(dashboardViewModel.nextBestAction?.recType, 'remedial');

      // 3. Step: Dashboard resolves P26 remediation target objective
      final targetObjectiveId = dashboardViewModel
              .activeRemediationObjectiveId ??
          await dashboardViewModel.getRemediationTargetObjectiveId(learnerId);
      expect(targetObjectiveId, 'lo_article_21_foundations');

      // 4. Step: Objective-filtered PYQ practice session launched
      final pyqController = PyqController(repository: pyqRepo);
      final questions =
          await pyqController.getQuestionsForObjective(targetObjectiveId!);
      expect(questions.isNotEmpty, isTrue);
      expect(questions.first.topic, 'Article 21');

      // 5. Step: Learner submits answer (Test 3: Attempt reaches P18)
      final initialAttemptCount =
          attemptRepo.getAttemptsForLearner(learnerId).length;
      expect(initialAttemptCount, 3);

      await pyqController.recordAttempt(
        questionId: questions.first.id,
        selectedAnswer: 'B', // Correct answer (Maneka Gandhi)
        learnerId: learnerId,
        objectiveId: targetObjectiveId,
      );

      final updatedAttempts = attemptRepo.getAttemptsForLearner(learnerId);
      expect(updatedAttempts.length, 4);
      final lastAttempt = updatedAttempts.last;
      expect(lastAttempt.questionId, 'PYQ_UPSC_2024_Q02');
      expect(lastAttempt.objectiveId, 'lo_article_21_foundations');
      expect(lastAttempt.learnerId, learnerId);
      expect(attemptRepo.getResultForAttempt(lastAttempt.attemptId)?.isCorrect,
          isTrue);

      // 6. Step: Complete remedial practice to raise accuracy above 60% threshold
      for (int i = 0; i < 5; i++) {
        await pyqRepo.recordAttempt(
          questionId: 'PYQ_UPSC_2024_Q02',
          selectedAnswer: 'B', // Correct
          learnerId: learnerId,
          objectiveId: 'lo_article_21_foundations',
        );
      }

      // 7. Step: P26 Reassessment - Re-evaluate diagnostic placement
      final reassessmentResult = diagnosticService.evaluatePlacement(
        DiagnosticAssessmentRequest(
          requestId: 'diag_req_reassess',
          learnerId: learnerId,
          targetObjectiveIds: const ['lo_article_21_foundations'],
          requestedAt: DateTime.now().toUtc(),
        ),
      );
      // Accuracy is now 6/9 = 66.7% (>= 50% developing threshold and >= 60% P23 weakness threshold)
      expect(
          reassessmentResult.frontier.remediationTargetObjectiveIds, isEmpty);

      // 8. Step: Dashboard refresh dynamically reflects resolved remediation
      await dashboardViewModel.loadDashboardData(learnerId);
      expect(dashboardViewModel.summary?.questionsAttempted, 9);
      expect(dashboardViewModel.summary?.correctAnswers, 6);
      expect(dashboardViewModel.hasRemedialTarget, isFalse);
    });

    testWidgets(
        'F. Dashboard UI exposes Start Remedial Practice action on remedial recommendation',
        (WidgetTester tester) async {
      bool remedialActionTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: NextBestActionCard(
              nba: const NextBestActionDto(
                id: 'nba_rem_01',
                recType: 'remedial',
                title: 'Remedial Study: Article 21',
                description: 'Address observed gap with micro-lesson.',
                priority: 'High',
                reason: 'Diagnostic evaluation indicates developing state.',
                confidenceScore: 0.95,
              ),
              onStartRemedial: () {
                remedialActionTriggered = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final remedialButton =
          find.widgetWithText(ElevatedButton, 'Start Remedial Practice');
      expect(remedialButton, findsOneWidget);

      await tester.tap(remedialButton);
      await tester.pumpAndSettle();

      expect(remedialActionTriggered, isTrue);
    });

    testWidgets(
        'G. GarudaDashboardPage Widget Acceptance: Exposes Start Remedial Practice when remedial target exists',
        (WidgetTester tester) async {
      final mockRepo = MockGarudaDashboardRepository();
      final viewModel = DashboardViewModel(repository: mockRepo);
      await viewModel.loadDashboardData('learner_01');

      expect(viewModel.hasRemedialTarget, isTrue);
      expect(
          viewModel.activeRemediationObjectiveId, 'lo_article_21_foundations');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: GarudaDashboardPage(viewModel: viewModel),
        ),
      );
      await tester.pumpAndSettle();

      // Start Remedial Practice button must be present in NextBestActionCard
      final remedialButton =
          find.widgetWithText(ElevatedButton, 'Start Remedial Practice');
      expect(remedialButton, findsOneWidget);
    });

    testWidgets(
        'H. PyqAttemptPage Widget Acceptance: Renders remedial session and captures learner attempt',
        (WidgetTester tester) async {
      final mockRepo = _MockPyqRepository();
      final controller = PyqController(repository: mockRepo);

      final q = PyqQuestionModel(
        id: 'PYQ_REMEDIAL_01',
        year: 2024,
        exam: 'UPSC CSE',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Article 21',
        difficulty: 'Medium',
        question: 'Due process under Article 21 was established in which case?',
        options: const [
          'A.K. Gopalan',
          'Maneka Gandhi',
        ],
        correctAnswer: 'B',
        officialAnswer: 'B',
        explanation: PyqExplanation(official: 'Maneka Gandhi v Union of India'),
        reference: 'UPSC',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: PyqAttemptPage(
            questions: [q],
            title: 'Remedial: Article 21 Due Process',
            learnerId: 'learner_titan_01',
            objectiveId: 'lo_article_21_foundations',
            controller: controller,
            enableTimer: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remedial: Article 21 Due Process'), findsOneWidget);
      expect(
          find.text(
              'Due process under Article 21 was established in which case?'),
          findsOneWidget);
      expect(find.text('Maneka Gandhi'), findsOneWidget);

      await tester.tap(find.text('Maneka Gandhi'));
      await tester.pumpAndSettle();

      // Option selected state shows explanation toggle
      expect(find.text('View Solution & Explanation'), findsOneWidget);
      expect(mockRepo.attemptRecorded, isTrue);
      expect(mockRepo.lastLearnerId, 'learner_titan_01');
      expect(mockRepo.lastObjectiveId, 'lo_article_21_foundations');
    });

    test('I. Objective Filtering: No fallback to unrelated questions',
        () async {
      final framework =
          CurriculumSeedData.buildUpscConstitutionalLawFramework();
      final curriculumService = CurriculumService(framework: framework);
      final pyqRepo = HivePyqRepository(
        curriculumService: curriculumService,
        defaultLearnerId: 'test_learner',
      );

      final box = await Hive.openBox<String>('pyq_questions');
      final modelQ1 = PyqQuestionModel(
        id: 'PYQ_BASIC_STRUCTURE_01',
        year: 2024,
        exam: 'UPSC CSE Prelims',
        paper: 'GS1',
        subject: 'Polity',
        topic: 'Basic Structure',
        difficulty: 'Medium',
        question: 'Which case established Basic Structure?',
        options: const ['A', 'B'],
        correctAnswer: 'A',
        officialAnswer: 'A',
        explanation: PyqExplanation(official: 'Kesavananda Bharati.'),
        reference: 'Constitution',
      );
      await box.put(modelQ1.id, jsonEncode(modelQ1.toJson()));

      // Target objective with no matching questions returns empty
      final questions =
          await pyqRepo.getQuestionsForObjective('lo_non_existent_objective');
      expect(questions, isEmpty);

      // Target objective with matching question returns that question
      final matchedQuestions =
          await pyqRepo.getQuestionsForObjective('lo_basic_structure_doctrine');
      expect(matchedQuestions.length, 1);
      expect(matchedQuestions.first.id, 'PYQ_BASIC_STRUCTURE_01');
    });

    testWidgets(
        'J. Dashboard UI does not expose Start Remedial Practice when no remedial target exists',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: NextBestActionCard(
              nba: const NextBestActionDto(
                id: 'nba_learn_01',
                recType: 'learning',
                title: 'Advance Frontier: Preamble',
                description: 'Prerequisites met. Ready to learn.',
                priority: 'Medium',
                reason: 'Curriculum sequence.',
                confidenceScore: 0.85,
              ),
              onStartRemedial: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final remedialButton =
          find.widgetWithText(ElevatedButton, 'Start Remedial Practice');
      expect(remedialButton, findsNothing);
    });
  });
}
