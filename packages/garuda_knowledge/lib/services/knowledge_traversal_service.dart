import '../domain/entities/knowledge_relationship.dart';
import '../domain/enums/relationship_type.dart';
import '../domain/value_objects/knowledge_object_id.dart';
import '../repositories/knowledge_repository.dart';

class KnowledgePath {
  final List<KnowledgeObjectId> nodes;
  final List<KnowledgeRelationship> edges;

  const KnowledgePath({required this.nodes, required this.edges});
}

class KnowledgeTraversalService {
  final KnowledgeRepository _repository;

  KnowledgeTraversalService(this._repository);

  Future<KnowledgePath?> findShortestPath(
    KnowledgeObjectId startId,
    KnowledgeObjectId targetId, {
    RelationshipType? filterType,
  }) async {
    if (startId == targetId) {
      return KnowledgePath(nodes: [startId], edges: []);
    }

    final visited = <KnowledgeObjectId>{startId};
    final queue = <List<KnowledgeObjectId>>[
      [startId]
    ];
    final edgeMap = <String, KnowledgeRelationship>{};

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      final rels = await _repository.findRelated(current, relationshipType: filterType);
      for (final rel in rels) {
        final neighbor = rel.sourceId == current ? rel.targetId : rel.sourceId;
        edgeMap['${current.value}->${neighbor.value}'] = rel;

        if (neighbor == targetId) {
          final fullNodes = [...path, neighbor];
          final fullEdges = <KnowledgeRelationship>[];
          for (int i = 0; i < fullNodes.length - 1; i++) {
            final e = edgeMap['${fullNodes[i].value}->${fullNodes[i + 1].value}'];
            if (e != null) fullEdges.add(e);
          }
          return KnowledgePath(nodes: fullNodes, edges: fullEdges);
        }

        if (!visited.contains(neighbor)) {
          visited.add(neighbor);
          queue.add([...path, neighbor]);
        }
      }
    }

    return null;
  }
}
