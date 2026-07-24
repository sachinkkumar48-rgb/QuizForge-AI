import 'package:flutter_test/flutter_test.dart';
import 'package:titan_search/titan_search.dart';

void main() {
  group('Search Models Unit Tests', () {
    final now = DateTime(2026, 7, 24, 16, 0);

    test('SearchQuery default values and copyWith', () {
      final query = SearchQuery(rawQuery: 'Polity Constitution');

      expect(query.rawQuery, 'Polity Constitution');
      expect(query.scopes.length, SearchScope.values.length);
      expect(query.includeSynonyms, isTrue);
      expect(query.fuzzyMatch, isTrue);

      final updated = query.copyWith(
        scopes: {SearchScope.notes, SearchScope.pyqs},
        exactMatchOnly: true,
      );

      expect(updated.scopes.length, 2);
      expect(updated.exactMatchOnly, isTrue);
    });

    test('SearchQuery serialization toJson and fromJson', () {
      final query = SearchQuery(
        rawQuery: 'Fundamental Rights',
        scopes: const {SearchScope.pdf, SearchScope.notes},
        limit: 15,
      );

      final json = query.toJson();
      final restored = SearchQuery.fromJson(json);

      expect(restored.rawQuery, query.rawQuery);
      expect(restored.scopes.contains(SearchScope.pdf), isTrue);
      expect(restored.limit, 15);
    });

    test('SearchResult serialization toJson and fromJson', () {
      final result = SearchResult(
        id: 'res_1',
        title: 'Article 21 Right to Life',
        snippet: 'Article 21 guarantees personal liberty...',
        scope: SearchScope.notes,
        score: 0.95,
        keywordScore: 0.9,
        knowledgeGraphScore: 0.8,
        matchedTerms: const ['Article 21', 'Liberty'],
        timestamp: now,
      );

      final json = result.toJson();
      final restored = SearchResult.fromJson(json);

      expect(restored.id, result.id);
      expect(restored.title, result.title);
      expect(restored.scope, SearchScope.notes);
      expect(restored.score, 0.95);
      expect(restored.matchedTerms, contains('Article 21'));
    });

    test('SearchIndexItem creation and copyWith', () {
      final item = SearchIndexItem(
        id: 'idx_1',
        contentId: 'c_100',
        title: 'Directive Principles',
        content: 'DPSP are non-justiciable principles in Part IV.',
        scope: SearchScope.notes,
        conceptIds: const ['DPSP', 'Polity'],
        tags: const ['upsc', 'polity'],
        timestamp: now,
      );

      expect(item.id, 'idx_1');
      expect(item.conceptIds, contains('DPSP'));

      final updated = item.copyWith(accessCount: 5);
      expect(updated.accessCount, 5);
      expect(updated.title, item.title);
    });
  });
}
