import 'package:flutter_test/flutter_test.dart';
import 'package:titan_ingestion_pipeline/titan_ingestion_pipeline.dart';

void main() {
  group('KnowledgeValidator Tests', () {
    late KnowledgeValidator validator;

    setUp(() {
      validator = KnowledgeValidator();
    });

    test('Validates valid Knowledge Object successfully', () {
      final obj = KnowledgeObject(
        id: 'k1',
        title: 'Valid Lesson',
        source: 'test.md',
        contentBlocks: const [ParagraphBlock(id: 'b1', text: 'Valid content')],
      );

      final result = validator.validate(obj);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Fails validation on empty content blocks', () {
      final obj = KnowledgeObject(
        id: 'k2',
        title: 'Empty Lesson',
        source: 'test.md',
        contentBlocks: const [],
      );

      final result = validator.validate(obj);
      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('Empty Lesson'));
    });

    test('Fails validation on duplicate title and source', () {
      final existing = KnowledgeObject(
        id: 'k1',
        title: 'Duplicate Lesson',
        source: 'book.pdf',
        contentBlocks: const [ParagraphBlock(id: 'b1', text: 'Content')],
      );

      final newObj = KnowledgeObject(
        id: 'k2',
        title: 'Duplicate Lesson',
        source: 'book.pdf',
        contentBlocks: const [ParagraphBlock(id: 'b2', text: 'Content')],
      );

      final result = validator.validate(newObj, existingObjects: [existing]);
      expect(result.isValid, isFalse);
      expect(result.errors.first, contains('Duplicate Lesson'));
    });
  });
}
