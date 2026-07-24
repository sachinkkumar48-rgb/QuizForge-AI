import '../entities/knowledge_relationship.dart';
import '../value_objects/relationship_type.dart';

/// Abstract contract interface defining persistence and graph relationship edge lookup
/// methods in the TITAN Knowledge Intelligence Engine domain.
abstract class RelationshipRepository {
  /// Persists a new or updated [KnowledgeRelationship] edge.
  Future<void> save(KnowledgeRelationship relationship);

  /// Deletes a [KnowledgeRelationship] edge identified by [relationshipId].
  Future<void> delete(String relationshipId);

  /// Retrieves a [KnowledgeRelationship] edge by [relationshipId], or returns `null` if not found.
  Future<KnowledgeRelationship?> findById(String relationshipId);

  /// Retrieves all outgoing relationship edges originating from [sourceKnowledgeId].
  Future<List<KnowledgeRelationship>> getOutgoingRelationships(
      String sourceKnowledgeId);

  /// Retrieves all incoming relationship edges pointing to [targetKnowledgeId].
  Future<List<KnowledgeRelationship>> getIncomingRelationships(
      String targetKnowledgeId);

  /// Retrieves all relationship edges matching the specified [type].
  Future<List<KnowledgeRelationship>> getRelationshipsByType(
      RelationshipType type);
}
