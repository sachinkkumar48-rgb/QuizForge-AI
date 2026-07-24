import '../entities/knowledge_object.dart';

/// Abstract repository interface defining persistence, retrieval, and search
/// contracts for [KnowledgeObject] entities in the TITAN platform.
abstract class KnowledgeRepository {
  /// Persists a new [KnowledgeObject].
  Future<void> save(KnowledgeObject object);

  /// Updates an existing [KnowledgeObject].
  Future<void> update(KnowledgeObject object);

  /// Deletes a [KnowledgeObject] identified by its unique [id].
  Future<void> delete(String id);

  /// Retrieves a [KnowledgeObject] by its unique [id].
  ///
  /// Returns `null` if no object is found matching [id].
  Future<KnowledgeObject?> findById(String id);

  /// Searches for [KnowledgeObject] entities matching the provided [query].
  ///
  /// Returns a list of matching objects, or an empty list if none match.
  Future<List<KnowledgeObject>> search(String query);
}
