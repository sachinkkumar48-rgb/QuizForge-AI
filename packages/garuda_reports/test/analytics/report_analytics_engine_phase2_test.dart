import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_reports/garuda_reports.dart';

void main() {
  group('ReportAnalyticsEngine Phase-2 metrics', () {
    late ReportAnalyticsReport report;

    setUp(() {
      report = ReportAnalyticsEngine.generateReport(
        reports: ReportSeedCorpus.phase1Reports,
        indices: ReportSeedCorpus.phase1Indices,
        surveys: ReportSeedCorpus.phase1Surveys,
        indicators: ReportSeedCorpus.phase1Indicators,
      );
    });

    test('reports corpus totals including expanded counts', () {
      expect(report.totalReports, equals(ReportSeedCorpus.expectedReportCorpus));
      expect(report.totalIndices, equals(ReportSeedCorpus.expectedIndexCorpus));
      expect(report.totalSurveys, equals(ReportSeedCorpus.expectedSurveyCorpus));
      expect(report.totalIndicators,
          equals(ReportSeedCorpus.expectedIndicatorCorpus));
      expect(report.indiaCoverageCount, greaterThan(0));
    });

    test('reports full evidence coverage after enrichment', () {
      expect(report.evidenceCoverage, greaterThan(0.99));
    });

    test('reports SDG, indicator and ranking distributions', () {
      expect(report.sdgDistribution, isNotEmpty);
      expect(report.sdgDistribution.containsKey('SDG 13 - Climate Action'),
          isTrue);
      expect(report.indicatorFrequency, isNotEmpty);
      expect(report.rankingFrequency, isNotEmpty);
      expect(report.rankingFrequency.containsKey('idx_ghi_2024'), isTrue);
    });

    test('reports cross-package link frequency and most-interconnected', () {
      expect(report.crossPackageLinkFrequency, isNotEmpty);
      expect(report.crossPackageLinkFrequency.containsKey('Article 112'), isTrue);
      expect(report.mostInterconnectedReports, isNotEmpty);
      expect(report.mostInterconnectedReports.first, isNotEmpty);
    });

    test('serialises to JSON', () {
      final json = jsonEncode(report.toJson());
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['totalReports'],
          equals(ReportSeedCorpus.expectedReportCorpus));
      expect(decoded['evidenceCoverage'], greaterThan(0.99));
      expect(decoded['sdgDistribution'], isNotEmpty);
    });
  });
}
