import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsSearchEngine Tests', () {
    late CurrentAffairsKnowledgeObject ko1;
    late CurrentAffairsKnowledgeObject ko2;

    setUp(() {
      final e1 = NewsEvent(
        id: 's1',
        headline: 'RBI Monetary Policy Committee announcement',
        summary: 'Repo rate kept unchanged at 6.5 percent.',
        content: 'RBI Monetary Policy announcement by Governor.',
        officialSource: 'Reserve Bank of India',
        publicationDate: DateTime(2025, 4, 1),
        category: CurrentAffairsCategory.economy,
        ministry: 'Ministry of Finance',
        keywords: ['repo rate', 'rbi', 'inflation'],
      );

      final e2 = NewsEvent(
        id: 's2',
        headline: 'Supreme Court hearing on Article 19 freedom of speech',
        summary: 'Bench deliberates on Article 19 restrictions.',
        content: 'Article 19 rights and reasonable restrictions.',
        officialSource: 'Supreme Court',
        publicationDate: DateTime(2025, 5, 1),
        category: CurrentAffairsCategory.polity,
        ministry: 'Judiciary',
        keywords: ['free speech', 'rights'],
      );

      ko1 = CurrentAffairsMapper.mapToKnowledgeObject(e1);
      ko2 = CurrentAffairsMapper.mapToKnowledgeObject(e2);
    });

    test('Filters search results by category, ministry, and keyword', () {
      final resultsCat = CurrentAffairsSearchEngine.search(
        objects: [ko1, ko2],
        query: const CurrentAffairsSearchQuery(category: CurrentAffairsCategory.economy),
      );
      expect(resultsCat.length, equals(1));
      expect(resultsCat.first.headline, contains('Monetary Policy'));

      final resultsKw = CurrentAffairsSearchEngine.search(
        objects: [ko1, ko2],
        query: const CurrentAffairsSearchQuery(keyword: 'Article 19'),
      );
      expect(resultsKw.length, equals(1));
      expect(resultsKw.first.headline, contains('Article 19'));
    });

    test('Autocomplete returns suggestions matching prefix', () {
      final suggestions = CurrentAffairsSearchEngine.autocomplete(
        objects: [ko1, ko2],
        prefix: 'repo',
      );
      expect(suggestions.isNotEmpty, isTrue);
      expect(suggestions.first.toLowerCase(), contains('repo'));
    });
  });
}
