import 'package:flutter_test/flutter_test.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';

void main() {
  group('KnowledgeGraphRepository Unit Tests', () {
    late KnowledgeGraphRepository repository;

    setUp(() {
      repository = KnowledgeGraphRepositoryImpl();
    });

    test('getGraph returns seeded UPSC knowledge graph', () async {
      final graph = await repository.getGraph();
      expect(graph.nodes.length, greaterThan(5));
      expect(graph.edges.length, greaterThan(5));
      expect(graph.getNode('sub_polity'), isNotNull);
    });

    test('addNode dynamically expands the active graph', () async {
      final newNode = KnowledgeNode(
        id: 'top_judiciary',
        title: 'Supreme Court & Judiciary',
        type: KnowledgeNodeType.topic,
        subjectCategory: 'Polity',
      );

      final updatedGraph = await repository.addNode(newNode);
      expect(updatedGraph.getNode('top_judiciary'), equals(newNode));

      final fetchedNode = await repository.getNode('top_judiciary');
      expect(fetchedNode, equals(newNode));
    });

    test('addEdge dynamically links nodes in the graph', () async {
      final newEdge = KnowledgeEdge(
        id: 'edge_polity_judiciary',
        sourceId: 'sub_polity',
        targetId: 'top_judiciary',
        relationType: KnowledgeRelationType.contains,
      );

      final updatedGraph = await repository.addEdge(newEdge);
      expect(updatedGraph.edges, contains(newEdge));
    });
  });
}
