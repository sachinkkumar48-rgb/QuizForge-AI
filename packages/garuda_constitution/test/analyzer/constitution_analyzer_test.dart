import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_constitution/garuda_constitution.dart';

void main() {
  group('ConstitutionAnalyzer Unit & Deliverable Coverage Tests', () {
    late InMemoryConstitutionRepository repository;

    setUp(() {
      repository = InMemoryConstitutionRepository();
    });

    test('analyzeRepository computes complete Phase-II Constitution Library statistics', () async {
      final report = await ConstitutionAnalyzer.analyzeRepository(repository);

      expect(report.totalArticles, equals(89));
      expect(report.activeArticlesCount, equals(86));
      expect(report.repealedArticlesCount, equals(3));
      expect(report.repealedArticles, containsAll(['31', '31D', '32A']));

      expect(report.totalAmendmentRecords, greaterThan(0));
      expect(report.uniqueAmendmentsCount, greaterThan(0));

      expect(report.totalCaseLawRecords, greaterThan(0));
      expect(report.uniqueCasesCount, greaterThan(0));

      expect(report.totalPYQLinks, greaterThan(0));
      expect(report.uniquePYQCount, greaterThan(0));

      expect(report.evidenceCoverageRate, equals(1.0));
      expect(report.bareTextCoverageRate, equals(1.0));
    });

    test('ConstitutionAnalysisReport serialization toJson round-trip', () async {
      final report = await ConstitutionAnalyzer.analyzeRepository(repository);
      final json = report.toJson();

      expect(json['totalArticles'], equals(89));
      expect(json['activeArticlesCount'], equals(86));
      expect(json['repealedArticlesCount'], equals(3));
      expect(json['evidenceCoverageRate'], equals(1.0));
      expect(json['bareTextCoverageRate'], equals(1.0));
    });
  });
}
