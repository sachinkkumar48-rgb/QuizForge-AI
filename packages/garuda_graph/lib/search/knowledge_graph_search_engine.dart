library;

import '../domain/entities/enums.dart';
import '../domain/entities/knowledge_link.dart';
import '../domain/repositories/knowledge_graph_repository.dart';

/// Graph search engine executing multi-vector semantic searches across Knowledge Links.
class KnowledgeGraphSearchEngine {
  final KnowledgeGraphRepository repository;

  KnowledgeGraphSearchEngine(this.repository);

  /// Find all links connected to a specific object/node ID.
  Future<List<KnowledgeLink>> findByObject(String nodeId) async {
    return await repository.findLinksByNode(nodeId);
  }

  /// Find links matching a Constitution Article (e.g. "Art 21").
  Future<List<KnowledgeLink>> findByArticle(String articleRef) async {
    return await _findByTypeOrAttribute(NodeType.article, articleRef);
  }

  /// Find links matching a Judicial Case Law (e.g. "Kesavananda Bharati").
  Future<List<KnowledgeLink>> findByCase(String caseName) async {
    return await _findByTypeOrAttribute(NodeType.caseLaw, caseName);
  }

  /// Find links matching a Legislative Act (e.g. "DPDP Act 2023").
  Future<List<KnowledgeLink>> findByAct(String actName) async {
    return await _findByTypeOrAttribute(NodeType.act, actName);
  }

  /// Find links matching a Constitutional Amendment.
  Future<List<KnowledgeLink>> findByAmendment(String amendmentRef) async {
    return await _findByTypeOrAttribute(NodeType.amendment, amendmentRef);
  }

  /// Find links matching a Committee or Commission.
  Future<List<KnowledgeLink>> findByCommittee(String committeeName) async {
    return await _findByTypeOrAttribute(NodeType.committee, committeeName);
  }

  /// Find links matching a Topic name.
  Future<List<KnowledgeLink>> findByTopic(String topic) async {
    return await _findByTypeOrAttribute(NodeType.topic, topic);
  }

  /// Find links matching a Concept name.
  Future<List<KnowledgeLink>> findByConcept(String concept) async {
    return await _findByTypeOrAttribute(NodeType.concept, concept);
  }

  Future<List<KnowledgeLink>> _findByTypeOrAttribute(
    NodeType type,
    String query,
  ) async {
    final lower = query.toLowerCase();
    final allLinks = await repository.searchLinks();

    return allLinks.where((link) {
      final srcMatch = (link.sourceObject.nodeType == type ||
              link.sourceObject.id.toLowerCase().contains(lower)) &&
          (link.sourceObject.name.toLowerCase().contains(lower) ||
              link.sourceObject.id.toLowerCase().contains(lower));

      final targetMatch = (link.targetObject.nodeType == type ||
              link.targetObject.id.toLowerCase().contains(lower)) &&
          (link.targetObject.name.toLowerCase().contains(lower) ||
              link.targetObject.id.toLowerCase().contains(lower));

      return srcMatch || targetMatch;
    }).toList();
  }
}
