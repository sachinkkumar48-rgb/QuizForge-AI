import 'package:flutter_test/flutter_test.dart';
import 'package:titan_search/titan_search.dart';

void main() {
  group('RankingEngine Tests', () {
    const engine = RankingEngine();
    final parser = QueryParser();
    final now = DateTime.now();

    final item1 = SearchIndexItem(
      id: 'idx_1',
      contentId: 'c_1',
      title: 'Indian Constitution and Fundamental Rights',
      content: 'Detailed analysis of Article 14 to 32.',
      scope: SearchScope.notes,
      conceptIds: const ['constitution', 'fundamental rights'],
      tags: const ['polity'],
      timestamp: now,
    );

    final item2 = SearchIndexItem(
      id: 'idx_2',
      contentId: 'c_2',
      title: 'Economic Survey Overview',
      content: 'GDP growth rate and fiscal deficit metrics.',
      scope: SearchScope.currentAffairs,
      conceptIds: const ['economy'],
      tags: const ['economy'],
      timestamp: now.subtract(const Duration(days: 100)),
    );

    test('Ranks items by keyword match relevance', () {
      final query = SearchQuery(rawQuery: 'Fundamental Rights');
      final parsed = parser.parse(query);

      final ranked = engine.rank(
        candidates: [item1, item2],
        parsedQuery: parsed,
      );

      expect(ranked.isNotEmpty, isTrue);
      expect(ranked.first.id, 'idx_1');
      expect(ranked.first.score, greaterThan(0.40));
    });

    test('Boosts score when recommendedContentIds match', () {
      final query = SearchQuery(rawQuery: 'Overview');
      final parsed = parser.parse(query);

      final unboosted = engine.rank(
        candidates: [item2],
        parsedQuery: parsed,
      );

      final boosted = engine.rank(
        candidates: [item2],
        parsedQuery: parsed,
        recommendedContentIds: {'c_2'},
      );

      expect(boosted.first.score, greaterThan(unboosted.first.score));
      expect(boosted.first.recommendationScore, 1.0);
    });

    test('Applies user topic weight from learning profile', () {
      final query = SearchQuery(rawQuery: 'Deficit');
      final parsed = parser.parse(query);

      final ranked = engine.rank(
        candidates: [item2],
        parsedQuery: parsed,
        userTopicWeights: {'economy': 0.9},
      );

      expect(ranked.first.learningProfileScore, 0.9);
    });
  });
}
