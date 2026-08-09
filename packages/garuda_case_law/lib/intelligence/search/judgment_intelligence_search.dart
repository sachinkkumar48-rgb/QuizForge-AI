/// Judgment Intelligence search (TITAN-KO-015.0 P4).
///
/// Ranked, evidence-backed search over the structured intelligence of the case
/// corpus. Supports exact, prefix and substring matching across issues,
/// holdings, ratios, articles, acts, doctrines, judges, bench, outcome, UPSC
/// themes, Prelims traps, Mains themes, significance and free keywords, plus
/// autocomplete over the indexed vocabulary.
///
/// This is NOT the P5 graph search — it operates over the P4 intelligence
/// layers only.
library;

import '../../domain/entities/case_knowledge_object.dart';
import '../domain/intelligence_enums.dart';
import '../domain/judgment_intelligence.dart';

/// Search query payload for Judgment Intelligence.
class JudgmentIntelligenceSearchQuery {
  final String? legalIssue;
  final String? holding;
  final String? ratio;
  final String? article;
  final String? act;
  final String? doctrine;
  final String? judge;
  final String? bench;
  final OutcomeDisposition? outcome;
  final String? upscTheme;
  final String? prelimsTrap;
  final String? mainsTheme;
  final String? significance;
  final String? keyword;

  /// When true, prefix matches rank above substring matches.
  final bool prefixMatch;

  /// Maximum number of hits to return.
  final int? limit;

  const JudgmentIntelligenceSearchQuery({
    this.legalIssue,
    this.holding,
    this.ratio,
    this.article,
    this.act,
    this.doctrine,
    this.judge,
    this.bench,
    this.outcome,
    this.upscTheme,
    this.prelimsTrap,
    this.mainsTheme,
    this.significance,
    this.keyword,
    this.prefixMatch = true,
    this.limit,
  });

  /// Whether no field of the query is set.
  bool get isEmpty =>
      legalIssue == null &&
      holding == null &&
      ratio == null &&
      article == null &&
      act == null &&
      doctrine == null &&
      judge == null &&
      bench == null &&
      outcome == null &&
      upscTheme == null &&
      prelimsTrap == null &&
      mainsTheme == null &&
      significance == null &&
      keyword == null;
}

/// A ranked search result.
class JudgmentIntelligenceSearchHit {
  final String caseId;
  final String caseName;
  final double score;

  /// Fields of the case's intelligence that matched (e.g. 'holding', 'ratio').
  final List<String> matchedFields;

  const JudgmentIntelligenceSearchHit({
    required this.caseId,
    required this.caseName,
    required this.score,
    required this.matchedFields,
  });
}

/// Ranked search engine over Judgment Intelligence.
class JudgmentIntelligenceSearchEngine {
  /// Executes a query over the given cases. Cases without intelligence score
  /// zero and are excluded. Results are sorted by descending score.
  static List<JudgmentIntelligenceSearchHit> search({
    required List<CaseKnowledgeObject> cases,
    JudgmentIntelligenceSearchQuery query = const JudgmentIntelligenceSearchQuery(),
  }) {
    if (query.isEmpty) return const [];
    final hits = <JudgmentIntelligenceSearchHit>[];
    for (final c in cases) {
      final intel = c.judgmentIntelligence;
      if (intel == null) continue;
      final score = _scoreCase(c, intel, query);
      if (score > 0) {
        hits.add(JudgmentIntelligenceSearchHit(
          caseId: c.caseId,
          caseName: c.caseName,
          score: score,
          matchedFields: _matchedFields(intel, query),
        ));
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    final limit = query.limit;
    return limit != null && limit >= 0 && hits.length > limit
        ? hits.sublist(0, limit)
        : hits;
  }

  /// Suggests indexed terms that start with [prefix]. Returns distinct terms,
  /// ranked by how many cases reference them.
  static List<String> autocomplete({
    required List<CaseKnowledgeObject> cases,
    required String prefix,
    int limit = 10,
  }) {
    final termCount = <String, int>{};
    final lower = prefix.toLowerCase();
    for (final c in cases) {
      final intel = c.judgmentIntelligence;
      if (intel == null) continue;
      for (final term in _indexedTerms(intel)) {
        if (term.toLowerCase().startsWith(lower)) {
          termCount[term] = (termCount[term] ?? 0) + 1;
        }
      }
    }
    final terms = termCount.keys.toList()
      ..sort((a, b) {
        final byCount = termCount[b]!.compareTo(termCount[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return terms.take(limit).toList(growable: false);
  }

  // -------------------------------------------------------------------------
  // Scoring
  // -------------------------------------------------------------------------

  static double _scoreCase(
      CaseKnowledgeObject c, JudgmentIntelligence intel, JudgmentIntelligenceSearchQuery q) {
    var score = 0.0;
    if (q.keyword != null) score += _matchAll(q.keyword!, intel) * 2.0;
    if (q.legalIssue != null) score += _scoreList(q.legalIssue!, intel.issues.map((e) => e.issue));
    if (q.holding != null) score += _scoreList(q.holding!, intel.holdings.map((e) => '${e.holding} ${e.legalPrinciple}'));
    if (q.ratio != null) score += _scoreList(q.ratio!, intel.ratios.map((e) => '${e.ratio} ${e.constitutionalBasis}'));
    if (q.article != null) score += _scoreList(q.article!, intel.issues.expand((e) => e.relatedArticles));
    if (q.act != null) score += _scoreList(q.act!, intel.issues.expand((e) => e.relatedActs));
    if (q.doctrine != null) score += _scoreList(q.doctrine!, intel.reasoning?.doctrinalReasoning ?? const []);
    if (q.judge != null) score += _scoreList(q.judge!, intel.bench?.judgeNames ?? const []);
    if (q.bench != null) score += _scoreText(q.bench!, intel.bench?.constitutionOfBench ?? '');
    if (q.outcome != null) {
      if (intel.outcome?.disposition == q.outcome) score += 1.0;
    }
    if (q.upscTheme != null) score += _scoreList(q.upscTheme!, intel.upscIntelligence?.mainsThemes ?? const []);
    if (q.prelimsTrap != null) score += _scoreList(q.prelimsTrap!, intel.upscIntelligence?.prelimsTraps ?? const []);
    if (q.mainsTheme != null) score += _scoreList(q.mainsTheme!, intel.upscIntelligence?.mainsThemes ?? const []);
    if (q.significance != null) {
      final sig = intel.judicialSignificance;
      if (sig != null) {
        score += _scoreText(q.significance!,
            '${sig.constitutionalSignificance} ${sig.upscSignificance}');
      }
    }
    return score;
  }

  static double _scoreList(String term, Iterable<String> values) {
    var s = 0.0;
    for (final v in values) {
      if (v.trim().isEmpty) continue;
      s += _matchWeight(term, v);
    }
    return s;
  }

  static double _scoreText(String term, String text) =>
      text.trim().isEmpty ? 0.0 : _matchWeight(term, text);

  /// Exact > prefix > substring.
  static double _matchWeight(String term, String value) {
    final t = term.trim().toLowerCase();
    final v = value.trim().toLowerCase();
    if (t.isEmpty) return 0;
    if (v == t) return 1.0;
    if (v.startsWith(t)) return 0.7;
    if (v.contains(t)) return 0.4;
    // token-level prefix match ("Golak" matches "Golaknath")
    final tokens = v.split(RegExp(r'[\s,.;:]+'));
    for (final tok in tokens) {
      if (tok.startsWith(t)) return 0.6;
      if (tok.contains(t)) return 0.35;
    }
    return 0;
  }

  static double _matchAll(String term, JudgmentIntelligence intel) {
    var s = 0.0;
    s += _scoreList(term, intel.issues.map((e) => e.issue));
    s += _scoreList(term, intel.holdings.map((e) => e.holding));
    s += _scoreList(term, intel.ratios.map((e) => e.ratio));
    s += _scoreList(term, intel.upscIntelligence?.prelimsFacts ?? const []);
    s += _scoreList(term, intel.upscIntelligence?.prelimsTraps ?? const []);
    s += _scoreList(term, intel.upscIntelligence?.mainsThemes ?? const []);
    s += _scoreList(term, intel.upscIntelligence?.essayThemes ?? const []);
    s += _scoreList(term, intel.upscIntelligence?.interviewAreas ?? const []);
    s += _scoreList(term, intel.upscIntelligence?.answerKeywords ?? const []);
    s += _scoreList(term, intel.bench?.judgeNames ?? const []);
    if (intel.reasoning != null) {
      s += _scoreText(term, intel.reasoning!.summary);
      s += _scoreList(term, intel.reasoning!.doctrinalReasoning);
    }
    if (intel.outcome != null) {
      s += _scoreText(term, intel.outcome!.operativeResult);
    }
    if (intel.judicialSignificance != null) {
      s += _scoreText(term, intel.judicialSignificance!.constitutionalSignificance);
    }
    return s;
  }

  static List<String> _matchedFields(
      JudgmentIntelligence intel, JudgmentIntelligenceSearchQuery q) {
    final fields = <String>{};
    if (q.keyword != null) fields.add('keyword');
    if (q.legalIssue != null && _scoreList(q.legalIssue!, intel.issues.map((e) => e.issue)) > 0) {
      fields.add('issue');
    }
    if (q.holding != null &&
        _scoreList(q.holding!, intel.holdings.map((e) => e.holding)) > 0) {
      fields.add('holding');
    }
    if (q.ratio != null && _scoreList(q.ratio!, intel.ratios.map((e) => e.ratio)) > 0) {
      fields.add('ratio');
    }
    if (q.article != null && _scoreList(q.article!, intel.issues.expand((e) => e.relatedArticles)) > 0) {
      fields.add('article');
    }
    if (q.judge != null && _scoreList(q.judge!, intel.bench?.judgeNames ?? const []) > 0) {
      fields.add('judge');
    }
    if (q.outcome != null && intel.outcome?.disposition == q.outcome) fields.add('outcome');
    if (q.prelimsTrap != null && _scoreList(q.prelimsTrap!, intel.upscIntelligence?.prelimsTraps ?? const []) > 0) {
      fields.add('prelimsTrap');
    }
    if (q.mainsTheme != null && _scoreList(q.mainsTheme!, intel.upscIntelligence?.mainsThemes ?? const []) > 0) {
      fields.add('mainsTheme');
    }
    return fields.toList()..sort();
  }

  static Iterable<String> _indexedTerms(JudgmentIntelligence intel) sync* {
    for (final i in intel.issues) {
      yield i.issue;
      yield* i.relatedArticles;
      yield* i.relatedActs;
    }
    for (final h in intel.holdings) {
      yield h.holding;
      yield h.legalPrinciple;
    }
    for (final r in intel.ratios) {
      yield r.ratio;
      yield r.constitutionalBasis;
    }
    yield* intel.bench?.judgeNames ?? const [];
    if (intel.bench != null) yield intel.bench!.constitutionOfBench;
    if (intel.reasoning != null) {
      yield intel.reasoning!.summary;
      yield* intel.reasoning!.doctrinalReasoning;
      yield* intel.reasoning!.reasoningTools;
    }
    final upsc = intel.upscIntelligence;
    if (upsc != null) {
      yield* upsc.prelimsFacts;
      yield* upsc.prelimsTraps;
      yield* upsc.mainsThemes;
      yield* upsc.mainsArguments;
      yield* upsc.answerKeywords;
      yield* upsc.essayThemes;
      yield* upsc.interviewAreas;
      yield* upsc.answerEnrichmentPoints;
    }
  }
}
