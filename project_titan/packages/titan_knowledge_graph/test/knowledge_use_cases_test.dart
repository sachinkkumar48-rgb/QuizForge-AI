import 'package:flutter_test/flutter_test.dart';
import 'package:titan_knowledge_graph/titan_knowledge_graph.dart';

void main() {
  group('Knowledge Graph Clean Architecture Use Cases Unit Tests', () {
    late KnowledgeGraphRepository repository;
    late BuildKnowledgeGraphUseCase buildGraphUseCase;
    late QueryKnowledgeGraphUseCase queryGraphUseCase;
    late FindRelatedTopicsUseCase findRelatedTopicsUseCase;
    late GetLearningPathUseCase getLearningPathUseCase;

    setUp(() {
      repository = KnowledgeGraphRepositoryImpl();
      buildGraphUseCase = BuildKnowledgeGraphUseCase(repository);
      queryGraphUseCase = QueryKnowledgeGraphUseCase(repository);
      findRelatedTopicsUseCase = FindRelatedTopicsUseCase(repository);
      getLearningPathUseCase = GetLearningPathUseCase(repository);
    });

    test('BuildKnowledgeGraphUseCase returns active graph', () async {
      final graph = await buildGraphUseCase.execute();
      expect(graph.nodes.isNotEmpty, isTrue);
    });

    test('QueryKnowledgeGraphUseCase retrieves node and performs BFS traversal',
        () async {
      final node = await queryGraphUseCase.getNode('sub_polity');
      expect(node, isNotNull);

      final bfsNodes = await queryGraphUseCase.traverseBfs('sub_polity');
      expect(bfsNodes.isNotEmpty, isTrue);
    });

    test('FindRelatedTopicsUseCase returns ranked related topic nodes',
        () async {
      final related = await findRelatedTopicsUseCase.execute('concept_art21');
      expect(related, isNotNull);
    });

    test('GetLearningPathUseCase calculates shortest learning path', () async {
      final path = await getLearningPathUseCase.execute(
        'sub_polity',
        'concept_art21',
      );
      expect(path, isNotNull);
      expect(path!.startNode?.id, equals('sub_polity'));
      expect(path.targetNode?.id, equals('concept_art21'));
    });
  });
}
