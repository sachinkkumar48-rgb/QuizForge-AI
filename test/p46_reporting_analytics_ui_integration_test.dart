import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:quizforge_upsc/controllers/dashboard_controller.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/pages/analytics_dashboard_page.dart';
import 'package:quizforge_upsc/pages/quizforge_dashboard_page.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:titan_core/titan_core.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P46 Reporting & Analytics UI Integration Tests', () {
    const testExam = 'upsc_prelims_gs1';
    const testLearner = 'default_learner';
    final baseDate = DateTime.utc(2026, 9, 8, 12, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late MasteryProgressionService masteryService;
    late LearnerAnalyticsService analyticsService;
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

      masteryService = MasteryProgressionService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
      );

      analyticsService = LearnerAnalyticsService(
        curriculumService: curriculumService,
        masteryService: masteryService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
      );

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
      TitanServiceLocator.instance
          .registerLazySingleton<AuthoritativeLearningStateRecoveryService>(
        () => authRecoveryService,
        allowOverride: true,
      );
      TitanServiceLocator.instance.registerLazySingleton<CurriculumService>(
        () => curriculumService,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<MasteryProgressionService>(
        () => masteryService,
        allowOverride: true,
      );
      TitanServiceLocator.instance
          .registerLazySingleton<LearnerAnalyticsService>(
        () => analyticsService,
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

    testWidgets(
        '1. Empty Learner State: renders informative empty state without fake numbers',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          AnalyticsDashboardPage(
            analyticsService: analyticsService,
            learnerId: testLearner,
            examId: testExam,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Analytics Engine'), findsOneWidget);
      expect(find.text('No Learning Activity Recorded'), findsOneWidget);
      expect(
        find.text(
            'Start adaptive practice or PYQs to generate authoritative performance reports and weak area insights.'),
        findsOneWidget,
      );
    });

    testWidgets(
        '2. Populated Analytics: renders Performance Overview, Mastery Distribution, and Weak Areas',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed authoritative state
      final progress1 = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 10,
        correctCount: 8,
        status: LearnerObjectiveStatus.achieved,
        lastAttemptAt: baseDate,
      );
      final progress2 = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_basic_structure_doctrine',
        attemptCount: 5,
        correctCount: 1,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate.add(const Duration(hours: 1)),
      );

      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {
          'lo_preamble_identity': progress1,
          'lo_basic_structure_doctrine': progress2,
        },
        lastUpdatedAt: baseDate.add(const Duration(hours: 1)),
        revision: 1,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      await tester.pumpWidget(
        buildTestWidget(
          AnalyticsDashboardPage(
            analyticsService: analyticsService,
            learnerId: testLearner,
            examId: testExam,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Performance Overview
      expect(find.text('Performance Overview'), findsOneWidget);
      expect(find.text('Overall Accuracy'), findsOneWidget);
      expect(find.text('60.0%'), findsOneWidget); // 9/15 = 60%
      expect(find.text('9/15 correct'), findsOneWidget);

      // Mastery Distribution
      expect(find.text('Mastery Distribution'), findsOneWidget);
      expect(find.text('Mastered: 1'), findsOneWidget);
      expect(find.text('Remediation Required: 1'), findsOneWidget);
      expect(find.text('Not Started: 1'), findsOneWidget);

      // Weak Areas
      expect(find.text('Weak Area Detection & Confidence'), findsOneWidget);
      expect(find.textContaining('Basic Structure Doctrine'), findsWidgets);
      expect(find.text('20.0%'), findsOneWidget); // 1/5 = 20%

      // Curriculum Breakdown
      expect(find.text('Curriculum Performance Drilldown'), findsOneWidget);
      expect(find.textContaining('Constitutional Foundations'), findsWidgets);
    });

    testWidgets(
        '3. Navigation: tapping Analytics icon on QuizForgeDashboardPage navigates to Analytics',
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

      // Find analytics button in AppBar
      final analyticsBtn = find.byKey(const Key('dashboard_analytics_button'));
      expect(analyticsBtn, findsOneWidget);

      // Tap and navigate
      await tester.tap(analyticsBtn);
      await tester.pumpAndSettle();

      // Verifies we are now on AnalyticsDashboardPage
      expect(find.byType(AnalyticsDashboardPage), findsOneWidget);
      expect(find.text('Learning Analytics Engine'), findsOneWidget);
    });

    testWidgets(
        '4. Export JSON Dialog: shows indented JSON when export icon is tapped',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final report = LearnerAnalyticsReport(
        generatedAt: baseDate,
        learnerId: testLearner,
        examId: testExam,
        summary: LearnerPerformanceSummary(
          totalAttempts: 5,
          correctCount: 4,
          incorrectCount: 1,
          accuracy: 0.8,
          objectivesAttempted: 1,
          objectivesMastered: 1,
          objectivesNeedingRemediation: 0,
          totalObjectives: 3,
          completionRate: 0.333,
          currentStreak: 1,
        ),
        weakAreas: const [],
        subjects: const [],
        masteryDistribution: const {ProgressionStage.mastered: 1},
        performanceTrends: const [],
      );

      await tester.pumpWidget(
        buildTestWidget(
          AnalyticsDashboardPage(
            initialReport: report,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find export action button
      final exportBtn = find.byIcon(Icons.download);
      expect(exportBtn, findsOneWidget);

      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Analytics Report JSON'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Analytics Report JSON'), findsNothing);
    });

    testWidgets(
        '5. Dynamic Refresh: updating learner state and refreshing updates metrics live',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Initial empty state
      await tester.pumpWidget(
        buildTestWidget(
          AnalyticsDashboardPage(
            analyticsService: analyticsService,
            learnerId: testLearner,
            examId: testExam,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Learning Activity Recorded'), findsOneWidget);

      // Save new practice state
      final progress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 10,
        correctCount: 10,
        status: LearnerObjectiveStatus.achieved,
        lastAttemptAt: baseDate,
      );
      final state = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        progressMap: {'lo_preamble_identity': progress},
        lastUpdatedAt: baseDate,
        revision: 1,
      );
      await authRepo.save(
          PersistedAuthoritativeLearnerState.fromAuthoritativeState(state));

      // Tap refresh button
      final refreshBtn = find.byIcon(Icons.refresh);
      expect(refreshBtn, findsOneWidget);
      await tester.tap(refreshBtn);
      await tester.pumpAndSettle();

      // Now report is populated!
      expect(find.text('Performance Overview'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('10/10 correct'), findsOneWidget);
    });
  });
}
