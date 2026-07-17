import 'package:flutter/foundation.dart';
import '../models/quiz_attempt.dart';
import 'impl/hive_quiz_history_repository.dart';

abstract class QuizHistoryRepository {
  static QuizHistoryRepository? _instance;

  static QuizHistoryRepository get instance {
    _instance ??= HiveQuizHistoryRepository();
    return _instance!;
  }

  @visibleForTesting
  static set instance(QuizHistoryRepository mock) {
    _instance = mock;
  }

  factory QuizHistoryRepository() => instance;

  Future<void> saveAttempt(QuizAttempt attempt);
  Future<List<QuizAttempt>> getAttempts();
  Future<void> deleteAttempt(String id);
  Future<void> clearHistory();
}
