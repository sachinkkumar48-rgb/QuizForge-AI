import '../domain/entities/knowledge_object.dart';
import '../domain/enums/knowledge_object_type.dart';
import 'knowledge_index.dart';
import 'knowledge_indexer.dart';

/// Manager class coordinating indexing lifecycle, statistics, and pipeline callbacks.
class KnowledgeIndexManager {
  final KnowledgeIndex _index;
  final KnowledgeIndexer _indexer;

  factory KnowledgeIndexManager({KnowledgeIndex? index, KnowledgeIndexer? indexer}) {
    final idx = index ?? KnowledgeIndex();
    final idxr = indexer ?? KnowledgeIndexer(idx);
    return KnowledgeIndexManager._(idx, idxr);
  }

  KnowledgeIndexManager._(this._index, this._indexer);

  KnowledgeIndex get index => _index;
  KnowledgeIndexer get indexer => _indexer;

  void indexObject(KnowledgeObject obj) {
    _indexer.indexObject(obj);
  }

  void indexBatch(List<KnowledgeObject> objects) {
    _indexer.indexBatch(objects);
  }

  void unindexObject(KnowledgeObject obj) {
    _indexer.removeObject(obj.id.value);
  }

  Set<String> getIdsByType(KnowledgeObjectType type) {
    return _index.searchTypes(type);
  }

  Set<String> getIdsByTag(String tag) {
    return _index.searchTags(tag);
  }

  Set<String> getIdsByKeyword(String keyword) {
    return _index.searchKeywords(keyword);
  }

  void clear() {
    _index.clear();
  }
}
