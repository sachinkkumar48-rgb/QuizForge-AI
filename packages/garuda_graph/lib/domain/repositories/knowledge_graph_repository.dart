library;

import '../entities/enums.dart';
import '../entities/knowledge_link.dart';
import '../entities/knowledge_node_ref.dart';

/// Abstract repository contract for Knowledge Graph persistence and graph queries.
abstract class KnowledgeGraphRepository {
  Future<bool> saveLink(KnowledgeLink link);
  Future<bool> updateLink(KnowledgeLink link);
  Future<bool> deleteLink(String linkId);
  Future<KnowledgeLink?> findLinkById(String linkId);
  Future<List<KnowledgeLink>> findLinksByNode(String nodeId);
  Future<List<KnowledgeLink>> searchLinks({
    String? sourceId,
    String? targetId,
    KnowledgeRelationshipType? relationshipType,
    LinkStatus? status,
  });
  Future<KnowledgeNodeRef?> getNode(String nodeId);
  Future<bool> saveNode(KnowledgeNodeRef node);
  Future<List<KnowledgeNodeRef>> listNodes();
}
