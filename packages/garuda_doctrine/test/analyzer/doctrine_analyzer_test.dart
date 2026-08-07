import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart';

void main() {
  group('DoctrineAnalyzer Unit & Deliverable Coverage Tests', () {
    late InMemoryDoctrineRepository repository;

    setUp(() {
      repository = InMemoryDoctrineRepository();
    });

    test('analyzeRepository computes complete Phase I doctrine statistics', () async {
      final report = await DoctrineAnalyzer.analyzeRepository(repository);

      expect(report.totalDoctrines, equals(20));
      expect(report.uniqueArticlesCount, greaterThan(10));
      expect(report.uniqueCasesCount, greaterThan(15));
      expect(report.uniqueAmendmentsCount, greaterThan(3));

      expect(report.totalPYQLinks, greaterThan(20));
      expect(report.totalKnowledgeGraphLinks, greaterThan(40));
      expect(report.evidenceCoverageRate, equals(1.0));
    });

    test('DoctrineAnalysisReport serialization toJson round-trip', () async {
      final report = await DoctrineAnalyzer.analyzeRepository(repository);
      final json = report.toJson();

      expect(json['totalDoctrines'], equals(20));
      expect(json['evidenceCoverageRate'], equals(1.0));
      expect(json['uniqueArticlesCount'], greaterThan(10));
    });
  });
}
