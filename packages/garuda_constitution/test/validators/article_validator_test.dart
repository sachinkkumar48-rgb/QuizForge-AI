import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  group('ConstitutionValidator Article Integrity Tests', () {
    test('Default Seed Repository with all Part III Articles passes validation with 0 errors', () async {
      final repo = InMemoryConstitutionRepository();
      final result = await ConstitutionValidator.validateRepository(repo);

      if (!result.isValid) {
        print('Validation Errors: ${result.errors}');
      }

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Validator detects missing bare constitutional text in Article', () async {
      final badArt = ArticleKnowledgeObject(
        objectId: 'KO-ART-BAD1',
        articleNumber: '999',
        officialTitle: 'Bad Article',
        originalNumber: '999',
        currentNumber: '999',
        title: 'Article 999: Bad Article',
        officialName: 'ARTICLE 999',
        description: 'Test',
        officialConstitutionalText: '', // Missing bare text
        originalGarudaExplanation: 'Test',
        historicalBackground: 'Test',
        status: ConstitutionStatus.active,
        effectiveDate: DateTime(1950, 1, 26),
      );

      final repo = InMemoryConstitutionRepository(
        articles: [...ConstitutionArticlesPart3.articles, badArt],
      );

      final result = await ConstitutionValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'MISSING_BARE_TEXT'), isTrue);
    });

    test('Validator detects duplicate case law entries in Article', () async {
      final badArt = ArticleKnowledgeObject(
        objectId: 'KO-ART-BAD2',
        articleNumber: '998',
        officialTitle: 'Duplicate Case Article',
        originalNumber: '998',
        currentNumber: '998',
        title: 'Article 998: Test',
        officialName: 'ARTICLE 998',
        description: 'Test',
        officialConstitutionalText: 'Test Bare Text',
        originalGarudaExplanation: 'Test',
        historicalBackground: 'Test',
        caseLaw: const [
          ArticleCaseLawRecord(
            caseName: 'Kesavananda Bharati v. State of Kerala',
            year: 1973,
            bench: 'SC',
            legalPrinciple: 'Basic Structure',
            importance: 'High',
          ),
          ArticleCaseLawRecord(
            caseName: 'Kesavananda Bharati v. State of Kerala',
            year: 1973,
            bench: 'SC',
            legalPrinciple: 'Basic Structure',
            importance: 'High',
          ),
        ],
        status: ConstitutionStatus.active,
        effectiveDate: DateTime(1950, 1, 26),
      );

      final repo = InMemoryConstitutionRepository(
        articles: [...ConstitutionArticlesPart3.articles, badArt],
      );

      final result = await ConstitutionValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'DUPLICATE_CASE_LAW'), isTrue);
    });

    test('Validator detects broken PYQ link format', () async {
      final badArt = ArticleKnowledgeObject(
        objectId: 'KO-ART-BAD3',
        articleNumber: '997',
        officialTitle: 'Bad PYQ Article',
        originalNumber: '997',
        currentNumber: '997',
        title: 'Article 997: Test',
        officialName: 'ARTICLE 997',
        description: 'Test',
        officialConstitutionalText: 'Test Bare Text',
        originalGarudaExplanation: 'Test',
        historicalBackground: 'Test',
        pyqIds: const ['INVALID_PYQ_FORMAT'],
        status: ConstitutionStatus.active,
        effectiveDate: DateTime(1950, 1, 26),
      );

      final repo = InMemoryConstitutionRepository(
        articles: [...ConstitutionArticlesPart3.articles, badArt],
      );

      final result = await ConstitutionValidator.validateRepository(repo);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'BROKEN_PYQ_LINK'), isTrue);
    });
  });
}
