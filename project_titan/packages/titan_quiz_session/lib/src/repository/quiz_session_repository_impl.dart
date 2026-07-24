import 'package:titan_quiz/titan_quiz.dart';
import '../enums/quiz_session_status.dart';
import '../exceptions/quiz_session_exception.dart';
import '../models/quiz_result_summary.dart';
import '../models/quiz_session.dart';
import '../models/session_configuration.dart';
import '../services/quiz_session_service.dart';
import 'quiz_session_repository.dart';

/// Concrete implementation of [QuizSessionRepository] managing session lifecycle and storage.
class QuizSessionRepositoryImpl implements QuizSessionRepository {
  final QuizSessionService _sessionService;
  final Map<String, QuizSession> _storage = {};

  bool _isInitialized = false;
  bool _isDisposed = false;

  QuizSessionRepositoryImpl({
    QuizSessionService sessionService = const QuizSessionService(),
  }) : _sessionService = sessionService;

  @override
  bool get isInitialized => _isInitialized && !_isDisposed;

  @override
  Future<void> initialize() async {
    if (_isDisposed) {
      throw const SessionStateException(
          'Cannot initialize a disposed QuizSessionRepository.');
    }
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    _storage.clear();
    _isInitialized = false;
    _isDisposed = true;
  }

  void _checkState() {
    if (_isDisposed) {
      throw const SessionStateException(
          'QuizSessionRepository has been disposed.');
    }
    if (!isInitialized) {
      throw const SessionStateException(
          'QuizSessionRepository is not initialized.');
    }
  }

  @override
  Future<QuizSession> createSession(
    Quiz quiz, {
    SessionConfiguration configuration = const SessionConfiguration.standard(),
  }) async {
    _checkState();
    final session =
        _sessionService.startSession(quiz, configuration: configuration);
    _storage[session.sessionId] = session;
    return session;
  }

  @override
  Future<QuizSession?> loadSession(String sessionId) async {
    _checkState();
    return _storage[sessionId];
  }

  @override
  Future<void> saveSession(QuizSession session) async {
    _checkState();
    _storage[session.sessionId] = session;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    _checkState();
    _storage.remove(sessionId);
  }

  @override
  Future<QuizSession> resumeSession(String sessionId) async {
    _checkState();
    final session = _storage[sessionId];
    if (session == null) {
      throw SessionStateException(
          'Session ID [$sessionId] not found in repository.');
    }

    final resumed = _sessionService.resumeSession(session);
    _storage[sessionId] = resumed;
    return resumed;
  }

  @override
  Future<QuizResultSummary> completeSession(String sessionId, Quiz quiz) async {
    _checkState();
    final session = _storage[sessionId];
    if (session == null) {
      throw SessionStateException(
          'Session ID [$sessionId] not found in repository.');
    }

    final summary = _sessionService.completeSession(session, quiz);

    final completedSession = session.copyWith(
      status: QuizSessionStatus.completed,
      completedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    );
    _storage[sessionId] = completedSession;

    return summary;
  }
}
