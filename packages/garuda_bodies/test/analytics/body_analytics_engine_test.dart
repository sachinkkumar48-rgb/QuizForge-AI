import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_bodies/garuda_bodies.dart';

void main() {
  group('BodyAnalyticsEngine', () {
    test('computes totals and coverage on an empty corpus', () {
      final report = BodyAnalyticsEngine.generateReport(
        bodies: const [],
        expectedBodies: 43,
      );
      expect(report.totalBodies, 0);
      expect(report.importedBodies, 0);
      expect(report.coveragePercentage, 0.0);
      expect(report.bodyTypeDistribution, isEmpty);
    });

    test('computes distributions and coverage over the Phase-I corpus',
        () async {
      final repo = InMemoryBodyRepository();
      final all = await repo.getAllBodies();

      final report = BodyAnalyticsEngine.generateReport(
        bodies: all,
        expectedBodies: BodySeedCorpus.expectedBodyCorpus,
      );

      expect(report.totalBodies, all.length);
      expect(report.importedBodies, all.length);
      expect(report.coveragePercentage, 100.0);
      expect(report.bodyTypeDistribution, isNotEmpty);
      expect(report.categoryDistribution, isNotEmpty);
      expect(report.ministryDistribution, isNotEmpty);
      expect(report.constitutionalBasisDistribution, isNotEmpty);
      expect(report.statutoryBasisDistribution, isNotEmpty);
      expect(report.jurisdictionDistribution, isNotEmpty);
      expect(report.yearEstablishedDistribution, isNotEmpty);
      expect(report.upscRelevanceDistribution, isNotEmpty);

      // constitutional bodies distribution
      expect(report.bodyTypeDistribution[BodyType.constitutional], 11);

      // linkage frequencies
      expect(report.topLinkedArticles, isNotEmpty);
      expect(report.topLinkedArticles.containsKey('Article 324'), isTrue);
      expect(report.topLinkedActs.containsKey('Reserve Bank of India Act, 1934'),
          isTrue);
      expect(report.topLinkedCases.containsKey('Vineet Narain v. Union of India'),
          isTrue);
    });

    test('most-interconnected bodies are ranked by relationship count',
        () async {
      final repo = InMemoryBodyRepository();
      final all = await repo.getAllBodies();
      final report = BodyAnalyticsEngine.generateReport(bodies: all);

      expect(report.mostInterconnectedBodies, isNotEmpty);
      // RBI has 2 relatedBodyIds + 0 relationships -> interconnected value 2.
      expect(report.mostInterconnectedBodies.values.first, greaterThanOrEqualTo(2));
    });

    test('evidence coverage and per-body link averages are positive', () async {
      final repo = InMemoryBodyRepository();
      final all = await repo.getAllBodies();
      final report = BodyAnalyticsEngine.generateReport(bodies: all);

      expect(report.evidenceCoverage, greaterThan(0));
      expect(report.averageArticleLinksPerBody, greaterThan(0));
      expect(report.averageActLinksPerBody, greaterThan(0));
    });

    test('corpus report (repository) aligns with analytics coverage', () async {
      final repo = InMemoryBodyRepository();
      final all = await repo.getAllBodies();
      final corpus = await repo.generateCorpusReport();
      final analytics = BodyAnalyticsEngine.generateReport(
        bodies: all,
        expectedBodies: BodySeedCorpus.expectedBodyCorpus,
      );

      expect(corpus.totalImportedBodies, analytics.totalBodies);
      expect(corpus.bodyCoveragePercentage, analytics.coveragePercentage);
      expect(corpus.bodyTypeCount, analytics.bodyTypeDistribution.length);
      expect(
          corpus.totalArticleLinks,
          analytics.topLinkedArticles.values.fold(
              0, (sum, v) => sum + v));
    });
  });
}
