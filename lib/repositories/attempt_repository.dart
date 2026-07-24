import '../models/attempt.dart';

abstract class AttemptRepository {
  Future<void> recordAttempt(QuestionAttempt attempt);
  Future<List<QuestionAttempt>> getAttemptsForQuestion(String questionId);
  Future<QuestionAttempt?> getLatestAttempt(String questionId);
  Future<List<QuestionAttempt>> getAllAttempts();
  Future<List<String>> getIncorrectQuestionIds();
  Future<void> clear();
}
