import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

import 'relationship_query_service_test.dart';

void main() {
  group('KnowledgeTraversalService Tests', () {
    late FakeRelationshipRepository repository;
    late RelationshipQueryService queryService;
    late KnowledgeTraversalService traversalService;

    setUp(() async {
      repository = FakeRelationshipRepository();
      queryService = RelationshipQueryService(repository);
      traversalService = KnowledgeTraversalService(queryService);
    });

    test('getNeighbors returns unique, sorted neighbor IDs', () async {
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r1',
        sourceKnowledgeId: 'node-A',
        targetKnowledgeId: 'node-Z',
        relationshipType: RelationshipType.relatedTo,
      ));
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r2',
        sourceKnowledgeId: 'node-A',
        targetKnowledgeId: 'node-M',
        relationshipType: RelationshipType.relatedTo,
      ));
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r3',
        sourceKnowledgeId: 'node-B',
        targetKnowledgeId: 'node-A',
        relationshipType: RelationshipType.relatedTo,
      ));

      final outgoingNeighbors =
          await traversalService.getNeighbors('node-A', outgoingOnly: true);
      expect(outgoingNeighbors, equals(['node-M', 'node-Z']));

      final allNeighbors =
          await traversalService.getNeighbors('node-A', outgoingOnly: false);
      expect(allNeighbors, equals(['node-B', 'node-M', 'node-Z']));
    });

    test('traverse respects maxDepth restriction', () async {
      // Line graph: A -> B -> C -> D
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r1',
        sourceKnowledgeId: 'node-A',
        targetKnowledgeId: 'node-B',
        relationshipType: RelationshipType.prerequisiteOf,
      ));
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r2',
        sourceKnowledgeId: 'node-B',
        targetKnowledgeId: 'node-C',
        relationshipType: RelationshipType.prerequisiteOf,
      ));
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r3',
        sourceKnowledgeId: 'node-C',
        targetKnowledgeId: 'node-D',
        relationshipType: RelationshipType.prerequisiteOf,
      ));

      final depth1 = await traversalService.traverse('node-A', maxDepth: 1);
      expect(depth1.visitedNodes, equals(['node-A', 'node-B']));
      expect(depth1.traversedEdges.length, equals(1));
      expect(depth1.traversalDepth, equals(1));

      final depth2 = await traversalService.traverse('node-A', maxDepth: 2);
      expect(depth2.visitedNodes, equals(['node-A', 'node-B', 'node-C']));
      expect(depth2.traversedEdges.length, equals(2));
      expect(depth2.traversalDepth, equals(2));
    });

    test('traverse detects cycles and prevents infinite loops', () async {
      // Cyclic graph: A -> B -> C -> A
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r1',
        sourceKnowledgeId: 'node-A',
        targetKnowledgeId: 'node-B',
        relationshipType: RelationshipType.relatedTo,
      ));
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r2',
        sourceKnowledgeId: 'node-B',
        targetKnowledgeId: 'node-C',
        relationshipType: RelationshipType.relatedTo,
      ));
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r3',
        sourceKnowledgeId: 'node-C',
        targetKnowledgeId: 'node-A',
        relationshipType: RelationshipType.relatedTo,
      ));

      final result = await traversalService.traverse('node-A', maxDepth: 10);
      expect(result.visitedNodes, equals(['node-A', 'node-B', 'node-C']));
      expect(result.statistics['cyclesDetected'], greaterThanOrEqualTo(1));
    });

    test('traverse produces deterministic node and edge visit sequences',
        () async {
      // Branching graph: A -> C, A -> B
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r2',
        sourceKnowledgeId: 'node-A',
        targetKnowledgeId: 'node-C',
        relationshipType: RelationshipType.relatedTo,
      ));
      await repository.save(KnowledgeRelationship(
        relationshipId: 'r1',
        sourceKnowledgeId: 'node-A',
        targetKnowledgeId: 'node-B',
        relationshipType: RelationshipType.relatedTo,
      ));

      final run1 = await traversalService.traverse('node-A', maxDepth: 2);
      final run2 = await traversalService.traverse('node-A', maxDepth: 2);

      expect(run1.visitedNodes, equals(run2.visitedNodes));
      expect(run1.traversedEdges, equals(run2.traversedEdges));
      expect(run1.visitedNodes, equals(['node-A', 'node-B', 'node-C']));
    });
  });
}
