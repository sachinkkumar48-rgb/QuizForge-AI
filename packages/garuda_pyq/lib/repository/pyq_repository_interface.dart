import '../models/paper_model.dart';
import '../models/question_model.dart';

abstract class IPYQRepository {
  Future<void> saveQuestion(Question question);
  Future<void> saveQuestions(List<Question> questions);
  Future<Question?> getQuestionById(String id);
  Future<List<Question>> getQuestionsByExam(
    String examId, {
    int? year,
    String? subject,
    String? stage,
  });
  Future<List<Question>> searchQuestions(Map<String, dynamic> criteria);
  Future<void> deleteQuestion(String id);
  Future<int> getQuestionCount();
  Future<List<Question>> getAllQuestions();
  Future<List<Paper>> getPapersByExam(String examId);
  Future<void> savePaper(Paper paper);
  Future<void> clear();
}
