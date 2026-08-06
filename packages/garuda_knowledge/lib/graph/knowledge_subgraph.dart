import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_relationship.dart';
import '../domain/value_objects/knowledge_object_id.dart';

class KnowledgeSubgraph {
  final Map<KnowledgeObjectId, KnowledgeObject> nodes;
  final List<KnowledgeRelationship> edges;

  const KnowledgeSubgraph({
    required this.nodes,
    required this.edges,
  });

  bool containsNode(KnowledgeObjectId id) => nodes.containsKey(id);

  List<KnowledgeRelationship> getEdgesFor(KnowledgeObjectId id) {
    return edges.where((e) => e.sourceId == id || e.targetId == id).toList();
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((k, v) => MapEntry(k.value, v.toJson())),
        'edges': edges.map((e) => e.toJson()).toList(),
      };
}
