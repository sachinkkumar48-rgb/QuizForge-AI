import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart';

void main() {
  group('DoctrineValidator Unit & Integrity Tests', () {
    test('Default Seed Repository with Phase I doctrines passes validation with 0 errors', () async {
      final repo = InMemoryDoctrineRepository();
      final result = await DoctrineValidator.validateRepository(repo);

      if (!result.isValid) {
        print('Validation errors: ${result.errors}');
      }

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Validator detects duplicate doctrine object IDs', () async {
      final dupeDoc = DoctrineKnowledgeObject(
        objectId: 'KO-DOC-BASIC-STRUCTURE', // Duplicate ID
        doctrineId: 'DUPE',
        name: 'Duplicate Doctrine',
        origin: 'Test',
        officialDefinition: 'Test',
        plainLanguageExplanation: 'Test',
        purpose: 'Test',
        scope: 'Test',
        originatingCase: 'Test Case',
        historicalContext: 'Test',
        evolution: 'Test',
        currentPosition: 'Test',
        oneLineSummary: 'Test',
        detailedExplanation: 'Test',
      );

      final repo = InMemoryDoctrineRepository(
        doctrines: [...DoctrineSeedData.doctrines, dupeDoc],
      );

      final result = await DoctrineValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'DUPLICATE_DOCTRINE_ID'), isTrue);
    });

    test('Validator detects missing definition or originating case', () async {
      final badDoc = DoctrineKnowledgeObject(
        objectId: 'KO-DOC-BAD',
        doctrineId: 'BAD',
        name: 'Bad Doctrine',
        origin: 'Test',
        officialDefinition: '', // Empty definition
        plainLanguageExplanation: 'Test',
        purpose: 'Test',
        scope: 'Test',
        originatingCase: '', // Empty case
        historicalContext: 'Test',
        evolution: 'Test',
        currentPosition: 'Test',
        oneLineSummary: 'Test',
        detailedExplanation: 'Test',
      );

      final repo = InMemoryDoctrineRepository(doctrines: [badDoc]);
      final result = await DoctrineValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'MISSING_DEFINITION'), isTrue);
      expect(result.errors.any((e) => e.code == 'MISSING_ORIGINATING_CASE'), isTrue);
    });
  });
}
