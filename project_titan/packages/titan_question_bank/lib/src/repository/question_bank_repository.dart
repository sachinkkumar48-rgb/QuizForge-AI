import '../models/question_bank_models.dart';

abstract class QuestionBankRepository {
  Future<List<KmpQuestionItem>> getQuestions(
      {KmpQuestionType? type, String? topicId});
  Future<KmpQuestionItem?> getQuestionById(String id);
  Future<KmpQuestionItem> createQuestion(KmpQuestionItem question);
  Future<KmpQuestionItem> updateQuestion(KmpQuestionItem question);
  Future<void> deleteQuestion(String id);
}
