import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('CurrentAffairsItem Tests', () {
    final pubDate = DateTime.parse('2026-07-23T10:00:00.000Z');

    test('initializes correctly with required and default parameters', () {
      final item = CurrentAffairsItem(
        id: 'ca-001',
        title: 'GST Council 53rd Meeting Outcomes',
        summary: 'Key highlights of GST rate rationalization decisions.',
        content:
            'The GST Council met in New Delhi to discuss tax rate rationalization.',
        publicationDate: pubDate,
        source: 'PIB',
        category: 'Economy',
        tags: ['Economy', 'Taxation'],
        relatedSubjects: ['GS Paper III'],
      );

      expect(item.id, equals('ca-001'));
      expect(item.title, equals('GST Council 53rd Meeting Outcomes'));
      expect(item.summary,
          equals('Key highlights of GST rate rationalization decisions.'));
      expect(
          item.content,
          equals(
              'The GST Council met in New Delhi to discuss tax rate rationalization.'));
      expect(item.publicationDate, equals(pubDate));
      expect(item.source, equals('PIB'));
      expect(item.category, equals('Economy'));
      expect(item.tags, equals(['Economy', 'Taxation']));
      expect(item.relatedSubjects, equals(['GS Paper III']));
    });

    test('guarantees immutability of tags and relatedSubjects collections', () {
      final item = CurrentAffairsItem(
        id: 'ca-002',
        title: 'ISRO NISAR Mission Progress',
        content:
            'ISRO and NASA joint NISAR satellite undergoing final integration tests.',
        tags: ['Science', 'Space'],
        relatedSubjects: ['Science & Tech'],
      );

      expect(() => (item.tags as List).add('Defence'), throwsUnsupportedError);
      expect(() => (item.relatedSubjects as List).add('GS Paper III'),
          throwsUnsupportedError);
    });

    test('copyWith modifies specified attributes while preserving others', () {
      final original = CurrentAffairsItem(
        id: 'ca-003',
        title: 'Bhashini AI Language Translation',
        content:
            'Bhashini mission empowers multilingual access to digital public infrastructure.',
        category: 'Technology',
        tags: ['AI'],
      );

      final copy = original.copyWith(
        source: 'PIB Press Release',
        category: 'Science & Technology',
        tags: ['AI', 'Language'],
      );

      expect(copy.id, equals('ca-003'));
      expect(copy.title, equals(original.title));
      expect(copy.source, equals('PIB Press Release'));
      expect(copy.category, equals('Science & Technology'));
      expect(copy.tags, equals(['AI', 'Language']));
    });

    test('toMap and fromMap achieve full round-trip serialization', () {
      final item = CurrentAffairsItem(
        id: 'ca-004',
        title: 'SCO Summit 2024 Joint Declaration',
        summary: 'Astana declaration adopted by SCO leaders.',
        content:
            'Member states adopted Astana Declaration promoting regional stability.',
        publicationDate: pubDate,
        source: 'Indian Express',
        category: 'International Relations',
        tags: ['IR', 'Diplomacy'],
        relatedSubjects: ['GS Paper II'],
      );

      final map = item.toMap();
      final restored = CurrentAffairsItem.fromMap(map);

      expect(restored, equals(item));
      expect(restored.id, equals('ca-004'));
      expect(restored.publicationDate, equals(pubDate));
      expect(restored.category, equals('International Relations'));
    });
  });
}
