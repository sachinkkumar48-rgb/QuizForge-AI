import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_schemes/garuda_schemes.dart';

void main() {
  group('SchemeAnalyticsEngine', () {
    test('computes totals and coverage on an empty corpus', () {
      final report = SchemeAnalyticsEngine.generateReport(
        schemes: const [],
        expectedSchemes: 67,
      );
      expect(report.totalSchemes, 0);
      expect(report.importedSchemes, 0);
      expect(report.coveragePercentage, 0.0);
      expect(report.ministryDistribution, isEmpty);
    });

    test('computes distributions and coverage over the Phase-I corpus',
        () async {
      final repo = InMemorySchemeRepository();
      final all = await repo.getAllSchemes();

      final report = SchemeAnalyticsEngine.generateReport(
        schemes: all,
        expectedSchemes: SchemeSeedCorpus.expectedSchemeCorpus,
      );

      expect(report.totalSchemes, all.length);
      expect(report.importedSchemes, all.length);
      expect(report.coveragePercentage, 100.0);
      expect(report.ministryDistribution, isNotEmpty);
      expect(report.categoryDistribution, isNotEmpty);
      expect(report.sectorDistribution, isNotEmpty);
      expect(report.launchYearDistribution, isNotEmpty);
      expect(report.statusDistribution.containsKey(SchemeStatus.operational),
          isTrue);
      expect(report.schemeTypeDistribution, isNotEmpty);
      expect(report.fundingPatternDistribution, isNotEmpty);

      // linkage frequencies
      expect(report.topLinkedArticles, isNotEmpty);
      expect(report.topLinkedArticles.containsKey('Article 21'), isTrue);
      expect(report.topLinkedActs, isNotEmpty);
      expect(report.topLinkedActs.containsKey(
          'Mahatma Gandhi National Rural Employment Guarantee Act, 2005'),
          isTrue);
      expect(report.topLinkedSdgs, isNotEmpty);

      // most-interconnected
      expect(report.mostInterconnectedSchemes, isNotEmpty);
      final topScheme = report.mostInterconnectedSchemes.entries.first;
      expect(topScheme.value, greaterThanOrEqualTo(2));
    });

    test('beneficiary distribution counts schemes per target group',
        () async {
      final repo = InMemorySchemeRepository();
      final all = await repo.getAllSchemes();
      final report = SchemeAnalyticsEngine.generateReport(schemes: all);

      expect(
          report.beneficiaryDistribution.containsKey(BeneficiaryGroup.women),
          isTrue);
      expect(
          report.beneficiaryDistribution[BeneficiaryGroup.farmers]!,
          greaterThan(0));
    });

    test('per-scheme averages are finite and non-negative', () async {
      final repo = InMemorySchemeRepository();
      final all = await repo.getAllSchemes();
      final report = SchemeAnalyticsEngine.generateReport(schemes: all);

      expect(report.averageBenefitPerScheme, greaterThanOrEqualTo(0));
      expect(report.averageComponentPerScheme, greaterThanOrEqualTo(0));
      expect(report.averageSdgPerScheme, greaterThan(0));
      expect(report.averagePyqPerScheme, greaterThan(0));
    });

    test('corpus report (repository) aligns with analytics coverage', () async {
      final repo = InMemorySchemeRepository();
      final all = await repo.getAllSchemes();
      final corpus = await repo.generateCorpusReport();
      final analytics = SchemeAnalyticsEngine.generateReport(
        schemes: all,
        expectedSchemes: SchemeSeedCorpus.expectedSchemeCorpus,
      );

      expect(corpus.totalImportedSchemes, analytics.totalSchemes);
      expect(corpus.schemeCoveragePercentage, analytics.coveragePercentage);
      expect(corpus.ministryCount, analytics.ministryDistribution.length);
      expect(corpus.totalPyqLinks, analytics.topLinkedPyqs.values.fold(0,
          (sum, v) => sum + v));
    });
  });
}
