import '../mappings/question_concept_mapping_model.dart';

abstract class IQuestionConceptRepository {
  Future<void> saveMapping(QuestionConceptMapping mapping);
  Future<void> saveMappings(List<QuestionConceptMapping> mappings);
  Future<List<QuestionConceptMapping>> getMappingsByQuestion(String questionId);
  Future<List<QuestionConceptMapping>> getMappingsByConcept(String conceptId);
  Future<List<QuestionConceptMapping>> getAllMappings();
  Future<void> deleteMapping(String questionId, String conceptId);
  Future<void> clear();
}
