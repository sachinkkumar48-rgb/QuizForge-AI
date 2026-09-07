import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:quizforge_upsc/controllers/dashboard_controller.dart';
import 'package:quizforge_upsc/core/di/service_locator_init.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/pages/adaptive_practice_page.dart';
import 'package:quizforge_upsc/pages/content_learning_path_page.dart';
import 'package:quizforge_upsc/pages/quizforge_dashboard_page.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P42 Content-to-Learning-Path UI Integration Tests', () {
    const testLearner = 'learner_ui_p42';
    const testExam = 'upsc_prelims_gs1';
    final baseDate = DateTime.utc(2026, 9, 7, 10, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late List<NormalizedQuestion> testCorpus;
    late ContentLearningPathService contentService;

    setUp(() {
      TitanServiceLocator.instance.reset();

      authRepo = InMemoryAuthoritativeLearningStateRepository();
      checkpointRepo = InMemorySessionCheckpointRepository();
      authRecoveryService = AuthoritativeLearningStateRecoveryService(
        repository: authRepo,
      );
      framework = CurriculumSeedData.buildUpscConstitutionalLawFramework();
      curriculumService = CurriculumService(framework: framework);

      testCorpus = [
        NormalizedQuestion(
          id: 'pyq_ui_fr_01',
          examId: testExam,
          year: 2024,
          paper: 'GS1',
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
          normalizedText:
              'Which Article protects Right to Life and Personal Liberty?',
          originalText:
              'Which Article protects Right to Life and Personal Liberty?',
          options: const [
            Option(key: 'A', text: 'Article 21', isCorrect: true),
            Option(key: 'B', text: 'Article 19', isCorrect: false),
            Option(key: 'C', text: 'Article 14', isCorrect: false),
            Option(key: 'D', text: 'Article 32', isCorrect: false),
          ],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          explanation: 'Article 21 protects personal liberty.',
          difficulty: 'Easy',
          source: PyqSourceReference.official(
            examId: testExam,
            year: 2024,
            paper: 'GS1',
          ),
          objectiveIds: const ['lo_article_21_foundations'],
        ),
        NormalizedQuestion(
          id: 'pyq_ui_ep_01',
          examId: testExam,
          year: 2023,
          paper: 'GS1',
          subject: 'Indian Polity',
          topic: 'Emergency Provisions',
          normalizedText:
              'Under which Article can National Emergency be proclaimed?',
          originalText:
              'Under which Article can National Emergency be proclaimed?',
          options: const [
            Option(key: 'A', text: 'Article 352', isCorrect: true),
            Option(key: 'B', text: 'Article 356', isCorrect: false),
            Option(key: 'C', text: 'Article 360', isCorrect: false),
            Option(key: 'D', text: 'Article 365', isCorrect: false),
          ],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          explanation: 'Article 352 provides for National Emergency.',
          difficulty: 'Medium',
          source: PyqSourceReference.official(
            examId: testExam,
            year: 2023,
            paper: 'GS1',
          ),
          objectiveIds: const ['lo_emergency_provisions'],
        ),
      ];

      contentService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        seedQuestions: testCorpus,
      );

      TitanServiceLocator.instance
          .registerLazySingleton<ContentLearningPathService>(
        () => contentService,
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
        '1. Content Discovery: Exam selection list displays and navigates to subjects',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          ContentLearningPathPage(
            service: contentService,
            learnerId: testLearner,
            corpus: testCorpus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Page Title & Catalogue
      expect(find.text('Learning Paths & Content'), findsOneWidget);
      expect(find.text('Select Examination'), findsOneWidget);
      expect(find.byKey(const Key('content_path_exam_upsc_prelims_gs1')),
          findsOneWidget);
      expect(find.text('Supported'), findsOneWidget);

      // Tap on UPSC Prelims GS1
      await tester
          .tap(find.byKey(const Key('content_path_exam_upsc_prelims_gs1')));
      await tester.pumpAndSettle();

      // Subject Selection screen is displayed
      expect(find.textContaining('Select Subject'), findsOneWidget);
      expect(find.text('Indian Polity'), findsOneWidget);
      expect(find.text('Economy'), findsOneWidget);
    });

    testWidgets(
        '2. Subject & Topic Selection: displays curriculum topics and question counts',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          ContentLearningPathPage(
            service: contentService,
            learnerId: testLearner,
            initialExamId: 'upsc_prelims_gs1',
            corpus: testCorpus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Indian Polity
      await tester
          .tap(find.byKey(const Key('content_path_subject_indian_polity')));
      await tester.pumpAndSettle();

      // Topics displayed
      expect(find.text('Topics in Indian Polity'), findsOneWidget);
      expect(find.text('Fundamental Rights'), findsOneWidget);
      expect(find.text('1 PYQs'), findsWidgets);
      expect(find.text('0 PYQs'), findsWidgets);
    });

    testWidgets(
        '3. Topic Selection & Learning Start: resolves objective and starts diagnostic for cold-start',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          ContentLearningPathPage(
            service: contentService,
            learnerId: testLearner,
            initialExamId: 'upsc_prelims_gs1',
            initialSubjectId: 'indian_polity',
            corpus: testCorpus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Fundamental Rights
      await tester
          .tap(find.byKey(const Key('content_path_topic_fundamental_rights')));
      await tester.pumpAndSettle();

      // Objective details card
      expect(
          find.byKey(const Key('content_path_objective_card')), findsOneWidget);
      expect(find.text('Evaluate the Expansion of Article 21 Rights'),
          findsOneWidget);
      expect(find.text('Bloom Level: EVALUATE'), findsOneWidget);

      // Recommended Action: Diagnostic for cold-start
      expect(find.text('RECOMMENDED ENTRY POINT'), findsOneWidget);
      expect(find.text('Take Diagnostic Assessment'), findsWidgets);
      expect(
          find.byKey(const Key('content_path_action_button')), findsOneWidget);

      // Tap action button to start learning
      await tester.tap(find.byKey(const Key('content_path_action_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AdaptivePracticePage), findsOneWidget);
    });

    testWidgets(
        '4. Resumption Flow: detects in-flight checkpoint and offers Resume button',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Save an in-flight checkpoint for Fundamental Rights
      final checkpoint = SessionCheckpoint(
        checkpointRevision: 1,
        authoritativeStateRevision: 1,
        sessionId: 'sess_active_fr_ui',
        examId: testExam,
        learnerId: testLearner,
        timestamp: baseDate,
        questionIndex: 1,
        activeObjectiveId: 'lo_article_21_foundations',
        completedQuestionIds: const ['pyq_ui_fr_01'],
        isCompleted: false,
        schemaVersion: 1,
        metadata: const {
          'topic': 'Fundamental Rights',
          'topicId': 'fundamental_rights',
          'totalQuestions': 2,
        },
      );
      await checkpointRepo.saveCheckpoint(checkpoint);

      await tester.pumpWidget(
        buildTestWidget(
          ContentLearningPathPage(
            service: contentService,
            learnerId: testLearner,
            initialExamId: 'upsc_prelims_gs1',
            initialSubjectId: 'indian_polity',
            corpus: testCorpus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Fundamental Rights
      await tester
          .tap(find.byKey(const Key('content_path_topic_fundamental_rights')));
      await tester.pumpAndSettle();

      // Should show Resume in-flight session banner and resume button
      expect(find.text('RESUME IN-FLIGHT SESSION'), findsOneWidget);
      expect(find.text('Resume Practice Session'), findsOneWidget);
      expect(
          find.byKey(const Key('content_path_resume_button')), findsOneWidget);

      // Tap Resume button navigates to AdaptivePracticePage in resume mode
      await tester.tap(find.byKey(const Key('content_path_resume_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AdaptivePracticePage), findsOneWidget);
    });

    testWidgets(
        '5. Empty Content Topic: shows truthful empty state when no questions exist',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          ContentLearningPathPage(
            service: contentService,
            learnerId: testLearner,
            initialExamId: 'upsc_prelims_gs1',
            initialSubjectId: 'indian_polity',
            corpus: testCorpus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap topic with 0 PYQs: Parliament & State Legislature
      await tester.tap(find.byKey(
          const Key('content_path_topic_parliament_and_state_legislature')));
      await tester.pumpAndSettle();

      // Should display empty content card
      expect(find.byKey(const Key('content_path_empty_state')), findsOneWidget);
      expect(find.text('No Practice Questions Available'), findsOneWidget);
      expect(find.text('Choose Another Topic'), findsOneWidget);

      // Tap Choose Another Topic returns to topic list
      await tester.tap(find.text('Choose Another Topic'));
      await tester.pumpAndSettle();

      expect(find.text('Topics in Indian Polity'), findsOneWidget);
    });

    testWidgets(
        '6. Dashboard Quick Action: tapping UPSC PYQ Vault navigates to ContentLearningPathPage',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sessionRecoveryService = LearningSessionRecoveryService(
        checkpointRepository: checkpointRepo,
        authoritativeRecoveryService: authRecoveryService,
      );

      final learnerDashboardController = LearnerDashboardController(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        curriculumService: curriculumService,
      );

      final dashboardController = DashboardController(
        learnerController: learnerDashboardController,
        sessionRepository: _TestSessionRepository(),
        historyRepository: _TestHistoryRepository(),
        sourceRepository: _TestQuizSourceRepository(),
      );

      await tester.pumpWidget(
        buildTestWidget(
          QuizForgeDashboardPage(controller: dashboardController),
        ),
      );
      await tester.pumpAndSettle();

      // Verify dashboard rendered
      expect(find.text('UPSC PYQ Vault'), findsOneWidget);

      // Tap UPSC PYQ Vault
      await tester.tap(find.text('UPSC PYQ Vault'));
      await tester.pumpAndSettle();

      // Navigated to ContentLearningPathPage
      expect(find.byType(ContentLearningPathPage), findsOneWidget);
      expect(find.text('Learning Paths & Content'), findsOneWidget);
    });
  });
}

class _TestSessionRepository implements QuizSessionRepository {
  QuizSession? _session;
  @override
  Future<void> deleteSession() async => _session = null;
  @override
  Future<bool> hasActiveSession() async => _session != null;
  @override
  Future<QuizSession?> loadSession() async => _session;
  @override
  Future<void> saveSession(QuizSession session) async => _session = session;
}

class _TestHistoryRepository implements QuizHistoryRepository {
  final List<QuizAttempt> _attempts = [];
  @override
  Future<void> clearHistory() async => _attempts.clear();
  @override
  Future<void> deleteAttempt(String id) async =>
      _attempts.removeWhere((a) => a.id == id);
  @override
  Future<List<QuizAttempt>> getAttempts() async => List.unmodifiable(_attempts);
  @override
  Future<void> saveAttempt(QuizAttempt attempt) async => _attempts.add(attempt);
}

class _TestQuizSourceRepository implements QuizSourceRepository {
  final List<QuizSource> _sources = [];
  @override
  Future<void> deleteSource(String id) async =>
      _sources.removeWhere((s) => s.id == id);
  @override
  Future<List<QuizSource>> getSources() async => List.unmodifiable(_sources);
  @override
  Future<void> saveSource(QuizSource source) async => _sources.add(source);
  @override
  Future<void> toggleFavorite(String id) async {}
  @override
  Future<void> updateSource(QuizSource source) async {}
}
