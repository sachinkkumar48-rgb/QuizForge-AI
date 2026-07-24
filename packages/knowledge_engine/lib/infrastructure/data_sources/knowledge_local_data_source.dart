import '../../domain/entities/knowledge_object.dart';

/// Abstract infrastructure contract for local database engines
/// (e.g., Hive, Isar, SQLite) in the TITAN Knowledge Intelligence Engine.
abstract class KnowledgeLocalDataSource {
  /// Persists a [KnowledgeObject] to local storage.
  Future<void> save(KnowledgeObject object);

  /// Updates an existing [KnowledgeObject] in local storage.
  Future<void> update(KnowledgeObject object);

  /// Removes a [KnowledgeObject] from local storage by its unique [id].
  Future<void> delete(String id);

  /// Retrieves a [KnowledgeObject] by [id] from local storage,
  /// or returns `null` if not found.
  Future<KnowledgeObject?> findById(String id);

  /// Searches local storage for objects matching [query].
  Future<List<KnowledgeObject>> search(String query);

  /// Retrieves all persisted [KnowledgeObject] entities from local storage.
  Future<List<KnowledgeObject>> getAll();

  /// Clears all local storage records.
  Future<void> clear();
}
