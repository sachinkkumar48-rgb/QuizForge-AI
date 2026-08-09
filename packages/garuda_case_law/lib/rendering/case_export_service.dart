/// P8 export orchestration (TITAN-KO-015.0 P8).
///
/// A thin orchestration layer over the renderers: it resolves cases through the
/// existing [CaseRepository], obtains the P5 [LegalGraph] (injected or built
/// deterministically from the corpus), and delegates analytics to the existing
/// P4/P5 APIs. It never performs legal research, evidence discovery, graph
/// inference or content generation — it only renders what already exists.
///
/// All output is deterministic and offline-first.
library;

import 'dart:convert';

import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

import '../domain/entities/case_knowledge_object.dart';
import '../graph/data/legal_graph_seed.dart';
import '../graph/domain/legal_graph.dart';
import '../repositories/case_repository.dart';
import '../repositories/in_memory_case_repository.dart';
import 'corpus_index_renderer.dart';
import 'corpus_statistics_renderer.dart';
import 'html_case_renderer.dart';
import 'json_case_renderer.dart';
import 'markdown_case_renderer.dart';
import 'render_format.dart';

class CaseExportService {
  final CaseRepository? repository;
  final List<CaseKnowledgeObject>? explicitCases;
  final LegalGraph? graph;

  const CaseExportService({this.repository, this.explicitCases, this.graph});

  /// The repository used for lookups. When [explicitCases] is supplied the
  /// repository is scoped to those cases so lookup stays consistent.
  CaseRepository get _repository {
    final r = repository;
    if (r != null) return r;
    final cases = explicitCases;
    return cases == null
        ? InMemoryCaseRepository()
        : InMemoryCaseRepository(cases: cases);
  }

  Future<List<CaseKnowledgeObject>> _cases() async {
    final cases = explicitCases;
    return cases ?? await _repository.getCases();
  }

  Future<CaseKnowledgeObject?> _findCase(String idOrName) async {
    final cases = explicitCases;
    if (cases != null) {
      final raw = idOrName.trim();
      if (raw.isEmpty) return null;
      final upper = raw.toUpperCase();
      for (final c in cases) {
        if (c.caseId.toUpperCase() == upper ||
            c.objectId.toUpperCase() == upper ||
            c.citation.toUpperCase() == upper ||
            c.caseName.toUpperCase() == upper ||
            c.aliases.any((a) => a.toUpperCase() == upper)) {
          return c;
        }
      }
      return null;
    }
    return _repository.findCase(idOrName);
  }

  /// The effective graph: an injected P5 graph, or the deterministic
  /// corpus→graph projection of the resolved cases. Never reconstructed by P8 —
  /// the projection is the existing `LegalGraphSeed` derivation.
  LegalGraph _effectiveGraph(List<CaseKnowledgeObject> cases) {
    final g = graph;
    if (g != null) return g;
    return LegalGraphSeed.fromCorpora(
      cases: cases,
      doctrines: DoctrineSeedData.doctrines,
    ).build();
  }

  // -------------------------------------------------------------------------
  // Individual case
  // -------------------------------------------------------------------------

  /// Renders a single case (by caseId, objectId, citation, name or alias) in
  /// [format]. Throws [ArgumentError] when no case matches.
  Future<String> exportCase(String idOrName, RenderFormat format) async {
    final c = await _findCase(idOrName);
    if (c == null) {
      throw ArgumentError.value(idOrName, 'idOrName', 'No case found');
    }
    final g = _effectiveGraph(await _cases());
    switch (format) {
      case RenderFormat.markdown:
        return MarkdownCaseRenderer.render(c, graph: g);
      case RenderFormat.html:
        return HtmlCaseRenderer.render(c, graph: g);
      case RenderFormat.json:
        return JsonCaseRenderer.renderString(c);
    }
  }

  /// The canonical JSON map for a single case (unchanged from
  /// `CaseKnowledgeObject.toJson()`).
  Future<Map<String, dynamic>> exportCaseJson(String idOrName) async {
    final c = await _findCase(idOrName);
    if (c == null) {
      throw ArgumentError.value(idOrName, 'idOrName', 'No case found');
    }
    return JsonCaseRenderer.renderMap(c);
  }

  // -------------------------------------------------------------------------
  // Full corpus
  // -------------------------------------------------------------------------

  /// Renders every case in the corpus in [format].
  Future<String> exportCorpus(RenderFormat format) async {
    final cases = await _cases();
    final g = _effectiveGraph(cases);
    switch (format) {
      case RenderFormat.markdown:
        return cases
            .map((c) => MarkdownCaseRenderer.render(c, graph: g))
            .join('\n\n---\n\n');
      case RenderFormat.html:
        final inner =
            cases.map((c) => HtmlCaseRenderer.render(c, graph: g)).join('\n');
        return '<div class="garuda-corpus">\n$inner\n</div>';
      case RenderFormat.json:
        return JsonCaseRenderer.renderCorpusString(cases);
    }
  }

  /// The full corpus as a JSON array of canonical case maps (no envelope —
  /// pure canonical serialization).
  Future<List<Map<String, dynamic>>> exportCorpusJson() async {
    final cases = await _cases();
    return [for (final c in cases) JsonCaseRenderer.renderMap(c)];
  }

  // -------------------------------------------------------------------------
  // Corpus index
  // -------------------------------------------------------------------------

  Future<String> exportCorpusIndex(RenderFormat format) async {
    final cases = await _cases();
    switch (format) {
      case RenderFormat.markdown:
        return CorpusIndexRenderer.renderMarkdown(cases);
      case RenderFormat.html:
        return CorpusIndexRenderer.renderHtml(cases);
      case RenderFormat.json:
        return const JsonEncoder.withIndent('  ')
            .convert(CorpusIndexRenderer.renderJson(cases));
    }
  }

  Future<Map<String, dynamic>> exportCorpusIndexJson() async {
    final cases = await _cases();
    return CorpusIndexRenderer.renderJson(cases);
  }

  // -------------------------------------------------------------------------
  // Corpus statistics
  // -------------------------------------------------------------------------

  /// Computes corpus statistics by delegating to the existing P4/P5 analytics.
  Future<CorpusStatistics> computeCorpusStatistics() async {
    final cases = await _cases();
    return CorpusStatistics.compute(cases, _effectiveGraph(cases));
  }

  Future<String> exportCorpusStatistics(RenderFormat format) async {
    final stats = await computeCorpusStatistics();
    switch (format) {
      case RenderFormat.markdown:
        return CorpusStatisticsRenderer.renderMarkdown(stats);
      case RenderFormat.html:
        return CorpusStatisticsRenderer.renderHtml(stats);
      case RenderFormat.json:
        return const JsonEncoder.withIndent('  ').convert(stats.toJson());
    }
  }

  Future<Map<String, dynamic>> exportCorpusStatisticsJson() async {
    final stats = await computeCorpusStatistics();
    return stats.toJson();
  }
}
