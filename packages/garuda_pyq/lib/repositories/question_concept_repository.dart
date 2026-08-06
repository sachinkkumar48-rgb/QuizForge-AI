import '../mappings/question_concept_mapping_model.dart';
import 'question_concept_repository_interface.dart';

class OfflineQuestionConceptRepository implements IQuestionConceptRepository {
  final Map<String, QuestionConceptMapping> _mappings = {};

  String _key(String questionId, String conceptId) => '${questionId}_$conceptId';

  @override
  Future<void> saveMapping(QuestionConceptMapping mapping) async {
    _mappings[_key(mapping.questionId, mapping.conceptId)] = mapping;
  }

  @override
  Future<void> saveMappings(List<QuestionConceptMapping> mappings) async {
    for (final m in mappings) {
      _mappings[_key(m.questionId, m.conceptId)] = m;
    }
  }

  @override
  Future<List<QuestionConceptMapping>> getMappingsByQuestion(
      String questionId) async {
    return _mappings.values
        .where((m) => m.questionId == questionId)
        .toList();
  }

  @override
  Future<List<QuestionConceptMapping>> getMappingsByConcept(
      String conceptId) async {
    return _mappings.values
        .where((m) => m.conceptId == conceptId)
        .toList();
  }

  @override
  Future<List<QuestionConceptMapping>> getAllMappings() async {
    return _mappings.values.toList();
  }

  @override
  Future<void> deleteMapping(String questionId, String conceptId) async {
    _mappings.remove(_key(questionId, conceptId));
  }

  @override
  Future<void> clear() async {
    _mappings.clear();
  }
}
