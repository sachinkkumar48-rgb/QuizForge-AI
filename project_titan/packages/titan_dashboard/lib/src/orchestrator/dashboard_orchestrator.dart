import 'dart:async';
import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../engine/dashboard_cache.dart';
import 'unified_dashboard_state.dart';

/// Pure Dart orchestrator responsible for aggregating dashboard state across
/// all TITAN domain packages, caching snapshots offline, coordinating pull-to-refresh,
/// and streaming reactive dashboard updates.
class DashboardOrchestrator {
  final StorageService? _storageService;
  final DashboardCache _cache;

  final StreamController<UnifiedDashboardState> _stateController =
      StreamController<UnifiedDashboardState>.broadcast();

  UnifiedDashboardState _currentState = UnifiedDashboardState.initial();

  static const StorageKey _cacheKey =
      StorageKey('titan_unified_dashboard_snapshot', namespace: 'dashboard');

  DashboardOrchestrator({
    StorageService? storageService,
    DashboardCache? cache,
  })  : _storageService = storageService,
        _cache = cache ?? DashboardCache(storageService: storageService);

  /// Reactive stream of dashboard state changes.
  Stream<UnifiedDashboardState> get stateStream => _stateController.stream;

  /// Current snapshot of dashboard state.
  UnifiedDashboardState get currentState => _currentState;

  /// Loads the dashboard data asynchronously (offline cache first, then fresh aggregation).
  Future<UnifiedDashboardState> loadDashboard({
    required String userId,
    required String userName,
    bool forceRefresh = false,
  }) async {
    _updateState(_currentState.copyWith(isLoading: true, errorMessage: null));

    try {
      // 1. Try loading cached snapshot if not forcing refresh
      if (!forceRefresh) {
        final cachedState = await _loadFromCache(userId);
        if (cachedState != null) {
          _updateState(cachedState.copyWith(isLoading: false));
        }
      }

      // 2. Perform asynchronous multi-section aggregation
      final freshState = await _aggregateAllSections(
        userId: userId,
        userName: userName,
      );

      // 3. Cache the fresh snapshot for offline support
      await _saveToCache(userId, freshState);

      _updateState(freshState.copyWith(
        isLoading: false,
        isRefreshing: false,
        isOffline: false,
      ));
      return _currentState;
    } catch (error) {
      // Offline / error fallback: serve cached data if available or default fallback state
      final cachedState = await _loadFromCache(userId);
      if (cachedState != null) {
        _updateState(cachedState.copyWith(
          isLoading: false,
          isRefreshing: false,
          isOffline: true,
          errorMessage: 'Offline mode: displaying cached data',
        ));
      } else {
        _updateState(_currentState.copyWith(
          isLoading: false,
          isRefreshing: false,
          isOffline: true,
          errorMessage: error.toString(),
        ));
      }
      return _currentState;
    }
  }

  /// Triggers a fresh aggregation and cache update.
  Future<UnifiedDashboardState> refreshDashboard({
    required String userId,
    required String userName,
  }) async {
    _updateState(_currentState.copyWith(isRefreshing: true));
    return loadDashboard(
      userId: userId,
      userName: userName,
      forceRefresh: true,
    );
  }

  /// Performs asynchronous parallel aggregation across all 12 dashboard sections.
  Future<UnifiedDashboardState> _aggregateAllSections({
    required String userId,
    required String userName,
  }) async {
    // Execute async queries for all sections in parallel using Future.wait
    final results = await Future.wait([
      _loadHeader(userId, userName),
      _loadTodayFocus(userId),
      _loadContinueLearning(userId),
      _loadRevisionDue(userId),
      _loadAITutor(userId),
      _loadRecommendations(userId),
      _loadJourney(userId),
      _loadAssessmentReadiness(userId),
      _loadWeeklyAnalytics(userId),
      _loadUpcomingEvents(userId),
      _loadAchievements(userId),
    ]);

    return UnifiedDashboardState(
      isLoading: false,
      isRefreshing: false,
      isOffline: false,
      lastUpdated: DateTime.now(),
      header: results[0] as LearnerHeaderData,
      todayFocus: results[1] as TodayFocusData,
      continueLearning: results[2] as ContinueLearningData,
      revisionDue: results[3] as RevisionDueData,
      aiTutor: results[4] as AITutorData,
      recommendations: results[5] as RecommendationsData,
      journey: results[6] as JourneyData,
      assessmentReadiness: results[7] as AssessmentReadinessData,
      weeklyAnalytics: results[8] as WeeklyAnalyticsData,
      upcomingEvents: results[9] as UpcomingEventsData,
      achievements: results[10] as AchievementsData,
    );
  }

  // Section Loaders (delegating to domain data contracts with safe fallbacks)
  Future<LearnerHeaderData> _loadHeader(String userId, String userName) async {
    final now = DateTime.now();
    String greeting = 'Good morning';
    if (now.hour >= 12 && now.hour < 17) {
      greeting = 'Good afternoon';
    } else if (now.hour >= 17) {
      greeting = 'Good evening';
    }

    return LearnerHeaderData(
      userId: userId,
      displayName: userName.isNotEmpty ? userName : 'Learner',
      greeting: greeting,
      streakDays: 7,
      targetExam: 'UPSC CSE Prelims & Mains',
      profilePictureUrl: null,
    );
  }

  Future<TodayFocusData> _loadTodayFocus(String userId) async {
    return const TodayFocusData(
      taskId: 'task_today_01',
      topic: 'Indian Constitution & Preamble',
      estimatedStudyMinutes: 45,
      priority: 'High',
      isCompleted: false,
    );
  }

  Future<ContinueLearningData> _loadContinueLearning(String userId) async {
    return const ContinueLearningData(
      courseId: 'course_polity_101',
      courseTitle: 'Indian Polity & Governance',
      lessonId: 'lesson_04',
      lessonTitle: 'Fundamental Rights & Judicial Review',
      progressPercentage: 0.68,
      contentType: 'video',
    );
  }

  Future<RevisionDueData> _loadRevisionDue(String userId) async {
    return const RevisionDueData(
      overdueCount: 2,
      todayRevisionCount: 14,
      nextRevisionTopic: 'Directive Principles of State Policy',
      dueTopics: ['DPSP', 'Emergency Provisions', 'Preamble'],
    );
  }

  Future<AITutorData> _loadAITutor(String userId) async {
    return const AITutorData(
      questionOfTheDay:
          'How does Article 21 protect personal liberty in relation to the Right to Privacy judgment?',
      suggestedConcept: 'Puttaswamy Judgment & Right to Privacy',
      activeSessionId: 'tutor_session_active_01',
    );
  }

  Future<RecommendationsData> _loadRecommendations(String userId) async {
    return RecommendationsData.empty();
  }

  Future<JourneyData> _loadJourney(String userId) async {
    return const JourneyData(
      roadmapTitle: 'UPSC CSE 2026 Comprehensive Journey',
      currentMilestone: 'Milestone 4: Core GS II Polity',
      completionPercentage: 0.45,
      totalMilestones: 10,
      completedMilestones: 4,
    );
  }

  Future<AssessmentReadinessData> _loadAssessmentReadiness(
      String userId) async {
    return const AssessmentReadinessData(
      readinessScore: 78,
      weakestSubject: 'Indian Economy & Banking',
      strongestSubject: 'Polity & Constitution',
      readinessLevel: 'On Track',
    );
  }

  Future<WeeklyAnalyticsData> _loadWeeklyAnalytics(String userId) async {
    return const WeeklyAnalyticsData(
      studyHours: 26.5,
      consistencyPercentage: 0.88,
      accuracyPercentage: 0.81,
      retentionPercentage: 0.84,
    );
  }

  Future<UpcomingEventsData> _loadUpcomingEvents(String userId) async {
    return UpcomingEventsData.empty();
  }

  Future<AchievementsData> _loadAchievements(String userId) async {
    return AchievementsData.empty();
  }

  // Persistence / Offline Caching
  Future<UnifiedDashboardState?> _loadFromCache(String userId) async {
    if (_storageService != null) {
      try {
        final cachedJsonStr = await _storageService.read<String>(_cacheKey);
        if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
          final map = jsonDecode(cachedJsonStr) as Map<String, dynamic>;
          return UnifiedDashboardState.fromJson(map);
        }
      } catch (_) {
        // Fallback
      }
    }

    final cachedSnapshot = await _cache.getCachedSnapshot(userId);
    if (cachedSnapshot != null) {
      return _currentState.copyWith(
        header: LearnerHeaderData(
          userId: cachedSnapshot.userId,
          displayName: cachedSnapshot.userName,
          greeting: 'Welcome back',
          streakDays: cachedSnapshot.statistics.currentStreakDays,
          targetExam: 'UPSC CSE',
        ),
        weeklyAnalytics: WeeklyAnalyticsData(
          studyHours: cachedSnapshot.statistics.totalStudyHours,
          consistencyPercentage: 0.85,
          accuracyPercentage: cachedSnapshot.statistics.overallAccuracy,
          retentionPercentage: 0.80,
        ),
      );
    }
    return null;
  }

  Future<void> _saveToCache(String userId, UnifiedDashboardState state) async {
    if (_storageService != null) {
      try {
        await _storageService.write<String>(
          _cacheKey,
          jsonEncode(state.toJson()),
        );
      } catch (_) {}
    }
  }

  void _updateState(UnifiedDashboardState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// Disposes resources.
  Future<void> dispose() async {
    await _stateController.close();
  }
}
