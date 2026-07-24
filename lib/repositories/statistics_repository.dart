import '../models/question_statistics.dart';

abstract class StatisticsRepository {
  Future<QuestionStatistics?> getQuestionStats(String questionId);
  Future<void> updateQuestionStats({
    required String questionId,
    required bool isCorrect,
    required int timeSpentSeconds,
  });
  Future<List<QuestionStatistics>> getAllStats();
  Future<void> clear();
}
