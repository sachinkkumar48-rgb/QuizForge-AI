import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('CurrentAffairsParser Tests', () {
    final parser = CurrentAffairsParser();
    final pubDate = DateTime.parse('2026-07-22T08:30:00.000Z');

    test(
        'validate returns valid result for complete items and invalid for missing fields',
        () {
      final validItem = CurrentAffairsItem(
        id: 'ca-100',
        title: 'Reserve Bank of India Monetary Policy',
        source: 'RBI Bulletin',
        content:
            'The Monetary Policy Committee decided to keep the repo rate unchanged.',
        summary: 'Repo rate kept unchanged.',
        category: 'Economy',
        tags: ['RBI', 'Monetary Policy'],
      );

      final result = parser.validate(validItem);
      expect(result.isValid, isTrue);
      expect(result.hasErrors, isFalse);

      final invalidItem = CurrentAffairsItem(
        id: '',
        title: '  ',
        content: '',
      );

      final invalidResult = parser.validate(invalidItem);
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errors.length, greaterThanOrEqualTo(3));
    });

    test(
        'normalize sanitizes whitespace in title, content, summary, and deduplicates tags',
        () {
      final rawItem = CurrentAffairsItem(
        id: 'ca-101',
        title: '  Monetary   Policy   Update  \r\n',
        source: ' PIB  ',
        summary: ' Summary   text  ',
        content:
            'Paragraph 1 content.\r\n\r\n\r\nParagraph 2 with   extra   spaces.',
        category: ' General ',
        tags: [' Polity ', 'Economy ', 'Polity', '  '],
        relatedSubjects: [' GS Paper III ', 'GS Paper III'],
      );

      final normalized = parser.normalize(rawItem);

      expect(normalized.title, equals('Monetary Policy Update'));
      expect(normalized.source, equals('PIB'));
      expect(normalized.summary, equals('Summary text'));
      expect(normalized.content,
          equals('Paragraph 1 content.\n\nParagraph 2 with extra spaces.'));
      expect(normalized.tags, containsAll(['Polity', 'Economy']));
      expect(normalized.relatedSubjects, equals(['GS Paper III']));
    });

    test('identifyCategory infers category when unassigned or General', () {
      final item = CurrentAffairsItem(
        id: 'ca-102',
        title: 'RBI Monetary Policy Committee Announcement',
        content:
            'The repo rate inflation targets remain under supervision by RBI.',
        category: 'General',
      );

      final category = parser.identifyCategory(item);
      expect(category, equals('Economy'));
    });

    test('assignTags merges category and cleans tags', () {
      final item = CurrentAffairsItem(
        id: 'ca-103',
        title: 'Coastal Management Ruling',
        content: 'National Green Tribunal ruling on coastal regulations.',
        category: 'Environment',
        tags: ['Coastal', 'Judicial'],
      );

      final tags = parser.assignTags(item);
      expect(tags, containsAll(['Coastal', 'Judicial', 'Environment']));
    });

    test('extractMetadata preserves source, date, category, tags, and subjects',
        () {
      final item = CurrentAffairsItem(
        id: 'ca-104',
        title: 'National Green Tribunal Ruling',
        source: 'The Hindu',
        publicationDate: pubDate,
        summary: 'NGT ruling summary.',
        content:
            'NGT directs coastal states to prepare Coastal Zone Management Plans.',
        category: 'Environment',
        tags: ['Environment', 'Judicial'],
        relatedSubjects: ['GS Paper III'],
      );

      final metadata = parser.extractMetadata(item);

      expect(metadata['itemId'], equals('ca-104'));
      expect(metadata['source'], equals('The Hindu'));
      expect(metadata['publicationDate'], equals(pubDate.toIso8601String()));
      expect(metadata['category'], equals('Environment'));
      expect(metadata['tags'], equals(['Environment', 'Judicial']));
      expect(metadata['relatedSubjects'], equals(['GS Paper III']));
      expect(metadata['contentType'], equals('current_affairs'));
    });
  });
}
