library;

import '../domain/entities/enums.dart';
import '../domain/entities/knowledge_link.dart';
import '../domain/entities/knowledge_node_ref.dart';
import '../domain/repositories/knowledge_graph_repository.dart';

/// Thread-safe in-memory and offline-first repository implementation of [KnowledgeGraphRepository].
class InMemoryKnowledgeGraphRepository implements KnowledgeGraphRepository {
  final Map<String, KnowledgeLink> _links = {};
  final Map<String, KnowledgeNodeRef> _nodes = {};

  @override
  Future<bool> saveLink(KnowledgeLink link) async {
    _links[link.id] = link;
    saveNode(link.sourceObject);
    saveNode(link.targetObject);
    return true;
  }

  @override
  Future<bool> updateLink(KnowledgeLink link) async {
    _links[link.id] = link;
    return true;
  }

  @override
  Future<bool> deleteLink(String linkId) async {
    return _links.remove(linkId) != null;
  }

  @override
  Future<KnowledgeLink?> findLinkById(String linkId) async {
    return _links[linkId];
  }

  @override
  Future<List<KnowledgeLink>> findLinksByNode(String nodeId) async {
    return _links.values
        .where((l) => l.sourceObject.id == nodeId || l.targetObject.id == nodeId)
        .toList();
  }

  @override
  Future<List<KnowledgeLink>> searchLinks({
    String? sourceId,
    String? targetId,
    KnowledgeRelationshipType? relationshipType,
    LinkStatus? status,
  }) async {
    var results = _links.values.toList();

    if (sourceId != null) {
      results = results.where((l) => l.sourceObject.id == sourceId).toList();
    }
    if (targetId != null) {
      results = results.where((l) => l.targetObject.id == targetId).toList();
    }
    if (relationshipType != null) {
      results = results.where((l) => l.relationshipType == relationshipType).toList();
    }
    if (status != null) {
      results = results.where((l) => l.status == status).toList();
    }

    return results;
  }

  @override
  Future<KnowledgeNodeRef?> getNode(String nodeId) async {
    return _nodes[nodeId];
  }

  @override
  Future<bool> saveNode(KnowledgeNodeRef node) async {
    _nodes[node.id] = node;
    return true;
  }

  @override
  Future<List<KnowledgeNodeRef>> listNodes() async {
    return _nodes.values.toList();
  }
}
