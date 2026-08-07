import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_current_affairs/garuda_current_affairs.dart';

void main() {
  group('CurrentAffairsTimeline Tests', () {
    late List<CurrentAffairsKnowledgeObject> mockObjects;

    setUp(() {
      final e1 = NewsEvent(
        id: 'timeline_1',
        headline: 'Event Jan 2026',
        summary: 'Summary 1',
        content: 'Content 1',
        officialSource: 'PIB',
        publicationDate: DateTime(2026, 1, 15),
        category: CurrentAffairsCategory.polity,
        subcategory: 'Executive',
      );

      final e2 = NewsEvent(
        id: 'timeline_2',
        headline: 'Event Feb 2026',
        summary: 'Summary 2',
        content: 'Content 2',
        officialSource: 'RBI',
        publicationDate: DateTime(2026, 2, 20),
        category: CurrentAffairsCategory.economy,
        subcategory: 'Banking',
      );

      final e3 = NewsEvent(
        id: 'timeline_3',
        headline: 'Event Mar 2026',
        summary: 'Summary 3',
        content: 'Content 3',
        officialSource: 'ISRO',
        publicationDate: DateTime(2026, 3, 25),
        category: CurrentAffairsCategory.scienceAndTechnology,
        subcategory: 'Space',
      );

      mockObjects = [
        CurrentAffairsMapper.mapToKnowledgeObject(e1),
        CurrentAffairsMapper.mapToKnowledgeObject(e2),
        CurrentAffairsMapper.mapToKnowledgeObject(e3),
      ];
    });

    test('should generate monthly timeline buckets', () {
      final timeline = CurrentAffairsTimeline.generateTimeline(
        objects: mockObjects,
        frequency: DigestFrequency.monthly,
      );

      expect(timeline.length, equals(3));
      expect(timeline.any((b) => b.label == '2026-01'), isTrue);
      expect(timeline.any((b) => b.label == '2026-02'), isTrue);
      expect(timeline.any((b) => b.label == '2026-03'), isTrue);
    });

    test('should generate theme-wise timeline buckets', () {
      final timeline = CurrentAffairsTimeline.generateTimeline(
        objects: mockObjects,
        frequency: DigestFrequency.themeWise,
      );

      expect(timeline.length, equals(3));
      expect(timeline.any((b) => b.label == 'Polity'), isTrue);
      expect(timeline.any((b) => b.label == 'Economy'), isTrue);
      expect(timeline.any((b) => b.label == 'Science & Technology'), isTrue);
    });

    test('should generate topic-wise timeline buckets', () {
      final timeline = CurrentAffairsTimeline.generateTimeline(
        objects: mockObjects,
        frequency: DigestFrequency.topicWise,
      );

      expect(timeline.length, equals(3));
      expect(timeline.any((b) => b.label == 'Executive'), isTrue);
      expect(timeline.any((b) => b.label == 'Banking'), isTrue);
      expect(timeline.any((b) => b.label == 'Space'), isTrue);
    });

    test('should filter by category during timeline generation', () {
      final timeline = CurrentAffairsTimeline.generateTimeline(
        objects: mockObjects,
        frequency: DigestFrequency.monthly,
        categoryFilter: CurrentAffairsCategory.economy,
      );

      expect(timeline.length, equals(1));
      expect(timeline.first.label, equals('2026-02'));
    });
  });
}
