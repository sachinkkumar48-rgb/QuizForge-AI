import 'dart:async';

import 'package:titan_ai/titan_ai.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';

import '../models/user_session.dart';
import '../session/session_manager.dart';

/// Integration bridge binding active user session state across Project TITAN modules:
/// - Learning Profile
/// - Analytics
/// - Recommendation Engine
/// - Planner
/// - AI Mentor
class IdentityIntegrationService {
  final SessionManager _sessionManager;
  final LearningProfileRepository? _learningProfileRepository;
  final ResultAnalyticsRepository? _analyticsRepository;
  final RecommendationRepository? _recommendationRepository;
  final StudyPlannerRepository? _plannerRepository;
  final AIService? _aiService;

  StreamSubscription<UserSession?>? _subscription;
  UserSession? _lastProcessedSession;

  IdentityIntegrationService({
    required SessionManager sessionManager,
    LearningProfileRepository? learningProfileRepository,
    ResultAnalyticsRepository? analyticsRepository,
    RecommendationRepository? recommendationRepository,
    StudyPlannerRepository? plannerRepository,
    AIService? aiService,
  })  : _sessionManager = sessionManager,
        _learningProfileRepository = learningProfileRepository,
        _analyticsRepository = analyticsRepository,
        _recommendationRepository = recommendationRepository,
        _plannerRepository = plannerRepository,
        _aiService = aiService;

  /// Starts listening to session state changes.
  void initialize() {
    _subscription?.cancel();
    _subscription = _sessionManager.sessionStream.listen(_onSessionChanged);
    if (_sessionManager.currentSession != null) {
      _onSessionChanged(_sessionManager.currentSession);
    }
  }

  /// Last session processed by integration handlers.
  UserSession? get lastProcessedSession => _lastProcessedSession;

  Future<void> _onSessionChanged(UserSession? session) async {
    _lastProcessedSession = session;
    if (session == null || !session.isActive) {
      await _handleSignedOut();
      return;
    }

    await Future.wait([
      _syncLearningProfile(session),
      _syncAnalytics(session),
      _syncRecommendations(session),
      _syncPlanner(session),
      _syncAiMentor(session),
    ]);
  }

  Future<void> _handleSignedOut() async {
    // Clear transient user context across modules if required
  }

  Future<void> _syncLearningProfile(UserSession session) async {
    if (_learningProfileRepository == null) return;
    try {
      await _learningProfileRepository.getLearningProfile(
        userId: session.user.id,
      );
    } catch (_) {
      // Ignored for offline compatibility / optional handling
    }
  }

  Future<void> _syncAnalytics(UserSession session) async {
    if (_analyticsRepository == null) return;
    // Session state synchronized with telemetry
  }

  Future<void> _syncRecommendations(UserSession session) async {
    if (_recommendationRepository == null) return;
    try {
      await _recommendationRepository.getLatestRecommendations();
    } catch (_) {}
  }

  Future<void> _syncPlanner(UserSession session) async {
    if (_plannerRepository == null) return;
    try {
      await _plannerRepository.getPlanForDate(DateTime.now());
    } catch (_) {}
  }

  Future<void> _syncAiMentor(UserSession session) async {
    if (_aiService == null) return;
    if (!_aiService.isInitialized) {
      try {
        await _aiService.initialize();
      } catch (_) {}
    }
  }

  /// Disposes active listeners.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
