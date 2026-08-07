import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

void main() {
  group('CaseValidator Unit & Integrity Tests', () {
    test('Default Seed Repository with Phase I cases passes validation with 0 errors', () async {
      final repo = InMemoryCaseRepository();
      final result = await CaseValidator.validateRepository(repo);

      if (!result.isValid) {
        print('Validation errors: ${result.errors}');
      }

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Validator detects duplicate case object IDs', () async {
      final dupeCase = CaseKnowledgeObject(
        objectId: 'KO-CASE-KESAVANANDA', // Duplicate ID
        caseId: 'DUPE',
        caseName: 'Duplicate Case',
        citation: 'AIR 2024 SC 9999',
        year: 2024,
        bench: 'Bench',
        historicalContext: 'Test',
        facts: 'Test',
        decision: 'Test',
        constitutionalSignificance: 'Test',
        judgmentDate: DateTime(2024, 1, 1),
        garudaExplanation: 'Test',
        oneLineSummary: 'Test',
        detailedSummary: 'Test',
      );

      final repo = InMemoryCaseRepository(
        cases: [...CaseSeedData.cases, dupeCase],
      );

      final result = await CaseValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'DUPLICATE_CASE_ID'), isTrue);
    });

    test('Validator detects missing citation', () async {
      final badCase = CaseKnowledgeObject(
        objectId: 'KO-CASE-BAD-CITATION',
        caseId: 'BAD_CIT',
        caseName: 'No Citation Case',
        citation: '', // Empty citation
        year: 2024,
        bench: 'Bench',
        historicalContext: 'Test',
        facts: 'Test',
        decision: 'Test',
        constitutionalSignificance: 'Test',
        judgmentDate: DateTime(2024, 1, 1),
        garudaExplanation: 'Test',
        oneLineSummary: 'Test',
        detailedSummary: 'Test',
      );

      final repo = InMemoryCaseRepository(cases: [badCase]);
      final result = await CaseValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'MISSING_CITATION'), isTrue);
    });
  });
}
