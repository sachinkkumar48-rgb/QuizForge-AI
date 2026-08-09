/// Deterministic in-memory index over the landmark case corpus
/// (TITAN-KO-015.0 P6).
///
/// Built from the actual 49-case corpus at construction time — no hard-coded
/// results. The index keeps the structured dimensions that map cleanly onto
/// `Map<String, Set<String>>` (name, alias, article, act, doctrine, judge,
/// year, court), a token keyword index with occurrence frequency, and the
/// autocomplete vocabulary. Everything is derived deterministically.
library;

import '../../domain/entities/case_knowledge_object.dart';
import '../../graph/domain/legal_graph_node_ref.dart';
import '../domain/case_search_suggestion.dart';
import 'case_search_normalizer.dart';

/// Field weights used by the engine's deterministic ranking.
///
/// Higher weight = the field is a stronger relevance signal. The priority is
/// documented in `P6_CASE_SEARCH_ENGINE.md`; changing a weight only changes
/// relative ordering of equal-quality matches, never what is searchable.
const Map<String, double> searchFieldWeights = {
  'caseName': 100,
  'alias': 90,
  'citation': 80,
  'article': 60,
  'act': 60,
  'doctrine': 60,
  'keyword': 55,
  'section': 55,
  'judge': 50,
  'issue': 40,
  'holding': 30,
  'ratio': 30,
  'reasoning': 25,
  'outcome': 25,
  'significance': 25,
  'upsc': 20,
  'timeline': 15,
  'text': 10,
};

/// The searchable field names in ranking-priority order (documentation aid).
const List<String> searchFieldOrder = [
  'caseName',
  'alias',
  'citation',
  'article',
  'act',
  'doctrine',
  'keyword',
  'section',
  'judge',
  'issue',
  'holding',
  'ratio',
  'reasoning',
  'outcome',
  'significance',
  'upsc',
  'timeline',
  'text',
];

/// Extracts every searchable value of a case, grouped by field name.
///
/// Only fields the corpus actually populates are produced. P3 record fields
/// and P4 `JudgmentIntelligence` layers are both covered; empty values are
/// skipped, never fabricated.
Map<String, List<String>> searchableFieldValues(CaseKnowledgeObject c) {
  final m = <String, List<String>>{};
  void add(String field, String v) {
    final t = v.trim();
    if (t.isEmpty) return;
    (m[field] ??= []).add(t);
  }

  void addAll(String field, Iterable<String> vs) {
    for (final v in vs) {
      add(field, v);
    }
  }

  // Identity & names
  add('caseName', c.caseName);
  addAll('alias', c.aliases);
  add('citation', c.citation);
  add('citation', c.neutralCitation);
  add('citation', c.reporterCitation);
  add('citation', c.judgmentTitle);

  // Structured legal references
  addAll('article', c.relatedArticles);
  addAll('act', c.relatedActs);
  addAll('section', c.sections);
  addAll('doctrine', c.doctrines);
  addAll('keyword', c.keywords);
  addAll('judge', c.judges);
  add('judge', c.authoringJudge);

  // P3 judgment text
  addAll('issue', c.issues);
  addAll('issue', c.constitutionalQuestions);
  addAll('issue', c.legalQuestions);
  addAll('ratio', c.ratioDecidendi);
  add('ratio', c.legalPrinciple);
  addAll('text', c.obiterDicta);
  addAll('text', c.keyPrinciples);
  add('significance', c.constitutionalSignificance);
  add('text', c.historicalContext);
  add('text', c.facts);
  addAll('text', c.petitionerArguments);
  addAll('text', c.respondentArguments);
  add('text', c.decision);
  add('text', c.majorityOpinion);
  add('text', c.minorityOpinion);
  add('text', c.dissent);
  add('text', c.oneLineSummary);
  add('text', c.detailedSummary);
  add('text', c.garudaExplanation);
  addAll('timeline', c.timeline);
  addAll('text', c.subsequentDevelopments);
  add('text', c.presentStatus);
  if (c.crossReferences.isNotEmpty) add('text', c.crossReferences.join(' '));

  // P4 Judgment Intelligence layers
  final intel = c.judgmentIntelligence;
  if (intel != null) {
    for (final i in intel.issues) {
      add('issue', i.issue);
      addAll('article', i.relatedArticles);
      addAll('act', i.relatedActs);
    }
    for (final h in intel.holdings) {
      add('holding', h.holding);
      add('holding', h.legalPrinciple);
    }
    for (final r in intel.ratios) {
      add('ratio', r.ratio);
      add('ratio', r.constitutionalBasis);
    }
    if (intel.reasoning != null) {
      add('reasoning', intel.reasoning!.summary);
      addAll('reasoning', intel.reasoning!.constitutionalPhilosophy);
      addAll('reasoning', intel.reasoning!.doctrinalReasoning);
      addAll('reasoning', intel.reasoning!.reasoningTools);
    }
    if (intel.outcome != null) {
      add('outcome', intel.outcome!.operativeResult);
      addAll('outcome', intel.outcome!.reliefGranted);
      addAll('outcome', intel.outcome!.reliefDenied);
      add('outcome', intel.outcome!.majorityOutcome);
      add('outcome', intel.outcome!.minorityOutcome ?? '');
    }
    if (intel.judicialSignificance != null) {
      add('significance',
          intel.judicialSignificance!.constitutionalSignificance);
      add('significance', intel.judicialSignificance!.legalSignificance);
      add('significance', intel.judicialSignificance!.upscSignificance);
      add('significance', intel.judicialSignificance!.historicalSignificance);
    }
    final upsc = intel.upscIntelligence;
    if (upsc != null) {
      addAll('upsc', upsc.prelimsFacts);
      addAll('upsc', upsc.prelimsTraps);
      addAll('upsc', upsc.mainsThemes);
      addAll('upsc', upsc.mainsArguments);
      addAll('upsc', upsc.mainsCounterarguments);
      addAll('upsc', upsc.answerKeywords);
      addAll('upsc', upsc.essayThemes);
      addAll('upsc', upsc.interviewAreas);
      addAll('upsc', upsc.answerEnrichmentPoints);
      addAll('upsc', upsc.contemporaryRelevance);
      addAll('upsc', upsc.likelyInterviewQuestions);
      addAll('upsc', upsc.conclusionIdeas);
    }
    for (final t in intel.timeline) {
      add('timeline', t.event);
      add('timeline', t.significance);
    }
  }

  return m;
}

/// Immutable snapshot of the inverted indexes over the corpus.
class CaseSearchIndex {
  final List<CaseKnowledgeObject> cases;

  final Map<String, CaseKnowledgeObject> _byCaseId = {};
  final Map<String, String> _caseNameToId = {};
  final Map<String, Set<String>> _byAlias = {};
  final Map<String, Set<String>> _byArticle = {};
  final Map<String, Set<String>> _byAct = {};
  final Map<String, Set<String>> _byDoctrine = {};
  final Map<String, Set<String>> _byJudge = {};
  final Map<int, Set<String>> _byYear = {};
  final Map<String, Set<String>> _byCourt = {};
  final Map<String, Set<String>> _keywordIndex = {};
  final Map<String, int> _keywordFrequency = {};
  final List<CaseSearchSuggestion> _vocabulary = [];

  /// doctrineId → display name (from the canonical doctrine library when the
  /// engine supplies doctrine nodes).
  final Map<String, String> doctrineIdToName;

  CaseSearchIndex({
    required this.cases,
    List<LegalGraphNodeRef>? doctrineNodes,
    Map<String, Set<String>>? doctrineCaseIds,
  }) : doctrineIdToName = doctrineNodes == null
            ? const {}
            : Map.unmodifiable({
                for (final n in doctrineNodes) n.id: n.name,
              }) {
    final cidMap = doctrineCaseIds ?? _deriveDoctrineCaseIds(cases);
    _build(cidMap);
  }

  // -------------------------------------------------------------------------
  // Lookups
  // -------------------------------------------------------------------------

  /// Number of cases indexed.
  int get indexedCaseCount => _byCaseId.length;

  /// Canonical case IDs of every indexed case.
  Set<String> get indexedCaseIds => Set.unmodifiable(_byCaseId.keys);

  /// Whether [id] is a known canonical case ID.
  bool hasCase(String id) => _byCaseId.containsKey(id);

  /// The case record for a canonical case ID, or null.
  CaseKnowledgeObject? byCaseId(String id) => _byCaseId[id];

  /// Resolves a canonical case ID, exact (case-insensitive) case ID, or
  /// exact normalized case name / alias to a canonical case ID.
  String? resolveCaseId(String idOrName) {
    final raw = idOrName.trim();
    if (raw.isEmpty) return null;
    if (_byCaseId.containsKey(raw)) return raw;
    final upper = raw.toUpperCase();
    if (_byCaseId.containsKey(upper)) return upper;
    final normalized = CaseSearchNormalizer.normalizeText(raw);
    if (_caseNameToId.containsKey(normalized)) return _caseNameToId[normalized];
    final aliasHits = _byAlias[normalized];
    if (aliasHits != null && aliasHits.length == 1) {
      return aliasHits.single;
    }
    return null;
  }

  /// Case IDs whose `relatedArticles` reference [article] under any supported
  /// variant (`21`, `Article 21`, `Art. 21`, `article21`).
  Set<String> caseIdsByArticle(String article) {
    final key = CaseSearchNormalizer.normalizeArticle(article);
    return key.isEmpty ? const {} : (_byArticle[key] ?? const {});
  }

  /// Case IDs whose `relatedActs` normalize to [act].
  Set<String> caseIdsByAct(String act) {
    final key = CaseSearchNormalizer.normalizeText(act);
    return key.isEmpty ? const {} : (_byAct[key] ?? const {});
  }

  /// Case IDs linked to [doctrineId] (case-record and doctrine-record roles).
  Set<String> caseIdsByDoctrine(String doctrineId) =>
      _byDoctrine[doctrineId.toUpperCase()] ?? const {};

  /// Case IDs whose judge list contains [judge] (exact normalized name).
  Set<String> caseIdsByJudge(String judge) {
    final key = CaseSearchNormalizer.normalizeText(judge);
    return key.isEmpty ? const {} : (_byJudge[key] ?? const {});
  }

  /// Case IDs decided in [year].
  Set<String> caseIdsByYear(int year) => _byYear[year] ?? const {};

  /// Case IDs decided in [court] (exact normalized name).
  Set<String> caseIdsByCourt(String court) {
    final key = CaseSearchNormalizer.normalizeText(court);
    return key.isEmpty ? const {} : (_byCourt[key] ?? const {});
  }

  /// Candidate case IDs sharing at least one word token with the term.
  Set<String> candidateCaseIds(String term) {
    final tokens = CaseSearchNormalizer.tokenize(term);
    if (tokens.isEmpty) return const {};
    final candidates = <String>{};
    for (final t in tokens) {
      candidates.addAll(_keywordIndex[t] ?? const {});
    }
    return candidates;
  }

  /// Total corpus frequency of a word token (0 when absent).
  int keywordFrequency(String token) =>
      _keywordFrequency[CaseSearchNormalizer.normalizeText(token)] ?? 0;

  // -------------------------------------------------------------------------
  // Autocomplete / suggestions
  // -------------------------------------------------------------------------

  /// Distinct suggestion terms matching the normalized prefix — as a whole
  /// normalized key or as any word token (so `khanna` matches
  /// `h r khanna j`). Ranked by occurrence count then term. Deduplicated by
  /// (kind, display term) so article key/number variants surface once.
  List<CaseSearchSuggestion> suggestionsForPrefix(String prefix,
      {int limit = 10}) {
    final normalizedPrefix = CaseSearchNormalizer.normalizeText(prefix);
    if (normalizedPrefix.isEmpty) return const [];

    final seen = <String>{};
    final hits = <CaseSearchSuggestion>[];
    for (final s in _vocabulary) {
      final matchesKey = s.normalizedKey.startsWith(normalizedPrefix);
      final matchesToken =
          s.normalizedKey.split(' ').any((t) => t.startsWith(normalizedPrefix));
      if (!matchesKey && !matchesToken) continue;
      if (seen.add('${s.kind.name}|${s.term}')) hits.add(s);
    }
    hits.sort((a, b) {
      final byCount = b.occurrenceCount.compareTo(a.occurrenceCount);
      return byCount != 0 ? byCount : a.term.compareTo(b.term);
    });
    return limit > 0 && hits.length > limit ? hits.sublist(0, limit) : hits;
  }

  /// Distinct suggestion *terms* (strings) for [prefix].
  List<String> autocompleteTerms(String prefix, {int limit = 10}) =>
      suggestionsForPrefix(prefix, limit: limit).map((s) => s.term).toList();

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  void _build(Map<String, Set<String>> doctrineCaseIds) {
    for (final c in cases) {
      _byCaseId[c.caseId] = c;
      _caseNameToId[CaseSearchNormalizer.normalizeText(c.caseName)] = c.caseId;

      for (final a in c.aliases) {
        (_byAlias[CaseSearchNormalizer.normalizeText(a)] ??= {}).add(c.caseId);
      }
      for (final art in c.relatedArticles) {
        final key = CaseSearchNormalizer.normalizeArticle(art);
        if (key.isNotEmpty) (_byArticle[key] ??= {}).add(c.caseId);
      }
      for (final act in c.relatedActs) {
        final key = CaseSearchNormalizer.normalizeText(act);
        if (key.isNotEmpty) (_byAct[key] ??= {}).add(c.caseId);
      }
      for (final d in c.doctrines) {
        (_byDoctrine[d.toUpperCase()] ??= {}).add(c.caseId);
      }
      for (final j in c.judges) {
        final key = CaseSearchNormalizer.normalizeText(j);
        if (key.isNotEmpty) (_byJudge[key] ??= {}).add(c.caseId);
      }
      if (c.authoringJudge.trim().isNotEmpty) {
        (_byJudge[CaseSearchNormalizer.normalizeText(c.authoringJudge)] ??= {})
            .add(c.caseId);
      }
      (_byYear[c.year] ??= {}).add(c.caseId);
      (_byCourt[CaseSearchNormalizer.normalizeText(c.court)] ??= {})
          .add(c.caseId);

      // Keyword token index with corpus frequency.
      for (final entry in searchableFieldValues(c).entries) {
        for (final v in entry.value) {
          for (final token in CaseSearchNormalizer.tokenize(v)) {
            if ((_keywordIndex[token] ??= {}).add(c.caseId)) {
              _keywordFrequency[token] = (_keywordFrequency[token] ?? 0) + 1;
            }
          }
        }
      }
    }

    for (final did in doctrineCaseIds.keys) {
      _byDoctrine[did] = {
        ..._byDoctrine[did] ?? const {},
        ...doctrineCaseIds[did]!,
      };
    }

    _buildVocabulary(doctrineCaseIds);
  }

  /// Builds the deduplicated autocomplete vocabulary with explicit case sets.
  void _buildVocabulary(Map<String, Set<String>> doctrineCaseIds) {
    final merged = <String,
        ({String term, CaseSearchSuggestionKind kind, String normalizedKey, Set<String> caseIds})>{};

    String key(String kind, String normalized) => '$kind|$normalized';
    void merge(String kind, String term, String normalized, String caseId) {
      final k = key(kind, normalized);
      final existing = merged[k];
      if (existing == null) {
        merged[k] = (
          term: term,
          kind: _kindOf(kind),
          normalizedKey: normalized,
          caseIds: {caseId},
        );
      } else {
        existing.caseIds.add(caseId);
      }
    }

    for (final c in cases) {
      final name = c.caseName.trim();
      if (name.isNotEmpty) {
        merge('caseName', name, CaseSearchNormalizer.normalizeText(name),
            c.caseId);
      }
      for (final a in c.aliases) {
        if (a.trim().isEmpty) continue;
        merge('alias', a, CaseSearchNormalizer.normalizeText(a), c.caseId);
      }
      for (final art in c.relatedArticles) {
        final articleKey = CaseSearchNormalizer.normalizeArticle(art);
        if (articleKey.isEmpty) continue;
        merge('article', art, CaseSearchNormalizer.normalizeText(art), c.caseId);
        merge('article', art, articleKey, c.caseId);
      }
      for (final act in c.relatedActs) {
        if (act.trim().isEmpty) continue;
        merge('act', act, CaseSearchNormalizer.normalizeText(act), c.caseId);
      }
      for (final j in c.judges) {
        if (j.trim().isEmpty) continue;
        merge('judge', j, CaseSearchNormalizer.normalizeText(j), c.caseId);
      }
    }

    for (final entry in doctrineIdToName.entries) {
      final id = entry.key;
      final name = entry.value;
      final caseIds = doctrineCaseIds[id] ?? const <String>{};
      if (caseIds.isEmpty) continue;
      final kName = key('doctrine', CaseSearchNormalizer.normalizeText(name));
      merged[kName] ??= (
        term: name,
        kind: CaseSearchSuggestionKind.doctrine,
        normalizedKey: CaseSearchNormalizer.normalizeText(name),
        caseIds: {},
      );
      merged[kName]!.caseIds.addAll(caseIds);
      final kId = key('doctrine', CaseSearchNormalizer.normalizeText(id));
      merged[kId] ??= (
        term: id,
        kind: CaseSearchSuggestionKind.doctrine,
        normalizedKey: CaseSearchNormalizer.normalizeText(id),
        caseIds: {},
      );
      merged[kId]!.caseIds.addAll(caseIds);
    }

    final suggestions = <CaseSearchSuggestion>[];
    for (final e in merged.values) {
      final caseIds = e.caseIds.toList()..sort();
      suggestions.add(CaseSearchSuggestion(
        term: e.term,
        kind: e.kind,
        normalizedKey: e.normalizedKey,
        caseIds: caseIds,
        occurrenceCount: caseIds.length,
      ));
    }
    suggestions.sort((a, b) {
      final byCount = b.occurrenceCount.compareTo(a.occurrenceCount);
      return byCount != 0 ? byCount : a.term.compareTo(b.term);
    });
    _vocabulary.addAll(suggestions);
  }

  static CaseSearchSuggestionKind _kindOf(String kind) =>
      switch (kind) {
        'caseName' => CaseSearchSuggestionKind.caseName,
        'alias' => CaseSearchSuggestionKind.alias,
        'article' => CaseSearchSuggestionKind.article,
        'act' => CaseSearchSuggestionKind.act,
        'judge' => CaseSearchSuggestionKind.judge,
        _ => CaseSearchSuggestionKind.doctrine,
      };

  /// Doctrine case IDs derived from the corpus `doctrines` field alone (used
  /// when the engine does not supply doctrine-record roles).
  static Map<String, Set<String>> _deriveDoctrineCaseIds(
      List<CaseKnowledgeObject> cases) {
    final map = <String, Set<String>>{};
    for (final c in cases) {
      for (final d in c.doctrines) {
        (map[d.toUpperCase()] ??= {}).add(c.caseId);
      }
    }
    return map;
  }
}
