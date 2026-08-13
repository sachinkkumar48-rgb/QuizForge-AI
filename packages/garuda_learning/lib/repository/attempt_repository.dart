/// Attempt Repository (TITAN-KO-018.0 P18).
///
/// Interface and in-memory implementation for [QuestionAttempt] and [AttemptResult] storage.
library;

import '../domain/entities/attempt_result.dart';
import '../domain/entities/question_attempt.dart';

abstract interface class AttemptRepository {
  /// Saves a question attempt.
  void saveAttempt(QuestionAttempt attempt);

  /// Saves an evaluation attempt result.
  void saveResult(AttemptResult result);

  /// Retrieves an attempt by ID, or null if not found.
  QuestionAttempt? getAttemptById(String attemptId);

  /// Retrieves an attempt result by attempt ID, or null if not found.
  AttemptResult? getResultForAttempt(String attemptId);

  /// Retrieves all attempts submitted by a learner, in deterministic chronological order.
  List<QuestionAttempt> getAttemptsForLearner(String learnerId);

  /// Retrieves attempts for a specific learner and objective pair.
  List<QuestionAttempt> getAttemptsForLearnerAndObjective(
    String learnerId,
    String objectiveId,
  );

  /// Retrieves results for a specific learner and objective pair.
  List<AttemptResult> getResultsForLearnerAndObjective(
    String learnerId,
    String objectiveId,
  );

  /// Retrieves attempts belonging to a specific assessment session.
  List<QuestionAttempt> getAttemptsForSession(String sessionId);

  /// Clears stored attempts and results (for testing).
  void clear();
}

class InMemoryAttemptRepository implements AttemptRepository {
  final Map<String, QuestionAttempt> _attempts = {};
  final Map<String, AttemptResult> _results = {};

  InMemoryAttemptRepository();

  @override
  void saveAttempt(QuestionAttempt attempt) {
    _attempts[attempt.attemptId] = attempt;
  }

  @override
  void saveResult(AttemptResult result) {
    _results[result.attemptId] = result;
  }

  @override
  QuestionAttempt? getAttemptById(String attemptId) {
    return _attempts[attemptId];
  }

  @override
  AttemptResult? getResultForAttempt(String attemptId) {
    return _results[attemptId];
  }

  @override
  List<QuestionAttempt> getAttemptsForLearner(String learnerId) {
    final list = _attempts.values
        .where((a) => a.learnerId == learnerId)
        .toList()
      ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    return List.unmodifiable(list);
  }

  @override
  List<QuestionAttempt> getAttemptsForLearnerAndObjective(
    String learnerId,
    String objectiveId,
  ) {
    final list = _attempts.values
        .where((a) => a.learnerId == learnerId && a.objectiveId == objectiveId)
        .toList()
      ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    return List.unmodifiable(list);
  }

  @override
  List<AttemptResult> getResultsForLearnerAndObjective(
    String learnerId,
    String objectiveId,
  ) {
    final attempts = getAttemptsForLearnerAndObjective(learnerId, objectiveId);
    final results = <AttemptResult>[];
    for (final att in attempts) {
      final res = _results[att.attemptId];
      if (res != null) {
        results.add(res);
      }
    }
    return List.unmodifiable(results);
  }

  @override
  List<QuestionAttempt> getAttemptsForSession(String sessionId) {
    final list = _attempts.values
        .where((a) => a.sessionId == sessionId)
        .toList()
      ..sort((a, b) => a.attemptedAt.compareTo(b.attemptedAt));
    return List.unmodifiable(list);
  }

  @override
  void clear() {
    _attempts.clear();
    _results.clear();
  }
}
