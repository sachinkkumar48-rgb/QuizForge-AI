/// P10 Evidence-Bounded Cross-Case Analysis service (TITAN-KO-015.0 P10).
///
/// A deterministic, offline-first composition/analysis layer over the
/// validated P3–P9 GARUDA Case Law corpus. It answers "what do the existing
/// validated case records show when those cases are compared?" — it performs
/// **no legal research**.
///
/// # Capabilities
///
/// - [compareCases] — deterministic comparison of two or more cases. The result
///   separates *factual source data* (what each P3/P4 record says) from
///   *structural observations* (what deterministic comparison safely derives:
///   chronology, P5 graph edges, holding/ratio/issue/outcome differences,
///   shared structured attributes). No "legally similar" verdict is ever made.
/// - [chronologicalAnalysis] — deterministic chronological ordering of selected
///   cases using authoritative existing dates (year, then judgment date).
/// - [precedentChainAnalysis] — precedent-chain analysis reusing the P5
///   `predecessorChain` / `successorChain` paths verbatim, enriched with P4
///   case intelligence. P5 relationship semantics are preserved exactly.
/// - [doctrineAnalysis] — doctrine-oriented analysis using existing P5
///   case → doctrine edges and P4 intelligence; doctrine roles are recorded
///   P5 evidence, never a P10 inference.
/// - [synthesize] — evidence-preserving multi-case synthesis aggregating
///   identity, chronology, P4 intelligence, doctrine/article/Act membership,
///   P5 graph relationships and P9 discovery context.
///
/// # Safety boundaries
///
/// P10 never fabricates citations, never reports a precedent relationship as a
/// citation, never invents graph edges, never reinterprets P5 relationship
/// types, and never emits unsupported legal conclusions (overruled / refined /
/// extended / "the doctrine evolved from X to Y"). Every observation carries
/// the canonical references and provenance that establish it.
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
import '../../discovery/service/case_discovery_service.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../../graph/data/legal_graph_seed.dart';
import '../../graph/domain/doctrine_relationship_type.dart';
import '../../graph/domain/legal_graph.dart';
import '../../graph/domain/legal_graph_edge.dart';
import '../../graph/service/doctrine_relationship_service.dart';
import '../../graph/service/legal_graph_traversal_service.dart';
import '../../graph/service/precedent_graph_service.dart';
import '../../intelligence/domain/judgment_intelligence.dart';
import '../../search/data/case_search_normalizer.dart';
import '../../search/service/case_search_engine.dart';
import '../domain/analysis_enums.dart';
import '../domain/case_comparison.dart';
import '../domain/case_synthesis.dart';
import '../domain/chronology.dart';
import '../domain/doctrine_analysis.dart';
import '../domain/precedent_chain_analysis.dart';
import '../domain/structural_observation.dart';

/// P10 facade over evidence-bounded cross-case analysis.
@immutable
class CrossCaseAnalysisService {
  /// The validated corpus this service reads from (canonical seed by default).
  final List<CaseKnowledgeObject> cases;

  /// The P5 legal graph snapshot.
  final LegalGraph graph;

  /// The P6 search engine (reused for exact case resolution).
  final CaseSearchEngine searchEngine;

  /// P5 case → case service.
  final PrecedentGraphService precedentService;

  /// P5 case ↔ doctrine service.
  final DoctrineRelationshipService doctrineService;

  /// P5 traversal service (chains, paths).
  final LegalGraphTraversalService traversalService;

  /// P9 discovery service (reused for synthesis discovery context).
  final CaseDiscoveryService discoveryService;

  /// Fixed shared-attribute kind ordering for deterministic serialization.
  static const List<SharedAttributeKind> _sharedKindOrder = [
    SharedAttributeKind.article,
    SharedAttributeKind.act,
    SharedAttributeKind.doctrine,
    SharedAttributeKind.judge,
  ];

  /// Fixed observation type ordering for deterministic serialization.
  static const List<StructuralObservationType> _observationTypeOrder = [
    StructuralObservationType.chronologicalOrder,
    StructuralObservationType.chronologicalSpan,
    StructuralObservationType.graphRelationship,
    StructuralObservationType.holdingDifference,
    StructuralObservationType.ratioDifference,
    StructuralObservationType.issueDifference,
    StructuralObservationType.outcomeDifference,
    StructuralObservationType.noSharedAttributes,
  ];

  factory CrossCaseAnalysisService({
    List<CaseKnowledgeObject>? cases,
    LegalGraph? graph,
    CaseSearchEngine? searchEngine,
    PrecedentGraphService? precedentService,
    DoctrineRelationshipService? doctrineService,
    LegalGraphTraversalService? traversalService,
    CaseDiscoveryService? discoveryService,
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
    final dd = discoveryService ??
        CaseDiscoveryService(
          cases: corpus,
          graph: g,
          searchEngine: se,
          precedentService: ps,
          doctrineService: ds,
          traversalService: ts,
        );
    return CrossCaseAnalysisService._(
      cases: List<CaseKnowledgeObject>.unmodifiable(corpus),
      graph: g,
      searchEngine: se,
      precedentService: ps,
      doctrineService: ds,
      traversalService: ts,
      discoveryService: dd,
    );
  }

  const CrossCaseAnalysisService._({
    required this.cases,
    required this.graph,
    required this.searchEngine,
    required this.precedentService,
    required this.doctrineService,
    required this.traversalService,
    required this.discoveryService,
  });

  // -------------------------------------------------------------------------
  // Convenience accessors
  // -------------------------------------------------------------------------

  /// Canonical IDs of every case in the corpus.
  Set<String> get caseIds => searchEngine.indexedCaseIds;

  /// Canonical doctrine IDs in the graph.
  List<String> get doctrineIds =>
      doctrineService.allDoctrines.map((d) => d.id).toList(growable: false);

  /// Whether [idOrName] resolves to a corpus case (canonical ID or name).
  bool hasCase(String idOrName) => _resolveCaseId(idOrName) != null;

  /// Whether [doctrineId] is a canonical doctrine in the graph.
  bool hasDoctrine(String doctrineId) =>
      doctrineService.hasDoctrine(doctrineId);

  // -------------------------------------------------------------------------
  // A. Case comparison
  // -------------------------------------------------------------------------

  /// Deterministic comparison of two or more existing cases.
  ///
  /// Inputs may be canonical IDs or case names. Unknown identifiers are never
  /// fabricated into the comparison — they are reported on
  /// [CaseComparisonResult.unresolvedCaseIds]. Duplicate identifiers are
  /// de-duplicated (first occurrence wins, input order preserved).
  ///
  /// The result separates [CaseComparisonItem] (factual source data from the
  /// P3/P4 records) from [SharedAttribute] and [StructuralObservation]
  /// (structural, evidence-bounded derivations).
  CaseComparisonResult compareCases(List<String> idOrNames) {
    final (resolved, unresolved) = _resolveAll(idOrNames);
    final items = <CaseComparisonItem>[
      for (final id in resolved) _buildComparisonItem(id),
    ];
    final shared = _sharedAttributes(resolved);
    final observations =
        _comparisonObservations(resolved, items, hasShared: shared.isNotEmpty);
    return CaseComparisonResult(
      caseIds: List.unmodifiable(resolved),
      items: List.unmodifiable(items),
      sharedAttributes: shared,
      observations: observations,
      unresolvedCaseIds: List.unmodifiable(unresolved),
    );
  }

  /// Convenience two-case comparison.
  CaseComparisonResult compareTwo(String a, String b) => compareCases([a, b]);

  // -------------------------------------------------------------------------
  // B. Chronology
  // -------------------------------------------------------------------------

  /// Deterministic chronological ordering of selected cases.
  ///
  /// Ordering uses the authoritative existing dates: judgment year asc, then
  /// judgment date asc, then case name asc, then case ID asc. Unknown
  /// identifiers are reported on [ChronologyAnalysis.unresolvedCaseIds].
  ChronologyAnalysis chronologicalAnalysis(List<String> idOrNames) {
    final (resolved, unresolved) = _resolveAll(idOrNames);
    final ordered = <CaseKnowledgeObject>[
      for (final id in resolved) _caseById(id)!,
    ]..sort(_compareCasesChronological);
    final entries = <ChronologicalCaseEntry>[
      for (var i = 0; i < ordered.length; i++)
        ChronologicalCaseEntry(
          caseId: ordered[i].caseId,
          caseName: ordered[i].caseName,
          year: ordered[i].year,
          judgmentDate: ordered[i].judgmentDate,
          position: i,
          caseObject: ordered[i],
        ),
    ];
    return ChronologyAnalysis(
      entries: List.unmodifiable(entries),
      unresolvedCaseIds: List.unmodifiable(unresolved),
    );
  }

  // -------------------------------------------------------------------------
  // C. Precedent-chain analysis
  // -------------------------------------------------------------------------

  /// Precedent-chain analysis over the P5 graph, reusing the P5
  /// `predecessorChain` / `successorChain` paths verbatim and enriching each
  /// node with its P4 case intelligence.
  ///
  /// Returns null when [idOrName] does not resolve to a corpus case. The chain
  /// always starts at the anchor case (even for a single-node chain); edge
  /// types are exposed as-is and never reinterpreted as citations.
  PrecedentChainAnalysis? precedentChainAnalysis(
    String idOrName, {
    PrecedentChainDirection direction = PrecedentChainDirection.predecessor,
  }) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return null;
    final path = direction == PrecedentChainDirection.predecessor
        ? traversalService.predecessorChain(id)
        : traversalService.successorChain(id);
    if (path == null) return null;

    final entries = <PrecedentChainEntry>[];
    for (var i = 0; i < path.nodes.length; i++) {
      final node = path.nodes[i];
      final c = _caseById(node.id);
      if (c == null) continue; // defensive: only corpus cases get entries
      final intel = c.judgmentIntelligence;
      PrecedentRelationshipStep? step;
      if (i > 0 && i - 1 < path.edges.length) {
        final e = path.edges[i - 1];
        step = PrecedentRelationshipStep(
          edgeId: e.edgeId,
          typeLabel: e.typeLabel,
          sourceId: e.sourceId,
          targetId: e.targetId,
          provenance: e.provenance,
          evidenceIds: List.unmodifiable(e.evidenceIds),
        );
      }
      entries.add(PrecedentChainEntry(
        caseId: c.caseId,
        caseName: c.caseName,
        year: c.year,
        judgmentDate: c.judgmentDate,
        holdings: _holdingTexts(intel),
        ratios: _ratioTexts(intel),
        issues: _issueTexts(intel),
        relationshipFromPrevious: step,
        caseObject: c,
      ));
    }
    if (entries.isEmpty) return null;
    return PrecedentChainAnalysis(
      anchorCaseId: id,
      direction: direction,
      entries: List.unmodifiable(entries),
    );
  }

  // -------------------------------------------------------------------------
  // D. Doctrine-oriented analysis
  // -------------------------------------------------------------------------

  /// Deterministic analysis of the cases belonging to a validated doctrine.
  ///
  /// [doctrineIdOrName] resolves by canonical doctrine ID or doctrine name.
  /// Member cases come from the existing P5 case → doctrine edges; doctrine
  /// roles (`establishes`, `applies`, ...) are recorded P5 evidence, not a P10
  /// inference. Cases are ordered chronologically. An unknown doctrine yields
  /// an empty result — nothing is fabricated.
  DoctrineAnalysisResult doctrineAnalysis(String doctrineIdOrName) {
    final doctrineId = _resolveDoctrineId(doctrineIdOrName);
    if (doctrineId == null) {
      return DoctrineAnalysisResult(
        doctrineId: doctrineIdOrName.trim().toUpperCase(),
        doctrineName: '',
        cases: const [],
        chronology:
            const ChronologyAnalysis(entries: [], unresolvedCaseIds: []),
        graphRelationships: const [],
        observations: const [],
      );
    }
    final doctrineName =
        doctrineService.doctrineNode(doctrineId)?.name ?? doctrineId;

    final entries = <DoctrineCaseEntry>[];
    for (final e in doctrineService.getCasesForDoctrine(doctrineId)) {
      final c = _caseById(e.sourceId);
      if (c == null) continue; // defensive: only corpus cases get entries
      final intel = c.judgmentIntelligence;
      entries.add(DoctrineCaseEntry(
        caseId: c.caseId,
        caseName: c.caseName,
        year: c.year,
        judgmentDate: c.judgmentDate,
        role: e.type.name,
        roleLabel: e.type.displayName,
        edgeId: e.edgeId,
        provenance: e.provenance,
        holdings: _holdingTexts(intel),
        ratios: _ratioTexts(intel),
        issues: _issueTexts(intel),
        outcome: _outcomeText(intel),
        caseObject: c,
      ));
    }
    entries.sort(_compareDoctrineEntries);

    final memberIds = entries.map((e) => e.caseId).toList(growable: false);
    final chronology = chronologicalAnalysis(memberIds);
    final graphRelationships = _precedentEdgesAmong(memberIds);
    final observations = <StructuralObservation>[];
    if (entries.isNotEmpty &&
        chronology.earliest != null &&
        chronology.latest != null) {
      observations.add(StructuralObservation(
        type: StructuralObservationType.chronologicalSpan,
        label: 'doctrine $doctrineId corpus cases span '
            '${chronology.earliest!.year}–${chronology.latest!.year}',
        references: [doctrineId],
        provenance: 'structural:chronology',
      ));
    }
    return DoctrineAnalysisResult(
      doctrineId: doctrineId,
      doctrineName: doctrineName,
      cases: List.unmodifiable(entries),
      chronology: chronology,
      graphRelationships: graphRelationships,
      observations: List.unmodifiable(observations),
    );
  }

  // -------------------------------------------------------------------------
  // E. Multi-case synthesis
  // -------------------------------------------------------------------------

  /// Evidence-preserving synthesis of a selected set of cases.
  ///
  /// Re-presents each case's identity, chronology, P4 intelligence,
  /// doctrine/article/Act membership, P5 graph relationships and P9 discovery
  /// context, and aggregates only deterministic structural facts. It never
  /// invents a legal conclusion.
  CaseSynthesis synthesize(List<String> idOrNames) {
    final (resolved, unresolved) = _resolveAll(idOrNames);
    final entries = <SynthesisCaseEntry>[];
    final edgeMap = <String, PrecedentGraphEdge>{};
    for (final id in resolved) {
      final c = _caseById(id)!;
      final intel = c.judgmentIntelligence;
      final touching = <PrecedentGraphEdge>[
        ...precedentService.outgoingRelationships(id),
        ...precedentService.incomingRelationships(id),
      ];
      final within = <PrecedentGraphEdge>[];
      for (final e in touching) {
        final other = e.sourceId == id ? e.targetId : e.sourceId;
        if (resolved.contains(other)) {
          within.add(e);
          edgeMap[e.edgeId] = e;
        }
      }
      within.sort(_compareEdges);
      entries.add(SynthesisCaseEntry(
        caseId: c.caseId,
        caseName: c.caseName,
        citation: c.citation,
        year: c.year,
        judgmentDate: c.judgmentDate,
        holdings: _holdingTexts(intel),
        ratios: _ratioTexts(intel),
        issues: _issueTexts(intel),
        outcome: _outcomeText(intel),
        significance: intel?.judicialSignificance?.constitutionalSignificance ??
            c.constitutionalSignificance,
        doctrines: _doctrineIdsFor(id),
        articles: _articleKeysFor(c),
        acts: _actKeysFor(c),
        evidenceIds: List.unmodifiable(c.evidenceIds),
        graphRelationships: List.unmodifiable(within),
        caseObject: c,
      ));
    }
    final graphRelationships = edgeMap.values.toList()..sort(_compareEdges);
    final aggregate = _synthesisAggregate(entries);
    final discoveryLinks = _synthesisDiscoveryLinks(resolved);
    final observations = <StructuralObservation>[
      if (resolved.length >= 2 &&
          aggregate.earliestYear != null &&
          aggregate.latestYear != null)
        StructuralObservation(
          type: StructuralObservationType.chronologicalSpan,
          label:
              'selection spans ${aggregate.earliestYear}–${aggregate.latestYear}',
          references: (resolved.toList()..sort()),
          provenance: 'structural:chronology',
        ),
    ];
    return CaseSynthesis(
      caseIds: List.unmodifiable(resolved),
      entries: List.unmodifiable(entries),
      aggregate: aggregate,
      graphRelationships: List.unmodifiable(graphRelationships),
      discoveryLinks: List.unmodifiable(discoveryLinks),
      observations: List.unmodifiable(observations),
      unresolvedCaseIds: List.unmodifiable(unresolved),
    );
  }

  // -------------------------------------------------------------------------
  // Resolution helpers
  // -------------------------------------------------------------------------

  /// Resolves [idOrName] to a canonical case ID, or null when unknown.
  String? _resolveCaseId(String idOrName) {
    final trimmed = idOrName.trim();
    if (trimmed.isEmpty) return null;
    return searchEngine.findExact(trimmed)?.caseId;
  }

  /// Resolves [idOrName] to a canonical doctrine ID (by canonical ID, by
  /// normalized doctrine name, or by normalized ID), or null when unknown.
  String? _resolveDoctrineId(String idOrName) {
    final q = idOrName.trim();
    if (q.isEmpty) return null;
    final upper = q.toUpperCase();
    if (doctrineService.hasDoctrine(upper)) return upper;
    final norm = CaseSearchNormalizer.normalizeText(q);
    if (norm.isEmpty) return null;
    String? byId;
    for (final node in doctrineService.allDoctrines) {
      if (CaseSearchNormalizer.normalizeText(node.name) == norm) {
        return node.id;
      }
      if (CaseSearchNormalizer.normalizeText(node.id) == norm && byId == null) {
        byId = node.id;
      }
    }
    return byId;
  }

  /// Resolves every input to a canonical case ID (de-duplicated, first
  /// occurrence, input order preserved) plus the unresolved identifiers.
  (List<String>, List<String>) _resolveAll(List<String> inputs) {
    final resolved = <String>[];
    final seen = <String>{};
    final unresolved = <String>[];
    final seenUnresolved = <String>{};
    for (final input in inputs) {
      final id = _resolveCaseId(input);
      if (id == null) {
        if (seenUnresolved.add(input)) unresolved.add(input);
      } else if (seen.add(id)) {
        resolved.add(id);
      }
    }
    return (resolved, unresolved);
  }

  CaseKnowledgeObject? _caseById(String caseId) {
    for (final c in cases) {
      if (c.caseId == caseId) return c;
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Comparison internals
  // -------------------------------------------------------------------------

  CaseComparisonItem _buildComparisonItem(String id) {
    final c = _caseById(id)!;
    final intel = c.judgmentIntelligence;
    return CaseComparisonItem(
      caseId: c.caseId,
      caseName: c.caseName,
      citation: c.citation,
      year: c.year,
      bench: c.bench,
      judges: (c.judges.toSet().toList()..sort()),
      holdings: _holdingTexts(intel),
      ratios: _ratioTexts(intel),
      issues: _issueTexts(intel),
      outcome: _outcomeText(intel),
      significance: intel?.judicialSignificance?.constitutionalSignificance ??
          c.constitutionalSignificance,
      articles: _articleKeysFor(c),
      acts: _actKeysFor(c),
      doctrines: _doctrineIdsFor(id),
      hasIntelligence: intel != null,
      evidenceIds: List.unmodifiable(c.evidenceIds),
      provenance: 'corpus:CaseKnowledgeObject;p4:judgmentIntelligence',
      caseObject: c,
    );
  }

  /// Structured attributes present in at least two of the compared cases,
  /// in a deterministic order (article, act, doctrine, judge; value asc).
  List<SharedAttribute> _sharedAttributes(List<String> ids) {
    if (ids.length < 2) return const [];
    final result = <SharedAttribute>[];

    // Constitutional articles (P3 `relatedArticles`, normalized).
    final articleToCases = <String, Set<String>>{};
    final articleToOriginal = <String, List<String>>{};
    for (final id in ids) {
      final c = _caseById(id)!;
      for (final ref in c.relatedArticles) {
        final key = CaseSearchNormalizer.normalizeArticle(ref);
        if (key.isEmpty) continue;
        (articleToCases[key] ??= <String>{}).add(id);
        (articleToOriginal[key] ??= <String>[]).add(ref);
      }
    }
    for (final key in articleToCases.keys.toList()..sort()) {
      final caseIds = articleToCases[key]!.toList()..sort();
      if (caseIds.length < 2) continue;
      result.add(SharedAttribute(
        kind: SharedAttributeKind.article,
        value: key,
        displayValue: _smallest(articleToOriginal[key]!),
        caseIds: caseIds,
        provenance: 'corpus:relatedArticles',
      ));
    }

    // Acts (P3 `relatedActs`, normalized).
    final actToCases = <String, Set<String>>{};
    final actToOriginal = <String, List<String>>{};
    for (final id in ids) {
      final c = _caseById(id)!;
      for (final ref in c.relatedActs) {
        final key = CaseSearchNormalizer.normalizeText(ref);
        if (key.isEmpty) continue;
        (actToCases[key] ??= <String>{}).add(id);
        (actToOriginal[key] ??= <String>[]).add(ref);
      }
    }
    for (final key in actToCases.keys.toList()..sort()) {
      final caseIds = actToCases[key]!.toList()..sort();
      if (caseIds.length < 2) continue;
      result.add(SharedAttribute(
        kind: SharedAttributeKind.act,
        value: key,
        displayValue: _smallest(actToOriginal[key]!),
        caseIds: caseIds,
        provenance: 'corpus:relatedActs',
      ));
    }

    // Doctrines (P5 case → doctrine edges).
    final doctrineToCases = <String, Set<String>>{};
    final doctrineProvenance = <String, List<String>>{};
    for (final id in ids) {
      for (final e in doctrineService.getDoctrinesForCase(id)) {
        (doctrineToCases[e.targetId] ??= <String>{}).add(id);
        (doctrineProvenance[e.targetId] ??= <String>[]).add(e.provenance);
      }
    }
    for (final d in doctrineToCases.keys.toList()..sort()) {
      final caseIds = doctrineToCases[d]!.toList()..sort();
      if (caseIds.length < 2) continue;
      result.add(SharedAttribute(
        kind: SharedAttributeKind.doctrine,
        value: d,
        displayValue: doctrineService.doctrineNode(d)?.name ?? d,
        caseIds: caseIds,
        provenance: _joinProvenance(doctrineProvenance[d]!),
      ));
    }

    // Judges (P3 `judges`, normalized for grouping).
    final judgeToCases = <String, Set<String>>{};
    final judgeToOriginal = <String, List<String>>{};
    for (final id in ids) {
      final c = _caseById(id)!;
      for (final name in c.judges) {
        final key = name.trim().toLowerCase();
        if (key.isEmpty) continue;
        (judgeToCases[key] ??= <String>{}).add(id);
        (judgeToOriginal[key] ??= <String>[]).add(name);
      }
    }
    for (final key in judgeToCases.keys.toList()..sort()) {
      final caseIds = judgeToCases[key]!.toList()..sort();
      if (caseIds.length < 2) continue;
      result.add(SharedAttribute(
        kind: SharedAttributeKind.judge,
        value: key,
        displayValue: _smallest(judgeToOriginal[key]!),
        caseIds: caseIds,
        provenance: 'corpus:judges',
      ));
    }

    result.sort(_compareSharedAttributes);
    return List.unmodifiable(result);
  }

  /// Structural observations over a comparison: pairwise chronology, verbatim
  /// P5 graph edges between the cases, and holding/ratio/issue/outcome
  /// differences, plus a no-shared-attributes marker when applicable.
  List<StructuralObservation> _comparisonObservations(
    List<String> resolved,
    List<CaseComparisonItem> items, {
    required bool hasShared,
  }) {
    if (resolved.length < 2) return const [];
    final result = <StructuralObservation>[];

    // Pairwise chronological order (strictly distinct positions only).
    for (var i = 0; i < resolved.length; i++) {
      for (var j = i + 1; j < resolved.length; j++) {
        final a = resolved[i];
        final b = resolved[j];
        final ca = _caseById(a)!;
        final cb = _caseById(b)!;
        final cmp = _compareCasesChronological(ca, cb);
        if (cmp < 0) {
          result.add(StructuralObservation(
            type: StructuralObservationType.chronologicalOrder,
            label: '$a (${ca.year}) precedes $b (${cb.year})',
            references: [a, b],
            provenance: 'corpus:year',
          ));
        } else if (cmp > 0) {
          result.add(StructuralObservation(
            type: StructuralObservationType.chronologicalOrder,
            label: '$b (${cb.year}) precedes $a (${ca.year})',
            references: [b, a],
            provenance: 'corpus:year',
          ));
        }
      }
    }

    // P5 graph edges between the compared cases (verbatim, never inferred).
    final edgeMap = <String, PrecedentGraphEdge>{};
    for (var i = 0; i < resolved.length; i++) {
      for (var j = i + 1; j < resolved.length; j++) {
        for (final e in precedentService.relationshipsBetween(
            resolved[i], resolved[j])) {
          edgeMap[e.edgeId] = e;
        }
      }
    }
    final edges = edgeMap.values.toList()..sort(_compareEdges);
    for (final e in edges) {
      result.add(StructuralObservation(
        type: StructuralObservationType.graphRelationship,
        label: '${e.sourceId} ${e.typeLabel} ${e.targetId}',
        references: [e.edgeId],
        provenance: e.provenance,
      ));
    }

    // Difference observations (structural, not legal).
    if (_dimensionDiffers(items, (it) => it.holdings)) {
      result.add(StructuralObservation(
        type: StructuralObservationType.holdingDifference,
        label: 'holdings differ across the ${resolved.length} compared case(s)',
        references: (resolved.toList()..sort()),
        provenance: 'p4:holdings',
      ));
    }
    if (_dimensionDiffers(items, (it) => it.ratios)) {
      result.add(StructuralObservation(
        type: StructuralObservationType.ratioDifference,
        label: 'ratios differ across the ${resolved.length} compared case(s)',
        references: (resolved.toList()..sort()),
        provenance: 'p4:ratios',
      ));
    }
    if (_dimensionDiffers(items, (it) => it.issues)) {
      result.add(StructuralObservation(
        type: StructuralObservationType.issueDifference,
        label: 'issues differ across the ${resolved.length} compared case(s)',
        references: (resolved.toList()..sort()),
        provenance: 'p4:issues',
      ));
    }
    if (_dimensionDiffers(items, (it) => [it.outcome])) {
      result.add(StructuralObservation(
        type: StructuralObservationType.outcomeDifference,
        label: 'outcomes differ across the ${resolved.length} compared case(s)',
        references: (resolved.toList()..sort()),
        provenance: 'p4:outcome',
      ));
    }

    if (!hasShared) {
      result.add(StructuralObservation(
        type: StructuralObservationType.noSharedAttributes,
        label: 'no shared structured attributes among the compared cases',
        references: (resolved.toList()..sort()),
        provenance: 'structural:comparison',
      ));
    }

    result.sort(_compareObservations);
    return List.unmodifiable(result);
  }

  // -------------------------------------------------------------------------
  // Synthesis internals
  // -------------------------------------------------------------------------

  SynthesisAggregate _synthesisAggregate(List<SynthesisCaseEntry> entries) {
    final doctrines = <String>{};
    final articles = <String>{};
    final acts = <String>{};
    int? earliest;
    int? latest;
    var totalHoldings = 0;
    var totalRatios = 0;
    var totalIssues = 0;
    for (final e in entries) {
      doctrines.addAll(e.doctrines);
      articles.addAll(e.articles);
      acts.addAll(e.acts);
      if (earliest == null || e.year < earliest) earliest = e.year;
      if (latest == null || e.year > latest) latest = e.year;
      totalHoldings += e.holdings.length;
      totalRatios += e.ratios.length;
      totalIssues += e.issues.length;
    }
    final commonArticles = _commonToAll(articles, entries, (e) => e.articles);
    final commonActs = _commonToAll(acts, entries, (e) => e.acts);
    final commonDoctrines =
        _commonToAll(doctrines, entries, (e) => e.doctrines);
    return SynthesisAggregate(
      doctrines: (doctrines.toList()..sort()),
      articles: (articles.toList()..sort()),
      acts: (acts.toList()..sort()),
      earliestYear: earliest,
      latestYear: latest,
      totalHoldings: totalHoldings,
      totalRatios: totalRatios,
      totalIssues: totalIssues,
      commonArticles: commonArticles,
      commonActs: commonActs,
      commonDoctrines: commonDoctrines,
    );
  }

  /// Values of [pool] present in EVERY entry, sorted ascending.
  List<String> _commonToAll(
    Set<String> pool,
    List<SynthesisCaseEntry> entries,
    List<String> Function(SynthesisCaseEntry) extract,
  ) {
    if (entries.isEmpty) return const [];
    final common = <String>[];
    for (final value in (pool.toList()..sort())) {
      if (entries.every((e) => extract(e).contains(value))) {
        common.add(value);
      }
    }
    return common;
  }

  /// P9 discovery links among the selection, reusing the P9 discovery service.
  List<SynthesisDiscoveryLink> _synthesisDiscoveryLinks(List<String> ids) {
    if (ids.length < 2) return const [];
    final result = <SynthesisDiscoveryLink>[];
    final idSet = ids.toSet();
    for (final source in ids) {
      for (final r in discoveryService.discoverRelatedCases(source)) {
        if (r.caseId == source || !idSet.contains(r.caseId)) continue;
        result.add(SynthesisDiscoveryLink(
          sourceCaseId: source,
          targetCaseId: r.caseId,
          reasons: List.unmodifiable(r.reasons),
        ));
      }
    }
    result.sort((a, b) {
      final c = a.sourceCaseId.compareTo(b.sourceCaseId);
      if (c != 0) return c;
      return a.targetCaseId.compareTo(b.targetCaseId);
    });
    return List.unmodifiable(result);
  }

  /// P5 precedent (case → case) edges among [ids], in a deterministic order.
  List<PrecedentGraphEdge> _precedentEdgesAmong(List<String> ids) {
    if (ids.length < 2) return const [];
    final edgeMap = <String, PrecedentGraphEdge>{};
    for (var i = 0; i < ids.length; i++) {
      for (var j = i + 1; j < ids.length; j++) {
        for (final e in precedentService.relationshipsBetween(ids[i], ids[j])) {
          edgeMap[e.edgeId] = e;
        }
      }
    }
    final list = edgeMap.values.toList()..sort(_compareEdges);
    return List.unmodifiable(list);
  }

  // -------------------------------------------------------------------------
  // Extraction helpers
  // -------------------------------------------------------------------------

  List<String> _holdingTexts(JudgmentIntelligence? intel) =>
      intel == null ? const [] : [for (final h in intel.holdings) h.holding];

  List<String> _ratioTexts(JudgmentIntelligence? intel) =>
      intel == null ? const [] : [for (final r in intel.ratios) r.ratio];

  List<String> _issueTexts(JudgmentIntelligence? intel) =>
      intel == null ? const [] : [for (final i in intel.issues) i.issue];

  String _outcomeText(JudgmentIntelligence? intel) =>
      intel?.outcome?.disposition.name ?? '';

  List<String> _articleKeysFor(CaseKnowledgeObject c) {
    final keys = <String>{};
    for (final ref in c.relatedArticles) {
      final key = CaseSearchNormalizer.normalizeArticle(ref);
      if (key.isNotEmpty) keys.add(key);
    }
    return (keys.toList()..sort());
  }

  List<String> _actKeysFor(CaseKnowledgeObject c) {
    final keys = <String>{};
    for (final ref in c.relatedActs) {
      final key = CaseSearchNormalizer.normalizeText(ref);
      if (key.isNotEmpty) keys.add(key);
    }
    return (keys.toList()..sort());
  }

  List<String> _doctrineIdsFor(String id) {
    final ids = <String>{
      for (final e in doctrineService.getDoctrinesForCase(id)) e.targetId,
    };
    return (ids.toList()..sort());
  }

  // -------------------------------------------------------------------------
  // Deterministic comparators
  // -------------------------------------------------------------------------

  static int _compareCasesChronological(
      CaseKnowledgeObject a, CaseKnowledgeObject b) {
    var c = a.year.compareTo(b.year);
    if (c != 0) return c;
    c = a.judgmentDate.compareTo(b.judgmentDate);
    if (c != 0) return c;
    c = a.caseName.compareTo(b.caseName);
    if (c != 0) return c;
    return a.caseId.compareTo(b.caseId);
  }

  static int _compareDoctrineEntries(DoctrineCaseEntry a, DoctrineCaseEntry b) {
    var c = a.year.compareTo(b.year);
    if (c != 0) return c;
    c = a.judgmentDate.compareTo(b.judgmentDate);
    if (c != 0) return c;
    c = a.caseName.compareTo(b.caseName);
    if (c != 0) return c;
    return a.caseId.compareTo(b.caseId);
  }

  static int _compareEdges(PrecedentGraphEdge a, PrecedentGraphEdge b) {
    var c = a.sourceId.compareTo(b.sourceId);
    if (c != 0) return c;
    c = a.typeLabel.compareTo(b.typeLabel);
    if (c != 0) return c;
    return a.targetId.compareTo(b.targetId);
  }

  static int _compareSharedAttributes(SharedAttribute a, SharedAttribute b) {
    var c = _sharedKindOrder
        .indexOf(a.kind)
        .compareTo(_sharedKindOrder.indexOf(b.kind));
    if (c != 0) return c;
    return a.value.compareTo(b.value);
  }

  static int _compareObservations(
      StructuralObservation a, StructuralObservation b) {
    var c = _observationTypeOrder
        .indexOf(a.type)
        .compareTo(_observationTypeOrder.indexOf(b.type));
    if (c != 0) return c;
    return a.label.compareTo(b.label);
  }

  // -------------------------------------------------------------------------
  // Small utilities
  // -------------------------------------------------------------------------

  static bool _dimensionDiffers(
    List<CaseComparisonItem> items,
    List<String> Function(CaseComparisonItem) extract,
  ) {
    final signatures = <String>{};
    for (final it in items) {
      final list = extract(it).toList()..sort();
      signatures.add(list.join('|'));
    }
    return signatures.length > 1;
  }

  static String _smallest(List<String> values) {
    final copy = values.toList()..sort();
    return copy.first;
  }

  static String _joinProvenance(List<String> parts) {
    final seen = <String>{};
    final out = <String>[];
    for (final p in parts) {
      if (p.isNotEmpty && seen.add(p)) out.add(p);
    }
    out.sort();
    return out.join(';');
  }
}
