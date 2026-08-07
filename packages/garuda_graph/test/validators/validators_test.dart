import 'package:garuda_graph/garuda_graph.dart';
import 'package:test/test.dart';

void main() {
  group('LinkValidatorEngine Tests', () {
    late KnowledgeGraphRepository repository;
    final now = DateTime.now();

    const nodeA = KnowledgeNodeRef(id: 'NodeA', name: 'Node A', nodeType: NodeType.topic);
    const nodeB = KnowledgeNodeRef(id: 'NodeB', name: 'Node B', nodeType: NodeType.topic);

    setUp(() {
      repository = InMemoryKnowledgeGraphRepository();
    });

    test('Self-referential link should fail validation', () async {
      final link = KnowledgeLink(
        id: 'self_link',
        sourceObject: nodeA,
        targetObject: nodeA,
        relationshipType: KnowledgeRelationshipType.relatedTo,
        confidenceScore: 0.8,
        createdAt: now,
        updatedAt: now,
      );

      final res = await LinkValidatorEngine.validateLink(link, repository: repository);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.code == 'CIRCULAR_LINK_SELF'), isTrue);
    });

    test('Duplicate link detection', () async {
      final link1 = KnowledgeLink(
        id: 'link_1',
        sourceObject: nodeA,
        targetObject: nodeB,
        relationshipType: KnowledgeRelationshipType.references,
        confidenceScore: 0.85,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveLink(link1);

      final duplicateLink = KnowledgeLink(
        id: 'link_2',
        sourceObject: nodeA,
        targetObject: nodeB,
        relationshipType: KnowledgeRelationshipType.references,
        confidenceScore: 0.90,
        createdAt: now,
        updatedAt: now,
      );

      final res = await LinkValidatorEngine.validateLink(duplicateLink, repository: repository);
      expect(res.isValid, isFalse);
      expect(res.errors.any((e) => e.code == 'DUPLICATE_LINK'), isTrue);
    });
  });
}
