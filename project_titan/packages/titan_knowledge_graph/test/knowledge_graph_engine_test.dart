import 'package:flutter_test/flutter_test.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';

void main() {
  group('KnowledgeGraphEngine Unit Tests', () {
    late KnowledgeGraphEngine engine;
    late KnowledgeGraph graph;

    setUp(() {
      engine = const KnowledgeGraphEngine();
      final repository = KnowledgeGraphRepositoryImpl(engine: engine);
      repository.getGraph().then((g) => graph = g);
    });

    test('bfsTraversal traverses graph up to max depth', () async {
      final repository = KnowledgeGraphRepositoryImpl(engine: engine);
      graph = await repository.getGraph();

      final visited = engine.bfsTraversal(
        graph: graph,
        startNodeId: 'sub_polity',
        maxDepth: 2,
      );

      expect(visited.isNotEmpty, isTrue);
      expect(visited.first.id, equals('sub_polity'));
    });

    test('discoverNeighbors returns direct outgoing and incoming connections',
        () async {
      final repository = KnowledgeGraphRepositoryImpl(engine: engine);
      graph = await repository.getGraph();

      final neighbors = engine.discoverNeighbors(
        graph: graph,
        nodeId: 'top_const',
      );

      expect(neighbors.any((n) => n.id == 'subtop_fund_rights'), isTrue);
    });

    test('findShortestLearningPath calculates optimal path between nodes',
        () async {
      final repository = KnowledgeGraphRepositoryImpl(engine: engine);
      graph = await repository.getGraph();

      final path = engine.findShortestLearningPath(
        graph: graph,
        startNodeId: 'sub_polity',
        targetNodeId: 'concept_art21',
      );

      expect(path, isNotNull);
      expect(path!.startNode?.id, equals('sub_polity'));
      expect(path.targetNode?.id, equals('concept_art21'));
      expect(path.nodes.length, greaterThanOrEqualTo(3));
    });

    test('rankRelatedTopics ranks topics by proximity and gap score', () async {
      final repository = KnowledgeGraphRepositoryImpl(engine: engine);
      graph = await repository.getGraph();

      final related = engine.rankRelatedTopics(
        graph: graph,
        rootNodeId: 'concept_art21',
        topN: 3,
      );

      expect(related, isNotNull);
      expect(related.any((n) => n.id == 'concept_art21'), isFalse);
    });
  });
}
