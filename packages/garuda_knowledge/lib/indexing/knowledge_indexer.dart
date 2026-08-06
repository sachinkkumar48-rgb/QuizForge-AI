import '../domain/entities/knowledge_object.dart';
import 'knowledge_index.dart';

/// Core indexing orchestrator responsible for batch and incremental index maintenance.
class KnowledgeIndexer {
  final KnowledgeIndex _index;

  KnowledgeIndexer(this._index);

  KnowledgeIndex get index => _index;

  /// Performs incremental indexing of a single object.
  void indexObject(KnowledgeObject obj) {
    // Prevent duplicate entries by unindexing first if exists
    _index.unindex(obj.id.value);
    _index.index(obj);
  }

  /// Performs high-performance batch indexing of multiple objects.
  void indexBatch(List<KnowledgeObject> objects) {
    for (final obj in objects) {
      indexObject(obj);
    }
  }

  /// Incremental indexing hook for single item updates.
  void incrementalIndex(KnowledgeObject obj) {
    indexObject(obj);
  }

  /// Removes an object from the index.
  void removeObject(String id) {
    _index.unindex(id);
  }

  /// Completely clears and rebuilds the index from an authoritative list.
  void rebuildIndex(List<KnowledgeObject> objects) {
    _index.clear();
    indexBatch(objects);
  }
}
