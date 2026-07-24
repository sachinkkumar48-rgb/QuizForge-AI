import '../../domain/entities/knowledge_object.dart';

/// Abstract infrastructure contract for remote cloud storage services
/// (e.g., Supabase, Firebase, REST APIs) in the TITAN Knowledge Intelligence Engine.
abstract class KnowledgeRemoteDataSource {
  /// Uploads or persists a [KnowledgeObject] to remote storage.
  Future<void> save(KnowledgeObject object);

  /// Updates an existing [KnowledgeObject] in remote storage.
  Future<void> update(KnowledgeObject object);

  /// Deletes a [KnowledgeObject] from remote storage by its unique [id].
  Future<void> delete(String id);

  /// Fetches a [KnowledgeObject] by [id] from remote storage,
  /// or returns `null` if not found.
  Future<KnowledgeObject?> findById(String id);

  /// Queries remote storage for objects matching [query].
  Future<List<KnowledgeObject>> search(String query);

  /// Fetches all remote objects updated after the specified [timestamp].
  Future<List<KnowledgeObject>> fetchUpdatedSince(DateTime timestamp);
}
