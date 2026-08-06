import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  group('ArticleKnowledgeObject Entity & Serialization Tests', () {
    test('Creation of ArticleKnowledgeObject holds all required Part III fields', () {
      final art14 = ConstitutionArticlesPart3.articles.firstWhere((a) => a.articleNumber == '14');

      expect(art14.objectId, equals('KO-ART-14'));
      expect(art14.articleNumber, equals('14'));
      expect(art14.part, equals('Part III'));
      expect(art14.chapter, equals('Right to Equality'));
      expect(art14.officialConstitutionalText, contains('equality before the law'));
      expect(art14.searchKeywords, contains('Equality before law'));
      expect(art14.keyTakeaways, isNotEmpty);
      expect(art14.caseLaw.any((c) => c.caseName.contains('Maneka Gandhi')), isTrue);
      expect(art14.pyqIds, isNotEmpty);
      expect(art14.revisionPoints, isNotEmpty);
    });

    test('ArticleKnowledgeObject toJson and fromJson round-trip preserves all payload', () {
      final art21 = ConstitutionArticlesPart3.articles.firstWhere((a) => a.articleNumber == '21');
      final json = art21.toJson();
      final restored = ArticleKnowledgeObject.fromJson(json);

      expect(restored.objectId, equals(art21.objectId));
      expect(restored.articleNumber, equals(art21.articleNumber));
      expect(restored.officialTitle, equals(art21.officialTitle));
      expect(restored.officialConstitutionalText, equals(art21.officialConstitutionalText));
      expect(restored.keyTakeaways, equals(art21.keyTakeaways));
      expect(restored.caseLaw.length, equals(art21.caseLaw.length));
      expect(restored.amendmentHistory.length, equals(art21.amendmentHistory.length));
      expect(restored.pyqIds, equals(art21.pyqIds));
    });

    test('ArticleAmendmentRecord toJson and fromJson cycle', () {
      final record = ArticleAmendmentRecord(
        amendmentName: '86th Constitutional Amendment Act, 2002',
        beforeText: 'No Art 21A',
        afterText: 'Inserted Art 21A',
        reason: 'Free compulsory education',
        effectiveDate: DateTime(2002, 12, 12),
      );

      final json = record.toJson();
      final restored = ArticleAmendmentRecord.fromJson(json);

      expect(restored.amendmentName, equals(record.amendmentName));
      expect(restored.beforeText, equals(record.beforeText));
      expect(restored.afterText, equals(record.afterText));
      expect(restored.reason, equals(record.reason));
    });

    test('ArticleCaseLawRecord toJson and fromJson cycle', () {
      final record = ArticleCaseLawRecord(
        caseName: 'Kesavananda Bharati v. State of Kerala',
        year: 1973,
        bench: 'Supreme Court (13-Judge Bench)',
        legalPrinciple: 'Basic Structure Doctrine',
        importance: 'Pillar of Constitutionalism',
      );

      final json = record.toJson();
      final restored = ArticleCaseLawRecord.fromJson(json);

      expect(restored.caseName, equals(record.caseName));
      expect(restored.year, equals(1973));
      expect(restored.bench, equals('Supreme Court (13-Judge Bench)'));
      expect(restored.legalPrinciple, equals('Basic Structure Doctrine'));
    });
  });
}
