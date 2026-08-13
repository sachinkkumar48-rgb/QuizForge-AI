/// Session Manager Service (TITAN-KO-018.0 P18).
///
/// Lifecycle manager for optional [AssessmentSession]s.
library;

import '../domain/entities/assessment_session.dart';
import '../domain/entities/question_attempt.dart';
import '../repository/learner_repository.dart';

class SessionManager {
  final LearnerRepository _learnerRepository;
  final Map<String, AssessmentSession> _sessions = {};

  SessionManager({required LearnerRepository learnerRepository})
      : _learnerRepository = learnerRepository;

  /// Starts a new [AssessmentSession] for a verified learner.
  AssessmentSession startSession({
    required String learnerId,
    List<String>? objectiveIds,
    List<String>? questionIds,
    String? sessionId,
  }) {
    if (!_learnerRepository.exists(learnerId)) {
      throw ArgumentError('Learner "$learnerId" does not exist');
    }

    final id = sessionId ??
        'sess_${learnerId}_${DateTime.now().toUtc().millisecondsSinceEpoch}';

    if (_sessions.containsKey(id)) {
      throw StateError('Session "$id" already exists');
    }

    final session = AssessmentSession(
      sessionId: id,
      learnerId: learnerId,
      objectiveIds: objectiveIds,
      questionIds: questionIds,
      startedAt: DateTime.now().toUtc(),
    );

    _sessions[id] = session;
    return session;
  }

  /// Adds a submitted attempt ID to an active session.
  AssessmentSession addAttemptToSession({
    required String sessionId,
    required QuestionAttempt attempt,
  }) {
    final session = getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Session "$sessionId" does not exist');
    }
    if (session.learnerId != attempt.learnerId) {
      throw ArgumentError(
          'Attempt learner "${attempt.learnerId}" does not match session learner "${session.learnerId}"');
    }

    final updated = session.addAttempt(attempt.attemptId);
    _sessions[sessionId] = updated;
    return updated;
  }

  /// Completes an active assessment session.
  AssessmentSession completeSession(String sessionId,
      {DateTime? completionTime}) {
    final session = getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Session "$sessionId" does not exist');
    }

    final completed = session.complete(completionTime: completionTime);
    _sessions[sessionId] = completed;
    return completed;
  }

  /// Retrieves a session by ID, or null if not found.
  AssessmentSession? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  /// Retrieves all sessions for a learner in deterministic chronological order.
  List<AssessmentSession> getSessionsForLearner(String learnerId) {
    final list = _sessions.values
        .where((s) => s.learnerId == learnerId)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return List.unmodifiable(list);
  }

  /// Clears stored sessions (for testing).
  void clear() {
    _sessions.clear();
  }
}
