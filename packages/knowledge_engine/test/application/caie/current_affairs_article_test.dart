import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('CurrentAffairsArticle Tests', () {
    final now = DateTime.now();

    test('initializes correctly with required parameters', () {
      final article = CurrentAffairsArticle(
        id: 'ca-001',
        title: 'GST Council 53rd Meeting Outcomes',
        source: 'PIB',
        content:
            'The GST Council met in New Delhi to discuss tax rate rationalization.',
        publicationDate: now,
        tags: ['Economy', 'Taxation'],
      );

      expect(article.id, equals('ca-001'));
      expect(article.title, equals('GST Council 53rd Meeting Outcomes'));
      expect(article.source, equals('PIB'));
      expect(article.publicationDate, equals(now));
      expect(article.tags, containsAll(['Economy', 'Taxation']));
      expect(article.language, equals('en'));
    });

    test('guarantees immutability of tags collection', () {
      final article = CurrentAffairsArticle(
        id: 'ca-002',
        title: 'ISRO NISAR Mission Progress',
        source: 'The Hindu',
        content:
            'ISRO and NASA joint NISAR satellite undergoing final integration tests.',
        tags: ['Science', 'Space'],
      );

      expect(
          () => (article.tags as List).add('Defence'), throwsUnsupportedError);
    });

    test('copyWith modifies specified attributes while preserving others', () {
      final original = CurrentAffairsArticle(
        id: 'ca-003',
        title: 'Bhashini AI Language Translation',
        source: 'MeitY',
        content:
            'Bhashini mission empowers multilingual access to digital public infrastructure.',
        tags: ['Technology'],
      );

      final copy = original.copyWith(
        source: 'PIB Press Release',
        tags: ['Technology', 'AI'],
      );

      expect(copy.id, equals('ca-003'));
      expect(copy.title, equals(original.title));
      expect(copy.source, equals('PIB Press Release'));
      expect(copy.tags, equals(['Technology', 'AI']));
    });

    test('toMap and fromMap achieve full round-trip serialization', () {
      final article = CurrentAffairsArticle(
        id: 'ca-004',
        title: 'SCO Summit 2024 Joint Declaration',
        source: 'Indian Express',
        content:
            'Member states adopted Astana Declaration promoting regional stability.',
        publicationDate: DateTime.parse('2026-07-20T10:00:00.000Z'),
        tags: ['IR', 'Diplomacy'],
        language: 'en',
      );

      final map = article.toMap();
      final restored = CurrentAffairsArticle.fromMap(map);

      expect(restored, equals(article));
      expect(restored.id, equals('ca-004'));
      expect(restored.publicationDate,
          equals(DateTime.parse('2026-07-20T10:00:00.000Z')));
    });

    test('throws assertion error for empty required fields', () {
      expect(
        () => CurrentAffairsArticle(
            id: '', title: 'Title', source: 'Source', content: 'Content'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CurrentAffairsArticle(
            id: '1', title: '   ', source: 'Source', content: 'Content'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CurrentAffairsArticle(
            id: '1', title: 'Title', source: '', content: 'Content'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CurrentAffairsArticle(
            id: '1', title: 'Title', source: 'Source', content: ''),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
