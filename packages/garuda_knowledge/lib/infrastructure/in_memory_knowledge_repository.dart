import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_relationship.dart';
import '../domain/entities/knowledge_tag.dart';
import '../domain/entities/knowledge_version.dart';
import '../domain/enums/knowledge_object_type.dart';
import '../domain/enums/relationship_type.dart';
import '../domain/value_objects/knowledge_object_id.dart';
import '../repositories/knowledge_repository.dart';

/// In-Memory Implementation of KnowledgeRepository for offline-first operation.
class InMemoryKnowledgeRepository implements KnowledgeRepository {
  final Map<String, KnowledgeObject> _store = {};

  @override
  Future<void> create(KnowledgeObject object) async {
    if (_store.containsKey(object.id.value)) {
      throw StateError('KnowledgeObject with ID "${object.id}" already exists.');
    }
    _store[object.id.value] = object;
  }

  @override
  Future<void> update(KnowledgeObject object) async {
    if (!_store.containsKey(object.id.value)) {
      throw StateError('KnowledgeObject with ID "${object.id}" does not exist.');
    }
    final existing = _store[object.id.value]!;
    final updatedHistory = List<KnowledgeVersion>.from(existing.versionHistory)
      ..add(existing.currentVersion);
    _store[object.id.value] = object.copyWith(versionHistory: updatedHistory);
  }

  @override
  Future<bool> delete(KnowledgeObjectId id) async {
    return _store.remove(id.value) != null;
  }

  @override
  Future<KnowledgeObject?> findById(KnowledgeObjectId id) async {
    return _store[id.value];
  }

  @override
  Future<List<KnowledgeObject>> findByType(KnowledgeObjectType type) async {
    return _store.values.where((obj) => obj.type == type).toList();
  }

  @override
  Future<List<KnowledgeObject>> findByTag(KnowledgeTag tag) async {
    return _store.values
        .where((obj) => obj.tags.any((t) => t.name.toLowerCase() == tag.name.toLowerCase()))
        .toList();
  }

  @override
  Future<List<KnowledgeRelationship>> findRelated(
    KnowledgeObjectId id, {
    RelationshipType? relationshipType,
  }) async {
    final results = <KnowledgeRelationship>[];
    for (final obj in _store.values) {
      for (final rel in obj.relationships) {
        if (rel.sourceId == id || rel.targetId == id) {
          if (relationshipType == null || rel.type == relationshipType) {
            results.add(rel);
          }
        }
      }
    }
    return results;
  }

  @override
  Future<List<KnowledgeObject>> search(
    String query, {
    KnowledgeObjectType? type,
    KnowledgeTag? tag,
  }) async {
    final lower = query.toLowerCase();
    return _store.values.where((obj) {
      if (type != null && obj.type != type) return false;
      if (tag != null && !obj.tags.any((t) => t.name.toLowerCase() == tag.name.toLowerCase())) {
        return false;
      }
      if (lower.isEmpty) return true;
      final matchTitle = obj.title.toLowerCase().contains(lower);
      final matchContent = obj.content.toLowerCase().contains(lower);
      final matchSummary = obj.summary?.toLowerCase().contains(lower) ?? false;
      return matchTitle || matchContent || matchSummary;
    }).toList();
  }

  @override
  Future<List<KnowledgeVersion>> versionHistory(KnowledgeObjectId id) async {
    final obj = _store[id.value];
    if (obj == null) return [];
    return [...obj.versionHistory, obj.currentVersion];
  }

  @override
  Future<void> bulkImport(List<KnowledgeObject> objects) async {
    for (final obj in objects) {
      _store[obj.id.value] = obj;
    }
  }

  @override
  Future<List<KnowledgeObject>> bulkExport() async {
    return _store.values.toList();
  }
}
