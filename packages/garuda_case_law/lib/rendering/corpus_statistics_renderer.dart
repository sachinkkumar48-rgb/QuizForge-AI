/// Corpus statistics rendering (TITAN-KO-015.0 P8).
///
/// Statistics REUSE the existing P4 `JudgmentIntelligenceAnalytics` and P5
/// `LegalGraphAnalytics` — nothing is independently recalculated. Evidence
/// coverage reuses the existing `CaseCorpusSupport.evidenceCoverage` metric.
/// The renderer only formats those already-derived metrics deterministically.
library;

import 'package:meta/meta.dart';

import '../data/case_corpus_support.dart';
import '../domain/entities/case_knowledge_object.dart';
import '../graph/analytics/legal_graph_analytics.dart';
import '../graph/domain/legal_graph.dart';
import '../graph/domain/legal_graph_path.dart';
import '../intelligence/analytics/judgment_intelligence_analytics.dart';
import 'html_safety.dart';

/// A deterministic statistics snapshot computed from the existing analytics.
@immutable
class CorpusStatistics {
  final int totalCases;
  final JudgmentIntelligenceAnalyticsReport intelligence;
  final LegalGraphAnalyticsReport graph;
  final double evidenceCoverage;

  const CorpusStatistics({
    required this.totalCases,
    required this.intelligence,
    required this.graph,
    required this.evidenceCoverage,
  });

  /// Computes statistics by delegating to the existing analytics APIs.
  factory CorpusStatistics.compute(
      List<CaseKnowledgeObject> cases, LegalGraph graph) {
    final intel = JudgmentIntelligenceAnalytics.analyze(cases);
    final g = LegalGraphAnalytics.compute(graph);
    return CorpusStatistics(
      totalCases: cases.length,
      intelligence: intel,
      graph: g,
      evidenceCoverage: CaseCorpusSupport.evidenceCoverage(cases),
    );
  }

  /// Deterministic JSON serialization. The intelligence half reuses the
  /// existing analytics report serialization; the graph half is projected from
  /// the existing report fields (there is no competing graph metric).
  Map<String, dynamic> toJson() => {
        'totalCases': totalCases,
        'evidenceCoverage': evidenceCoverage,
        'intelligence': intelligence.toJson(),
        'graph': {
          'totalNodes': graph.totalNodes,
          'totalEdges': graph.totalEdges,
          'caseCount': graph.caseCount,
          'doctrineCount': graph.doctrineCount,
          'caseCaseEdges': graph.caseCaseEdges,
          'caseDoctrineEdges': graph.caseDoctrineEdges,
          'relationshipTypeDistribution':
              _sorted(graph.relationshipTypeDistribution),
          'precedentTypeDistribution': _sorted(graph.precedentTypeDistribution),
          'doctrineTypeDistribution': _sorted(graph.doctrineTypeDistribution),
          'mostConnectedCases': [
            for (final c in graph.mostConnectedCases)
              {'caseId': c.caseId, 'degree': c.degree},
          ],
          'mostConnectedDoctrines': [
            for (final d in graph.mostConnectedDoctrines)
              {'doctrineId': d.doctrineId, 'caseCount': d.caseCount},
          ],
          'isolatedCases': List<String>.of(graph.isolatedCases),
          'connectivityComponents': graph.connectivityComponents,
          'largestComponentSize': graph.largestComponentSize,
          'longestPrecedentChain': _pathJson(graph.longestPrecedentChain),
        },
      };

  static Map<String, dynamic>? _pathJson(LegalGraphPath? path) {
    if (path == null) return null;
    return {
      'length': path.length,
      'nodes': path.nodeIds,
      'edgeLabels': path.edgeLabels,
    };
  }

  static Map<String, int> _sorted(Map<String, int> map) {
    final keys = map.keys.toList()..sort();
    return {for (final k in keys) k: map[k]!};
  }
}

/// Renders [CorpusStatistics] to Markdown, HTML and JSON.
class CorpusStatisticsRenderer {
  static String renderMarkdown(CorpusStatistics s) => _md(s);

  static String renderHtml(CorpusStatistics s) => _html(s);

  static Map<String, dynamic> renderJson(CorpusStatistics s) => s.toJson();

  // -------------------------------------------------------------------------
  // Markdown
  // -------------------------------------------------------------------------

  static String _md(CorpusStatistics s) {
    final b = StringBuffer();
    final i = s.intelligence;
    final g = s.graph;

    b.writeln('# GARUDA Landmark Case Corpus Statistics');
    b.writeln();
    b.writeln('**Total cases:** ${s.totalCases}');
    b.writeln('**Evidence coverage:** ${_pct(s.evidenceCoverage)}');
    b.writeln(
        '**Completeness index:** ${i.completenessIndex.toStringAsFixed(3)}');
    b.writeln();

    b.writeln('## Judgment Intelligence (P4)');
    b.writeln();
    _mdRow(b, 'Cases with bench', i.casesWithBench, i.benchCoverageRate);
    _mdRow(b, 'Cases with verified bench', i.casesWithVerifiedBench, null);
    _mdRow(
        b, 'Cases with holdings', i.casesWithHoldings, i.holdingCoverageRate);
    _mdRow(
        b, 'Cases with ratio decidendi', i.casesWithRatio, i.ratioCoverageRate);
    _mdRow(b, 'Cases with reasoning', i.casesWithReasoning,
        i.reasoningCoverageRate);
    _mdRow(b, 'Cases with outcome', i.casesWithOutcome, i.outcomeCoverageRate);
    _mdRow(b, 'Cases with significance', i.casesWithSignificance, null);
    _mdRow(b, 'Cases with UPSC intelligence', i.casesWithUpscIntelligence,
        i.upscCoverageRate);
    _mdRow(b, 'Cases with timeline', i.casesWithTimeline, null);
    b.writeln();
    b.writeln('UPSC coverage — prelims: ${_pct(i.prelimsCoverageRate)}, '
        'mains: ${_pct(i.mainsCoverageRate)}, '
        'interview: ${_pct(i.interviewCoverageRate)}');
    if (i.articleFrequency.isNotEmpty) {
      b.writeln();
      b.writeln('### Most cited constitutional articles');
      final top = _topN(i.articleFrequency, 10);
      for (final MapEntry(:key, :value) in top) {
        b.writeln('- **$key** — cited by $value case(s)');
      }
    }
    b.writeln();

    b.writeln('## Precedent & Doctrine Graph (P5)');
    b.writeln();
    b.writeln('- **Nodes:** ${g.totalNodes} '
        '(${g.caseCount} cases, ${g.doctrineCount} doctrines)');
    b.writeln('- **Edges:** ${g.totalEdges} '
        '(${g.caseCaseEdges} case→case, ${g.caseDoctrineEdges} case→doctrine)');
    b.writeln('- **Connectivity components:** ${g.connectivityComponents} '
        '(largest: ${g.largestComponentSize})');
    if (g.isolatedCases.isNotEmpty) {
      b.writeln('- **Isolated cases:** ${g.isolatedCases.join(', ')}');
    }
    if (g.relationshipTypeDistribution.isNotEmpty) {
      b.writeln();
      b.writeln('### Relationship type distribution');
      for (final MapEntry(:key, :value)
          in g.relationshipTypeDistribution.entries) {
        b.writeln('- **$key** — $value');
      }
    }
    if (g.mostConnectedCases.isNotEmpty) {
      b.writeln();
      b.writeln('### Most connected cases');
      for (final c in g.mostConnectedCases.take(10)) {
        b.writeln('- **${c.caseId}** — degree ${c.degree}');
      }
    }
    if (g.longestPrecedentChain != null) {
      final chain = g.longestPrecedentChain!;
      b.writeln();
      b.writeln('### Longest evidence-backed precedent chain '
          '(${chain.length} hops)');
      b.writeln();
      b.writeln('> ${chain.toString()}');
    }
    b.writeln();
    return b.toString();
  }

  static void _mdRow(StringBuffer b, String label, int count, double? rate) {
    b.writeln('- **$label:** $count'
        '${rate == null ? '' : ' (${_pct(rate)})'}');
  }

  // -------------------------------------------------------------------------
  // HTML
  // -------------------------------------------------------------------------

  static String _html(CorpusStatistics s) {
    final b = StringBuffer();
    final i = s.intelligence;
    final g = s.graph;
    final esc = HtmlSafety.escapeText;

    b.writeln(
        '<section class="corpus-statistics" aria-label="Corpus statistics">');
    b.writeln('  <h1>GARUDA Landmark Case Corpus Statistics</h1>');
    b.writeln('  <p class="stats-meta">Total cases: ${s.totalCases} · '
        'Evidence coverage: ${_pct(s.evidenceCoverage)} · '
        'Completeness index: ${i.completenessIndex.toStringAsFixed(3)}</p>');

    b.writeln('  <section class="stats-intelligence" '
        'aria-label="Judgment intelligence">');
    b.writeln('    <h2>Judgment Intelligence (P4)</h2>');
    b.writeln('    <ul class="stats-list">');
    _htmlRow(b, 'Cases with bench', i.casesWithBench, i.benchCoverageRate);
    _htmlRow(b, 'Cases with verified bench', i.casesWithVerifiedBench, null);
    _htmlRow(
        b, 'Cases with holdings', i.casesWithHoldings, i.holdingCoverageRate);
    _htmlRow(
        b, 'Cases with ratio decidendi', i.casesWithRatio, i.ratioCoverageRate);
    _htmlRow(b, 'Cases with reasoning', i.casesWithReasoning,
        i.reasoningCoverageRate);
    _htmlRow(
        b, 'Cases with outcome', i.casesWithOutcome, i.outcomeCoverageRate);
    _htmlRow(b, 'Cases with significance', i.casesWithSignificance, null);
    _htmlRow(b, 'Cases with UPSC intelligence', i.casesWithUpscIntelligence,
        i.upscCoverageRate);
    _htmlRow(b, 'Cases with timeline', i.casesWithTimeline, null);
    b.writeln('    </ul>');
    b.writeln('    <p class="stats-note">UPSC coverage — prelims: '
        '${_pct(i.prelimsCoverageRate)}, mains: ${_pct(i.mainsCoverageRate)}, '
        'interview: ${_pct(i.interviewCoverageRate)}</p>');
    if (i.articleFrequency.isNotEmpty) {
      b.writeln('    <h3>Most cited constitutional articles</h3>');
      b.writeln('    <ul class="stats-list">');
      for (final MapEntry(:key, :value) in _topN(i.articleFrequency, 10)) {
        b.writeln('      <li><strong>${esc(key)}</strong> — '
            'cited by $value case(s)</li>');
      }
      b.writeln('    </ul>');
    }
    b.writeln('  </section>');

    b.writeln('  <section class="stats-graph" aria-label="Precedent and '
        'doctrine graph">');
    b.writeln('    <h2>Precedent &amp; Doctrine Graph (P5)</h2>');
    b.writeln('    <ul class="stats-list">');
    b.writeln('      <li><strong>Nodes:</strong> ${g.totalNodes} '
        '(${g.caseCount} cases, ${g.doctrineCount} doctrines)</li>');
    b.writeln('      <li><strong>Edges:</strong> ${g.totalEdges} '
        '(${g.caseCaseEdges} case→case, ${g.caseDoctrineEdges} case→doctrine)</li>');
    b.writeln('      <li><strong>Connectivity components:</strong> '
        '${g.connectivityComponents} (largest: ${g.largestComponentSize})</li>');
    if (g.isolatedCases.isNotEmpty) {
      b.writeln('      <li><strong>Isolated cases:</strong> '
          '${esc(g.isolatedCases.join(', '))}</li>');
    }
    b.writeln('    </ul>');
    if (g.relationshipTypeDistribution.isNotEmpty) {
      b.writeln('    <h3>Relationship type distribution</h3>');
      b.writeln('    <ul class="stats-list">');
      for (final MapEntry(:key, :value)
          in g.relationshipTypeDistribution.entries) {
        b.writeln('      <li><strong>${esc(key)}</strong> — $value</li>');
      }
      b.writeln('    </ul>');
    }
    if (g.mostConnectedCases.isNotEmpty) {
      b.writeln('    <h3>Most connected cases</h3>');
      b.writeln('    <ul class="stats-list">');
      for (final c in g.mostConnectedCases.take(10)) {
        b.writeln('      <li><strong>${esc(c.caseId)}</strong> — '
            'degree ${c.degree}</li>');
      }
      b.writeln('    </ul>');
    }
    if (g.longestPrecedentChain != null) {
      b.writeln('    <h3>Longest evidence-backed precedent chain '
          '(${g.longestPrecedentChain!.length} hops)</h3>');
      b.writeln('    <blockquote class="quotation">'
          '${esc(g.longestPrecedentChain!.toString())}</blockquote>');
    }
    b.writeln('  </section>');

    b.writeln('</section>');
    return b.toString();
  }

  static void _htmlRow(StringBuffer b, String label, int count, double? rate) {
    b.writeln('      <li><strong>${HtmlSafety.escapeText(label)}:</strong> '
        '$count${rate == null ? '' : ' (${_pct(rate)})'}</li>');
  }

  // -------------------------------------------------------------------------
  // Shared helpers
  // -------------------------------------------------------------------------

  static String _pct(double v) => '${(v * 100).toStringAsFixed(1)}%';

  /// Deterministic top-N by value (ties broken by key) over a frequency map.
  static List<MapEntry<String, int>> _topN(Map<String, int> map, int n) {
    final sorted = map.entries.toList()
      ..sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        return byValue != 0 ? byValue : a.key.compareTo(b.key);
      });
    return sorted.take(n).toList();
  }
}
