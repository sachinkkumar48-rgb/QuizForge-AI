import '../concepts/concept_model.dart';
import '../concepts/concept_relationship_model.dart';

abstract class IConceptRepository {
  Future<void> saveConcept(Concept concept);
  Future<void> saveConcepts(List<Concept> concepts);
  Future<Concept?> getConceptById(String id);
  Future<List<Concept>> getConceptsBySubject(String subject);
  Future<List<Concept>> getAllConcepts();
  Future<void> deleteConcept(String id);
  Future<void> saveRelationship(ConceptRelationship relationship);
  Future<List<ConceptRelationship>> getRelationshipsForConcept(String conceptId);
  Future<List<ConceptRelationship>> getAllRelationships();
  Future<void> clear();
}
