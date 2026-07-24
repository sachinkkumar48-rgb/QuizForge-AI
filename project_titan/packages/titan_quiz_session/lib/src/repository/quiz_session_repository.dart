import 'package:titan_domain/titan_domain.dart';
import 'package:titan_quiz/titan_quiz.dart';
import '../models/quiz_result_summary.dart';
import '../models/quiz_session.dart';
import '../models/session_configuration.dart';

/// Repository contract managing storage, persistence, and lifecycle transitions for [QuizSession] entities.
abstract class QuizSessionRepository implements Repository<QuizSession> {
  /// Creates and persists a new quiz session for [quiz].
  Future<QuizSession> createSession(
    Quiz quiz, {
    SessionConfiguration configuration = const SessionConfiguration.standard(),
  });

  /// Retrieves a persisted session by [sessionId]. Returns null if not found.
  Future<QuizSession?> loadSession(String sessionId);

  /// Persists updates to [session].
  Future<void> saveSession(QuizSession session);

  /// Deletes a persisted session by [sessionId].
  Future<void> deleteSession(String sessionId);

  /// Resumes a paused session by [sessionId].
  Future<QuizSession> resumeSession(String sessionId);

  /// Finalizes and evaluates a session by [sessionId], returning the [QuizResultSummary].
  Future<QuizResultSummary> completeSession(String sessionId, Quiz quiz);
}
