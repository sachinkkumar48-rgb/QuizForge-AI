import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

class FakeRelationshipRepository implements RelationshipRepository {
  final Map<String, KnowledgeRelationship> _storage = {};

  @override
  Future<void> save(KnowledgeRelationship relationship) async {
    _storage[relationship.relationshipId] = relationship;
  }

  @override
  Future<void> delete(String relationshipId) async {
    _storage.remove(relationshipId);
  }

  @override
  Future<KnowledgeRelationship?> findById(String relationshipId) async {
    return _storage[relationshipId];
  }

  @override
  Future<List<KnowledgeRelationship>> getOutgoingRelationships(
      String sourceKnowledgeId) async {
    return _storage.values
        .where((rel) => rel.sourceKnowledgeId == sourceKnowledgeId)
        .toList();
  }

  @override
  Future<List<KnowledgeRelationship>> getIncomingRelationships(
      String targetKnowledgeId) async {
    return _storage.values
        .where((rel) => rel.targetKnowledgeId == targetKnowledgeId)
        .toList();
  }

  @override
  Future<List<KnowledgeRelationship>> getRelationshipsByType(
      RelationshipType type) async {
    return _storage.values
        .where((rel) => rel.relationshipType == type)
        .toList();
  }
}

void main() {
  group('RelationshipQueryService Tests', () {
    late FakeRelationshipRepository repository;
    late RelationshipQueryService queryService;

    final rel1 = KnowledgeRelationship(
      relationshipId: 'rel-1',
      sourceKnowledgeId: 'node-A',
      targetKnowledgeId: 'node-B',
      relationshipType: RelationshipType.prerequisiteOf,
      confidence: 0.9,
    );

    final rel2 = KnowledgeRelationship(
      relationshipId: 'rel-2',
      sourceKnowledgeId: 'node-A',
      targetKnowledgeId: 'node-C',
      relationshipType: RelationshipType.relatedTo,
      confidence: 0.8,
    );

    final rel3 = KnowledgeRelationship(
      relationshipId: 'rel-3',
      sourceKnowledgeId: 'node-D',
      targetKnowledgeId: 'node-A',
      relationshipType: RelationshipType.prerequisiteOf,
      confidence: 0.95,
    );

    setUp(() async {
      repository = FakeRelationshipRepository();
      await repository.save(rel1);
      await repository.save(rel2);
      await repository.save(rel3);
      queryService = RelationshipQueryService(repository);
    });

    test('getOutgoingRelationships returns only edges originating from nodeId',
        () async {
      final outgoing = await queryService.getOutgoingRelationships('node-A');
      expect(outgoing.length, equals(2));
      expect(outgoing.map((e) => e.relationshipId),
          containsAll(['rel-1', 'rel-2']));
    });

    test('getIncomingRelationships returns only edges pointing to nodeId',
        () async {
      final incoming = await queryService.getIncomingRelationships('node-A');
      expect(incoming.length, equals(1));
      expect(incoming.first.relationshipId, equals('rel-3'));
      expect(incoming.first.sourceKnowledgeId, equals('node-D'));
    });

    test(
        'getRelationshipsByType with outgoingOnly=true returns matching outgoing edges',
        () async {
      final result = await queryService.getRelationshipsByType(
        'node-A',
        RelationshipType.prerequisiteOf,
        outgoingOnly: true,
      );
      expect(result.length, equals(1));
      expect(result.first.relationshipId, equals('rel-1'));
    });

    test(
        'getRelationshipsByType with outgoingOnly=false returns matching incoming and outgoing edges',
        () async {
      final result = await queryService.getRelationshipsByType(
        'node-A',
        RelationshipType.prerequisiteOf,
        outgoingOnly: false,
      );
      expect(result.length, equals(2));
      expect(
          result.map((e) => e.relationshipId), containsAll(['rel-1', 'rel-3']));
    });

    test('getAllRelationships returns all incoming and outgoing relationships',
        () async {
      final all = await queryService.getAllRelationships('node-A');
      expect(all.length, equals(3));
      expect(all.map((e) => e.relationshipId),
          containsAll(['rel-1', 'rel-2', 'rel-3']));
    });

    test('querying non-existent or empty nodeId returns empty list', () async {
      expect(await queryService.getOutgoingRelationships(''), isEmpty);
      expect(
          await queryService.getIncomingRelationships('non-existent'), isEmpty);
    });
  });
}
