/// Corpus index rendering (TITAN-KO-015.0 P8).
///
/// A deterministic index over the validated landmark-case corpus. Organization
/// (chronology, doctrine, constitutional article, UPSC relevance) is derived
/// ONLY from existing case metadata — no classifications are invented. The
/// index is a summary listing; full evidence and relationship preservation
/// lives in the per-case renders.
library;

import 'package:meta/meta.dart';

import '../domain/entities/case_enums.dart' show RelevanceLevel;
import '../domain/entities/case_knowledge_object.dart';
import 'html_safety.dart';

/// A single deterministic index entry.
@immutable
class CorpusIndexEntry {
  final String caseId;
  final String caseName;
  final int year;
  final String citation;
  final String court;
  final String oneLineSummary;

  const CorpusIndexEntry({
    required this.caseId,
    required this.caseName,
    required this.year,
    required this.citation,
    required this.court,
    required this.oneLineSummary,
  });

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'caseName': caseName,
        'year': year,
        'citation': citation,
        'court': court,
        if (oneLineSummary.isNotEmpty) 'oneLineSummary': oneLineSummary,
      };
}

/// Immutable, deterministic corpus index.
@immutable
class CorpusIndex {
  /// Entries sorted by (year, caseId).
  final List<CorpusIndexEntry> entries;

  /// Decade label (e.g. `1970s`) → case IDs, sorted.
  final Map<String, List<String>> byDecade;

  /// Doctrine ID → case IDs engaging it, sorted.
  final Map<String, List<String>> byDoctrine;

  /// Constitutional article → case IDs, sorted.
  final Map<String, List<String>> byArticle;

  /// UPSC relevance level → case IDs, sorted (excludes `notApplicable`).
  final Map<String, List<String>> byPrelimsRelevance;

  const CorpusIndex({
    required this.entries,
    required this.byDecade,
    required this.byDoctrine,
    required this.byArticle,
    required this.byPrelimsRelevance,
  });

  int get totalCases => entries.length;

  /// Builds the index from [cases]. All ordering and grouping is derived from
  /// case metadata; nothing is invented.
  factory CorpusIndex.build(List<CaseKnowledgeObject> cases) {
    final entries = <CorpusIndexEntry>[
      for (final c in cases)
        CorpusIndexEntry(
          caseId: c.caseId,
          caseName: c.caseName,
          year: c.year,
          citation: c.citation,
          court: c.court,
          oneLineSummary: c.oneLineSummary,
        ),
    ]..sort((a, b) {
        final byYear = a.year.compareTo(b.year);
        return byYear != 0 ? byYear : a.caseId.compareTo(b.caseId);
      });

    final byDecade = <String, List<String>>{};
    final byDoctrine = <String, List<String>>{};
    final byArticle = <String, List<String>>{};
    final byPrelims = <String, List<String>>{};

    void add(Map<String, List<String>> map, String key, String caseId) {
      map.putIfAbsent(key, () => []).add(caseId);
    }

    for (final c in cases) {
      if (c.year > 0) add(byDecade, '${c.year ~/ 10 * 10}s', c.caseId);
      for (final d in c.doctrines) {
        add(byDoctrine, d, c.caseId);
      }
      for (final a in c.relatedArticles) {
        add(byArticle, a, c.caseId);
      }
      if (c.prelimsRelevance != RelevanceLevel.notApplicable) {
        add(byPrelims, c.prelimsRelevance.name, c.caseId);
      }
    }

    Map<String, List<String>> sorted(Map<String, List<String>> map) {
      final keys = map.keys.toList()..sort();
      return {
        for (final k in keys) k: List<String>.of(map[k]!)..sort(),
      };
    }

    return CorpusIndex(
      entries: entries,
      byDecade: sorted(byDecade),
      byDoctrine: sorted(byDoctrine),
      byArticle: sorted(byArticle),
      byPrelimsRelevance: sorted(byPrelims),
    );
  }
}

/// Renders a [CorpusIndex] (or a raw corpus) to Markdown, HTML and JSON.
class CorpusIndexRenderer {
  // -------------------------------------------------------------------------
  // Markdown
  // -------------------------------------------------------------------------

  static String renderMarkdown(List<CaseKnowledgeObject> cases) =>
      _indexMarkdown(CorpusIndex.build(cases));

  static String renderMarkdownIndex(CorpusIndex index) => _indexMarkdown(index);

  static String _indexMarkdown(CorpusIndex index) {
    final b = StringBuffer();
    b.writeln('# GARUDA Landmark Case Corpus Index');
    b.writeln();
    b.writeln('${index.totalCases} landmark cases — deterministic, offline, '
        'evidence-backed.');
    b.writeln();

    b.writeln('## Chronology');
    b.writeln();
    for (final entry in index.entries) {
      b.writeln('- **${entry.caseId}** — ${entry.caseName} (${entry.year})');
    }
    b.writeln();

    void grouped(
        String title, Map<String, List<String>> groups, CorpusIndex idx) {
      if (groups.isEmpty) return;
      b.writeln('## $title');
      b.writeln();
      for (final MapEntry(:key, :value) in groups.entries) {
        b.writeln('### $key');
        for (final id in value) {
          final e = _byId(idx, id);
          b.writeln('- **$id** — ${e?.caseName ?? id}'
              '${e != null ? ' (${e.year})' : ''}');
        }
        b.writeln();
      }
    }

    grouped('By Doctrine', index.byDoctrine, index);
    grouped('By Constitutional Article', index.byArticle, index);
    grouped('By UPSC Relevance', index.byPrelimsRelevance, index);

    return b.toString();
  }

  static CorpusIndexEntry? _byId(CorpusIndex index, String id) {
    for (final e in index.entries) {
      if (e.caseId == id) return e;
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // HTML
  // -------------------------------------------------------------------------

  static String renderHtml(List<CaseKnowledgeObject> cases) =>
      _indexHtml(CorpusIndex.build(cases));

  static String renderHtmlIndex(CorpusIndex index) => _indexHtml(index);

  static String _indexHtml(CorpusIndex index) {
    final b = StringBuffer();
    b.writeln('<section class="corpus-index" aria-label="Corpus index">');
    b.writeln('  <h1>GARUDA Landmark Case Corpus Index</h1>');
    b.writeln('  <p class="index-meta">${index.totalCases} landmark cases — '
        'deterministic, offline, evidence-backed.</p>');

    b.writeln('  <section class="index-chronology" aria-label="Chronology">');
    b.writeln('    <h2>Chronology</h2>');
    b.writeln('    <ul class="index-list">');
    for (final entry in index.entries) {
      b.writeln(
          '      <li><strong>${HtmlSafety.escapeText(entry.caseId)}</strong> '
          '— ${HtmlSafety.escapeText(entry.caseName)} '
          '(${entry.year})</li>');
    }
    b.writeln('    </ul>');
    b.writeln('  </section>');

    void grouped(String title, Map<String, List<String>> groups) {
      if (groups.isEmpty) return;
      b.writeln('  <section class="index-group" aria-label="$title">');
      b.writeln('    <h2>${HtmlSafety.escapeText(title)}</h2>');
      for (final MapEntry(:key, :value) in groups.entries) {
        b.writeln('    <h3>${HtmlSafety.escapeText(key)}</h3>');
        b.writeln('    <ul class="index-list">');
        for (final id in value) {
          final e = _byId(index, id);
          b.writeln('      <li><strong>${HtmlSafety.escapeText(id)}</strong> — '
              '${HtmlSafety.escapeText(e?.caseName ?? id)}'
              '${e != null ? ' (${e.year})' : ''}</li>');
        }
        b.writeln('    </ul>');
      }
      b.writeln('  </section>');
    }

    grouped('By Doctrine', index.byDoctrine);
    grouped('By Constitutional Article', index.byArticle);
    grouped('By UPSC Relevance', index.byPrelimsRelevance);

    b.writeln('</section>');
    return b.toString();
  }

  // -------------------------------------------------------------------------
  // JSON
  // -------------------------------------------------------------------------

  static Map<String, dynamic> renderJson(List<CaseKnowledgeObject> cases) =>
      _indexJson(CorpusIndex.build(cases));

  static Map<String, dynamic> renderJsonIndex(CorpusIndex index) =>
      _indexJson(index);

  static Map<String, dynamic> _indexJson(CorpusIndex index) => {
        'totalCases': index.totalCases,
        'entries': index.entries.map((e) => e.toJson()).toList(),
        'groupings': {
          'byDecade': index.byDecade,
          'byDoctrine': index.byDoctrine,
          'byArticle': index.byArticle,
          'byPrelimsRelevance': index.byPrelimsRelevance,
        },
      };
}
