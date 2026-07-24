import '../models/explanation.dart';

abstract class ExplanationRepository {
  Future<List<Explanation>> getExplanations(String questionId);
  Future<Explanation?> getExplanationByType(
      String questionId, String explanationType);
  Future<void> saveExplanation(Explanation explanation);
  Future<void> saveExplanationsBatch(List<Explanation> explanations);
  Future<void> deleteExplanation(String explanationId);
  Future<void> clear();
}
