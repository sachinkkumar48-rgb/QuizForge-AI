import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_relationship.dart';
import '../domain/entities/knowledge_tag.dart';
import '../domain/entities/knowledge_version.dart';
import '../domain/enums/knowledge_object_type.dart';
import '../domain/enums/relationship_type.dart';
import '../domain/value_objects/knowledge_object_id.dart';

/// Repository interface for storing and retrieving Knowledge Objects and Relationships.
abstract class KnowledgeRepository {
  /// Store a new Knowledge Object. Throws if ID already exists.
  Future<void> create(KnowledgeObject object);

  /// Update an existing Knowledge Object. Throws if ID is not found.
  Future<void> update(KnowledgeObject object);

  /// Delete a Knowledge Object by ID.
  Future<bool> delete(KnowledgeObjectId id);

  /// Find a Knowledge Object by ID.
  Future<KnowledgeObject?> findById(KnowledgeObjectId id);

  /// Find all Knowledge Objects matching a specific type.
  Future<List<KnowledgeObject>> findByType(KnowledgeObjectType type);

  /// Find all Knowledge Objects tagged with a specific tag.
  Future<List<KnowledgeObject>> findByTag(KnowledgeTag tag);

  /// Find all related Knowledge Objects for a given target ID.
  Future<List<KnowledgeRelationship>> findRelated(
    KnowledgeObjectId id, {
    RelationshipType? relationshipType,
  });

  /// Search Knowledge Objects by text query, optional type, and tag.
  Future<List<KnowledgeObject>> search(
    String query, {
    KnowledgeObjectType? type,
    KnowledgeTag? tag,
  });

  /// Get full version history for a Knowledge Object.
  Future<List<KnowledgeVersion>> versionHistory(KnowledgeObjectId id);

  /// Bulk import multiple Knowledge Objects into the repository.
  Future<void> bulkImport(List<KnowledgeObject> objects);

  /// Bulk export all Knowledge Objects from the repository.
  Future<List<KnowledgeObject>> bulkExport();
}
