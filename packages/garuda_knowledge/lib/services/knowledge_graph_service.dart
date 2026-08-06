import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_relationship.dart';
import '../domain/value_objects/knowledge_object_id.dart';
import '../graph/knowledge_subgraph.dart';
import '../repositories/knowledge_repository.dart';

class KnowledgeGraphService {
  final KnowledgeRepository _repository;

  KnowledgeGraphService(this._repository);

  Future<KnowledgeSubgraph> extractSubgraph(
    KnowledgeObjectId rootId, {
    int maxDepth = 2,
  }) async {
    final nodes = <KnowledgeObjectId, KnowledgeObject>{};
    final edges = <KnowledgeRelationship>[];
    final queue = <KnowledgeObjectId>[rootId];
    final visited = <KnowledgeObjectId>{};

    int currentDepth = 0;
    while (queue.isNotEmpty && currentDepth <= maxDepth) {
      final levelSize = queue.length;
      for (int i = 0; i < levelSize; i++) {
        final currentId = queue.removeAt(0);
        if (visited.contains(currentId)) continue;
        visited.add(currentId);

        final obj = await _repository.findById(currentId);
        if (obj != null) {
          nodes[currentId] = obj;
          final rels = await _repository.findRelated(currentId);
          for (final rel in rels) {
            if (!edges.any((e) => e.id == rel.id)) {
              edges.add(rel);
            }
            final neighborId =
                rel.sourceId == currentId ? rel.targetId : rel.sourceId;
            if (!visited.contains(neighborId)) {
              queue.add(neighborId);
            }
          }
        }
      }
      currentDepth++;
    }

    return KnowledgeSubgraph(nodes: nodes, edges: edges);
  }
}
