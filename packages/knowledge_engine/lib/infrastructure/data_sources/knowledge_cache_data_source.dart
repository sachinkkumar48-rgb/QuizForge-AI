import '../../domain/entities/knowledge_object.dart';

/// Abstract infrastructure contract for ultra-fast in-memory caching
/// in the TITAN Knowledge Intelligence Engine.
abstract class KnowledgeCacheDataSource {
  /// Retrieves a cached [KnowledgeObject] by [id], or returns `null` on cache miss.
  KnowledgeObject? get(String id);

  /// Stores a [KnowledgeObject] in memory.
  void put(KnowledgeObject object);

  /// Evicts a [KnowledgeObject] from the memory cache by [id].
  void remove(String id);

  /// Evicts all cached entries.
  void clear();
}
