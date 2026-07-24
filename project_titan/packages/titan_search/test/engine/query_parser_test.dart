import 'package:flutter_test/flutter_test.dart';
import 'package:titan_search/titan_search.dart';

void main() {
  group('QueryParser Tests', () {
    final parser = QueryParser();

    test('Parses raw tokens and extracts exact phrases', () {
      final query = SearchQuery(rawQuery: 'upsc "fundamental rights" polity');
      final parsed = parser.parse(query);

      expect(parsed.tokens, contains('upsc'));
      expect(parsed.tokens, contains('polity'));
      expect(parsed.exactPhrases, contains('fundamental rights'));
    });

    test('Expands UPSC synonyms when enabled', () {
      final query = SearchQuery(rawQuery: 'polity', includeSynonyms: true);
      final parsed = parser.parse(query);

      expect(parsed.synonyms.containsKey('polity'), isTrue);
      expect(parsed.expandedConcepts, contains('constitution'));
      expect(parsed.expandedConcepts, contains('governance'));
    });

    test('Does not expand synonyms when disabled', () {
      final query = SearchQuery(rawQuery: 'polity', includeSynonyms: false);
      final parsed = parser.parse(query);

      expect(parsed.synonyms, isEmpty);
      expect(parsed.expandedConcepts, isEmpty);
    });
  });
}
