import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

import '../services/recommendation_service_test.dart';
import '../services/relationship_query_service_test.dart';

void main() {
  group('KnowledgeSearchService Tests', () {
    late FakeKnowledgeRepository knowledgeRepository;
    late FakeRelationshipRepository relRepository;
    late RelationshipQueryService queryService;
    late KnowledgeTraversalService traversalService;
    late KnowledgeSearchService searchService;

    final kObj1 = KnowledgeObject(
      id: 'k-001',
      type: KnowledgeType.pdf,
      title: 'Preamble and Fundamental Rights',
      summary: 'Basic structure doctrine and Article 14-32',
      source: 'src-1',
      subjects: ['Polity'],
      topics: ['Preamble', 'Rights'],
      keywords: ['UPSC', 'Law'],
      language: 'en',
    );

    final kObj2 = KnowledgeObject(
      id: 'k-002',
      type: KnowledgeType.article,
      title: 'Directive Principles of State Policy',
      summary: 'Part IV DPSP guidelines',
      source: 'src-2',
      subjects: ['Polity'],
      topics: ['DPSP'],
      keywords: ['State', 'Policy'],
      language: 'en',
    );

    final kObj3 = KnowledgeObject(
      id: 'k-003',
      type: KnowledgeType.pyq,
      title: 'UPSC 2024 Prelims Polity Question',
      summary: 'Which article governs right to privacy?',
      source: 'src-3',
      subjects: ['Polity'],
      topics: ['Rights'],
      keywords: ['PYQ', '2024'],
      language: 'en',
    );

    final kObj4 = KnowledgeObject(
      id: 'k-004',
      type: KnowledgeType.pdf,
      title: 'Monetary Policy and Inflation',
      summary: 'RBI interest rates and repo rate',
      source: 'src-4',
      subjects: ['Economy'],
      topics: ['Inflation'],
      keywords: ['RBI', 'Money'],
      language: 'en',
    );

    setUp(() async {
      knowledgeRepository = FakeKnowledgeRepository();
      relRepository = FakeRelationshipRepository();

      await knowledgeRepository.save(kObj1);
      await knowledgeRepository.save(kObj2);
      await knowledgeRepository.save(kObj3);
      await knowledgeRepository.save(kObj4);

      queryService = RelationshipQueryService(relRepository);
      traversalService = KnowledgeTraversalService(queryService);

      searchService = KnowledgeSearchService(
        knowledgeRepository: knowledgeRepository,
        queryService: queryService,
        traversalService: traversalService,
      );
    });

    test('search filters by freeText and ranks exact match top', () async {
      final query = KnowledgeSearchQuery(freeText: 'Rights');
      final result = await searchService.search(query);

      expect(result.totalCount, greaterThanOrEqualTo(2));
      expect(result.matchedObjects.first.subjects, contains('Polity'));
    });

    test('search filters by subjects and knowledgeTypes correctly', () async {
      final query = KnowledgeSearchQuery(
        subjects: ['Polity'],
        knowledgeTypes: [KnowledgeType.article],
      );
      final result = await searchService.search(query);

      expect(result.totalCount, equals(1));
      expect(result.matchedObjects.first.id, equals('k-002'));
    });

    test('search applies pagination with limit and offset', () async {
      final queryAll = KnowledgeSearchQuery(limit: 2, offset: 0);
      final page1 = await searchService.search(queryAll);
      expect(page1.matchedObjects.length, equals(2));

      final queryPage2 = KnowledgeSearchQuery(limit: 2, offset: 2);
      final page2 = await searchService.search(queryPage2);
      expect(page2.matchedObjects.length, equals(2));

      expect(
        page1.matchedObjects.map((e) => e.id).toSet().intersection(
              page2.matchedObjects.map((e) => e.id).toSet(),
            ),
        isEmpty,
      );
    });

    test('searchByTopic shortcut filters by topic', () async {
      final result = await searchService.searchByTopic('Rights');

      expect(result.totalCount, equals(2));
      expect(result.matchedObjects.map((e) => e.id),
          containsAll(['k-001', 'k-003']));
    });

    test('searchBySubject shortcut filters by subject', () async {
      final result = await searchService.searchBySubject('Economy');

      expect(result.totalCount, equals(1));
      expect(result.matchedObjects.first.id, equals('k-004'));
    });

    test('searchByTag shortcut filters by keyword tag', () async {
      final result = await searchService.searchByTag('RBI');

      expect(result.totalCount, equals(1));
      expect(result.matchedObjects.first.id, equals('k-004'));
    });

    test('searchRelated uses graph traversal to discover connected entities',
        () async {
      await relRepository.save(KnowledgeRelationship(
        relationshipId: 'rel-10',
        sourceKnowledgeId: 'k-001',
        targetKnowledgeId: 'k-002',
        relationshipType: RelationshipType.relatedTo,
      ));

      final result = await searchService.searchRelated('k-001');

      expect(result.totalCount, equals(1));
      expect(result.matchedObjects.first.id, equals('k-002'));
    });

    test(
        'searchPrerequisites uses graph relationships to identify prerequisites',
        () async {
      await relRepository.save(KnowledgeRelationship(
        relationshipId: 'rel-11',
        sourceKnowledgeId: 'k-001',
        targetKnowledgeId: 'k-002',
        relationshipType: RelationshipType.prerequisiteOf,
      ));

      final result = await searchService.searchPrerequisites('k-002');

      expect(result.totalCount, equals(1));
      expect(result.matchedObjects.first.id, equals('k-001'));
    });

    test('searchNextTopics finds outgoing next topics from graph edges',
        () async {
      await relRepository.save(KnowledgeRelationship(
        relationshipId: 'rel-12',
        sourceKnowledgeId: 'k-001',
        targetKnowledgeId: 'k-003',
        relationshipType: RelationshipType.expands,
      ));

      final result = await searchService.searchNextTopics('k-001');

      expect(result.totalCount, equals(1));
      expect(result.matchedObjects.first.id, equals('k-003'));
    });
  });
}
