import 'package:flutter_test/flutter_test.dart';
import 'package:knowledge_engine/domain/value_objects/knowledge_type.dart';

void main() {
  group('KnowledgeType Enum Tests', () {
    test('contains all required enum values', () {
      expect(KnowledgeType.values, contains(KnowledgeType.pdf));
      expect(KnowledgeType.values, contains(KnowledgeType.article));
      expect(KnowledgeType.values, contains(KnowledgeType.pyq));
      expect(KnowledgeType.values, contains(KnowledgeType.note));
      expect(KnowledgeType.values, contains(KnowledgeType.book));
      expect(KnowledgeType.values, contains(KnowledgeType.report));
      expect(KnowledgeType.values, contains(KnowledgeType.video));
      expect(KnowledgeType.values, contains(KnowledgeType.other));
      expect(KnowledgeType.values.length, equals(8));
    });

    test('name property returns correct string representation', () {
      expect(KnowledgeType.pdf.name, equals('pdf'));
      expect(KnowledgeType.article.name, equals('article'));
      expect(KnowledgeType.pyq.name, equals('pyq'));
      expect(KnowledgeType.note.name, equals('note'));
      expect(KnowledgeType.book.name, equals('book'));
      expect(KnowledgeType.report.name, equals('report'));
      expect(KnowledgeType.video.name, equals('video'));
      expect(KnowledgeType.other.name, equals('other'));
    });
  });
}
