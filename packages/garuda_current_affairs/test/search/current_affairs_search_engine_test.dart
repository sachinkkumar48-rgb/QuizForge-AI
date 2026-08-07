import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsSearchEngine Tests', () {
    late List<CurrentAffairsKnowledgeObject> mockObjects;

    setUp(() {
      final e1 = NewsEvent(
        id: 'search_1',
        headline: 'Digital Personal Data Protection Act Implementation',
        summary: 'Rules issued by Ministry of Electronics and IT.',
        content: 'Data fiduciary compliance guidelines.',
        officialSource: 'PIB',
        ministry: 'Ministry of Electronics and IT',
        publicationDate: DateTime(2026, 3, 10),
        category: CurrentAffairsCategory.governance,
        keywords: ['DPDP', 'Data Protection', 'Privacy'],
      );

      final e2 = NewsEvent(
        id: 'search_2',
        headline: 'Cabinet approves PM-KISAN funds',
        summary: 'Direct benefit transfer for farmers.',
        content: 'Agricultural support scheme.',
        officialSource: 'PIB',
        ministry: 'Ministry of Agriculture',
        publicationDate: DateTime(2026, 4, 15),
        category: CurrentAffairsCategory.agriculture,
        keywords: ['PM-KISAN', 'Farmers', 'Agriculture'],
      );

      mockObjects = [
        CurrentAffairsMapper.mapToKnowledgeObject(e1),
        CurrentAffairsMapper.mapToKnowledgeObject(e2),
      ];
    });

    test('should search by keyword across headline, summary, and keywords', () {
      const query = CurrentAffairsSearchQuery(keyword: 'Data Protection');
      final results = CurrentAffairsSearchEngine.search(objects: mockObjects, query: query);

      expect(results.length, equals(1));
      expect(results.first.id, equals('search_1'));
    });

    test('should search by ministry', () {
      const query = CurrentAffairsSearchQuery(ministry: 'Agriculture');
      final results = CurrentAffairsSearchEngine.search(objects: mockObjects, query: query);

      expect(results.length, equals(1));
      expect(results.first.id, equals('search_2'));
    });

    test('should search by linked Act', () {
      const query = CurrentAffairsSearchQuery(act: 'Digital Personal Data Protection Act');
      final results = CurrentAffairsSearchEngine.search(objects: mockObjects, query: query);


      expect(results.length, equals(1));
      expect(results.first.id, equals('search_1'));
    });

    test('should search by date range', () {
      final query = CurrentAffairsSearchQuery(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 30),
      );
      final results = CurrentAffairsSearchEngine.search(objects: mockObjects, query: query);

      expect(results.length, equals(1));
      expect(results.first.id, equals('search_2'));
    });

    test('should generate autocomplete suggestions', () {
      final suggestions = CurrentAffairsSearchEngine.autocomplete(
        objects: mockObjects,
        prefix: 'Digi',
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.any((s) => s.contains('Digital')), isTrue);
    });
  });
}
