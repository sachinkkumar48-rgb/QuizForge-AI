import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsParser Tests', () {
    test('should correctly parse raw JSON into NewsEvent instance', () {
      final json = {
        'id': 'pib_1001',
        'headline': 'Supreme Court upholds Constitution Amendment',
        'summary': 'Bench examines Article 368 and basic structure.',
        'content': 'Comprehensive judgment on judicial review.',
        'officialSource': 'Supreme Court of India',
        'sourceUrl': 'https://main.sci.gov.in/judgment/1001',
        'publicationDate': '2026-02-20T10:00:00Z',
        'ministry': 'Judiciary',
        'importance': 'critical',
        'keywords': ['Constitution', 'Judicial Review', 'Article 368'],
        'tags': ['Polity', 'Landmark Case'],
        'evidenceIds': ['ev_sc_1001'],
      };

      final newsEvent = CurrentAffairsParser.parseRawJson(json);

      expect(newsEvent.id, equals('pib_1001'));
      expect(newsEvent.headline, equals('Supreme Court upholds Constitution Amendment'));
      expect(newsEvent.category, equals(CurrentAffairsCategory.polity));
      expect(newsEvent.importance, equals(CurrentAffairsImportance.critical));
      expect(newsEvent.keywords, contains('Judicial Review'));
      expect(newsEvent.evidenceIds, contains('ev_sc_1001'));
    });

    test('should handle missing optional fields gracefully with defaults', () {
      final json = <String, dynamic>{
        'title': 'DRDO conducts flight test of missile',
      };

      final newsEvent = CurrentAffairsParser.parseRawJson(json);

      expect(newsEvent.headline, equals('DRDO conducts flight test of missile'));
      expect(newsEvent.category, equals(CurrentAffairsCategory.security));
      expect(newsEvent.country, equals('India'));
      expect(newsEvent.importance, equals(CurrentAffairsImportance.medium));
      expect(newsEvent.id, startsWith('event_'));
    });
  });
}
