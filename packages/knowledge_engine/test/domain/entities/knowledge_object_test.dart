import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/domain/entities/knowledge_object.dart';
import 'package:knowledge_engine/domain/value_objects/knowledge_type.dart';

void main() {
  group('KnowledgeObject Entity Tests', () {
    final now = DateTime.parse('2026-07-22T12:00:00Z');

    KnowledgeObject createSampleObject({
      String id = 'ko_001',
      KnowledgeType type = KnowledgeType.pdf,
      String title = 'UPSC GS Paper 1 Notes',
      String summary = 'Comprehensive notes for Ancient Indian History',
      String source = 'https://quizforge.ai/docs/history.pdf',
      String language = 'en',
      List<String> subjects = const ['History', 'Polity'],
      List<String> topics = const ['Ancient History', 'Gupta Empire'],
      List<String> keywords = const ['UPSC', 'GS1', 'History'],
      Map<String, dynamic> metadata = const {
        'pageCount': 42,
        'author': 'TITAN'
      },
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      return KnowledgeObject(
        id: id,
        type: type,
        title: title,
        summary: summary,
        source: source,
        language: language,
        subjects: subjects,
        topics: topics,
        keywords: keywords,
        metadata: metadata,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      );
    }

    test('initializes with correct properties and defaults', () {
      final obj = createSampleObject();

      expect(obj.id, equals('ko_001'));
      expect(obj.type, equals(KnowledgeType.pdf));
      expect(obj.title, equals('UPSC GS Paper 1 Notes'));
      expect(obj.summary,
          equals('Comprehensive notes for Ancient Indian History'));
      expect(obj.source, equals('https://quizforge.ai/docs/history.pdf'));
      expect(obj.language, equals('en'));
      expect(obj.subjects, equals(['History', 'Polity']));
      expect(obj.topics, equals(['Ancient History', 'Gupta Empire']));
      expect(obj.keywords, equals(['UPSC', 'GS1', 'History']));
      expect(obj.metadata, equals({'pageCount': 42, 'author': 'TITAN'}));
      expect(obj.createdAt, equals(now));
      expect(obj.updatedAt, equals(now));
    });

    test('guarantees immutability by returning unmodifiable collections', () {
      final obj = createSampleObject();

      expect(() => obj.subjects.add('Geography'), throwsUnsupportedError);
      expect(() => obj.topics.add('New Topic'), throwsUnsupportedError);
      expect(() => obj.keywords.add('New Keyword'), throwsUnsupportedError);
      expect(() => obj.metadata['newKey'] = 'newValue', throwsUnsupportedError);
    });

    test('value equality evaluates identical objects as equal', () {
      final obj1 = createSampleObject();
      final obj2 = createSampleObject();

      expect(obj1, equals(obj2));
      expect(obj1.hashCode, equals(obj2.hashCode));
    });

    test('value equality returns false when fields differ', () {
      final obj1 = createSampleObject();
      final obj2 = obj1.copyWith(title: 'Different Title');

      expect(obj1, isNot(equals(obj2)));
    });

    test(
        'copyWith updates specified fields while keeping original values for others',
        () {
      final original = createSampleObject();
      final updated = original.copyWith(
        title: 'Updated Title',
        type: KnowledgeType.pyq,
        subjects: ['Polity'],
      );

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Updated Title'));
      expect(updated.type, equals(KnowledgeType.pyq));
      expect(updated.subjects, equals(['Polity']));
      expect(updated.summary, equals(original.summary));
      expect(updated.source, equals(original.source));
    });

    test('toMap and fromMap achieve full round-trip serialization', () {
      final original = createSampleObject();
      final map = original.toMap();
      final restored = KnowledgeObject.fromMap(map);

      expect(restored, equals(original));
    });

    test('toString includes key identifying details', () {
      final obj = createSampleObject();
      expect(obj.toString(), contains('ko_001'));
      expect(obj.toString(), contains('pdf'));
      expect(obj.toString(), contains('UPSC GS Paper 1 Notes'));
    });
  });
}
