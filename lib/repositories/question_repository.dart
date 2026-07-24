import '../models/question.dart';

abstract class QuestionRepository {
  Future<List<Question>> getAllQuestions();
  Future<Question?> getQuestionById(String id);
  Future<List<Question>> getQuestionsByPaper(String paperId);
  Future<List<Question>> getQuestionsByYear(int year, {String? exam});
  Future<List<Question>> getQuestionsBySubject(String subject, {String? exam});
  Future<List<Question>> getQuestionsByTopic(String topic, {String? exam});
  Future<List<String>> getSubjects({String? exam});
  Future<List<String>> getTopics({String? exam, String? subject});
  Future<List<Question>> searchQuestions({
    String? query,
    int? year,
    String? subject,
    String? topic,
    String? difficulty,
    String? exam,
  });
  Future<void> saveQuestion(Question question);
  Future<void> saveQuestionsBatch(List<Question> questions);
  Future<void> clear();
}
