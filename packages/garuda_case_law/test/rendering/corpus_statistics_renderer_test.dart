import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P8 — corpus statistics rendering (TITAN-KO-015.0 P8).
///
/// Statistics must REUSE the existing P4/P5 analytics rather than recalculate.
/// Verifies delegation to the existing analytics, evidence coverage reuse,
/// format integrity and determinism.
void main() {
  final corpus = CaseSeedData.cases;
  late LegalGraph graph;

  setUpAll(() {
    graph = LegalGraphSeed.fromCorpora(
      cases: corpus,
      doctrines: DoctrineSeedData.doctrines,
    ).build();
  });

  group('1. reuse of existing analytics', () {
    test('statistics delegate to the P4 analytics report', () {
      final stats = CorpusStatistics.compute(corpus, graph);
      final expected = JudgmentIntelligenceAnalytics.analyze(corpus);
      expect(stats.totalCases, 49);
      expect(stats.intelligence.totalCases, expected.totalCases);
      expect(stats.intelligence.completenessIndex, expected.completenessIndex);
      expect(stats.intelligence.evidenceCoverage, expected.evidenceCoverage);
      expect(
          stats.intelligence.prelimsCoverageRate, expected.prelimsCoverageRate);
    });

    test('statistics delegate to the P5 graph analytics report', () {
      final stats = CorpusStatistics.compute(corpus, graph);
      final expected = LegalGraphAnalytics.compute(graph);
      expect(stats.graph.totalNodes, expected.totalNodes);
      expect(stats.graph.totalEdges, expected.totalEdges);
      expect(stats.graph.caseCaseEdges, expected.caseCaseEdges);
      expect(stats.graph.caseDoctrineEdges, expected.caseDoctrineEdges);
      expect(
          stats.graph.connectivityComponents, expected.connectivityComponents);
    });

    test('evidence coverage reuses the corpus metric', () {
      final stats = CorpusStatistics.compute(corpus, graph);
      expect(
          stats.evidenceCoverage, CaseCorpusSupport.evidenceCoverage(corpus));
      expect(stats.evidenceCoverage, 1.0);
    });
  });

  group('2. markdown', () {
    test('renders headline metrics and both analytics sections', () {
      final stats = CorpusStatistics.compute(corpus, graph);
      final md = CorpusStatisticsRenderer.renderMarkdown(stats);
      expect(md, startsWith('# GARUDA Landmark Case Corpus Statistics'));
      expect(md, contains('**Total cases:** 49'));
      expect(md, contains('**Evidence coverage:** 100.0%'));
      expect(md, contains('## Judgment Intelligence (P4)'));
      expect(md, contains('## Precedent & Doctrine Graph (P5)'));
    });
  });

  group('3. html', () {
    test('renders semantic sections', () {
      final stats = CorpusStatistics.compute(corpus, graph);
      final html = CorpusStatisticsRenderer.renderHtml(stats);
      expect(html, contains('<section class="corpus-statistics"'));
      expect(html, contains('<h2>Judgment Intelligence (P4)</h2>'));
      expect(
        html,
        contains('<h2>Precedent &amp; Doctrine Graph (P5)</h2>'),
      );
      expect(html, isNot(contains('<script')));
    });
  });

  group('4. json', () {
    test('renders a deterministic machine-readable snapshot', () {
      final stats = CorpusStatistics.compute(corpus, graph);
      final m = CorpusStatisticsRenderer.renderJson(stats);
      expect(m['totalCases'], 49);
      expect(m['evidenceCoverage'], closeTo(1.0, 1e-9));
      expect(m['intelligence'], isA<Map<String, dynamic>>());
      expect(m['graph'], isA<Map<String, dynamic>>());
      final graphJson = m['graph'] as Map<String, dynamic>;
      expect(graphJson['totalNodes'], isA<int>());
      expect(graphJson['relationshipTypeDistribution'],
          isA<Map<String, dynamic>>());
      // Sorted distribution maps → deterministic key order.
      final keys =
          (graphJson['relationshipTypeDistribution'] as Map).keys.toList();
      expect(keys, List.of(keys)..sort());
    });

    test('statistics JSON is byte-stable across calls', () {
      final stats = CorpusStatistics.compute(corpus, graph);
      expect(
        const JsonEncoder.withIndent('  ')
            .convert(CorpusStatisticsRenderer.renderJson(stats)),
        const JsonEncoder.withIndent('  ')
            .convert(CorpusStatisticsRenderer.renderJson(stats)),
      );
    });
  });

  group('5. determinism', () {
    test('markdown / html render byte-identically', () {
      final stats = CorpusStatistics.compute(corpus, graph);
      expect(CorpusStatisticsRenderer.renderMarkdown(stats),
          CorpusStatisticsRenderer.renderMarkdown(stats));
      expect(CorpusStatisticsRenderer.renderHtml(stats),
          CorpusStatisticsRenderer.renderHtml(stats));
    });
  });
}
