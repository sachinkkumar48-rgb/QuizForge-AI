import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_knowledge/garuda_knowledge.dart';

void main() {
  group('Ingestion Parsers', () {
    late KnowledgeSource testSource;

    setUp(() {
      testSource = const KnowledgeSource(
        sourceId: 'TEST_SRC',
        title: 'Test Source',
      );
    });

    test('TextKnowledgeParser parses plain text and headers', () {
      final doc = KnowledgeDocument.create(
        documentId: 'DOC-001',
        source: testSource,
        type: KnowledgeDocumentType.constitution,
        title: 'Article 21 Title',
        content: '# Section 1\nProtection of life and personal liberty.\n# Section 2\nNo person shall be deprived...',
        publicationDate: DateTime(1950, 1, 26),
      );

      final parser = TextKnowledgeParser();
      final result = parser.parse(doc);

      expect(result.isSuccess, isTrue);
      expect(result.title, equals('Article 21 Title'));
      expect(result.sections.length, equals(2));
      expect(result.parsedMetadata['parserType'], equals('TextKnowledgeParser'));
    });

    test('JsonKnowledgeParser parses structured JSON payload', () {
      const jsonContent = '''
{
  "title": "UPSC Question 2024",
  "body": "Which article deals with Equality before Law?",
  "sections": ["Question", "Options", "Explanation"]
}
''';

      final doc = KnowledgeDocument.create(
        documentId: 'DOC-002',
        source: testSource,
        type: KnowledgeDocumentType.upscQuestionPaper,
        title: 'Raw Document Title',
        content: jsonContent,
        publicationDate: DateTime(2024, 6, 16),
      );

      final parser = JsonKnowledgeParser();
      final result = parser.parse(doc);

      expect(result.isSuccess, isTrue);
      expect(result.title, equals('UPSC Question 2024'));
      expect(result.content, contains('Equality before Law'));
      expect(result.sections.length, equals(3));
    });

    test('TextKnowledgeParser handles empty document failure cleanly', () {
      final doc = KnowledgeDocument(
        documentId: 'DOC-EMPTY',
        source: testSource,
        type: KnowledgeDocumentType.generic,
        title: 'Empty',
        content: '   ',
        publicationDate: DateTime.now(),
        checksum: 'invalid',
        retrievedDate: DateTime.now(),
      );

      final parser = TextKnowledgeParser();
      final result = parser.parse(doc);

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('empty'));
    });
  });
}
