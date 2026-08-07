import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsTimeline Tests', () {
    test('Groups events into monthly and theme-wise timeline buckets', () {
      final e1 = NewsEvent(
        id: 't1',
        headline: 'Event 1 in May 2025',
        summary: 'Summary 1',
        content: 'Content 1',
        officialSource: 'PIB',
        publicationDate: DateTime(2025, 5, 10),
        category: CurrentAffairsCategory.economy,
      );

      final e2 = NewsEvent(
        id: 't2',
        headline: 'Event 2 in April 2025',
        summary: 'Summary 2',
        content: 'Content 2',
        officialSource: 'RBI',
        publicationDate: DateTime(2025, 4, 20),
        category: CurrentAffairsCategory.economy,
      );

      final ko1 = CurrentAffairsMapper.mapToKnowledgeObject(e1);
      final ko2 = CurrentAffairsMapper.mapToKnowledgeObject(e2);

      final monthly = CurrentAffairsTimeline.generateTimeline(
        objects: [ko1, ko2],
        frequency: DigestFrequency.monthly,
      );

      expect(monthly.length, equals(2));

      final themeWise = CurrentAffairsTimeline.generateTimeline(
        objects: [ko1, ko2],
        frequency: DigestFrequency.themeWise,
      );

      expect(themeWise.length, equals(1));
      expect(themeWise.first.label, equals('Economy'));
    });
  });
}
