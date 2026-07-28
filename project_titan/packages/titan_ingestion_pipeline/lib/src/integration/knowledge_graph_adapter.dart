import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';
import '../models/knowledge_object.dart';

/// Integration adapter converting Knowledge Objects to Knowledge Graph nodes & edges.
class KnowledgeGraphAdapter {
  final KnowledgeGraphRepository graphRepository;

  KnowledgeGraphAdapter({required this.graphRepository});

  /// Generates knowledge graph nodes and relationships for a [KnowledgeObject].
  Future<KnowledgeGraph> buildAndSaveGraph(KnowledgeObject object) async {
    final nodesMap = <String, KnowledgeNode>{};
    final edgesList = <KnowledgeEdge>[];

    // 1. Lesson Root Node
    final rootNode = KnowledgeNode(
      id: 'node_lesson_${object.id}',
      title: object.title,
      type: KnowledgeNodeType.topic,
      subjectCategory: object.difficulty,
      masteryWeight: 1.0,
    );
    nodesMap[rootNode.id] = rootNode;
    await graphRepository.addNode(rootNode);

    // 2. Concept Nodes & Links
    for (final concept in object.concepts) {
      final conceptNodeId = 'node_concept_${concept.id}';
      final conceptNode = KnowledgeNode(
        id: conceptNodeId,
        title: concept.name,
        type: KnowledgeNodeType.concept,
        subjectCategory: concept.type.name,
        masteryWeight: 0.8,
      );
      nodesMap[conceptNodeId] = conceptNode;
      await graphRepository.addNode(conceptNode);

      final edge = KnowledgeEdge(
        id: 'edge_${object.id}_${concept.id}',
        sourceId: rootNode.id,
        targetId: conceptNodeId,
        relationType: KnowledgeRelationType.contains,
        weight: 0.9,
      );
      edgesList.add(edge);
      await graphRepository.addEdge(edge);
    }

    // 3. Explicit Relationship Edges
    for (final rel in object.relationships) {
      final edge = KnowledgeEdge(
        id: 'edge_rel_${rel.sourceId}_${rel.targetId}',
        sourceId: 'node_concept_${rel.sourceId}',
        targetId: 'node_concept_${rel.targetId}',
        relationType: KnowledgeRelationType.relatedTo,
        weight: rel.weight,
      );
      edgesList.add(edge);
      await graphRepository.addEdge(edge);
    }

    return KnowledgeGraph(nodes: nodesMap, edges: edgesList);
  }
}
