import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/controllers/dashboard_controller.dart';
import 'package:quizforge_upsc/core/di/service_locator_init.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/pages/adaptive_practice_page.dart';
import 'package:quizforge_upsc/pages/quizforge_dashboard_page.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:quizforge_upsc/widgets/dashboard/dashboard_header_widget.dart';
import 'package:quizforge_upsc/widgets/dashboard/plugin_module_grid_widget.dart';
import 'package:quizforge_upsc/widgets/dashboard/quick_action_card_widget.dart';
import 'package:quizforge_upsc/widgets/dashboard/recent_activity_card_widget.dart';
import 'package:quizforge_upsc/widgets/dashboard/stat_summary_card_widget.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P41 Learner Dashboard UI Integration Tests', () {
    const testExam = 'upsc_prelims_gs1';
    final baseDate = DateTime.utc(2026, 9, 6, 12, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late LearnerDashboardController learnerController;
    late _FakeQuizSessionRepository fakeSessionRepo;
    late _FakeQuizHistoryRepository fakeHistoryRepo;
    late _FakeQuizSourceRepository fakeSourceRepo;

    setUp(() {
      TitanServiceLocator.instance.reset();

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

      fakeSessionRepo = _FakeQuizSessionRepository();
      fakeHistoryRepo = _FakeQuizHistoryRepository();
      fakeSourceRepo = _FakeQuizSourceRepository();

      learnerController = LearnerDashboardController(
        authRepository: authRepo,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        sessionRecoveryService: sessionRecoveryService,
        curriculumService: curriculumService,
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

    DashboardController createController() {
      return DashboardController(
        learnerController: learnerController,
        sessionRepository: fakeSessionRepo,
        historyRepository: fakeHistoryRepo,
        sourceRepository: fakeSourceRepo,
      );
    }

    testWidgets('1. UI First-Time Learner: shows Start Learning and Diagnostic Recommendation',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = createController();

      await tester.pumpWidget(
        buildTestWidget(
          QuizForgeDashboardPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Header & App Bar
      expect(find.text('QuizForge AI'), findsOneWidget);

      // Section A: Start Adaptive Practice (no recoverable session)
      expect(find.text('Start Adaptive Practice'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);

      // Section B: Progress Summary shows New Aspirant
      expect(find.text('Current Learning Progress'), findsOneWidget);
      expect(find.text('New Aspirant'), findsOneWidget);

      // Section C: Next Best Action recommends diagnostic
      expect(find.text('Take Diagnostic Assessment'), findsWidgets);
      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('2. UI Active Session: displays In-Progress Session and Continue Action',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final activeCheckpoint = SessionCheckpoint(
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        sessionId: 'sess_ui_active_01',
        learnerId: 'default_learner',
        examId: testExam,
        questionIndex: 2,
        completedQuestionIds: const ['q1', 'q2'],
        activeObjectiveId: 'lo_const_fr_01',
        timestamp: baseDate,
        isCompleted: false,
        metadata: {'totalQuestions': 5, 'topic': 'Fundamental Rights'},
      );
      await checkpointRepo.saveCheckpoint(activeCheckpoint);
      final controller = createController();

      await tester.pumpWidget(
        buildTestWidget(
          QuizForgeDashboardPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Should display in-progress session banner
      expect(find.text('IN-PROGRESS ADAPTIVE SESSION'), findsOneWidget);
      expect(find.text('Fundamental Rights'), findsWidgets);
      expect(find.text('Question 3 of 5 in progress'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tapping Continue navigates to AdaptivePracticePage in resume mode
      await tester.tap(find.text('Continue').first);
      await tester.pumpAndSettle();

      expect(find.byType(AdaptivePracticePage), findsOneWidget);
    });

    testWidgets('3. UI Real Metrics: displays authoritative attempts and accuracy without fake numbers',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final progress = LearnerProgress(
        learnerId: 'default_learner',
        objectiveId: 'lo_const_fr_01',
        attemptCount: 10,
        correctCount: 8,
        status: LearnerObjectiveStatus.achieved,
        lastAttemptAt: baseDate,
      );

      final authState = AuthoritativeLearnerState(
        learnerId: 'default_learner',
        examId: testExam,
        progressMap: {'lo_const_fr_01': progress},
        lastUpdatedAt: baseDate,
        revision: 2,
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState));
      final controller = createController();

      await tester.pumpWidget(
        buildTestWidget(
          QuizForgeDashboardPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Accuracy 80.0%
      expect(find.text('80.0%'), findsOneWidget);
      // Questions Solved 10
      expect(find.text('10'), findsOneWidget);
      // Status Proficient
      expect(find.text('Proficient'), findsOneWidget);
    });

    testWidgets('4. UI Next Best Action: tapping Action navigates to practice topic',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = createController();

      await tester.pumpWidget(
        buildTestWidget(
          QuizForgeDashboardPage(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Find Action button in Next Best Action card
      final actionButton = find.widgetWithText(OutlinedButton, 'Action');
      expect(actionButton, findsOneWidget);

      await tester.tap(actionButton);
      await tester.pumpAndSettle();

      // Should have navigated to practice session
      expect(find.byType(AdaptivePracticePage), findsOneWidget);
    });
  });
}

class _FakeQuizSessionRepository implements QuizSessionRepository {
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

class _FakeQuizHistoryRepository implements QuizHistoryRepository {
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

class _FakeQuizSourceRepository implements QuizSourceRepository {
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
