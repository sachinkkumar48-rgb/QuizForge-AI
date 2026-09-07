import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:quizforge_upsc/controllers/dashboard_controller.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/pages/learning_plan_page.dart';
import 'package:quizforge_upsc/pages/quizforge_dashboard_page.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P43 Personalized Learning Plan UI Integration Tests', () {
    const testLearner = 'learner_ui_p43';
    const testExam = 'upsc_prelims_gs1';
    final baseDate = DateTime.utc(2026, 9, 7, 10, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryRemedialLessonRepository remedialRepo;
    late DeterministicRemedialLessonService remedialService;
    late InMemoryDiagnosticPlacementRepository diagnosticRepo;
    late List<NormalizedQuestion> testCorpus;
    late ContentLearningPathService contentService;
    late PersonalizedLearningPlanService planService;
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

      remedialRepo = InMemoryRemedialLessonRepository();
      remedialRepo.saveLesson(RemedialLesson(
        lessonId: 'rem_art21_01',
        objectiveId: 'lo_article_21_foundations',
        title: 'Article 21 Remedial Review',
        summary: 'Targeted remediation on personal liberty jurisprudence.',
        learningPoints: const ['Procedure by Law', 'Due Process of Law'],
        explanation: 'Detailed micro-lesson on Article 21.',
        estimatedMinutes: 10,
        authoredAt: baseDate,
      ));
      remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      diagnosticRepo = InMemoryDiagnosticPlacementRepository();

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
          id: 'pyq_ui_bs_01',
          examId: testExam,
          year: 2024,
          paper: 'GS1',
          subject: 'Indian Polity',
          topic: 'Preamble & Basic Structure',
          normalizedText: 'Kesavananda Bharati case established what doctrine?',
          originalText: 'Kesavananda Bharati case established what doctrine?',
          options: const [
            Option(key: 'A', text: 'Basic Structure', isCorrect: true),
            Option(key: 'B', text: 'Procedure by Law', isCorrect: false),
          ],
          officialAnswer: const Answer(correctOptionKeys: ['A']),
          explanation: 'Established basic structure doctrine in 1973.',
          difficulty: 'Medium',
          source: PyqSourceReference.official(
            examId: testExam,
            year: 2024,
            paper: 'GS1',
          ),
          objectiveIds: const ['lo_basic_structure_doctrine'],
        ),
      ];

      contentService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        remedialService: remedialService,
        seedQuestions: testCorpus,
      );

      planService = PersonalizedLearningPlanService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        contentService: contentService,
        diagnosticRepository: diagnosticRepo,
        remedialService: remedialService,
        seedQuestions: testCorpus,
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
          .registerSingleton<PersonalizedLearningPlanService>(
        planService,
        allowOverride: true,
      );
    });

    tearDown(() {
      TitanServiceLocator.instance.reset();
    });

    testWidgets(
        'UI Test 1: Renders Personalized Learning Plan with recommended action and explainable WHY reason',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Save an in-progress objective state
      final inProgress = LearnerProgress(
        learnerId: testLearner,
        objectiveId: 'lo_preamble_identity',
        attemptCount: 2,
        correctCount: 2,
        status: LearnerObjectiveStatus.inProgress,
        lastAttemptAt: baseDate,
      );
      final authState = AuthoritativeLearnerState(
        learnerId: testLearner,
        examId: testExam,
        revision: 3,
        progressMap: {'lo_preamble_identity': inProgress},
        lastUpdatedAt: baseDate,
      );
      await authRepo.save(
        PersistedAuthoritativeLearnerState.fromAuthoritativeState(authState),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LearningPlanPage(
            service: planService,
            learnerId: testLearner,
            examId: testExam,
            corpus: testCorpus,
          ),
        ),
      );

      // Loading state shown initially
      expect(find.text('Personalized Learning Plan'), findsOneWidget);
      await tester.pumpAndSettle();

      // Verify Plan Overview Card
      expect(find.text('UPSC PRELIMS GS1'), findsOneWidget);
      expect(find.text('Rev 3'), findsOneWidget);
      expect(find.text('Curriculum Mastery Progress'), findsOneWidget);

      // Verify Current Recommended Action
      expect(find.text('TOP PRIORITY RECOMMENDATION'), findsOneWidget);
      expect(find.text('WHY THIS ACTION IS RECOMMENDED'), findsOneWidget);
      expect(
        find.textContaining(
            'Practice recommended to advance competency toward mastery threshold'),
        findsOneWidget,
      );
      expect(find.text('Practice Questions'), findsOneWidget);

      // Verify Upcoming Action Sequence section
      expect(find.text('Upcoming Learning Sequence'), findsOneWidget);
    });

    testWidgets(
        'UI Test 2: Renders in-flight session continuation recommendation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Create an in-flight checkpoint
      final checkpoint = SessionCheckpoint(
        checkpointRevision: 2,
        authoritativeStateRevision: 1,
        sessionId: 'sess_p43_ui_resume',
        examId: testExam,
        learnerId: testLearner,
        timestamp: baseDate.subtract(const Duration(minutes: 5)),
        questionIndex: 1,
        activeObjectiveId: 'lo_basic_structure_doctrine',
        completedQuestionIds: const [],
        isCompleted: false,
        metadata: const {
          'topic': 'Preamble & Basic Structure',
          'totalQuestions': 3,
        },
      );
      await checkpointRepo.saveCheckpoint(checkpoint);

      await tester.pumpWidget(
        MaterialApp(
          home: LearningPlanPage(
            service: planService,
            learnerId: testLearner,
            examId: testExam,
            corpus: testCorpus,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top priority action should be resume session
      expect(find.text('TOP PRIORITY RECOMMENDATION'), findsOneWidget);
      expect(find.text('Resume Session'), findsOneWidget);
      expect(
        find.textContaining(
            'Continue unfinished practice session on Preamble & Basic Structure'),
        findsOneWidget,
      );
    });

    testWidgets('UI Test 3: Dashboard AppBar navigates to LearningPlanPage',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = DashboardController(
        learnerController: learnerController,
        sessionRepository: fakeSessionRepo,
        historyRepository: fakeHistoryRepo,
        sourceRepository: fakeSourceRepo,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizForgeDashboardPage(
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Learning Plan button in AppBar
      final planButton = find.byTooltip('Learning Plan');
      expect(planButton, findsOneWidget);

      // Tap to open LearningPlanPage
      await tester.tap(planButton);
      await tester.pumpAndSettle();

      // Verify LearningPlanPage rendered
      expect(find.text('Personalized Learning Plan'), findsOneWidget);
      expect(find.text('UPSC PRELIMS GS1'), findsOneWidget);
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
