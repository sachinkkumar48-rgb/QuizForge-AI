/// P11 Evidence-Backed Case Explanation service (TITAN-KO-015.0 P11).
///
/// A deterministic, offline-first knowledge-product composition layer that
/// transforms existing validated GARUDA Case Law evidence into a structured,
/// human-readable, provenance-preserving [CaseExplanation].
///
/// P11 is NOT an AI answer generator. It never invents explanations, never
/// infers new legal propositions, never independently determines what the law
/// is, and never hallucinates legal relationships. Every statement in every
/// section is composed from existing validated P3–P10 source data:
///
/// - **Case identity / overview / Articles / Acts / evidence** — P3 corpus.
/// - **Issues / holdings / reasoning / outcome / significance / UPSC** — P4
///   Judgment Intelligence (with explicit P3 fallbacks where supported).
/// - **Doctrines / precedent context** — P5 graph edges, verbatim.
/// - **Related cases** — P9 related-case discovery, verbatim reasons.
/// - **Cross-case context** — P10 analysis (chronology, precedent chains,
///   comparison shared attributes/observations, doctrine analysis).
/// - **Evidence presentation** — P8 `EvidenceEntry` registry resolution.
///
/// Missing data is represented by an omitted section, never by fabricated
/// content. Output is deterministic: identical corpus + identical services
/// produce byte-identical structured output (see `P11_CASE_EXPLANATION.md`).
library;

import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;
import 'package:meta/meta.dart';

import '../../analysis/domain/analysis_enums.dart';
import '../../analysis/service/cross_case_analysis_service.dart';
import '../../data/case_seed_data.dart';
import '../../discovery/domain/discovery_reason.dart';
import '../../discovery/service/case_discovery_service.dart';
import '../../domain/entities/case_enums.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../../graph/data/legal_graph_seed.dart';
import '../../graph/domain/doctrine_relationship_type.dart';
import '../../graph/domain/legal_graph.dart';
import '../../graph/domain/legal_graph_edge.dart';
import '../../graph/domain/legal_graph_node_type.dart';
import '../../graph/service/doctrine_relationship_service.dart';
import '../../graph/service/legal_graph_traversal_service.dart';
import '../../graph/service/precedent_graph_service.dart';
import '../../intelligence/domain/intelligence_enums.dart';
import '../../rendering/evidence_entry.dart';
import '../../search/service/case_search_engine.dart';
import '../domain/case_explanation.dart';
import '../domain/explanation_enums.dart';
import '../domain/explanation_section.dart';

/// Builds evidence-backed case explanations by deterministically composing
/// existing validated P3–P10 data. No legal research is performed.
@immutable
class CaseExplanationService {
  /// The full validated corpus this service reads from.
  final List<CaseKnowledgeObject> cases;

  /// The P5 legal graph snapshot (never modified).
  final LegalGraph graph;

  /// P6 search engine used for canonical case resolution.
  final CaseSearchEngine searchEngine;

  /// P5 precedent-graph service (case → case edges).
  final PrecedentGraphService precedentService;

  /// P5 doctrine-relationship service (case ↔ doctrine edges).
  final DoctrineRelationshipService doctrineService;

  /// P5 traversal service (chains, paths).
  final LegalGraphTraversalService traversalService;

  /// P9 related-case discovery service.
  final CaseDiscoveryService discoveryService;

  /// P10 cross-case analysis service.
  final CrossCaseAnalysisService analysisService;

  /// Builds a service over the shared corpus/services. All dependencies are
  /// optional and default to the canonical offline corpus, so the default
  /// constructor is deterministic and offline-first.
  factory CaseExplanationService({
    List<CaseKnowledgeObject>? cases,
    LegalGraph? graph,
    CaseSearchEngine? searchEngine,
    PrecedentGraphService? precedentService,
    DoctrineRelationshipService? doctrineService,
    LegalGraphTraversalService? traversalService,
    CaseDiscoveryService? discoveryService,
    CrossCaseAnalysisService? analysisService,
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
    final an = analysisService ??
        CrossCaseAnalysisService(
          cases: corpus,
          graph: g,
          searchEngine: se,
          precedentService: ps,
          doctrineService: ds,
          traversalService: ts,
          discoveryService: dd,
        );
    return CaseExplanationService._(
      cases: List<CaseKnowledgeObject>.unmodifiable(corpus),
      graph: g,
      searchEngine: se,
      precedentService: ps,
      doctrineService: ds,
      traversalService: ts,
      discoveryService: dd,
      analysisService: an,
    );
  }

  const CaseExplanationService._({
    required this.cases,
    required this.graph,
    required this.searchEngine,
    required this.precedentService,
    required this.doctrineService,
    required this.traversalService,
    required this.discoveryService,
    required this.analysisService,
  });

  // -------------------------------------------------------------------------
  // Convenience accessors
  // -------------------------------------------------------------------------

  /// Canonical IDs of every case in the corpus.
  Set<String> get caseIds => searchEngine.indexedCaseIds;

  /// Whether [idOrName] resolves to a corpus case (canonical ID or name).
  bool hasCase(String idOrName) => _resolveCaseId(idOrName) != null;

  /// Canonical corpus case IDs referenced by [explanation], including the
  /// explained case itself, sorted and de-duplicated.
  ///
  /// Statement references also carry non-case identifiers (doctrine IDs, edge
  /// IDs, holding IDs, evidence IDs, article keys); only identifiers that
  /// resolve to a validated corpus case are returned here, so the result never
  /// fabricates a case ID.
  List<String> referencedCaseIds(CaseExplanation explanation) {
    final corpus = {for (final c in cases) c.caseId};
    final self = explanation.caseId;
    final out = <String>[self];
    final seen = <String>{self};
    for (final id in explanation.referencedIds) {
      if (id != self && corpus.contains(id) && seen.add(id)) out.add(id);
    }
    out.sort();
    return List.unmodifiable(out);
  }

  /// The canonical corpus case IDs referenced by [explanation] that are not the
  /// explained case itself, sorted. Empty when the explanation references no
  /// other corpus case.
  List<String> otherCaseIds(CaseExplanation explanation) =>
      referencedCaseIds(explanation)
          .where((id) => id != explanation.caseId)
          .toList(growable: false);

  /// Resolves [idOrName] to a canonical corpus case ID, or null when unknown.
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

  String _caseName(String caseId) =>
      graph.nodeFor(caseId, LegalGraphNodeType.caseLaw)?.name ??
      _caseById(caseId)?.caseName ??
      caseId;

  String _date(DateTime d) => d.toIso8601String().split('T').first;

  String? _nonEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Builds the evidence-backed explanation for one canonical case, or null
  /// when [idOrName] does not resolve to a corpus case.
  CaseExplanation? explain(String idOrName) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return null;
    final c = _caseById(id)!;
    final sections = <ExplanationSection?>[
      _identitySection(c),
      _overviewSection(c),
      _issuesSection(c),
      _holdingsSection(c),
      _reasoningSection(c),
      _outcomeSection(c),
      _significanceSection(c),
      _doctrinesSection(id),
      _articlesSection(c),
      _actsSection(c),
      _relatedCasesSection(id),
      _precedentContextSection(id),
      _crossCaseContextSection(id, c),
      _upscSection(c),
      _evidenceSection(c),
    ].whereType<ExplanationSection>().toList(growable: false);
    return CaseExplanation(
      caseId: id,
      caseName: c.caseName,
      sections: List.unmodifiable(sections),
    );
  }

  /// Builds explanations for the entire corpus, in canonical corpus order.
  /// Every resolved corpus case produces an explanation.
  List<CaseExplanation> explainAll() =>
      [for (final c in cases) explain(c.caseId)!];

  // -------------------------------------------------------------------------
  // Section builders — every builder returns null when no validated evidence
  // exists for that section (missing data is an absent section).
  // -------------------------------------------------------------------------

  ExplanationSection? _identitySection(CaseKnowledgeObject c) {
    final id = c.caseId;
    final stmts = <ExplanationStatement>[
      _stmt('Case ID', id, [id], 'corpus:caseId'),
      _stmt('Case name', c.caseName, [id], 'corpus:caseName'),
      if (_nonEmpty(c.citation) case final String t)
        _stmt('Citation', t, [id], 'corpus:citation'),
      if (_nonEmpty(c.neutralCitation) case final String t)
        _stmt('Neutral citation', t, [id], 'corpus:neutralCitation'),
      if (_nonEmpty(c.reporterCitation) case final String t)
        _stmt('Reporter citation', t, [id], 'corpus:reporterCitation'),
      _stmt('Year', '${c.year}', [id], 'corpus:year'),
      if (_nonEmpty(c.court) case final String t)
        _stmt('Court', t, [id], 'corpus:court'),
      if (_nonEmpty(c.bench) case final String t)
        _stmt('Bench', t, [id], 'corpus:bench'),
      _stmt(
          'Judgment date', _date(c.judgmentDate), [id], 'corpus:judgmentDate'),
      if (c.caseType != null)
        _stmt('Case type', c.caseType!.displayName, [id], 'corpus:caseType'),
      _stmt('Status', c.status.name, [id], 'corpus:status'),
      if (_nonEmpty(c.presentStatus) case final String t)
        _stmt('Present status', t, [id], 'corpus:presentStatus'),
      if (_nonEmpty(c.objectId) case final String t)
        _stmt('Object ID', t, [id], 'corpus:objectId'),
    ];
    return ExplanationSection(
      type: ExplanationSectionType.identity,
      title: ExplanationSectionType.identity.displayTitle,
      statements: stmts,
    );
  }

  ExplanationSection? _overviewSection(CaseKnowledgeObject c) {
    final id = c.caseId;
    final stmts = <ExplanationStatement>[
      if (_nonEmpty(c.oneLineSummary) case final String t)
        _stmt('One-line summary', t, [id], 'corpus:oneLineSummary'),
      if (_nonEmpty(c.facts) case final String t)
        _stmt('Facts', t, [id], 'corpus:facts'),
      if (_nonEmpty(c.historicalContext) case final String t)
        _stmt('Historical context', t, [id], 'corpus:historicalContext'),
      if (_nonEmpty(c.detailedSummary) case final String t)
        _stmt('Detailed summary', t, [id], 'corpus:detailedSummary'),
    ];
    return stmts.isEmpty
        ? null
        : ExplanationSection(
            type: ExplanationSectionType.overview,
            title: ExplanationSectionType.overview.displayTitle,
            statements: stmts,
          );
  }

  ExplanationSection? _issuesSection(CaseKnowledgeObject c) {
    final id = c.caseId;
    final intel = c.judgmentIntelligence;
    final stmts = <ExplanationStatement>[];
    if (intel != null && intel.issues.isNotEmpty) {
      for (var i = 0; i < intel.issues.length; i++) {
        final issue = intel.issues[i];
        stmts.add(_stmt(
            'Issue ${i + 1}', issue.issue, [id, issue.issueId], 'p4:issues'));
      }
    } else if (c.issues.isNotEmpty) {
      for (var i = 0; i < c.issues.length; i++) {
        stmts.add(_stmt('Issue ${i + 1}', c.issues[i], [id], 'corpus:issues'));
      }
    }
    return stmts.isEmpty
        ? null
        : ExplanationSection(
            type: ExplanationSectionType.issues,
            title: ExplanationSectionType.issues.displayTitle,
            statements: stmts,
          );
  }

  ExplanationSection? _holdingsSection(CaseKnowledgeObject c) {
    final id = c.caseId;
    final intel = c.judgmentIntelligence;
    if (intel == null || intel.holdings.isEmpty) return null;
    final stmts = <ExplanationStatement>[];
    for (var i = 0; i < intel.holdings.length; i++) {
      final h = intel.holdings[i];
      final refs = <String>[id, h.holdingId];
      if (h.evidence.evidenceId.isNotEmpty) refs.add(h.evidence.evidenceId);
      final text = h.legalPrinciple.isNotEmpty
          ? '${h.holding}\n\nLegal principle: ${h.legalPrinciple}'
          : h.holding;
      stmts.add(_stmt('Holding ${i + 1}', text, refs, 'p4:holdings'));
    }
    return ExplanationSection(
      type: ExplanationSectionType.holdings,
      title: ExplanationSectionType.holdings.displayTitle,
      statements: stmts,
    );
  }

  ExplanationSection? _reasoningSection(CaseKnowledgeObject c) {
    final id = c.caseId;
    final r = c.judgmentIntelligence?.reasoning;
    if (r == null) return null;
    final stmts = <ExplanationStatement>[
      if (_nonEmpty(r.summary) case final String t)
        _stmt('Summary', t, [id], 'p4:reasoning.summary'),
      if (r.approach != InterpretiveApproach.other)
        _stmt('Interpretive approach', r.approach.name, [id],
            'p4:reasoning.approach'),
      for (final p in r.constitutionalPhilosophy)
        if (p.trim().isNotEmpty)
          _stmt('Constitutional philosophy', p, [id],
              'p4:reasoning.constitutionalPhilosophy'),
      for (final d in r.doctrinalReasoning)
        if (d.trim().isNotEmpty)
          _stmt('Doctrinal reasoning', d, [id],
              'p4:reasoning.doctrinalReasoning'),
      for (final t in r.reasoningTools)
        if (t.trim().isNotEmpty)
          _stmt('Reasoning tool', t, [id], 'p4:reasoning.reasoningTools'),
    ];
    return stmts.isEmpty
        ? null
        : ExplanationSection(
            type: ExplanationSectionType.reasoning,
            title: ExplanationSectionType.reasoning.displayTitle,
            statements: stmts,
          );
  }

  ExplanationSection? _outcomeSection(CaseKnowledgeObject c) {
    final id = c.caseId;
    final o = c.judgmentIntelligence?.outcome;
    if (o == null) {
      final decision = _nonEmpty(c.decision);
      if (decision == null) return null;
      return ExplanationSection(
        type: ExplanationSectionType.outcome,
        title: ExplanationSectionType.outcome.displayTitle,
        statements: [
          _stmt('Decision', decision, [id], 'corpus:decision')
        ],
      );
    }
    final stmts = <ExplanationStatement>[
      _stmt('Disposition', o.disposition.name, [id], 'p4:outcome.disposition'),
      if (_nonEmpty(o.operativeResult) case final String t)
        _stmt('Operative result', t, [id], 'p4:outcome.operativeResult'),
      if (_nonEmpty(o.majorityOutcome) case final String t)
        _stmt('Majority outcome', t, [id], 'p4:outcome.majorityOutcome'),
      if (o.minorityOutcome case final String t when t.trim().isNotEmpty)
        _stmt('Minority outcome', t, [id], 'p4:outcome.minorityOutcome'),
      for (final r in o.reliefGranted)
        if (r.trim().isNotEmpty)
          _stmt('Relief granted', r, [id], 'p4:outcome.reliefGranted'),
      for (final r in o.reliefDenied)
        if (r.trim().isNotEmpty)
          _stmt('Relief denied', r, [id], 'p4:outcome.reliefDenied'),
    ];
    return stmts.isEmpty
        ? null
        : ExplanationSection(
            type: ExplanationSectionType.outcome,
            title: ExplanationSectionType.outcome.displayTitle,
            statements: stmts,
          );
  }

  ExplanationSection? _significanceSection(CaseKnowledgeObject c) {
    final id = c.caseId;
    final sig = c.judgmentIntelligence?.judicialSignificance;
    final stmts = <ExplanationStatement>[];
    final p4Constitutional = _nonEmpty(sig?.constitutionalSignificance ?? '');
    if (p4Constitutional != null) {
      stmts.add(_stmt('Constitutional significance', p4Constitutional, [id],
          'p4:judicialSignificance'));
    } else if (_nonEmpty(c.constitutionalSignificance) case final String t) {
      stmts.add(_stmt('Constitutional significance', t, [id],
          'corpus:constitutionalSignificance'));
    }
    if (_nonEmpty(sig?.legalSignificance ?? '') case final String t) {
      stmts
          .add(_stmt('Legal significance', t, [id], 'p4:judicialSignificance'));
    }
    if (_nonEmpty(sig?.historicalSignificance ?? '') case final String t) {
      stmts.add(
          _stmt('Historical significance', t, [id], 'p4:judicialSignificance'));
    }
    if (sig != null && sig.significanceScore > 0) {
      stmts.add(_stmt('Significance score', '${sig.significanceScore}', [id],
          'p4:judicialSignificance'));
    }
    return stmts.isEmpty
        ? null
        : ExplanationSection(
            type: ExplanationSectionType.legalSignificance,
            title: ExplanationSectionType.legalSignificance.displayTitle,
            statements: stmts,
          );
  }

  ExplanationSection? _doctrinesSection(String id) {
    final edges =
        List<DoctrineGraphEdge>.of(doctrineService.getDoctrinesForCase(id))
          ..sort(_byDoctrineTarget);
    if (edges.isEmpty) return null;
    final stmts = <ExplanationStatement>[
      for (final e in edges)
        _stmt(
          'Doctrine: ${doctrineService.doctrineNode(e.targetId)?.name ?? e.targetId}',
          '${e.type.displayName} (${e.type.name})',
          [id, e.targetId, e.edgeId],
          e.provenance,
        ),
    ];
    return ExplanationSection(
      type: ExplanationSectionType.doctrines,
      title: ExplanationSectionType.doctrines.displayTitle,
      statements: stmts,
    );
  }

  ExplanationSection? _articlesSection(CaseKnowledgeObject c) {
    if (c.relatedArticles.isEmpty) return null;
    final stmts = <ExplanationStatement>[
      for (final ref in c.relatedArticles)
        if (ref.trim().isNotEmpty)
          _stmt('Article', ref, [c.caseId], 'corpus:relatedArticles'),
    ];
    return stmts.isEmpty
        ? null
        : ExplanationSection(
            type: ExplanationSectionType.articles,
            title: ExplanationSectionType.articles.displayTitle,
            statements: stmts,
          );
  }

  ExplanationSection? _actsSection(CaseKnowledgeObject c) {
    if (c.relatedActs.isEmpty) return null;
    final stmts = <ExplanationStatement>[
      for (final ref in c.relatedActs)
        if (ref.trim().isNotEmpty)
          _stmt('Act', ref, [c.caseId], 'corpus:relatedActs'),
    ];
    return stmts.isEmpty
        ? null
        : ExplanationSection(
            type: ExplanationSectionType.acts,
            title: ExplanationSectionType.acts.displayTitle,
            statements: stmts,
          );
  }

  ExplanationSection? _relatedCasesSection(String id) {
    final results = discoveryService.discoverRelatedCases(id);
    if (results.isEmpty) return null;
    final stmts = <ExplanationStatement>[
      for (final r in results)
        _relatedCaseStatement(id, r.caseId, r.caseName, r.year, r.reasons),
    ];
    return ExplanationSection(
      type: ExplanationSectionType.relatedCases,
      title: ExplanationSectionType.relatedCases.displayTitle,
      statements: stmts,
    );
  }

  ExplanationStatement _relatedCaseStatement(String sourceId, String caseId,
      String caseName, int year, List<DiscoveryReason> reasons) {
    final reasonLabels = reasons.map((x) => x.label).join('; ');
    final refs = <String>{sourceId, caseId};
    final provenances = <String>{};
    for (final r in reasons) {
      refs.addAll(r.references);
      if (r.provenance.trim().isNotEmpty) provenances.add(r.provenance.trim());
    }
    final text = reasonLabels.isEmpty
        ? '$caseName ($year)'
        : '$caseName ($year) — $reasonLabels';
    final sortedRefs = refs.toList()..sort();
    final sortedProv = provenances.toList()..sort();
    return _stmt('Related case', text, sortedRefs, sortedProv.join(';'));
  }

  ExplanationSection? _precedentContextSection(String id) {
    final outgoing =
        List<PrecedentGraphEdge>.of(precedentService.outgoingRelationships(id))
          ..sort(_byTypeThenTarget);
    final incoming =
        List<PrecedentGraphEdge>.of(precedentService.incomingRelationships(id))
          ..sort(_byTypeThenSource);
    if (outgoing.isEmpty && incoming.isEmpty) return null;
    final stmts = <ExplanationStatement>[
      for (final e in outgoing)
        _stmt(
          '${e.typeLabel} (outgoing)',
          '${_caseName(e.targetId)} (${e.targetId})',
          [id, e.edgeId, e.targetId],
          e.provenance,
        ),
      for (final e in incoming)
        _stmt(
          '${e.typeLabel} (incoming)',
          '${_caseName(e.sourceId)} (${e.sourceId})',
          [id, e.edgeId, e.sourceId],
          e.provenance,
        ),
    ];
    return ExplanationSection(
      type: ExplanationSectionType.precedentContext,
      title: ExplanationSectionType.precedentContext.displayTitle,
      statements: stmts,
    );
  }

  ExplanationSection? _crossCaseContextSection(
      String id, CaseKnowledgeObject c) {
    final relatedIds = [
      for (final r in discoveryService.discoverRelatedCases(id)) r.caseId,
    ];
    final stmts = <ExplanationStatement>[];

    // 1. Chronological position among the case + its related cases (P10).
    if (relatedIds.isNotEmpty) {
      final chrono =
          analysisService.chronologicalAnalysis(<String>[id, ...relatedIds]);
      final pos = chrono.positionOf(id);
      final earliest = chrono.earliest;
      final latest = chrono.latest;
      if (pos != null && earliest != null && latest != null) {
        stmts.add(_stmt(
          'Chronological position',
          'Among ${chrono.entries.length} compared case(s), ${c.caseName} '
              '(${c.year}) is at chronological position $pos (0-based; '
              'earliest ${earliest.caseId} (${earliest.year}), '
              'latest ${latest.caseId} (${latest.year})).',
          _sorted([id, ...relatedIds]),
          'p10:chronology',
        ));
      }
    }

    // 2. Precedent-chain context (P10), predecessor and successor. A chain is
    //    presented only when it has real hops (`length > 0`); the anchor-only
    //    chain P10 returns for a disconnected case carries no relationship and
    //    would present the case as related to itself.
    final pred = analysisService.precedentChainAnalysis(id,
        direction: PrecedentChainDirection.predecessor);
    if (pred != null && pred.length > 0) {
      stmts.add(_stmt(
        'Predecessor chain',
        pred.entries.map((e) => '${e.caseId} (${e.year})').join(' → '),
        _sorted([id, ...pred.entries.map((e) => e.caseId)]),
        'p10:precedentChain',
      ));
    }
    final succ = analysisService.precedentChainAnalysis(id,
        direction: PrecedentChainDirection.successor);
    if (succ != null && succ.length > 0) {
      stmts.add(_stmt(
        'Successor chain',
        succ.entries.map((e) => '${e.caseId} (${e.year})').join(' → '),
        _sorted([id, ...succ.entries.map((e) => e.caseId)]),
        'p10:precedentChain',
      ));
    }

    // 3. Comparison over the case + its related cases (P10): shared
    //    attributes and non-redundant structural observations. Raw graph edges
    //    (already in Precedent Context), the chronology order marker and the
    //    negative "no shared attributes" marker are deliberately excluded.
    if (relatedIds.isNotEmpty) {
      final cmp = analysisService.compareCases(<String>[id, ...relatedIds]);
      for (final s in cmp.sharedAttributes) {
        stmts.add(_stmt(
          'Shared ${s.kind.name}: ${s.displayValue}',
          'Present in: ${s.caseIds.join(', ')}',
          _sorted([id, ...s.caseIds]),
          s.provenance,
        ));
      }
      for (final o in cmp.observations) {
        if (o.type == StructuralObservationType.graphRelationship ||
            o.type == StructuralObservationType.noSharedAttributes ||
            o.type == StructuralObservationType.chronologicalOrder) {
          continue;
        }
        stmts.add(_stmt(
          'Observation: ${o.type.name}',
          o.label,
          o.references,
          o.provenance,
        ));
      }
    }

    // 4. Doctrine-analysis context (P10): other validated cases engaging the
    //    same doctrines, with their P5 roles.
    final doctrineEdges =
        List<DoctrineGraphEdge>.of(doctrineService.getDoctrinesForCase(id))
          ..sort(_byDoctrineTarget);
    for (final de in doctrineEdges) {
      final result = analysisService.doctrineAnalysis(de.targetId);
      final others = result.cases
          .where((m) => m.caseId != id && _caseById(m.caseId) != null)
          .toList();
      if (others.isEmpty) continue;
      final name =
          doctrineService.doctrineNode(de.targetId)?.name ?? de.targetId;
      stmts.addAll([
        for (final m in others)
          _stmt(
            'Doctrine $name — also engaged',
            '${m.caseName} (${m.year}) — ${m.roleLabel}',
            _sorted([id, de.targetId, m.caseId, m.edgeId]),
            m.provenance,
          ),
      ]);
    }

    if (stmts.isEmpty) return null;
    return ExplanationSection(
      type: ExplanationSectionType.crossCaseContext,
      title: ExplanationSectionType.crossCaseContext.displayTitle,
      statements: stmts,
    );
  }

  ExplanationSection? _upscSection(CaseKnowledgeObject c) {
    final id = c.caseId;
    final u = c.judgmentIntelligence?.upscIntelligence;
    final stmts = <ExplanationStatement>[
      _stmt('Prelims relevance', c.prelimsRelevance.name, [id],
          'corpus:prelimsRelevance'),
      _stmt('Mains relevance', c.mainsRelevance.name, [id],
          'corpus:mainsRelevance'),
      if (_nonEmpty(c.examImportance) case final String t)
        _stmt('Exam importance', t, [id], 'corpus:examImportance'),
      if (_nonEmpty(c.trend) case final String t)
        _stmt('Trend', t, [id], 'corpus:trend'),
      if (c.timesAsked > 0)
        _stmt('Times asked', '${c.timesAsked}', [id], 'corpus:timesAsked'),
      if (c.lastAskedYear > 0)
        _stmt('Last asked year', '${c.lastAskedYear}', [id],
            'corpus:lastAskedYear'),
      for (final t in c.themes)
        if (t.trim().isNotEmpty) _stmt('Theme', t, [id], 'corpus:themes'),
      for (final s in c.subjects)
        if (s.trim().isNotEmpty) _stmt('Subject', s, [id], 'corpus:subjects'),
      for (final t in c.prelimsTraps)
        if (t.trim().isNotEmpty)
          _stmt('Prelims trap', t, [id], 'corpus:prelimsTraps'),
      for (final t in c.mainsThemes)
        if (t.trim().isNotEmpty)
          _stmt('Mains theme', t, [id], 'corpus:mainsThemes'),
      for (final a in c.interviewAngles)
        if (a.trim().isNotEmpty)
          _stmt('Interview angle', a, [id], 'corpus:interviewAngles'),
      for (final f in c.frequentlyConfusedCases)
        if (f.trim().isNotEmpty)
          _stmt('Frequently confused case', f, [id],
              'corpus:frequentlyConfusedCases'),
      if (u != null) ...[
        for (final f in u.prelimsFacts)
          if (f.trim().isNotEmpty)
            _stmt('Prelims fact', f, [id], 'p4:upscIntelligence'),
        for (final t in u.prelimsTraps)
          if (t.trim().isNotEmpty)
            _stmt('Prelims trap', t, [id], 'p4:upscIntelligence'),
        for (final t in u.mainsThemes)
          if (t.trim().isNotEmpty)
            _stmt('Mains theme', t, [id], 'p4:upscIntelligence'),
        for (final k in u.answerKeywords)
          if (k.trim().isNotEmpty)
            _stmt('Answer keyword', k, [id], 'p4:upscIntelligence'),
        for (final t in u.essayThemes)
          if (t.trim().isNotEmpty)
            _stmt('Essay theme', t, [id], 'p4:upscIntelligence'),
        for (final a in u.interviewAreas)
          if (a.trim().isNotEmpty)
            _stmt('Interview area', a, [id], 'p4:upscIntelligence'),
        for (final t in u.contemporaryRelevance)
          if (t.trim().isNotEmpty)
            _stmt('Contemporary relevance', t, [id], 'p4:upscIntelligence'),
        for (final s in u.relatedSyllabusAreas)
          _stmt('Syllabus area', s.displayName, [id], 'p4:upscIntelligence'),
      ],
    ];
    return stmts.isEmpty
        ? null
        : ExplanationSection(
            type: ExplanationSectionType.upscRelevance,
            title: ExplanationSectionType.upscRelevance.displayTitle,
            statements: stmts,
          );
  }

  ExplanationSection? _evidenceSection(CaseKnowledgeObject c) {
    final id = c.caseId;
    final stmts = <ExplanationStatement>[
      if (_nonEmpty(c.officialSource) case final String t)
        _stmt('Official source', t, [id], 'corpus:officialSource'),
      if (_nonEmpty(c.primarySource) case final String t)
        _stmt('Primary source', t, [id], 'corpus:primarySource'),
      if (_nonEmpty(c.lastVerifiedDate) case final String t)
        _stmt('Last verified', t, [id], 'corpus:lastVerifiedDate'),
      for (final ev in c.evidenceIds)
        if (ev.trim().isNotEmpty)
          _stmt('Evidence', _evidenceLabel(ev), [id, ev], 'corpus:evidenceIds'),
      for (final cit in c.citations)
        if (cit.trim().isNotEmpty)
          _stmt('Recorded citation', cit, [id], 'corpus:citations'),
      for (final ref in c.evidenceReferences)
        if (ref.trim().isNotEmpty)
          _stmt('Evidence reference', ref, [id], 'corpus:evidenceReferences'),
    ];
    return stmts.isEmpty
        ? null
        : ExplanationSection(
            type: ExplanationSectionType.evidence,
            title: ExplanationSectionType.evidence.displayTitle,
            statements: stmts,
          );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Presents one evidence ID through the P8 [EvidenceEntry] registry
  /// resolution — the same predicate P7 uses. Nothing is guessed.
  String _evidenceLabel(String evidenceId) {
    final entry = EvidenceEntry.fromId(evidenceId);
    if (entry.typeLabel.isEmpty) {
      return entry.verified
          ? 'registered (verified)'
          : 'registered (unresolved)';
    }
    return '${entry.typeLabel} — ${entry.verified ? 'verified' : 'registered (unresolved)'}';
  }

  ExplanationStatement _stmt(
          String label, String text, List<String> refs, String provenance) =>
      ExplanationStatement(
        label: label,
        text: text,
        sourceRefs: refs,
        provenance: provenance,
      );

  /// Sorts and de-duplicates canonical references for deterministic output.
  List<String> _sorted(Iterable<String> refs) {
    final seen = <String>{};
    final out = <String>[];
    for (final r in refs) {
      if (r.isNotEmpty && seen.add(r)) out.add(r);
    }
    out.sort();
    return out;
  }

  int _byDoctrineTarget(DoctrineGraphEdge a, DoctrineGraphEdge b) =>
      a.targetId.compareTo(b.targetId);

  int _byTypeThenTarget(PrecedentGraphEdge a, PrecedentGraphEdge b) {
    final t = a.typeLabel.compareTo(b.typeLabel);
    return t != 0 ? t : a.targetId.compareTo(b.targetId);
  }

  int _byTypeThenSource(PrecedentGraphEdge a, PrecedentGraphEdge b) {
    final t = a.typeLabel.compareTo(b.typeLabel);
    return t != 0 ? t : a.sourceId.compareTo(b.sourceId);
  }
}
