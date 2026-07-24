import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

import 'relationship_query_service_test.dart';

class FakeKnowledgeRepository implements KnowledgeRepository {
  final Map<String, KnowledgeObject> _storage = {};

  @override
  Future<void> save(KnowledgeObject object) async {
    _storage[object.id] = object;
  }

  @override
  Future<void> update(KnowledgeObject object) async {
    _storage[object.id] = object;
  }

  @override
  Future<void> delete(String id) async {
    _storage.remove(id);
  }

  @override
  Future<KnowledgeObject?> findById(String id) async {
    return _storage[id];
  }

  @override
  Future<List<KnowledgeObject>> search(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return _storage.values.toList();
    return _storage.values.where((obj) {
      return obj.title.toLowerCase().contains(clean) ||
          obj.summary.toLowerCase().contains(clean) ||
          obj.subjects.any((s) => s.toLowerCase().contains(clean)) ||
          obj.topics.any((t) => t.toLowerCase().contains(clean)) ||
          obj.keywords.any((k) => k.toLowerCase().contains(clean));
    }).toList();
  }
}

void main() {
  group('RecommendationService Tests', () {
    late FakeRelationshipRepository relRepository;
    late FakeKnowledgeRepository knowledgeRepository;
    late RelationshipQueryService queryService;
    late KnowledgeTraversalService traversalService;
    late RecommendationService recommendationService;

    final kObjA = KnowledgeObject(
      id: 'k-A',
      type: KnowledgeType.pdf,
      title: 'Polity Basics',
      summary: 'Summary of Polity Basics',
      source: 'src-A',
    );

    final kObjB = KnowledgeObject(
      id: 'k-B',
      type: KnowledgeType.pdf,
      title: 'Directive Principles',
      summary: 'Summary of Directive Principles',
      source: 'src-B',
    );

    final kObjC = KnowledgeObject(
      id: 'k-C',
      type: KnowledgeType.pdf,
      title: 'Fundamental Duties',
      summary: 'Summary of Fundamental Duties',
      source: 'src-C',
    );

    setUp(() async {
      relRepository = FakeRelationshipRepository();
      knowledgeRepository = FakeKnowledgeRepository();

      await knowledgeRepository.save(kObjA);
      await knowledgeRepository.save(kObjB);
      await knowledgeRepository.save(kObjC);

      queryService = RelationshipQueryService(relRepository);
      traversalService = KnowledgeTraversalService(queryService);

      recommendationService = RecommendationService(
        knowledgeRepository: knowledgeRepository,
        queryService: queryService,
        traversalService: traversalService,
      );
    });

    test(
        'relatedKnowledge returns connected knowledge objects ordered by confidence',
        () async {
      await relRepository.save(KnowledgeRelationship(
        relationshipId: 'r1',
        sourceKnowledgeId: 'k-A',
        targetKnowledgeId: 'k-B',
        relationshipType: RelationshipType.relatedTo,
        confidence: 0.8,
      ));
      await relRepository.save(KnowledgeRelationship(
        relationshipId: 'r2',
        sourceKnowledgeId: 'k-A',
        targetKnowledgeId: 'k-C',
        relationshipType: RelationshipType.expands,
        confidence: 0.95,
      ));

      final recommendations =
          await recommendationService.relatedKnowledge('k-A', limit: 5);
      expect(recommendations.length, equals(2));
      // Higher confidence (0.95) kObjC first, then kObjB (0.8)
      expect(recommendations.first.id, equals('k-C'));
      expect(recommendations.last.id, equals('k-B'));
    });

    test(
        'prerequisiteKnowledge returns prerequisite objects required for target node',
        () async {
      // kObjA is a prerequisite of kObjB
      await relRepository.save(KnowledgeRelationship(
        relationshipId: 'r1',
        sourceKnowledgeId: 'k-A',
        targetKnowledgeId: 'k-B',
        relationshipType: RelationshipType.prerequisiteOf,
        confidence: 0.9,
      ));

      final prereqs = await recommendationService.prerequisiteKnowledge('k-B');
      expect(prereqs.length, equals(1));
      expect(prereqs.first.id, equals('k-A'));
      expect(prereqs.first.title, equals('Polity Basics'));
    });

    test(
        'nextTopics suggests next study topics based on prerequisiteOf and expands edges',
        () async {
      // kObjA is a prerequisite for kObjB, and expands kObjC
      await relRepository.save(KnowledgeRelationship(
        relationshipId: 'r1',
        sourceKnowledgeId: 'k-A',
        targetKnowledgeId: 'k-B',
        relationshipType: RelationshipType.prerequisiteOf,
        confidence: 0.9,
      ));
      await relRepository.save(KnowledgeRelationship(
        relationshipId: 'r2',
        sourceKnowledgeId: 'k-A',
        targetKnowledgeId: 'k-C',
        relationshipType: RelationshipType.expands,
        confidence: 0.85,
      ));

      final next = await recommendationService.nextTopics('k-A', limit: 5);
      expect(next.length, equals(2));
      expect(next.first.id, equals('k-B')); // prerequisiteOf prioritized first
      expect(next.last.id, equals('k-C'));
    });
  });
}
