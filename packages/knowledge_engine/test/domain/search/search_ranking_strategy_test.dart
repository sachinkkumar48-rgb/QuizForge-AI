import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultSearchRankingStrategy Tests', () {
    const rankingStrategy = DefaultSearchRankingStrategy();

    final objExact = KnowledgeObject(
      id: 'k-exact',
      type: KnowledgeType.pdf,
      title: 'Fundamental Rights',
      summary: 'Detailed guide on Fundamental Rights under Part III',
      source: 'src-1',
      subjects: ['Polity'],
      topics: ['Rights'],
      keywords: ['Article14', 'Article19'],
    );

    final objPartial = KnowledgeObject(
      id: 'k-partial',
      type: KnowledgeType.pdf,
      title: 'Indian Constitution Rights Overview',
      summary: 'Basic summary of constitutional features',
      source: 'src-2',
      subjects: ['Polity'],
      topics: ['Overview'],
    );

    final objUnrelated = KnowledgeObject(
      id: 'k-unrelated',
      type: KnowledgeType.pdf,
      title: 'Physical Geography',
      summary: 'Plate tectonics and landforms',
      source: 'src-3',
      subjects: ['Geography'],
    );

    test('exact match gets highest relevance score boost', () {
      final query = KnowledgeSearchQuery(freeText: 'Fundamental Rights');

      final scoreExact = rankingStrategy.calculateScore(objExact, query);
      final scorePartial = rankingStrategy.calculateScore(objPartial, query);

      expect(scoreExact, greaterThan(scorePartial));
      expect(scoreExact, greaterThanOrEqualTo(100.0));
    });

    test('graph proximity adds proximity score boost', () {
      final query = KnowledgeSearchQuery(freeText: 'Rights');

      final scoreWithoutGraph =
          rankingStrategy.calculateScore(objPartial, query);
      final scoreWithGraph = rankingStrategy.calculateScore(
        objPartial,
        query,
        connectedGraphNodeIds: {'k-partial'},
      );

      expect(scoreWithGraph, equals(scoreWithoutGraph + 15.0));
    });

    test('rank orders candidates by score descending relevance', () {
      final query = KnowledgeSearchQuery(freeText: 'Fundamental Rights');
      final candidates = [objUnrelated, objPartial, objExact];

      final ranked = rankingStrategy.rank(candidates, query);

      expect(ranked.first.id, equals('k-exact'));
      expect(ranked[1].id, equals('k-partial'));
      expect(ranked.last.id, equals('k-unrelated'));
    });

    test('rank performs deterministic tie-breaking by ID when scores match',
        () {
      final objA = KnowledgeObject(
        id: 'k-001',
        type: KnowledgeType.pdf,
        title: 'Sameness Test',
        summary: 'Same content summary',
        source: 'src-A',
      );
      final objB = KnowledgeObject(
        id: 'k-002',
        type: KnowledgeType.pdf,
        title: 'Sameness Test',
        summary: 'Same content summary',
        source: 'src-B',
      );

      final query = KnowledgeSearchQuery(freeText: 'Sameness');

      final run1 = rankingStrategy.rank([objB, objA], query);
      final run2 = rankingStrategy.rank([objA, objB], query);

      expect(run1.map((e) => e.id), equals(['k-001', 'k-002']));
      expect(run2.map((e) => e.id), equals(['k-001', 'k-002']));
    });

    test('rank respects titleAscending and titleDescending sort orders', () {
      final queryAsc =
          KnowledgeSearchQuery(sortOrder: SearchSortOrder.titleAscending);
      final queryDesc =
          KnowledgeSearchQuery(sortOrder: SearchSortOrder.titleDescending);

      final candidates = [objPartial, objExact, objUnrelated];

      final rankedAsc = rankingStrategy.rank(candidates, queryAsc);
      expect(rankedAsc.first.title, equals('Fundamental Rights'));

      final rankedDesc = rankingStrategy.rank(candidates, queryDesc);
      expect(rankedDesc.first.title, equals('Physical Geography'));
    });
  });
}
