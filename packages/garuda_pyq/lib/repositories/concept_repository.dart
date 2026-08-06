import '../concepts/concept_model.dart';
import '../concepts/concept_relationship_model.dart';
import 'concept_repository_interface.dart';

class OfflineConceptRepository implements IConceptRepository {
  final Map<String, Concept> _concepts = {};
  final Map<String, ConceptRelationship> _relationships = {};

  @override
  Future<void> saveConcept(Concept concept) async {
    _concepts[concept.id] = concept;
  }

  @override
  Future<void> saveConcepts(List<Concept> concepts) async {
    for (final c in concepts) {
      _concepts[c.id] = c;
    }
  }

  @override
  Future<Concept?> getConceptById(String id) async {
    return _concepts[id];
  }

  @override
  Future<List<Concept>> getConceptsBySubject(String subject) async {
    return _concepts.values
        .where((c) => c.subject.toLowerCase() == subject.toLowerCase())
        .toList();
  }

  @override
  Future<List<Concept>> getAllConcepts() async {
    return _concepts.values.toList();
  }

  @override
  Future<void> deleteConcept(String id) async {
    _concepts.remove(id);
    _relationships.removeWhere((k, v) =>
        v.sourceConceptId == id || v.targetConceptId == id);
  }

  @override
  Future<void> saveRelationship(ConceptRelationship relationship) async {
    _relationships[relationship.id] = relationship;
  }

  @override
  Future<List<ConceptRelationship>> getRelationshipsForConcept(
      String conceptId) async {
    return _relationships.values
        .where((r) =>
            r.sourceConceptId == conceptId || r.targetConceptId == conceptId)
        .toList();
  }

  @override
  Future<List<ConceptRelationship>> getAllRelationships() async {
    return _relationships.values.toList();
  }

  @override
  Future<void> clear() async {
    _concepts.clear();
    _relationships.clear();
  }
}
