import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

void main() {
  group('CaseAnalyzer Unit & Deliverable Coverage Tests', () {
    late InMemoryCaseRepository repository;

    setUp(() {
      repository = InMemoryCaseRepository();
    });

    test('analyzeRepository computes complete Phase I case statistics', () async {
      final report = await CaseAnalyzer.analyzeRepository(repository);

      expect(report.totalCases, equals(49));
      expect(report.landmarkPrecedentsCount, equals(41));
      expect(report.overruledCasesCount, greaterThanOrEqualTo(5));

      expect(report.uniqueArticlesCount, greaterThan(10));
      expect(report.uniqueAmendmentsCount, greaterThan(5));
      expect(report.uniqueJudgesCount, greaterThan(20));

      expect(report.totalPYQLinks, greaterThan(20));
      expect(report.totalKnowledgeGraphLinks, greaterThan(50));
      expect(report.evidenceCoverageRate, equals(1.0));
    });

    test('CaseAnalysisReport serialization toJson round-trip', () async {
      final report = await CaseAnalyzer.analyzeRepository(repository);
      final json = report.toJson();

      expect(json['totalCases'], equals(49));
      expect(json['evidenceCoverageRate'], equals(1.0));
      expect(json['uniqueArticlesCount'], greaterThan(10));
    });
  });
}
