import 'package:flutter/foundation.dart';
import 'package:garuda_learning/garuda_learning.dart';
import 'package:titan_core/titan_core.dart';

import '../models/quiz_attempt.dart';
import '../plugins/plugins.dart';
import '../repositories/quiz_history_repository.dart';
import '../repositories/quiz_session_repository.dart';
import '../repositories/quiz_source_repository.dart';
import '../services/adaptive_learning_runtime_coordinator.dart';
import 'dashboard_state.dart';

/// State Controller managing state lifecycle and data fetching for QuizForge Dashboard.
///
/// Unifies authoritative progress tracking, durable session recovery, pedagogical
/// next best action formulation, and plugin modules into a single reactive controller.
class DashboardController extends ValueNotifier<DashboardState> {
  final QuizSourceRepository _sourceRepository;
  final QuizHistoryRepository _historyRepository;
  final QuizSessionRepository _sessionRepository;
  final AdaptiveLearningRuntimeCoordinator? _learningCoordinator;
  final LearnerDashboardController _learnerController;
  final MasteryProgressionService? _progressionService;
  PersonalizedPriorityQueue? _priorityQueue;
  bool _isDisposed = false;
  Future<void>? _loadingFuture;

  DashboardController({
    QuizSourceRepository? sourceRepository,
    QuizHistoryRepository? historyRepository,
    QuizSessionRepository? sessionRepository,
    AdaptiveLearningRuntimeCoordinator? learningCoordinator,
    LearnerDashboardController? learnerController,
    MasteryProgressionService? progressionService,
  })  : _sourceRepository = sourceRepository ?? QuizSourceRepository(),
        _historyRepository = historyRepository ?? QuizHistoryRepository(),
        _sessionRepository = sessionRepository ?? QuizSessionRepository(),
        _learningCoordinator = learningCoordinator ?? _resolveCoordinator(),
        _learnerController = learnerController ?? _resolveLearnerController(),
        _progressionService =
            progressionService ?? _resolveProgressionService(),
        super(DashboardState.loading()) {
    _subscribeToCoordinator();
    loadDashboardData();
  }

  DashboardState get state => value;

  /// Current personalized learning priority queue (P43).
  PersonalizedPriorityQueue? get priorityQueue => _priorityQueue;

  /// Underlying authoritative Learner Dashboard presentation controller.
  LearnerDashboardController get learnerController => _learnerController;

  /// Current immutable snapshot of authoritative learner dashboard state.
  LearnerDashboardState get learnerState => _learnerController.state;

  Future<void> loadDashboardData() async {
    if (_isDisposed) return;
    if (_loadingFuture != null) {
      return _loadingFuture;
    }

    _loadingFuture = _performLoadDashboardData();
    try {
      await _loadingFuture;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> _performLoadDashboardData() async {
    if (_isDisposed) return;
    value = DashboardState.loading();

    try {
      final activeLearner = _learningCoordinator?.activeLearnerId ?? 'default_learner';

      // 1. Authoritative Learner Dashboard State & Recovery (P41)
      await _learnerController.loadDashboard(
        learnerId: activeLearner,
        examId: 'upsc_prelims_gs1',
      );
      final lState = _learnerController.state;

      // 1b. Resolve Personalized Learning Priority Queue (P43)
      try {
        _priorityQueue = await _progressionService?.resolvePriorityQueue(
          learnerId: activeLearner,
          examId: 'upsc_prelims_gs1',
        );
      } catch (_) {}

      // 2. Fetch active session information (authoritative checkpoint takes precedence)
      String? activeSessionName;
      if (lState.continueLearning.hasRecoverableSession) {
        activeSessionName = lState.continueLearning.topic != null
            ? '${lState.continueLearning.topic} (In Progress)'
            : 'Adaptive Session (In Progress)';
      } else {
        try {
          final hasSession = await _sessionRepository.hasActiveSession();
          if (hasSession) {
            final session = await _sessionRepository.loadSession();
            activeSessionName = session?.sourceName;
          }
        } catch (_) {}
      }

      // 3. Fetch PDF sources
      int pdfCount = 0;
      try {
        final sources = await _sourceRepository.getSources();
        pdfCount = sources.length;
      } catch (_) {}

      // 4. Fetch history attempts
      var attempts = <QuizAttempt>[];
      try {
        attempts = await _historyRepository.getAttempts();
      } catch (_) {}
      final totalCompleted = attempts.length +
          lState.history.where((h) => h.isCompleted).length;

      final finalQuestionsAnswered = lState.progressSummary.totalQuestionsAttempted > 0
          ? lState.progressSummary.totalQuestionsAttempted
          : attempts.fold<int>(0, (sum, a) => sum + a.analytics.totalQuestions);

      final double? finalAccuracy = lState.progressSummary.averageAccuracy ??
          (attempts.isNotEmpty
              ? attempts.fold<double>(0.0, (sum, a) => sum + a.analytics.accuracy) /
                  attempts.length
              : null);

      final studyStreakDays = finalQuestionsAnswered > 0
          ? 1 + (finalQuestionsAnswered ~/ 10)
          : 1;

      final stats = DashboardStats(
        totalQuizzesCompleted: totalCompleted,
        averageAccuracyPercentage: finalAccuracy ?? 0.0,
        studyStreakDays: studyStreakDays,
        totalQuestionsAnswered: finalQuestionsAnswered,
        totalPdfSources: pdfCount,
      );

      // 5. Build recent activities list without fake data
      final recentList = <RecentActivity>[];

      // Next best action recommendation card
      if (lState.nextAction.isAvailable &&
          lState.nextAction.actionType != AdaptiveActionType.none &&
          lState.nextAction.actionType != AdaptiveActionType.continueSession) {
        recentList.add(
          RecentActivity(
            id: 'adaptive_rec_target',
            title: lState.nextAction.title,
            subtitle: lState.nextAction.description,
            timestamp: DateTime.now(),
            scorePercentage: finalAccuracy ?? 0.0,
            categoryTag: 'Next Best Action',
          ),
        );
      }

      // Checkpoint history
      for (final h in lState.history.take(5)) {
        recentList.add(
          RecentActivity(
            id: h.sessionId,
            title: h.topic,
            subtitle: h.isCompleted
                ? '${h.totalQuestions} Questions Completed'
                : 'Question ${h.questionIndex + 1} of ${h.totalQuestions}',
            timestamp: h.timestamp,
            scorePercentage: finalAccuracy ?? 0.0,
            categoryTag: h.isCompleted ? 'Completed' : 'In Progress',
          ),
        );
      }

      // Attempt history
      for (final a in attempts.take(5)) {
        if (!recentList.any((r) => r.id == a.id)) {
          recentList.add(
            RecentActivity(
              id: a.id,
              title: a.sourceName,
              subtitle: "${a.analytics.totalQuestions} Questions Completed",
              timestamp: a.completedAt,
              scorePercentage: a.analytics.accuracy,
              categoryTag: "Quiz",
            ),
          );
        }
      }

      // 6. Build active modules list from PluginRegistry
      final registry = PluginRegistry();
      final modulesList = registry.registeredModules.map((m) {
        return DashboardModuleInfo(
          id: m.id,
          title: m.name,
          category: m.category,
          isEnabled: registry.isModuleEnabled(m.id),
        );
      }).toList();

      if (!_isDisposed) {
        value = DashboardState.ready(
          userGreeting: _determineGreeting(),
          stats: stats,
          recentActivities: recentList,
          activeModules: modulesList,
          activeSessionSourceName: activeSessionName,
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        value = DashboardState.error(
          "Failed to load dashboard metrics: ${e.toString()}",
        );
      }
    }
  }

  Future<void> refresh() async {
    await loadDashboardData();
  }

  String _determineGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning, Aspirant!";
    } else if (hour < 17) {
      return "Good Afternoon, Aspirant!";
    } else {
      return "Good Evening, Aspirant!";
    }
  }

  static AdaptiveLearningRuntimeCoordinator? _resolveCoordinator() {
    try {
      if (TitanServiceLocator.instance
          .isRegistered<AdaptiveLearningRuntimeCoordinator>()) {
        return TitanServiceLocator.instance
            .get<AdaptiveLearningRuntimeCoordinator>();
      }
    } catch (_) {}
    return null;
  }

  static LearnerDashboardController _resolveLearnerController() {
    try {
      if (TitanServiceLocator.instance
          .isRegistered<LearnerDashboardController>()) {
        return TitanServiceLocator.instance.get<LearnerDashboardController>();
      }
    } catch (_) {}

    final authRepo = TitanServiceLocator.instance
            .isRegistered<AuthoritativeLearningStateRepository>()
        ? TitanServiceLocator.instance
            .get<AuthoritativeLearningStateRepository>()
        : InMemoryAuthoritativeLearningStateRepository();

    final authRecovery = TitanServiceLocator.instance
            .isRegistered<AuthoritativeLearningStateRecoveryService>()
        ? TitanServiceLocator.instance
            .get<AuthoritativeLearningStateRecoveryService>()
        : AuthoritativeLearningStateRecoveryService(repository: authRepo);

    final checkpointRepo =
        TitanServiceLocator.instance.isRegistered<SessionCheckpointRepository>()
            ? TitanServiceLocator.instance.get<SessionCheckpointRepository>()
            : InMemorySessionCheckpointRepository();

    final sessionRecovery = TitanServiceLocator.instance
            .isRegistered<LearningSessionRecoveryService>()
        ? TitanServiceLocator.instance.get<LearningSessionRecoveryService>()
        : LearningSessionRecoveryService(
            checkpointRepository: checkpointRepo,
            authoritativeRecoveryService: authRecovery,
          );

    final curriculum =
        TitanServiceLocator.instance.isRegistered<CurriculumService>()
            ? TitanServiceLocator.instance.get<CurriculumService>()
            : null;

    final remedial = TitanServiceLocator.instance
            .isRegistered<DeterministicRemedialLessonService>()
        ? TitanServiceLocator.instance.get<DeterministicRemedialLessonService>()
        : null;

    final diagnostic = TitanServiceLocator.instance
            .isRegistered<DiagnosticAssessmentService>()
        ? TitanServiceLocator.instance.get<DiagnosticAssessmentService>()
        : null;

    return LearnerDashboardController(
      authRepository: authRepo,
      authRecoveryService: authRecovery,
      checkpointRepository: checkpointRepo,
      sessionRecoveryService: sessionRecovery,
      curriculumService: curriculum,
      remedialService: remedial,
      diagnosticService: diagnostic,
    );
  }

  static MasteryProgressionService _resolveProgressionService() {
    try {
      if (TitanServiceLocator.instance
          .isRegistered<MasteryProgressionService>()) {
        return TitanServiceLocator.instance.get<MasteryProgressionService>();
      }
    } catch (_) {}

    final authRepo = TitanServiceLocator.instance
            .isRegistered<AuthoritativeLearningStateRepository>()
        ? TitanServiceLocator.instance
            .get<AuthoritativeLearningStateRepository>()
        : InMemoryAuthoritativeLearningStateRepository();

    final authRecovery = TitanServiceLocator.instance
            .isRegistered<AuthoritativeLearningStateRecoveryService>()
        ? TitanServiceLocator.instance
            .get<AuthoritativeLearningStateRecoveryService>()
        : AuthoritativeLearningStateRecoveryService(repository: authRepo);

    final checkpointRepo = TitanServiceLocator.instance
            .isRegistered<SessionCheckpointRepository>()
        ? TitanServiceLocator.instance.get<SessionCheckpointRepository>()
        : InMemorySessionCheckpointRepository();

    final curriculum = TitanServiceLocator.instance
            .isRegistered<CurriculumService>()
        ? TitanServiceLocator.instance.get<CurriculumService>()
        : CurriculumService(
            framework: CurriculumSeedData.buildUpscConstitutionalLawFramework(),
          );

    final remedial = TitanServiceLocator.instance
            .isRegistered<DeterministicRemedialLessonService>()
        ? TitanServiceLocator.instance.get<DeterministicRemedialLessonService>()
        : null;

    final diagnostic = TitanServiceLocator.instance
            .isRegistered<DiagnosticPlacementRepository>()
        ? TitanServiceLocator.instance.get<DiagnosticPlacementRepository>()
        : null;

    final contentService = TitanServiceLocator.instance
            .isRegistered<ContentLearningPathService>()
        ? TitanServiceLocator.instance.get<ContentLearningPathService>()
        : ContentLearningPathService(
            curriculumService: curriculum,
            authRecoveryService: authRecovery,
            checkpointRepository: checkpointRepo,
          );

    return MasteryProgressionService(
      curriculumService: curriculum,
      authRecoveryService: authRecovery,
      checkpointRepository: checkpointRepo,
      contentService: contentService,
      diagnosticRepository: diagnostic,
      remedialService: remedial,
    );
  }

  void _subscribeToCoordinator() {
    final coordinator = _learningCoordinator ?? _resolveCoordinator();
    coordinator?.masteryNotifier.addListener(_onMasteryUpdated);
  }

  void _onMasteryUpdated() {
    if (_isDisposed) return;
    loadDashboardData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    final coordinator = _learningCoordinator ?? _resolveCoordinator();
    coordinator?.masteryNotifier.removeListener(_onMasteryUpdated);
    _learnerController.dispose();
    super.dispose();
  }
}
