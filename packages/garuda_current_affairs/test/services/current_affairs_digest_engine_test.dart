import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsDigestEngine Tests', () {
    late List<CurrentAffairsKnowledgeObject> mockObjects;

    setUp(() {
      final e1 = NewsEvent(
        id: 'digest_1',
        headline: 'Election Commission issues Advisory on Code of Conduct',
        summary: 'Instructions for state elections.',
        content: 'Article 324 powers exercised by ECI.',
        officialSource: 'Election Commission of India (ECI)',
        publicationDate: DateTime(2026, 5, 1),
        category: CurrentAffairsCategory.polity,
      );

      final e2 = NewsEvent(
        id: 'digest_2',
        headline: 'NITI Aayog releases Innovation Index',
        summary: 'State ranking in R&D infrastructure.',
        content: 'Public governance benchmark.',
        officialSource: 'NITI Aayog',
        publicationDate: DateTime(2026, 5, 2),
        category: CurrentAffairsCategory.governance,
      );

      mockObjects = [
        CurrentAffairsMapper.mapToKnowledgeObject(e1),
        CurrentAffairsMapper.mapToKnowledgeObject(e2),
      ];
    });

    test('should generate Daily Brief digest', () {
      final digest = CurrentAffairsDigestEngine.generateDailyBrief(mockObjects);

      expect(digest.type, equals(DigestFrequency.daily));
      expect(digest.items.length, equals(2));
      expect(digest.markdownContent, contains('# DAILY UPSC Current Affairs Brief'));

      expect(digest.markdownContent, contains('Election Commission issues Advisory'));
    });

    test('should generate Weekly Brief digest', () {
      final digest = CurrentAffairsDigestEngine.generateWeeklyBrief(mockObjects);
      expect(digest.type, equals(DigestFrequency.weekly));
      expect(digest.markdownContent, contains('WEEKLY'));
    });

    test('should generate Monthly Magazine digest', () {
      final digest = CurrentAffairsDigestEngine.generateMonthlyMagazine(mockObjects);
      expect(digest.type, equals(DigestFrequency.monthly));
      expect(digest.markdownContent, contains('MONTHLY'));
    });

    test('should generate Topic Revision Sheets digest', () {
      final digest = CurrentAffairsDigestEngine.generateTopicRevisionSheets(
        mockObjects,
        topic: 'Election',
      );

      expect(digest.type, equals(DigestFrequency.topicWise));
      expect(digest.items.length, equals(1));
      expect(digest.items.first.headline, contains('Election Commission'));
    });
  });
}
