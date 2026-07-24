import 'package:flutter_test/flutter_test.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';

void main() {
  group('Knowledge Graph Immutable Models Unit Tests', () {
    test('KnowledgeNode supports equality, copyWith, and metadata immutability',
        () {
      final node1 = KnowledgeNode(
        id: 'node_1',
        title: 'Article 21',
        type: KnowledgeNodeType.concept,
        subjectCategory: 'Polity',
        masteryWeight: 0.7,
        metadata: const {'author': 'UPSC Prep'},
      );

      final node2 = node1.copyWith();
      expect(node1, equals(node2));
      expect(node1.hashCode, equals(node2.hashCode));

      final node3 = node1.copyWith(title: 'Article 21 Rights');
      expect(node1 == node3, isFalse);

      expect(() => node1.metadata['new_key'] = 'val', throwsUnsupportedError);
    });

    test('KnowledgeEdge supports equality and copyWith', () {
      final edge1 = KnowledgeEdge(
        id: 'edge_1',
        sourceId: 'sub_polity',
        targetId: 'top_const',
        relationType: KnowledgeRelationType.contains,
        weight: 0.9,
      );

      final edge2 = edge1.copyWith();
      expect(edge1, equals(edge2));
      expect(edge1.hashCode, equals(edge2.hashCode));

      final edge3 = edge1.copyWith(weight: 0.5);
      expect(edge1 == edge3, isFalse);
    });

    test('KnowledgeGraph maintains node and edge immutability', () {
      final node = KnowledgeNode(
        id: 'n1',
        title: 'Node 1',
        type: KnowledgeNodeType.topic,
      );
      final edge = KnowledgeEdge(
        id: 'e1',
        sourceId: 'n1',
        targetId: 'n2',
        relationType: KnowledgeRelationType.contains,
      );

      final graph = KnowledgeGraph(
        nodes: {'n1': node},
        edges: [edge],
      );

      expect(graph.getNode('n1'), equals(node));
      expect(graph.getOutgoingEdges('n1'), contains(edge));
      expect(() => graph.nodes['n2'] = node, throwsUnsupportedError);
      expect(() => graph.edges.add(edge), throwsUnsupportedError);
    });

    test('KnowledgePath calculates step count and start/target nodes', () {
      final n1 = KnowledgeNode(
          id: 'n1', title: 'Node 1', type: KnowledgeNodeType.topic);
      final n2 = KnowledgeNode(
          id: 'n2', title: 'Node 2', type: KnowledgeNodeType.concept);
      final edge = KnowledgeEdge(
        id: 'e1',
        sourceId: 'n1',
        targetId: 'n2',
        relationType: KnowledgeRelationType.contains,
      );

      final path = KnowledgePath(
        nodes: [n1, n2],
        edges: [edge],
        totalDistance: 1.5,
      );

      expect(path.stepCount, equals(2));
      expect(path.startNode, equals(n1));
      expect(path.targetNode, equals(n2));
    });
  });
}
