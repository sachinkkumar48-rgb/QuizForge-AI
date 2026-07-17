import '../models/quiz_session.dart';
import 'impl/hive_quiz_session_repository.dart';

abstract class QuizSessionRepository {
  static QuizSessionRepository? _instance;

  static QuizSessionRepository get instance {
    _instance ??= HiveQuizSessionRepository();
    return _instance!;
  }

  static set instance(QuizSessionRepository mock) {
    _instance = mock;
  }

  factory QuizSessionRepository() => instance;

  Future<void> saveSession(QuizSession session);
  Future<QuizSession?> loadSession();
  Future<void> deleteSession();
  Future<bool> hasActiveSession();
}
