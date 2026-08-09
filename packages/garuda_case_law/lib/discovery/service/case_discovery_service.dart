/// P9 Case Discovery & Exploration service (TITAN-KO-015.0 P9).
///
/// A deterministic, offline-first application/service layer that composes the
/// validated P3–P8 knowledge into navigable discovery capabilities. It performs
/// no legal research: every related case, collection entry and navigation step
/// derives exclusively from existing validated data (P3 corpus, P4
/// intelligence, P5 graph, P6 search, P7 validation guarantees).
///
/// # Related case discovery
///
/// `discoverRelatedCases` returns cases related to a source case. Relatedness
/// is derived only from objectively computable, validated information:
///
/// - direct P5 case → case graph edges ([DiscoveryReasonType.graphRelationship]);
/// - shared validated doctrine membership ([DiscoveryReasonType.sharedDoctrine]);
/// - shared validated constitutional article references
///   ([DiscoveryReasonType.sharedArticle]);
/// - shared validated Act references ([DiscoveryReasonType.sharedAct]).
///
/// Every result carries the reasons that explain it and the provenance of each
/// derivation. P9 deliberately does NOT claim legal similarity, does not score
/// by wording/holdings, and never infers relationships.
///
/// # Collections
///
/// Doctrine / Article / Act collections are deterministic P6 query results
/// (`casesForDoctrine`, `casesForArticle`, `casesForAct`), reusing the existing
/// search engine — no collection storage is created.
///
/// # Precedent navigation
///
/// Navigation methods read the P5 graph as-is: direct precedents, raw
/// incoming/outgoing relationship sets, longest precedent chains, shortest
/// paths, and transitive authority ancestors/descendants. No graph edge is
/// created or modified, and precedent relationships are never reported as
/// citations (citation extraction is out of scope).
///
/// # Determinism & offline
///
/// Identical corpus + identical query ⇒ identical results. Iteration is always
/// converted to a documented deterministic order and no network, LLM or
/// external service is involved.
library;

import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;
import 'package:meta/meta.dart';

import '../../data/case_seed_data.dart';
import '../../domain/entities/case_enums.dart' show PrecedentRelationshipType;
import '../../domain/entities/case_knowledge_object.dart';
import '../../graph/data/legal_graph_seed.dart';
import '../../graph/domain/legal_graph.dart';
import '../../graph/domain/legal_graph_edge.dart';
import '../../graph/domain/legal_graph_node_ref.dart';
import '../../graph/domain/legal_graph_node_type.dart';
import '../../graph/domain/legal_graph_path.dart';
import '../../graph/service/doctrine_relationship_service.dart';
import '../../graph/service/legal_graph_traversal_service.dart';
import '../../graph/service/precedent_graph_service.dart';
import '../../search/data/case_search_normalizer.dart';
import '../../search/domain/case_search_result.dart';
import '../../search/service/case_search_engine.dart';
import '../domain/discovery_reason.dart';
import '../domain/related_case_result.dart';

/// P9 facade over related-case discovery, structured collections and precedent
/// navigation.
@immutable
class CaseDiscoveryService {
  /// The validated corpus this service reads from (canonical seed by default).
  final List<CaseKnowledgeObject> cases;

  /// The P5 legal graph snapshot.
  final LegalGraph graph;

  /// The P6 search engine (reused for structured collections).
  final CaseSearchEngine searchEngine;

  /// P5 case → case service.
  final PrecedentGraphService precedentService;

  /// P5 case ↔ doctrine service.
  final DoctrineRelationshipService doctrineService;

  /// P5 traversal service (chains, paths, neighborhoods).
  final LegalGraphTraversalService traversalService;

  /// Edge types that express reliance on an earlier authority. Mirrors the P5
  /// `PrecedentGraphService` authority semantics so ancestor/descendant
  /// traversal stays consistent with how P5 reads the graph.
  static const Set<PrecedentRelationshipType> _authorityTypes = {
    PrecedentRelationshipType.followed,
    PrecedentRelationshipType.applied,
    PrecedentRelationshipType.affirmed,
    PrecedentRelationshipType.approved,
    PrecedentRelationshipType.clarified,
    PrecedentRelationshipType.expanded,
  };

  /// Fixed reason-kind priority: graph relationships first, then shared
  /// doctrine, shared article, shared Act (matches the P9 discovery ordering
  /// documented in `P9_CASE_DISCOVERY.md`).
  static const List<DiscoveryReasonType> _reasonKindOrder = [
    DiscoveryReasonType.graphRelationship,
    DiscoveryReasonType.sharedDoctrine,
    DiscoveryReasonType.sharedArticle,
    DiscoveryReasonType.sharedAct,
  ];

  factory CaseDiscoveryService({
    List<CaseKnowledgeObject>? cases,
    LegalGraph? graph,
    CaseSearchEngine? searchEngine,
    PrecedentGraphService? precedentService,
    DoctrineRelationshipService? doctrineService,
    LegalGraphTraversalService? traversalService,
  }) {
    final corpus = cases ?? CaseSeedData.cases;
    final g = graph ??
        LegalGraphSeed.fromCorpora(
          cases: corpus,
          doctrines: DoctrineSeedData.doctrines,
        ).build();
    final ps = precedentService ?? PrecedentGraphService(graph: g);
    final ds = doctrineService ?? DoctrineRelationshipService(graph: g);
    final ts = traversalService ?? LegalGraphTraversalService(graph: g);
    final se = searchEngine ??
        CaseSearchEngine(
          cases: corpus,
          graph: g,
          precedentService: ps,
          doctrineService: ds,
          traversalService: ts,
        );
    return CaseDiscoveryService._(
      cases: List<CaseKnowledgeObject>.unmodifiable(corpus),
      graph: g,
      searchEngine: se,
      precedentService: ps,
      doctrineService: ds,
      traversalService: ts,
    );
  }

  const CaseDiscoveryService._({
    required this.cases,
    required this.graph,
    required this.searchEngine,
    required this.precedentService,
    required this.doctrineService,
    required this.traversalService,
  });

  // -------------------------------------------------------------------------
  // Convenience accessors
  // -------------------------------------------------------------------------

  /// Canonical IDs of every case in the corpus.
  Set<String> get caseIds => searchEngine.indexedCaseIds;

  /// Canonical doctrine IDs in the graph.
  List<String> get doctrineIds =>
      doctrineService.allDoctrines.map((d) => d.id).toList(growable: false);

  /// Whether [caseId] (canonical ID or name) resolves to a corpus case.
  bool hasCase(String idOrName) => _resolveCaseId(idOrName) != null;

  /// Whether [doctrineId] is a canonical doctrine in the graph.
  bool hasDoctrine(String doctrineId) =>
      doctrineService.hasDoctrine(doctrineId);

  /// Resolves [idOrName] to a canonical case ID, or null when unknown.
  String? _resolveCaseId(String idOrName) {
    final trimmed = idOrName.trim();
    if (trimmed.isEmpty) return null;
    return searchEngine.findExact(trimmed)?.caseId;
  }

  CaseKnowledgeObject? _caseById(String caseId) {
    for (final c in cases) {
      if (c.caseId == caseId) return c;
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // A. Related case discovery
  // -------------------------------------------------------------------------

  /// Deterministically discovers cases related to [idOrName] (canonical case ID
  /// or name). Every result carries explainable, evidence-backed reasons.
  ///
  /// Relatedness is derived only from validated P3–P7 information — direct P5
  /// graph edges, shared doctrine membership, shared article references and
  /// shared Act references. No similarity model, wording scoring or inference
  /// is involved, and no result equals the source case itself.
  ///
  /// Unknown IDs and cases with no connectable metadata return an empty list.
  /// Results are ordered by number of independent reasons (descending), then by
  /// the P6 deterministic tie-break: year descending, case name ascending, case
  /// ID ascending.
  List<RelatedCaseResult> discoverRelatedCases(
    String idOrName, {
    int? limit,
  }) {
    final sourceId = _resolveCaseId(idOrName);
    if (sourceId == null) return const [];

    final reasonsByTarget = <String, List<DiscoveryReason>>{};
    void addReason(String targetId, DiscoveryReason reason) {
      if (targetId == sourceId) return; // self-exclusion
      if (targetId.isEmpty) return;
      (reasonsByTarget[targetId] ??= []).add(reason);
    }

    _addGraphRelationshipReasons(sourceId, addReason);
    _addSharedDoctrineReasons(sourceId, addReason);
    _addSharedArticleReasons(sourceId, addReason);
    _addSharedActReasons(sourceId, addReason);

    final results = <RelatedCaseResult>[];
    for (final entry in reasonsByTarget.entries) {
      final c = _caseById(entry.key);
      if (c == null) continue; // never fabricate a record for an unknown ID
      final reasons = _sortReasons(entry.value);
      results.add(RelatedCaseResult(
        sourceCaseId: sourceId,
        caseId: c.caseId,
        caseName: c.caseName,
        year: c.year,
        reasons: reasons,
        caseObject: c,
      ));
    }
    results.sort(_compareResults);

    if (limit != null && limit >= 0 && results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  /// Adds a graph relationship reason for every direct P5 case → case edge
  /// touching [sourceId]. Direction and type are preserved verbatim from the
  /// edge — nothing is inferred.
  void _addGraphRelationshipReasons(
    String sourceId,
    void Function(String targetId, DiscoveryReason reason) add,
  ) {
    for (final e in precedentService.incomingRelationships(sourceId)) {
      final other = e.sourceId;
      add(
          other,
          DiscoveryReason(
            type: DiscoveryReasonType.graphRelationship,
            label: 'direct precedent: $other ${e.typeLabel} $sourceId',
            references: [e.edgeId, other, e.typeLabel],
            provenance: e.provenance,
          ));
    }
    for (final e in precedentService.outgoingRelationships(sourceId)) {
      if (e.sourceId == e.targetId) continue; // defensive; graph forbids loops
      add(
          e.targetId,
          DiscoveryReason(
            type: DiscoveryReasonType.graphRelationship,
            label: 'direct precedent: $sourceId ${e.typeLabel} ${e.targetId}',
            references: [e.edgeId, e.targetId, e.typeLabel],
            provenance: e.provenance,
          ));
    }
  }

  /// Adds a shared-doctrine reason for every other case engaging the same
  /// validated doctrines as [sourceId] (P5 case ↔ doctrine edges).
  void _addSharedDoctrineReasons(
    String sourceId,
    void Function(String targetId, DiscoveryReason reason) add,
  ) {
    final myEdges = doctrineService.getDoctrinesForCase(sourceId);
    for (final myEdge in myEdges) {
      final doctrineId = myEdge.targetId;
      for (final otherEdge in doctrineService.getCasesForDoctrine(doctrineId)) {
        add(
            otherEdge.sourceId,
            DiscoveryReason(
              type: DiscoveryReasonType.sharedDoctrine,
              label: 'shared doctrine: $doctrineId',
              references: [doctrineId],
              provenance:
                  _joinProvenance([myEdge.provenance, otherEdge.provenance]),
            ));
      }
    }
  }

  /// Adds a shared-article reason for every other case that references the same
  /// constitutional article as [sourceId] (P3 `relatedArticles`, normalized).
  void _addSharedArticleReasons(
    String sourceId,
    void Function(String targetId, DiscoveryReason reason) add,
  ) {
    final myCase = _caseById(sourceId);
    if (myCase == null) return;

    final articleKeyToCases = <String, List<String>>{};
    for (final c in cases) {
      if (c.caseId == sourceId) continue;
      for (final ref in c.relatedArticles) {
        final key = CaseSearchNormalizer.normalizeArticle(ref);
        if (key.isEmpty) continue;
        (articleKeyToCases[key] ??= []).add(c.caseId);
      }
    }

    final seenKeys = <String>{};
    for (final ref in myCase.relatedArticles) {
      final key = CaseSearchNormalizer.normalizeArticle(ref);
      if (key.isEmpty) continue;
      if (!seenKeys.add(key)) continue;
      for (final otherId in articleKeyToCases[key] ?? const <String>[]) {
        add(
            otherId,
            DiscoveryReason(
              type: DiscoveryReasonType.sharedArticle,
              label: 'shared article: $key',
              references: [key],
              provenance: 'corpus:relatedArticles',
            ));
      }
    }
  }

  /// Adds a shared-Act reason for every other case that references the same Act
  /// as [sourceId] (P3 `relatedActs`, normalized).
  void _addSharedActReasons(
    String sourceId,
    void Function(String targetId, DiscoveryReason reason) add,
  ) {
    final myCase = _caseById(sourceId);
    if (myCase == null) return;

    final actKeyToCases = <String, List<String>>{};
    for (final c in cases) {
      if (c.caseId == sourceId) continue;
      for (final ref in c.relatedActs) {
        final key = CaseSearchNormalizer.normalizeText(ref);
        if (key.isEmpty) continue;
        (actKeyToCases[key] ??= []).add(c.caseId);
      }
    }

    final seenActs = <String>{};
    for (final ref in myCase.relatedActs) {
      final key = CaseSearchNormalizer.normalizeText(ref);
      if (key.isEmpty) continue;
      if (!seenActs.add(key)) continue;
      for (final otherId in actKeyToCases[key] ?? const <String>[]) {
        add(
            otherId,
            DiscoveryReason(
              type: DiscoveryReasonType.sharedAct,
              label: 'shared act: $key',
              references: [key],
              provenance: 'corpus:relatedActs',
            ));
      }
    }
  }

  static String _joinProvenance(List<String> parts) {
    final seen = <String>{};
    final out = <String>[];
    for (final p in parts) {
      if (p.isEmpty || !seen.add(p)) continue;
      out.add(p);
    }
    return out.join(';');
  }

  /// Sorts reasons within a result: fixed kind priority, then label ascending.
  static List<DiscoveryReason> _sortReasons(List<DiscoveryReason> reasons) {
    final copy = List<DiscoveryReason>.of(reasons);
    copy.sort((a, b) {
      final ka = _reasonKindOrder.indexOf(a.type);
      final kb = _reasonKindOrder.indexOf(b.type);
      if (ka != kb) return ka.compareTo(kb);
      return a.label.compareTo(b.label);
    });
    return List<DiscoveryReason>.unmodifiable(copy);
  }

  /// Deterministic result ordering: more independent reasons first, then year
  /// descending, case name ascending, case ID ascending (P6 tie-break).
  static int _compareResults(RelatedCaseResult a, RelatedCaseResult b) {
    if (a.reasons.length != b.reasons.length) {
      return b.reasons.length.compareTo(a.reasons.length);
    }
    if (a.year != b.year) return b.year.compareTo(a.year);
    final byName = a.caseName.toLowerCase().compareTo(b.caseName.toLowerCase());
    if (byName != 0) return byName;
    return a.caseId.compareTo(b.caseId);
  }

  // -------------------------------------------------------------------------
  // B. Doctrine / Article / Act collections (P6 query results)
  // -------------------------------------------------------------------------

  /// All cases associated with a Constitutional Doctrine (canonical ID or name).
  ///
  /// Delegates to the P6 `findByDoctrine` — a deterministic, evidence-gated
  /// query result. Empty for unknown/unassociated doctrines.
  List<CaseSearchResult> casesForDoctrine(String doctrineIdOrName,
      {int? limit}) {
    final results = searchEngine.findByDoctrine(doctrineIdOrName);
    return _applyLimit(results, limit);
  }

  /// All cases associated with a constitutional Article (e.g. `21`,
  /// `Article 21`, `191a`). Deterministic P6 query result.
  List<CaseSearchResult> casesForArticle(String article, {int? limit}) {
    final results = searchEngine.findByArticle(article);
    return _applyLimit(results, limit);
  }

  /// All cases associated with an Act (e.g. `Passports Act`,
  /// `Indian Penal Code, 1860`). Deterministic P6 query result.
  List<CaseSearchResult> casesForAct(String act, {int? limit}) {
    final results = searchEngine.findByAct(act);
    return _applyLimit(results, limit);
  }

  static List<CaseSearchResult> _applyLimit(
    List<CaseSearchResult> results,
    int? limit,
  ) {
    if (limit == null || limit < 0 || results.length <= limit) return results;
    return results.sublist(0, limit);
  }

  // -------------------------------------------------------------------------
  // C. Precedent navigation (P5 graph semantics preserved)
  // -------------------------------------------------------------------------

  /// The cases [idOrName] directly relies on as authority (P5 authority edges
  /// only: followed/applied/affirmed/approved/clarified/expanded).
  List<PrecedentGraphEdge> directPrecedents(String idOrName) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return const [];
    return precedentService.directPrecedents(id);
  }

  /// All P5 case → case edges originating from [idOrName].
  List<PrecedentGraphEdge> outgoingRelationships(String idOrName) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return const [];
    return precedentService.outgoingRelationships(id);
  }

  /// All P5 case → case edges targeting [idOrName].
  List<PrecedentGraphEdge> incomingRelationships(String idOrName) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return const [];
    return precedentService.incomingRelationships(id);
  }

  /// All P5 case → case edges between [aIdOrName] and [bIdOrName].
  List<PrecedentGraphEdge> relationshipsBetween(
    String aIdOrName,
    String bIdOrName,
  ) {
    final a = _resolveCaseId(aIdOrName);
    final b = _resolveCaseId(bIdOrName);
    if (a == null || b == null || a == b) return const [];
    return precedentService.relationshipsBetween(a, b);
  }

  /// Transitive authority ancestors of [idOrName] — every case reachable by
  /// walking the P5 authority edges forward (the authorities this case relies
  /// on, directly or transitively). Deterministic, cycle-safe, sorted by ID.
  List<LegalGraphNodeRef> ancestors(String idOrName) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return const [];
    return _transitiveAuthorityClosure(id, outgoing: true);
  }

  /// Transitive authority descendants of [idOrName] — every case reachable by
  /// walking the P5 authority edges backward (cases relying on this case,
  /// directly or transitively). Deterministic, cycle-safe, sorted by ID.
  List<LegalGraphNodeRef> descendants(String idOrName) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return const [];
    return _transitiveAuthorityClosure(id, outgoing: false);
  }

  List<LegalGraphNodeRef> _transitiveAuthorityClosure(
    String startId, {
    required bool outgoing,
  }) {
    final visited = <String>{startId};
    final queue = <String>[startId];
    final found = <LegalGraphNodeRef>[];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final edges = outgoing
          ? graph.edgesFrom(current, LegalGraphNodeType.caseLaw)
          : graph.edgesTo(current, LegalGraphNodeType.caseLaw);
      for (final e in edges.whereType<PrecedentGraphEdge>()) {
        if (!_authorityTypes.contains(e.type)) continue;
        final next = outgoing ? e.targetId : e.sourceId;
        if (!visited.add(next)) continue; // cycle-safe
        final node = graph.nodeFor(next, LegalGraphNodeType.caseLaw);
        if (node != null) found.add(node);
        queue.add(next);
      }
    }
    found.sort((a, b) => a.id.compareTo(b.id));
    return List<LegalGraphNodeRef>.unmodifiable(found);
  }

  /// Longest simple chain of precedent authorities upstream of [idOrName] (P5).
  LegalGraphPath? predecessorChain(String idOrName) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return null;
    return traversalService.predecessorChain(id);
  }

  /// Longest simple chain of precedent authorities downstream of [idOrName]
  /// (P5).
  LegalGraphPath? successorChain(String idOrName) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return null;
    return traversalService.successorChain(id);
  }

  /// Shortest P5 path between two cases, or null when disconnected.
  LegalGraphPath? pathBetween(String fromIdOrName, String toIdOrName) {
    final from = _resolveCaseId(fromIdOrName);
    final to = _resolveCaseId(toIdOrName);
    if (from == null || to == null || from == to) return null;
    return traversalService.shortestPath(from, to);
  }
}
