import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:garuda_pyq/garuda_pyq.dart';
import 'package:quizforge_upsc/controllers/dashboard_controller.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/pages/quizforge_dashboard_page.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:titan_core/titan_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P43 Mastery-Driven Learning Progression UI Integration Tests', () {
    const testExam = 'upsc_prelims_gs1';
    final baseDate = DateTime.utc(2026, 9, 8, 12, 0, 0);

    late InMemoryAuthoritativeLearningStateRepository authRepo;
    late InMemorySessionCheckpointRepository checkpointRepo;
    late AuthoritativeLearningStateRecoveryService authRecoveryService;
    late LearningSessionRecoveryService sessionRecoveryService;
    late CurriculumFramework framework;
    late CurriculumService curriculumService;
    late InMemoryRemedialLessonRepository remedialRepo;
    late DeterministicRemedialLessonService remedialService;
    late ContentLearningPathService contentService;
    late List<NormalizedQuestion> seedCorpus;
    late MasteryProgressionService progressionService;
    late LearnerDashboardController learnerController;
    late _FakeQuizSessionRepository fakeSessionRepo;
    late _FakeQuizHistoryRepository fakeHistoryRepo;
    late _FakeQuizSourceRepository fakeSourceRepo;

    NormalizedQuestion buildTestQuestion({
      required String id,
      required String subject,
      required String topic,
      required String objectiveId,
    }) {
      return NormalizedQuestion(
        id: id,
        examId: testExam,
        year: 2024,
        paper: 'GS1',
        subject: subject,
        topic: topic,
        normalizedText: 'Question stem for $id',
        originalText: 'Original text for $id',
        options: const [
          Option(key: 'A', text: 'Option A', isCorrect: true),
          Option(key: 'B', text: 'Option B', isCorrect: false),
          Option(key: 'C', text: 'Option C', isCorrect: false),
          Option(key: 'D', text: 'Option D', isCorrect: false),
        ],
        officialAnswer: const Answer(correctOptionKeys: ['A']),
        explanation: 'Official explanation for $id',
        difficulty: 'Medium',
        source: PyqSourceReference.official(
          examId: testExam,
          year: 2024,
          paper: 'GS1',
        ),
        objectiveIds: [objectiveId],
      );
    }

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
      remedialRepo.saveLesson(
        RemedialLesson(
          lessonId: 'rem_art21_ui',
          objectiveId: 'lo_article_21_foundations',
          title: 'Article 21: Life and Personal Liberty Micro-Lesson',
          summary: 'Review foundational expansion of Article 21 rights.',
          learningPoints: const ['Substantive due process evolution'],
          explanation: 'Detailed explanation of Article 21 rights.',
          estimatedMinutes: 8,
          authoredAt: baseDate,
        ),
      );
      remedialService = DeterministicRemedialLessonService(
        lessonRepository: remedialRepo,
      );

      contentService = ContentLearningPathService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
      );

      seedCorpus = [
        buildTestQuestion(
          id: 'q_art21_ui',
          subject: 'Indian Polity',
          topic: 'Fundamental Rights',
          objectiveId: 'lo_article_21_foundations',
        ),
        buildTestQuestion(
          id: 'q_bs_ui',
          subject: 'Indian Polity',
          topic: 'Basic Structure',
          objectiveId: 'lo_basic_structure_doctrine',
        ),
        buildTestQuestion(
          id: 'q_preamble_ui',
          subject: 'Indian Polity',
          topic: 'Preamble',
          objectiveId: 'lo_preamble_identity',
        ),
      ];

      progressionService = MasteryProgressionService(
        curriculumService: curriculumService,
        authRecoveryService: authRecoveryService,
        checkpointRepository: checkpointRepo,
        contentService: contentService,
        remedialService: remedialService,
        seedQuestions: seedCorpus,
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
        remedialService: remedialService,
      );
    });

    testWidgets('Renders YOUR LEARNING PRIORITIES card with cold start diagnostic action', (tester) async {
      final controller = DashboardController(
        sourceRepository: fakeSourceRepo,
        historyRepository: fakeHistoryRepo,
        sessionRepository: fakeSessionRepo,
        learnerController: learnerController,
        progressionService: progressionService,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizForgeDashboardPage(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and priorities section
      expect(find.text("YOUR LEARNING PRIORITIES"), findsOneWidget);
      expect(find.text("Take Diagnostic Assessment"), findsAtLeastNWidgets(1));
      expect(find.byKey(const Key('priority_queue_action_button')), findsOneWidget);
      expect(find.text("Not Started"), findsAtLeastNWidgets(1));
    });

    testWidgets('Renders remediation required priority when learner exhibits persistent difficulty', (tester) async {
      // Setup state with weak performance on Article 21
      final stateFailure = AuthoritativeLearnerState(
        learnerId: 'default_learner',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'default_learner',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 6,
            correctCount: 1,
            status: LearnerObjectiveStatus.inProgress,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'default_learner',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 5,
            correctCount: 3,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateFailure));

      final controller = DashboardController(
        sourceRepository: fakeSourceRepo,
        historyRepository: fakeHistoryRepo,
        sessionRepository: fakeSessionRepo,
        learnerController: learnerController,
        progressionService: progressionService,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizForgeDashboardPage(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Priorities Card displays Remediation Required
      expect(find.text("YOUR LEARNING PRIORITIES"), findsOneWidget);
      expect(find.text("Remediation"), findsAtLeastNWidgets(1));
      expect(find.text("Start Remedial Micro-Lesson"), findsOneWidget);
      expect(find.text("Attempts: 6"), findsOneWidget);
      expect(find.text("Accuracy: 16%"), findsOneWidget);

      // Verify Upcoming Priorities section exists
      expect(find.text("Upcoming Priorities"), findsOneWidget);
      expect(find.text("#2"), findsOneWidget);
    });

    testWidgets('Tapping priority action button triggers appropriate navigation flow', (tester) async {
      final stateMastered = AuthoritativeLearnerState(
        learnerId: 'default_learner',
        examId: testExam,
        revision: 1,
        lastUpdatedAt: baseDate,
        progressMap: {
          'lo_preamble_identity': LearnerProgress(
            learnerId: 'default_learner',
            objectiveId: 'lo_preamble_identity',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_article_21_foundations': LearnerProgress(
            learnerId: 'default_learner',
            objectiveId: 'lo_article_21_foundations',
            attemptCount: 10,
            correctCount: 9,
            status: LearnerObjectiveStatus.achieved,
          ),
          'lo_basic_structure_doctrine': LearnerProgress(
            learnerId: 'default_learner',
            objectiveId: 'lo_basic_structure_doctrine',
            attemptCount: 6,
            correctCount: 4,
            status: LearnerObjectiveStatus.inProgress,
          ),
        },
      );
      await authRepo.save(PersistedAuthoritativeLearnerState.fromAuthoritativeState(stateMastered));

      final controller = DashboardController(
        sourceRepository: fakeSourceRepo,
        historyRepository: fakeHistoryRepo,
        sessionRepository: fakeSessionRepo,
        learnerController: learnerController,
        progressionService: progressionService,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuizForgeDashboardPage(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("YOUR LEARNING PRIORITIES"), findsOneWidget);
      expect(find.byKey(const Key('priority_queue_action_button')), findsOneWidget);

      // Tap the action button
      await tester.ensureVisible(find.byKey(const Key('priority_queue_action_button')));
      await tester.tap(find.byKey(const Key('priority_queue_action_button')));
      await tester.pumpAndSettle();

      // Navigation occurred without errors
      expect(find.byType(QuizForgeDashboardPage), findsNothing);
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
