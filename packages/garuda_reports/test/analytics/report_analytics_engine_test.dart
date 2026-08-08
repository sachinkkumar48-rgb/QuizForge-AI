import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportAnalyticsEngine Tests', () {
    late InMemoryReportRepository repository;

    setUp(() {
      repository = InMemoryReportRepository();
    });

    test('should generate comprehensive analytics report over seed corpus',
        () async {
      final reports = await repository.getAllReports();
      final indices = await repository.getAllIndices();
      final surveys = await repository.getAllSurveys();
      final indicators = await repository.getAllIndicators();

      final report = ReportAnalyticsEngine.generateReport(
        reports: reports,
        indices: indices,
        surveys: surveys,
        indicators: indicators,
      );

      expect(report.totalReports, equals(ReportSeedCorpus.expectedReportCorpus));
      expect(report.totalIndices, equals(9));
      expect(report.totalSurveys, equals(4));
      expect(report.totalIndicators,
          equals(ReportSeedCorpus.expectedIndicatorCorpus));

      // Publisher-wise distribution
      expect(report.publisherDistribution, isNotEmpty);
      expect(report.publisherDistribution.values.reduce((a, b) => a + b),
          equals(ReportSeedCorpus.expectedReportCorpus));

      // Subject-wise (category) distribution
      expect(report.categoryDistribution.containsKey(ReportCategory.economy),
          isTrue);
      expect(report.categoryDistribution.values.reduce((a, b) => a + b),
          equals(ReportSeedCorpus.expectedReportCorpus));

      // Year-wise distribution
      expect(report.yearDistribution, isNotEmpty);
      expect(report.yearDistribution.containsKey(2024), isTrue);

      // Coverage metrics
      expect(report.indicatorCoverage, greaterThan(0));
      expect(report.recommendationCoverage, greaterThan(0));
      expect(report.statisticCoverage, greaterThan(0));
      expect(report.chapterCoverage, greaterThan(0));

      // Link densities
      expect(report.pyqMappingDensity, greaterThan(0));
      expect(report.currentAffairsLinkDensity, greaterThan(0));
      expect(report.upscFrequency, greaterThan(0));

      // Top linked entities
      expect(report.topLinkedArticles.containsKey('Article 280'), isTrue);
      expect(report.topLinkedActs.containsKey('FRBM Act, 2003'), isTrue);
      expect(report.topLinkedCommittees.containsKey('comm_fc_15th_2017'), isTrue);
      expect(report.topLinkedSchemes.containsKey('POSHAN Abhiyaan'), isTrue);

      // Index rankings snapshot
      expect(report.indexRankings['idx_ghi_2024'], contains('105'));
    });

    test('should handle empty report list gracefully', () {
      final report = ReportAnalyticsEngine.generateReport(reports: []);

      expect(report.totalReports, equals(0));
      expect(report.indicatorCoverage, equals(0.0));
      expect(report.recommendationCoverage, equals(0.0));
      expect(report.pyqMappingDensity, equals(0.0));
      expect(report.currentAffairsLinkDensity, equals(0.0));
      expect(report.upscFrequency, equals(0.0));
      expect(report.publisherDistribution, isEmpty);
    });
  });
}
