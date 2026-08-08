import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_international/garuda_international.dart';

void main() {
  group('InternationalAnalyticsEngine', () {
    test('computes totals and coverage on an empty corpus', () {
      final report = InternationalAnalyticsEngine.generateReport(
        organisations: const [],
        expectedOrganisations: 66,
      );
      expect(report.totalOrganisations, 0);
      expect(report.importedOrganisations, 0);
      expect(report.coveragePercentage, 0.0);
      expect(report.bodyTypeDistribution, isEmpty);
      expect(report.indiaRelevantOrganisations, isEmpty);
    });

    test('computes distributions and coverage over the Phase-I corpus',
        () async {
      final repo = InMemoryInternationalRepository();
      final all = await repo.getAllOrganisations();

      final report = InternationalAnalyticsEngine.generateReport(
        organisations: all,
        expectedOrganisations: InternationalSeedCorpus.expectedInternationalCorpus,
      );

      expect(report.totalOrganisations, all.length);
      expect(report.importedOrganisations, all.length);
      expect(report.coveragePercentage, 100.0);
      expect(report.bodyTypeDistribution, isNotEmpty);
      expect(report.categoryDistribution, isNotEmpty);
      expect(report.regionDistribution, isNotEmpty);
      expect(report.headquartersRegionDistribution, isNotEmpty);
      expect(report.membershipTypeDistribution, isNotEmpty);
      expect(report.indiaRelationshipDistribution, isNotEmpty);
      expect(report.foundingDecadeDistribution, isNotEmpty);
      expect(report.upscRelevanceDistribution, isNotEmpty);

      // UN system count
      expect(report.categoryDistribution[InternationalCategory.unitedNations],
          greaterThan(15));

      // treaty frequency
      expect(report.topTreaties, isNotEmpty);
      expect(report.topTreaties.containsKey('Charter of the United Nations, 1945'),
          isTrue);
    });

    test('most-interconnected and India-relevant organisations are present',
        () async {
      final repo = InMemoryInternationalRepository();
      final all = await repo.getAllOrganisations();
      final report = InternationalAnalyticsEngine.generateReport(
          organisations: all);

      expect(report.mostInterconnectedOrganisations, isNotEmpty);
      expect(report.indiaRelevantOrganisations, isNotEmpty);
      // India is a founding/full member of many organisations.
      expect(report.indiaRelevantOrganisations.length, greaterThan(30));
    });

    test('evidence coverage and SDG linkage are positive', () async {
      final repo = InMemoryInternationalRepository();
      final all = await repo.getAllOrganisations();
      final report = InternationalAnalyticsEngine.generateReport(
          organisations: all);

      expect(report.evidenceCoverage, greaterThan(0));
      expect(report.topLinkedSdgs, isNotEmpty);
      expect(report.topConventions, isNotEmpty);
    });

    test('corpus report (repository) aligns with analytics coverage', () async {
      final repo = InMemoryInternationalRepository();
      final all = await repo.getAllOrganisations();
      final corpus = await repo.generateCorpusReport();
      final analytics = InternationalAnalyticsEngine.generateReport(
        organisations: all,
        expectedOrganisations: InternationalSeedCorpus.expectedInternationalCorpus,
      );

      expect(corpus.totalImportedOrganisations, analytics.totalOrganisations);
      expect(corpus.organisationCoveragePercentage, analytics.coveragePercentage);
      expect(corpus.bodyTypeCount, analytics.bodyTypeDistribution.length);
      expect(corpus.totalIndiaRelevantOrganisations,
          analytics.indiaRelevantOrganisations.length);
    });
  });
}
