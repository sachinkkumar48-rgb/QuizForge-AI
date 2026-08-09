/// Case Law Search Engine (TITAN-KO-015.0 P6).
///
/// Offline-first, deterministic search over the landmark case corpus. The
/// engine owns an in-memory [CaseSearchIndex] and reads the P5 Precedent &
/// Doctrine Graph through its existing services — search and graph traversal
/// stay separate responsibilities; the engine *queries* the graph, never
/// rebuilds or mutates it.
///
/// Ranking is deterministic and explainable: every matched field contributes
/// its weight × a match quality (exact > prefix > token-prefix > substring),
/// and equal scores are broken by year desc → case name asc → case ID asc.
library;

import '../../data/case_official_sources.dart';
import '../../data/case_seed_data.dart';
import '../../domain/entities/case_enums.dart'
    show PrecedentRelationshipType, RelevanceLevel;
import '../../domain/entities/case_knowledge_object.dart';
import '../../graph/data/legal_graph_seed.dart';
import '../../graph/domain/doctrine_relationship_type.dart';
import '../../graph/domain/legal_graph.dart';
import '../../graph/domain/legal_graph_edge.dart';
import '../../graph/domain/legal_graph_node_type.dart';
import '../../graph/service/doctrine_relationship_service.dart';
import '../../graph/service/legal_graph_traversal_service.dart';
import '../../graph/service/precedent_graph_service.dart';
import '../data/case_search_index.dart';
import '../data/case_search_normalizer.dart';
import '../domain/case_search_enums.dart';
import '../domain/case_search_filters.dart';
import '../domain/case_search_query.dart';
import '../domain/case_search_result.dart';
import '../domain/case_search_suggestion.dart';

/// Deterministic, offline-first search engine over the landmark case corpus.
class CaseSearchEngine {
  final CaseSearchIndex index;
  final PrecedentGraphService precedentService;
  final DoctrineRelationshipService doctrineService;
  final LegalGraphTraversalService traversalService;

  /// Cached searchable field values per case (built once at construction).
  final Map<String, Map<String, List<String>>> _fieldValuesByCase;

  /// Deterministic precedence order of precedent relationship types, used to
  /// order relationship results so that reliance edges precede overruling
  /// edges and curated affinities come last.
  static const List<PrecedentRelationshipType> _relationshipOrder = [
    PrecedentRelationshipType.followed,
    PrecedentRelationshipType.applied,
    PrecedentRelationshipType.affirmed,
    PrecedentRelationshipType.approved,
    PrecedentRelationshipType.clarified,
    PrecedentRelationshipType.expanded,
    PrecedentRelationshipType.overruled,
    PrecedentRelationshipType.reversed,
    PrecedentRelationshipType.distinguished,
    PrecedentRelationshipType.limited,
    PrecedentRelationshipType.related,
  ];

  /// Score contribution per relevance-rank point on an UPSC filter dimension.
  static const double _upscRankWeight = 5.0;

  factory CaseSearchEngine({
    List<CaseKnowledgeObject>? cases,
    LegalGraph? graph,
    PrecedentGraphService? precedentService,
    DoctrineRelationshipService? doctrineService,
    LegalGraphTraversalService? traversalService,
  }) {
    final g = graph ?? LegalGraphSeed.fromCorpus().build();
    final ps = precedentService ?? PrecedentGraphService(graph: g);
    final ds = doctrineService ?? DoctrineRelationshipService(graph: g);
    final ts = traversalService ?? LegalGraphTraversalService(graph: g);
    final casesList = cases ?? CaseSeedData.cases;

    final doctrineCaseIds = <String, Set<String>>{};
    for (final d in ds.allDoctrines) {
      final ids = ds.getCasesForDoctrine(d.id).map((e) => e.sourceId).toSet();
      if (ids.isNotEmpty) doctrineCaseIds[d.id] = ids;
    }

    return CaseSearchEngine._(
      index: CaseSearchIndex(
        cases: casesList,
        doctrineNodes: ds.allDoctrines,
        doctrineCaseIds: doctrineCaseIds,
      ),
      precedentService: ps,
      doctrineService: ds,
      traversalService: ts,
    );
  }

  CaseSearchEngine._({
    required this.index,
    required this.precedentService,
    required this.doctrineService,
    required this.traversalService,
  }) : _fieldValuesByCase = {
         for (final c in index.cases) c.caseId: searchableFieldValues(c),
       };

  // -------------------------------------------------------------------------
  // Corpus surface
  // -------------------------------------------------------------------------

  /// Number of indexed cases.
  int get indexedCaseCount => index.indexedCaseCount;

  /// Canonical case IDs of every indexed case.
  Set<String> get indexedCaseIds => index.indexedCaseIds;

  // -------------------------------------------------------------------------
  // Free-text search
  // -------------------------------------------------------------------------

  /// Runs a ranked search. An empty query (no term, no filters) returns the
  /// full corpus ordered by the deterministic tie-breaker — useful as the
  /// "browse all" view.
  List<CaseSearchResult> search(CaseSearchQuery query) {
    final filters = query.filters ?? const CaseSearchFilters();
    var ids = index.indexedCaseIds.toSet();
    if (!filters.isEmpty) {
      ids = _applyFilters(ids, filters);
    }
    if (ids.isEmpty) return const [];

    final rawTerm = query.term?.trim() ?? '';
    final hasTerm = rawTerm.isNotEmpty &&
        CaseSearchNormalizer.normalizeText(rawTerm).isNotEmpty;

    final results = <CaseSearchResult>[];
    for (final id in ids) {
      results.add(_scoreCase(index.byCaseId(id)!, query.term, filters));
    }
    // A non-blank term that matches nothing is a no-result query, not a
    // browse-all query.
    if (hasTerm && !results.any((r) => r.score > 0)) return const [];

    results.sort(_compareResults);
    final limit = query.limit;
    if (limit != null && limit >= 0 && results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  /// Convenience for a text search constrained by composable filters.
  List<CaseSearchResult> searchWithFilters(
    String term,
    CaseSearchFilters filters, {
    int? limit,
  }) =>
      search(CaseSearchQuery(term: term, filters: filters, limit: limit));

  /// Exact lookup by canonical case ID, (case-insensitive) ID, or exact
  /// normalized case name / alias. Returns null when nothing matches.
  CaseSearchResult? findExact(String idOrName) {
    final id = index.resolveCaseId(idOrName);
    if (id == null) return null;
    final c = index.byCaseId(id)!;
    return CaseSearchResult(
      caseId: c.caseId,
      caseName: c.caseName,
      score: 100.0,
      matchedFields: const ['caseName'],
      matchedContext: const {'caseName': []},
      evidenceStatus: _evidenceStatus(c),
      caseObject: c,
    );
  }

  // -------------------------------------------------------------------------
  // Structured finders
  // -------------------------------------------------------------------------

  /// Cases whose `relatedArticles` reference [article] (`21`, `Article 21`,
  /// `Art. 21`, `article21` all resolve consistently).
  List<CaseSearchResult> findByArticle(String article) {
    final key = CaseSearchNormalizer.normalizeArticle(article);
    if (key.isEmpty) return const [];
    return search(CaseSearchQuery(
      term: 'Article $key',
      filters: const CaseSearchFilters().copyWith(articles: {key}),
    ));
  }

  /// Cases referencing [act] in `relatedActs` (case-insensitive substring on
  /// the normalized act name).
  List<CaseSearchResult> findByAct(String act) {
    final q = act.trim();
    if (q.isEmpty) return const [];
    return search(CaseSearchQuery(
      term: q,
      filters: const CaseSearchFilters().copyWith(acts: {q}),
    ));
  }

  /// Cases linked to [doctrine] (by doctrine ID or name) through the P5 graph
  /// and the corpus `doctrines` field. Establishing / applying cases rank
  /// above generic engagement.
  List<CaseSearchResult> findByDoctrine(String doctrine) {
    final id = _resolveDoctrineId(doctrine);
    if (id == null) return const [];

    final edges = doctrineService.getCasesForDoctrine(id);
    final byCase = <String, List<DoctrineGraphEdge>>{};
    for (final e in edges) {
      (byCase[e.sourceId] ??= []).add(e);
    }
    for (final c in index.cases) {
      if (c.doctrines.any((d) => d.toUpperCase() == id)) {
        byCase.putIfAbsent(c.caseId, () => []);
      }
    }

    final results = <CaseSearchResult>[];
    for (final entry in byCase.entries) {
      final c = index.byCaseId(entry.key);
      if (c == null) continue;
      final roles = entry.value;
      final bestRole = roles.isEmpty
          ? null
          : roles.reduce((a, b) => a.type.index <= b.type.index ? a : b).type;
      results.add(CaseSearchResult(
        caseId: c.caseId,
        caseName: c.caseName,
        score: bestRole == null ? 1.0 : _doctrineRoleScore(bestRole),
        matchedFields: const ['doctrine'],
        matchedContext: {
          'doctrine': [
            bestRole == null
                ? 'linked · $id'
                : '${bestRole.displayName} · $id',
          ],
        },
        evidenceStatus: _evidenceStatus(c),
        caseObject: c,
      ));
    }
    results.sort(_compareResults);
    return results;
  }

  /// Cases heard by [judge] (case-insensitive substring on the judge list and
  /// the authoring judge).
  List<CaseSearchResult> findByJudge(String judge) {
    final q = judge.trim();
    if (q.isEmpty) return const [];
    return search(CaseSearchQuery(
      term: q,
      filters: const CaseSearchFilters().copyWith(judges: {q}),
    ));
  }

  /// Cases decided in [year].
  List<CaseSearchResult> findByYear(int year) =>
      search(CaseSearchQuery(filters: CaseSearchFilters(year: year)));

  /// Cases decided within the inclusive year range [from]..[to].
  List<CaseSearchResult> findByYearRange(int from, int to) {
    final lo = from <= to ? from : to;
    final hi = from <= to ? to : from;
    return search(CaseSearchQuery(
      filters: CaseSearchFilters(yearFrom: lo, yearTo: hi),
    ));
  }

  /// Cases connected to [caseId] through P5 precedent edges, optionally
  /// restricted to [type]. When [type] is null all relationship neighbors are
  /// returned (incoming and outgoing), de-duplicated.
  List<CaseSearchResult> findByRelationship(
    String caseId, {
    PrecedentRelationshipType? type,
  }) {
    final id = index.resolveCaseId(caseId);
    if (id == null) return const [];

    final edges = <PrecedentGraphEdge>[];
    if (type != null) {
      for (final e in precedentService.incomingRelationships(id)) {
        if (e.type == type) edges.add(e);
      }
      for (final e in precedentService.outgoingRelationships(id)) {
        if (e.type == type && e.sourceId != e.targetId) edges.add(e);
      }
    } else {
      edges.addAll(precedentService.incomingRelationships(id));
      edges.addAll(precedentService.outgoingRelationships(id)
          .where((e) => e.sourceId != e.targetId));
    }

    final seen = <String>{};
    final results = <CaseSearchResult>[];
    for (final e in edges) {
      final otherId = e.sourceId == id ? e.targetId : e.sourceId;
      if (!seen.add(otherId)) continue;
      final c = index.byCaseId(otherId);
      if (c == null) continue;
      results.add(_relationshipResult(c, id, e));
    }
    results.sort((a, b) {
      final byType = _relationshipRank(a).compareTo(_relationshipRank(b));
      return byType != 0 ? byType : _compareResults(a, b);
    });
    return results;
  }

  /// Cases directly related to [caseId] (curated `related` edges), or within
  /// [maxHops] hops when > 1 (multi-hop traversal through the P5 graph).
  List<CaseSearchResult> findRelatedCases(String caseId, {int maxHops = 1}) {
    final id = index.resolveCaseId(caseId);
    if (id == null) return const [];
    final results = <CaseSearchResult>[];

    if (maxHops <= 1) {
      final seen = <String>{};
      for (final e in precedentService.relatedCases(id)) {
        final other = e.sourceId == id ? e.targetId : e.sourceId;
        if (seen.add(other)) {
          final c = index.byCaseId(other);
          if (c != null) results.add(_relationshipResult(c, id, e));
        }
      }
    } else {
      final neighbors = traversalService.neighborsWithinHops(
        id,
        maxHops: maxHops,
        nodeType: LegalGraphNodeType.caseLaw,
      );
      for (final n in neighbors) {
        final c = index.byCaseId(n.id);
        if (c == null) continue;
        results.add(CaseSearchResult(
          caseId: c.caseId,
          caseName: c.caseName,
          score: 1.0,
          matchedFields: const ['relationship:related'],
          matchedContext: {
            'relationship': ['related within $maxHops hop(s) · $id'],
          },
          evidenceStatus: _evidenceStatus(c),
          caseObject: c,
        ));
      }
    }
    results.sort(_compareResults);
    return results;
  }

  /// Cases relevant to a UPSC dimension, read from the existing P3
  /// `RelevanceLevel` fields (never fabricated). With [minimum] set, only
  /// cases at or above that level are returned; the filter is inclusive.
  List<CaseSearchResult> findByUpscRelevance(
    CaseSearchUpscDimension dimension, {
    RelevanceLevel? minimum,
  }) =>
      search(CaseSearchQuery(
        filters: CaseSearchFilters(
          upscDimensions: {dimension},
          minimumUpscRelevance: minimum,
        ),
      ));

  // -------------------------------------------------------------------------
  // Autocomplete / suggestions
  // -------------------------------------------------------------------------

  /// Distinct suggestion terms whose normalized form starts with [prefix].
  List<String> autocomplete(String prefix, {int limit = 10}) =>
      index.autocompleteTerms(prefix, limit: limit);

  /// Structured suggestions (term + kind + target case IDs) for [prefix].
  List<CaseSearchSuggestion> suggestions(String prefix, {int limit = 10}) =>
      index.suggestionsForPrefix(prefix, limit: limit);

  // -------------------------------------------------------------------------
  // Filtering
  // -------------------------------------------------------------------------

  Set<String> _applyFilters(Set<String> ids, CaseSearchFilters f) {
    var result = ids;

    result = result.where((id) {
      final c = index.byCaseId(id)!;
      return f.matchesYear(c.year) &&
          _matchesCourt(c.court, f.court) &&
          _matchesUpsc(c, f.upscDimensions, f.minimumUpscRelevance) &&
          (!f.evidenceOnly || _evidenceStatus(c) == SearchEvidenceStatus.verified);
    }).toSet();

    for (final art in f.articles) {
      result = result.intersection(index.caseIdsByArticle(art));
    }
    for (final act in f.acts) {
      result = result.intersection(_actFilterCaseIds(act));
    }
    for (final d in f.doctrines) {
      final id = _resolveDoctrineId(d) ?? d.toUpperCase();
      result = result.intersection(index.caseIdsByDoctrine(id));
    }
    for (final j in f.judges) {
      result = result.intersection(_judgeFilterCaseIds(j));
    }
    if (f.relationshipType != null) {
      result = result.intersection(_relationshipCaseIds(f.relationshipType!));
    }
    return result;
  }

  bool _matchesCourt(String court, String? filter) {
    if (filter == null) return true;
    final q = CaseSearchNormalizer.normalizeText(filter);
    return q.isNotEmpty &&
        CaseSearchNormalizer.normalizeText(court).contains(q);
  }

  bool _matchesUpsc(
    CaseKnowledgeObject c,
    Set<CaseSearchUpscDimension> dimensions,
    RelevanceLevel? minimum,
  ) {
    if (dimensions.isEmpty) return true;
    final minRank = minimum == null ? 1 : relevanceRank(minimum);
    for (final dim in dimensions) {
      if (relevanceRank(_upscLevel(c, dim)) < minRank) return false;
    }
    return true;
  }

  Set<String> _actFilterCaseIds(String act) {
    final q = CaseSearchNormalizer.normalizeText(act);
    if (q.isEmpty) return const {};
    return index.cases.where((c) {
      for (final a in [...c.relatedActs, ...c.sections]) {
        if (CaseSearchNormalizer.normalizeText(a).contains(q)) return true;
      }
      return false;
    }).map((c) => c.caseId).toSet();
  }

  Set<String> _judgeFilterCaseIds(String judge) {
    final q = CaseSearchNormalizer.normalizeText(judge);
    if (q.isEmpty) return const {};
    return index.cases.where((c) {
      for (final j in [...c.judges, c.authoringJudge]) {
        if (CaseSearchNormalizer.normalizeText(j).contains(q)) return true;
      }
      return false;
    }).map((c) => c.caseId).toSet();
  }

  Set<String> _relationshipCaseIds(PrecedentRelationshipType type) {
    final result = <String>{};
    for (final e
        in precedentService.snapshot.edges.whereType<PrecedentGraphEdge>()) {
      if (e.type == type) {
        result.add(e.sourceId);
        result.add(e.targetId);
      }
    }
    return result;
  }

  // -------------------------------------------------------------------------
  // Scoring & ranking
  // -------------------------------------------------------------------------

  CaseSearchResult _scoreCase(
    CaseKnowledgeObject c,
    String? term,
    CaseSearchFilters filters,
  ) {
    final matchedFields = <String>{};
    final context = <String, List<String>>{};
    var score = 0.0;

    final t = term?.trim() ?? '';
    if (t.isNotEmpty &&
        CaseSearchNormalizer.normalizeText(t).isNotEmpty) {
      final values = _fieldValuesByCase[c.caseId]!;
      for (final entry in values.entries) {
        final weight = searchFieldWeights[entry.key] ?? 10.0;
        var fieldScore = 0.0;
        final fieldContext = <String>[];
        for (final v in entry.value) {
          var w = CaseSearchNormalizer.matchWeight(t, v);
          // Article references also match on their normalized article key, so
          // `Art. 19(1)(a)` / `Article 19(1)(a)` / `191a` resolve to the same
          // cases regardless of variant.
          if (w == 0 &&
              entry.key == 'article' &&
              CaseSearchNormalizer.normalizeText(t).isNotEmpty) {
            final tk = CaseSearchNormalizer.normalizeArticle(t);
            final vk = CaseSearchNormalizer.normalizeArticle(v);
            if (tk.isNotEmpty && tk == vk) w = 1.0;
          }
          if (w > 0) {
            fieldScore += w * weight;
            if (fieldContext.length < 5) fieldContext.add(v);
          }
        }
        if (fieldScore > 0) {
          score += fieldScore;
          matchedFields.add(entry.key);
          context[entry.key] = fieldContext;
        }
      }
    }

    // UPSC relevance dimensions contribute a deterministic ranking signal.
    if (filters.upscDimensions.isNotEmpty) {
      var upscBoost = 0.0;
      for (final dim in filters.upscDimensions) {
        final rank = relevanceRank(_upscLevel(c, dim));
        if (rank > 0) upscBoost += rank * _upscRankWeight;
      }
      if (upscBoost > 0) {
        score += upscBoost;
        matchedFields.add('upsc');
        context.putIfAbsent('upsc', () => []).add(
            filters.upscDimensions.map((d) => d.displayName).join(' + '));
      }
    }

    return CaseSearchResult(
      caseId: c.caseId,
      caseName: c.caseName,
      score: score,
      matchedFields: searchFieldOrder.where(matchedFields.contains).toList(),
      matchedContext: context,
      evidenceStatus: _evidenceStatus(c),
      caseObject: c,
    );
  }

  CaseSearchResult _relationshipResult(
    CaseKnowledgeObject c,
    String centerId,
    PrecedentGraphEdge e,
  ) {
    final direction = e.sourceId == centerId ? 'outgoing' : 'incoming';
    return CaseSearchResult(
      caseId: c.caseId,
      caseName: c.caseName,
      score: 1.0,
      matchedFields: ['relationship:${e.type.name}'],
      matchedContext: {
        'relationship': ['$direction · ${e.type.name} · $centerId'],
      },
      evidenceStatus: _evidenceStatus(c),
      caseObject: c,
    );
  }

  int _relationshipRank(CaseSearchResult r) {
    final typeName = r.matchedFields.first.replaceFirst('relationship:', '');
    final idx =
        _relationshipOrder.indexWhere((t) => t.name == typeName);
    return idx < 0 ? _relationshipOrder.length : idx;
  }

  double _doctrineRoleScore(DoctrineRelationshipType role) =>
      (DoctrineRelationshipType.values.length - role.index).toDouble();

  /// Deterministic total ordering: score desc → year desc → case name asc →
  /// case ID asc.
  int _compareResults(CaseSearchResult a, CaseSearchResult b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byYear = b.caseObject.year.compareTo(a.caseObject.year);
    if (byYear != 0) return byYear;
    final byName = a.caseName.compareTo(b.caseName);
    if (byName != 0) return byName;
    return a.caseId.compareTo(b.caseId);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  RelevanceLevel _upscLevel(CaseKnowledgeObject c, CaseSearchUpscDimension dim) =>
      switch (dim) {
        CaseSearchUpscDimension.prelims => c.prelimsRelevance,
        CaseSearchUpscDimension.mains => c.mainsRelevance,
        CaseSearchUpscDimension.essay => c.essayRelevance,
        CaseSearchUpscDimension.interview => c.interviewRelevance,
      };

  SearchEvidenceStatus _evidenceStatus(CaseKnowledgeObject c) {
    final hasOfficial =
        c.evidenceIds.any(CaseOfficialSources.isRegisteredEvidence);
    if (hasOfficial) return SearchEvidenceStatus.verified;
    if (c.evidenceIds.isNotEmpty) return SearchEvidenceStatus.editorial;
    return SearchEvidenceStatus.unverified;
  }

  /// Resolves a doctrine reference — canonical ID (`BASIC_STRUCTURE`) or name
  /// (`Basic Structure`) — to its canonical ID, or null when unresolvable.
  String? _resolveDoctrineId(String input) {
    final q = input.trim();
    if (q.isEmpty) return null;
    final upper = q.toUpperCase();
    if (index.doctrineIdToName.containsKey(upper)) return upper;
    if (doctrineService.hasDoctrine(upper)) return upper;

    final norm = CaseSearchNormalizer.normalizeText(q);
    if (norm.isEmpty) return null;
    String? exactId;
    String? prefixId;
    for (final node in doctrineService.allDoctrines) {
      final nameNorm = CaseSearchNormalizer.normalizeText(node.name);
      final idNorm = CaseSearchNormalizer.normalizeText(node.id);
      if (nameNorm == norm) return node.id;
      if (idNorm == norm && exactId == null) exactId = node.id;
      if (nameNorm.startsWith(norm) && prefixId == null) prefixId = node.id;
    }
    return exactId ?? prefixId;
  }
}
