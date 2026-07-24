import 'package:knowledge_engine/knowledge_engine.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeSearchQuery Tests', () {
    test('initializes with default parameters', () {
      final query = KnowledgeSearchQuery();

      expect(query.freeText, isNull);
      expect(query.subjects, isEmpty);
      expect(query.topics, isEmpty);
      expect(query.knowledgeTypes, isEmpty);
      expect(query.relationshipTypes, isEmpty);
      expect(query.tags, isEmpty);
      expect(query.language, isNull);
      expect(query.limit, equals(20));
      expect(query.offset, equals(0));
      expect(query.sortOrder, equals(SearchSortOrder.relevance));
      expect(query.filters, isEmpty);
    });

    test('guarantees immutability by returning unmodifiable collections', () {
      final query = KnowledgeSearchQuery(
        subjects: ['Polity'],
        topics: ['Preamble'],
        tags: ['UPSC'],
      );

      expect(() => (query.subjects as List).add('Economy'),
          throwsUnsupportedError);
      expect(
          () => (query.topics as List).add('Rights'), throwsUnsupportedError);
      expect(() => (query.tags as List).add('2025'), throwsUnsupportedError);
    });

    test('copyWith modifies specified attributes while preserving others', () {
      final original = KnowledgeSearchQuery(
        freeText: 'Preamble',
        subjects: ['Polity'],
        limit: 10,
      );

      final copy = original.copyWith(
        limit: 50,
        sortOrder: SearchSortOrder.newestFirst,
      );

      expect(copy.freeText, equals('Preamble'));
      expect(copy.subjects, equals(['Polity']));
      expect(copy.limit, equals(50));
      expect(copy.sortOrder, equals(SearchSortOrder.newestFirst));
    });

    test('toMap and fromMap achieve full round-trip serialization', () {
      final query = KnowledgeSearchQuery(
        freeText: 'Directive Principles',
        subjects: ['Polity'],
        topics: ['DPSP'],
        knowledgeTypes: [KnowledgeType.pdf],
        relationshipTypes: [RelationshipType.prerequisiteOf],
        tags: ['Article39'],
        language: 'en',
        limit: 15,
        offset: 5,
        sortOrder: SearchSortOrder.titleAscending,
        filters: {'minConfidence': 0.8},
      );

      final map = query.toMap();
      final restored = KnowledgeSearchQuery.fromMap(map);

      expect(restored, equals(query));
      expect(restored.freeText, equals('Directive Principles'));
      expect(restored.knowledgeTypes.first, equals(KnowledgeType.pdf));
      expect(restored.relationshipTypes.first,
          equals(RelationshipType.prerequisiteOf));
      expect(restored.sortOrder, equals(SearchSortOrder.titleAscending));
      expect(restored.filters['minConfidence'], equals(0.8));
    });

    test('throws assertion error for invalid limit or offset', () {
      expect(
          () => KnowledgeSearchQuery(limit: 0), throwsA(isA<AssertionError>()));
      expect(() => KnowledgeSearchQuery(offset: -1),
          throwsA(isA<AssertionError>()));
    });
  });
}
