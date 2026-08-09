import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P4.6 — Judgment Intelligence analytics over the corpus (TITAN-KO-015.0 P4).
void main() {
  final cases = CaseSeedData.cases;

  group('Coverage metrics', () {
    final report = JudgmentIntelligenceAnalytics.analyze(cases);

    test('reports total and missing intelligence counts', () {
      expect(report.totalCases, 49);
      expect(report.missingIntelligenceCount, 0);
    });

    test('full bench, holdings, ratio, outcome, UPSC coverage', () {
      expect(report.casesWithBench, 49);
      expect(report.casesWithHoldings, 49);
      expect(report.casesWithRatio, 49);
      expect(report.casesWithOutcome, 49);
      expect(report.casesWithSignificance, 49);
      expect(report.casesWithUpscIntelligence, 49);
      expect(report.casesWithTimeline, 49);
    });

    test('coverage rates are 1.0 for the enriched corpus', () {
      expect(report.benchCoverageRate, 1.0);
      expect(report.holdingCoverageRate, 1.0);
      expect(report.upscCoverageRate, 1.0);
      expect(report.prelimsCoverageRate, 1.0);
      expect(report.mainsCoverageRate, 1.0);
      expect(report.interviewCoverageRate, 1.0);
    });

    test('evidence coverage reflects verified (non-editorial) components',
        () {
      // Reasoning carries deliberately editorial evidence (edr) by design;
      // bench, holdings, ratios, outcome and timeline are verified. So the
      // verified-evidence ratio is high but below 1.0.
      expect(report.evidenceCoverage, greaterThan(0.85));
      expect(report.evidenceCoverage, lessThan(1.0));
    });

    test('completeness index is high', () {
      expect(report.completenessIndex, greaterThan(0.9));
    });

    test('issue categories and articles are tabulated', () {
      expect(report.issueCategoryDistribution, isNotEmpty);
      expect(report.articleFrequency, isNotEmpty);
      expect(report.articleFrequency.keys,
          anyElement(contains('Article 21')));
    });

    test('significance score distribution is populated', () {
      expect(report.significanceScoreDistribution, isNotEmpty);
      final scores = report.significanceScoreDistribution.keys;
      expect(scores.reduce((a, b) => a < b ? a : b), greaterThanOrEqualTo(0));
      expect(scores.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(100));
    });
  });

  group('Serialization', () {
    test('analytics report serializes to JSON', () {
      final report = JudgmentIntelligenceAnalytics.analyze(cases);
      final json = report.toJson();
      expect(json['totalCases'], 49);
      expect(json['benchCoverageRate'], 1.0);
      expect(json['upscCoverageRate'], 1.0);
      expect(json['issueCategoryDistribution'], isA<Map>());
      expect(json['articleFrequency'], isA<Map>());
    });
  });
}
