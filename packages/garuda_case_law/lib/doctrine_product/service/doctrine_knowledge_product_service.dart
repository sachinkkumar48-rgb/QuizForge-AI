/// P12 Evidence-Backed Doctrine Knowledge Product service (TITAN-KO-015.0 P12).
///
/// A deterministic, offline-first knowledge-product composition layer that
/// transforms existing validated GARUDA Case Law + Doctrine evidence into a
/// structured, doctrine-level, provenance-preserving
/// [DoctrineKnowledgeProduct].
///
/// P12 is NOT a legal reasoning engine. It never invents doctrine development,
/// precedent, citation, current-law status or legal conclusions. Every statement
/// in every section is composed from existing validated P3–P11 source data:
///
/// - **Doctrine identity / overview** — the canonical `garuda_doctrine` record,
///   verbatim, field by field.
/// - **Constituent cases / precedent relationships / chronology / structural
///   observations** — P10 `CrossCaseAnalysisService.doctrineAnalysis`, which
///   reads the P5 case → doctrine and case → case edges verbatim.
/// - **Articles / Acts / UPSC / evidence** — the P3 corpus records of the
///   constituent cases, plus the P8 `EvidenceEntry` registry resolution.
/// - **Related doctrine context** — only a deterministic *structural* overlap
///   (shared constituent case), explicitly marked non-legal; never a "related
///   doctrine" or legal-similarity claim.
/// - **Case-level knowledge** — one P11 [CaseExplanation] per constituent case,
///   reused directly (never re-implemented).
///
/// Source hierarchy (documented in `P12_DOCTRINE_KNOWLEDGE_PRODUCT.md`):
/// canonical `garuda_doctrine` record → P5 graph edges → P3 corpus fields →
/// P4 intelligence → P6 canonical resolution → P9 discovery → P10 doctrine
/// analysis → P11 case explanations.
///
/// Missing data is represented by an omitted section, never by fabricated
/// content. Output is deterministic: identical corpus + identical services
/// produce byte-identical structured output, in the fixed section order, with
/// sorted references and sorted statements.
library;

import 'package:garuda_doctrine/garuda_doctrine.dart'
    show
        DoctrineCategory,
        DoctrineKnowledgeObject,
        DoctrineSeedData,
        DoctrineStatus;
import 'package:meta/meta.dart';

import '../../analysis/domain/doctrine_analysis.dart';
import '../../analysis/service/cross_case_analysis_service.dart';
import '../../data/case_seed_data.dart';
import '../../discovery/service/case_discovery_service.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../../explanation/domain/case_explanation.dart';
import '../../explanation/service/case_explanation_service.dart';
import '../../graph/data/legal_graph_seed.dart';
import '../../graph/domain/legal_graph.dart';
import '../../graph/service/doctrine_relationship_service.dart';
import '../../graph/service/legal_graph_traversal_service.dart';
import '../../graph/service/precedent_graph_service.dart';
import '../../rendering/evidence_entry.dart';
import '../../search/data/case_search_normalizer.dart';
import '../../search/service/case_search_engine.dart';
import '../domain/doctrine_knowledge_product.dart';
import '../domain/doctrine_product_enums.dart';
import '../domain/doctrine_product_section.dart';

/// Builds evidence-backed doctrine knowledge products by deterministically
/// composing existing validated P3–P11 data. No legal research is performed.
@immutable
class DoctrineKnowledgeProductService {
  /// The full validated corpus this service reads from.
  final List<CaseKnowledgeObject> cases;

  /// The canonical `garuda_doctrine` records.
  final List<DoctrineKnowledgeObject> doctrines;

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

  /// P10 cross-case analysis service (doctrine analysis).
  final CrossCaseAnalysisService analysisService;

  /// P11 case-explanation service (per constituent case).
  final CaseExplanationService explanationService;

  /// doctrineId → constituent case IDs (sorted), derived once from the P5 graph.
  /// Used only for the deterministic structural shared-constituent-case overlap.
  final Map<String, List<String>> doctrineMemberIds;

  /// Builds a service over the shared corpus/services. All inputs are optional
  /// and default to the canonical offline corpus, so the default constructor is
  /// deterministic and offline-first.
  factory DoctrineKnowledgeProductService({
    List<CaseKnowledgeObject>? cases,
    List<DoctrineKnowledgeObject>? doctrines,
    LegalGraph? graph,
    CaseSearchEngine? searchEngine,
    PrecedentGraphService? precedentService,
    DoctrineRelationshipService? doctrineService,
    LegalGraphTraversalService? traversalService,
    CaseDiscoveryService? discoveryService,
    CrossCaseAnalysisService? analysisService,
    CaseExplanationService? explanationService,
  }) {
    final corpus = cases ?? CaseSeedData.cases;
    final doctrineRecords = doctrines ?? DoctrineSeedData.doctrines;
    final g = graph ??
        LegalGraphSeed.fromCorpora(
          cases: corpus,
          doctrines: doctrineRecords,
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
    final ex = explanationService ??
        CaseExplanationService(
          cases: corpus,
          graph: g,
          searchEngine: se,
          precedentService: ps,
          doctrineService: ds,
          traversalService: ts,
          discoveryService: dd,
          analysisService: an,
        );
    final members = <String, List<String>>{};
    for (final node in ds.allDoctrines) {
      final ids = ds.getCasesForDoctrine(node.id).map((e) => e.sourceId).toSet()
        ..removeWhere((id) => !_corpusHas(corpus, id));
      final sorted = ids.toList()..sort();
      members[node.id] = List<String>.unmodifiable(sorted);
    }
    return DoctrineKnowledgeProductService._(
      cases: List<CaseKnowledgeObject>.unmodifiable(corpus),
      doctrines: List<DoctrineKnowledgeObject>.unmodifiable(doctrineRecords),
      graph: g,
      searchEngine: se,
      precedentService: ps,
      doctrineService: ds,
      traversalService: ts,
      discoveryService: dd,
      analysisService: an,
      explanationService: ex,
      doctrineMemberIds: Map<String, List<String>>.unmodifiable(members),
    );
  }

  const DoctrineKnowledgeProductService._({
    required this.cases,
    required this.doctrines,
    required this.graph,
    required this.searchEngine,
    required this.precedentService,
    required this.doctrineService,
    required this.traversalService,
    required this.discoveryService,
    required this.analysisService,
    required this.explanationService,
    required this.doctrineMemberIds,
  });

  static bool _corpusHas(List<CaseKnowledgeObject> corpus, String id) {
    for (final c in corpus) {
      if (c.caseId == id) return true;
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Convenience accessors
  // -------------------------------------------------------------------------

  /// Canonical doctrine IDs, in canonical `garuda_doctrine` record order.
  List<String> get doctrineIds => [for (final d in doctrines) d.doctrineId];

  /// Whether [idOrName] resolves to a canonical doctrine (ID or name).
  bool hasDoctrine(String idOrName) => resolveDoctrineId(idOrName) != null;

  /// Resolves [idOrName] to a canonical doctrine ID (by canonical ID, by
  /// normalized doctrine name, or by normalized ID), or null when unknown.
  ///
  /// Mirrors P10's doctrine resolution; no doctrine is ever fabricated.
  String? resolveDoctrineId(String idOrName) {
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

  /// Canonical corpus case IDs referenced by [product], including the
  /// doctrine's constituent cases, sorted and de-duplicated.
  ///
  /// Statement references also carry non-case identifiers (doctrine IDs, edge
  /// IDs, article keys, evidence IDs); only identifiers that resolve to a
  /// validated corpus case are returned here, so the result never fabricates a
  /// case ID.
  List<String> referencedCaseIds(DoctrineKnowledgeProduct product) {
    final corpus = {for (final c in cases) c.caseId};
    final out = <String>[];
    final seen = <String>{};
    for (final id in product.referencedIds) {
      if (corpus.contains(id) && seen.add(id)) out.add(id);
    }
    out.sort();
    return List.unmodifiable(out);
  }

  // -------------------------------------------------------------------------
  // Product building
  // -------------------------------------------------------------------------

  /// Builds the knowledge product for [doctrineIdOrName], or null when the
  /// doctrine does not resolve. Missing data is represented by an absent
  /// section — nothing is fabricated.
  DoctrineKnowledgeProduct? build(String doctrineIdOrName) {
    final id = resolveDoctrineId(doctrineIdOrName);
    if (id == null) return null;
    final record = _doctrineById(id);
    if (record == null) return null; // canonical record must resolve
    final analysis = analysisService.doctrineAnalysis(id);
    final sections = <DoctrineSection>[
      if (_identitySection(id, record) case final DoctrineSection s) s,
      if (_overviewSection(id, record) case final DoctrineSection s) s,
      if (_constituentCasesSection(id, analysis) case final DoctrineSection s)
        s,
      if (_articlesSection(id, analysis.cases) case final DoctrineSection s) s,
      if (_actsSection(id, analysis.cases) case final DoctrineSection s) s,
      if (_precedentRelationshipsSection(analysis) case final DoctrineSection s)
        s,
      if (_chronologySection(id, analysis) case final DoctrineSection s) s,
      if (_structuralObservationsSection(id, analysis)
          case final DoctrineSection s)
        s,
      if (_upscRelevanceSection(id, analysis.cases)
          case final DoctrineSection s)
        s,
      if (_evidenceSection(id, record, analysis.cases)
          case final DoctrineSection s)
        s,
    ];
    return DoctrineKnowledgeProduct(
      doctrineId: id,
      doctrineName: record.name,
      sections: List<DoctrineSection>.unmodifiable(sections),
      caseExplanations: _explanationsFor(analysis.cases),
    );
  }

  /// Builds the knowledge product for every canonical doctrine, in canonical
  /// record order. Every resolved doctrine produces a product.
  List<DoctrineKnowledgeProduct> buildAll() =>
      [for (final id in doctrineIds) build(id)!];

  /// One P11 [CaseExplanation] per constituent case, in the same chronological
  /// order as the constituent-case analysis. Reuses P11 directly.
  List<CaseExplanation> _explanationsFor(List<DoctrineCaseEntry> entries) {
    final out = <CaseExplanation>[];
    for (final e in entries) {
      final ex = explanationService.explain(e.caseId);
      if (ex != null) out.add(ex);
    }
    return List<CaseExplanation>.unmodifiable(out);
  }

  // -------------------------------------------------------------------------
  // Section builders — every builder returns null when no validated evidence
  // exists for that section (missing data is an absent section).
  // -------------------------------------------------------------------------

  DoctrineSection? _identitySection(String id, DoctrineKnowledgeObject d) {
    final stmts = <DoctrineStatement>[
      _stmt('Doctrine ID', id, [id], 'doctrine:$id.doctrineId'),
      _stmt('Doctrine name', d.name, [id], 'doctrine:$id.name'),
      if (_nonEmpty(d.origin))
        _stmt('Origin', d.origin, [id], 'doctrine:$id.origin'),
      _stmt('Category', d.category.displayName, [id], 'doctrine:$id.category'),
      _stmt('Current status', d.currentStatus.displayName, [id],
          'doctrine:$id.currentStatus'),
      if (d.aliases.isNotEmpty)
        _stmt('Aliases', d.aliases.join(', '), [id], 'doctrine:$id.aliases'),
    ];
    return stmts.isEmpty
        ? null
        : DoctrineSection(
            type: DoctrineSectionType.identity,
            title: DoctrineSectionType.identity.displayTitle,
            statements: stmts,
          );
  }

  DoctrineSection? _overviewSection(String id, DoctrineKnowledgeObject d) {
    final stmts = <DoctrineStatement>[
      if (_nonEmpty(d.officialDefinition))
        _stmt('Official definition', d.officialDefinition, [id],
            'doctrine:$id.officialDefinition'),
      if (_nonEmpty(d.plainLanguageExplanation))
        _stmt('Plain-language explanation', d.plainLanguageExplanation, [id],
            'doctrine:$id.plainLanguageExplanation'),
      if (_nonEmpty(d.oneLineSummary))
        _stmt('One-line summary', d.oneLineSummary, [id],
            'doctrine:$id.oneLineSummary'),
      if (_nonEmpty(d.purpose))
        _stmt('Purpose', d.purpose, [id], 'doctrine:$id.purpose'),
      if (_nonEmpty(d.scope))
        _stmt('Scope', d.scope, [id], 'doctrine:$id.scope'),
      if (_nonEmpty(d.detailedExplanation))
        _stmt('Detailed explanation', d.detailedExplanation, [id],
            'doctrine:$id.detailedExplanation'),
      if (_nonEmpty(d.garudaExplanation))
        _stmt('Garuda explanation', d.garudaExplanation, [id],
            'doctrine:$id.garudaExplanation'),
      if (_nonEmpty(d.currentPosition))
        _stmt('Recorded current position', d.currentPosition, [id],
            'doctrine:$id.currentPosition'),
    ];
    return stmts.isEmpty
        ? null
        : DoctrineSection(
            type: DoctrineSectionType.overview,
            title: DoctrineSectionType.overview.displayTitle,
            statements: stmts,
          );
  }

  DoctrineSection? _constituentCasesSection(
      String doctrineId, DoctrineAnalysisResult analysis) {
    if (analysis.cases.isEmpty) return null;
    final stmts = <DoctrineStatement>[];
    for (var i = 0; i < analysis.cases.length; i++) {
      final e = analysis.cases[i];
      stmts.add(_stmt(
        'Constituent case ${i + 1}',
        '${e.caseName} (${e.year}) — ${e.roleLabel}',
        [e.caseId, e.edgeId, doctrineId],
        e.provenance,
      ));
    }
    return DoctrineSection(
      type: DoctrineSectionType.constituentCases,
      title: DoctrineSectionType.constituentCases.displayTitle,
      statements: stmts,
    );
  }

  DoctrineSection? _articlesSection(
      String doctrineId, List<DoctrineCaseEntry> entries) {
    if (entries.isEmpty) return null;
    final byKey = <String, List<String>>{};
    final casesByKey = <String, Set<String>>{};
    for (final e in entries) {
      for (final ref in e.caseObject.relatedArticles) {
        if (ref.trim().isEmpty) continue;
        final key = CaseSearchNormalizer.normalizeArticle(ref);
        final display = key.isEmpty ? ref.trim() : key;
        byKey.putIfAbsent(display, () => []).add(ref.trim());
        casesByKey.putIfAbsent(display, () => {}).add(e.caseId);
      }
    }
    if (byKey.isEmpty) return null;
    final keys = byKey.keys.toList()..sort();
    final stmts = <DoctrineStatement>[];
    for (final key in keys) {
      final refs = byKey[key]!.toSet().toList()..sort();
      final refCases = casesByKey[key]!.toList()..sort();
      stmts.add(_stmt(
        'Article $key',
        refs.join(', '),
        [doctrineId, ...refCases],
        'corpus:relatedArticles',
      ));
    }
    return DoctrineSection(
      type: DoctrineSectionType.articles,
      title: DoctrineSectionType.articles.displayTitle,
      statements: stmts,
    );
  }

  DoctrineSection? _actsSection(
      String doctrineId, List<DoctrineCaseEntry> entries) {
    if (entries.isEmpty) return null;
    final byKey = <String, List<String>>{};
    final casesByKey = <String, Set<String>>{};
    for (final e in entries) {
      for (final ref in e.caseObject.relatedActs) {
        if (ref.trim().isEmpty) continue;
        final key = CaseSearchNormalizer.normalizeText(ref);
        final display = key.isEmpty ? ref.trim() : ref.trim();
        byKey.putIfAbsent(display, () => []).add(ref.trim());
        casesByKey.putIfAbsent(display, () => {}).add(e.caseId);
      }
    }
    if (byKey.isEmpty) return null;
    final keys = byKey.keys.toList()..sort();
    final stmts = <DoctrineStatement>[];
    for (final key in keys) {
      final refs = byKey[key]!.toSet().toList()..sort();
      final refCases = casesByKey[key]!.toList()..sort();
      stmts.add(_stmt(
        'Act',
        refs.join(', '),
        [doctrineId, ...refCases],
        'corpus:relatedActs',
      ));
    }
    return DoctrineSection(
      type: DoctrineSectionType.acts,
      title: DoctrineSectionType.acts.displayTitle,
      statements: stmts,
    );
  }

  DoctrineSection? _precedentRelationshipsSection(
      DoctrineAnalysisResult analysis) {
    if (analysis.graphRelationships.isEmpty) return null;
    final stmts = <DoctrineStatement>[];
    for (final edge in analysis.graphRelationships) {
      final src = _caseById(edge.sourceId)?.caseName ?? edge.sourceId;
      final tgt = _caseById(edge.targetId)?.caseName ?? edge.targetId;
      stmts.add(_stmt(
        edge.typeLabel,
        '$src → $tgt (${edge.typeLabel})',
        [edge.edgeId, edge.sourceId, edge.targetId],
        edge.provenance,
      ));
    }
    return DoctrineSection(
      type: DoctrineSectionType.precedentRelationships,
      title: DoctrineSectionType.precedentRelationships.displayTitle,
      statements: stmts,
    );
  }

  DoctrineSection? _chronologySection(
      String doctrineId, DoctrineAnalysisResult analysis) {
    final ch = analysis.chronology;
    if (ch.isEmpty) return null;
    final stmts = <DoctrineStatement>[
      if (ch.earliest != null)
        _stmt('Earliest', '${ch.earliest!.caseName} (${ch.earliest!.year})',
            [ch.earliest!.caseId], 'p10:chronology'),
      if (ch.latest != null)
        _stmt('Latest', '${ch.latest!.caseName} (${ch.latest!.year})',
            [ch.latest!.caseId], 'p10:chronology'),
      if (ch.earliest != null && ch.latest != null)
        _stmt('Year span', '${ch.earliest!.year}–${ch.latest!.year}',
            [doctrineId], 'p10:chronology'),
    ];
    return stmts.isEmpty
        ? null
        : DoctrineSection(
            type: DoctrineSectionType.chronology,
            title: DoctrineSectionType.chronology.displayTitle,
            statements: stmts,
          );
  }

  DoctrineSection? _structuralObservationsSection(
      String doctrineId, DoctrineAnalysisResult analysis) {
    final stmts = <DoctrineStatement>[];
    // P10 structural observations, verbatim.
    for (final o in analysis.observations) {
      stmts.add(_stmt(o.type.name, o.label, o.references, o.provenance));
    }
    // Deterministic structural overlap: another doctrine sharing a constituent
    // case. Explicitly a structural grouping, never a legal relationship.
    for (final overlap in _overlapsFor(doctrineId, analysis.caseIds)) {
      final caseObj = _caseById(overlap.caseId);
      final yearText = caseObj == null ? '' : ' (${caseObj.year})';
      stmts.add(_stmt(
        'Shared constituent case (structural)',
        '${caseObj?.caseName ?? overlap.caseId}$yearText is a constituent case '
            'of both $doctrineId and ${overlap.doctrineId} — a structural '
            'grouping, not a legal relationship.',
        [doctrineId, overlap.doctrineId, overlap.caseId],
        'p5:caseDoctrineEdges',
      ));
    }
    if (stmts.isEmpty) return null;
    return DoctrineSection(
      type: DoctrineSectionType.structuralObservations,
      title: DoctrineSectionType.structuralObservations.displayTitle,
      statements: stmts,
    );
  }

  DoctrineSection? _upscRelevanceSection(
      String doctrineId, List<DoctrineCaseEntry> entries) {
    if (entries.isEmpty) return null;
    final stmts = <DoctrineStatement>[];
    final themes = <String, Set<String>>{};
    final subjects = <String, Set<String>>{};
    for (final e in entries) {
      final c = e.caseObject;
      stmts.add(_stmt(
        'UPSC relevance — ${e.caseId}',
        'Prelims: ${c.prelimsRelevance.name}; Mains: ${c.mainsRelevance.name}; '
            'Essay: ${c.essayRelevance.name}; Interview: ${c.interviewRelevance.name}',
        [e.caseId],
        'corpus:upscRelevance',
      ));
      for (final t in c.themes) {
        if (t.trim().isNotEmpty) {
          themes.putIfAbsent(t.trim(), () => {}).add(e.caseId);
        }
      }
      for (final s in c.subjects) {
        if (s.trim().isNotEmpty) {
          subjects.putIfAbsent(s.trim(), () => {}).add(e.caseId);
        }
      }
    }
    final themeKeys = themes.keys.toList()..sort();
    for (final t in themeKeys) {
      final refCases = themes[t]!.toList()..sort();
      stmts.add(_stmt('Theme', t, [doctrineId, ...refCases], 'corpus:themes'));
    }
    final subjectKeys = subjects.keys.toList()..sort();
    for (final s in subjectKeys) {
      final refCases = subjects[s]!.toList()..sort();
      stmts.add(
          _stmt('Subject', s, [doctrineId, ...refCases], 'corpus:subjects'));
    }
    return DoctrineSection(
      type: DoctrineSectionType.upscRelevance,
      title: DoctrineSectionType.upscRelevance.displayTitle,
      statements: stmts,
    );
  }

  DoctrineSection? _evidenceSection(String doctrineId,
      DoctrineKnowledgeObject d, List<DoctrineCaseEntry> entries) {
    final stmts = <DoctrineStatement>[
      if (_nonEmpty(d.primarySource))
        _stmt('Primary source', d.primarySource, [doctrineId],
            'doctrine:$doctrineId.primarySource'),
      for (final cit in d.citations)
        if (cit.trim().isNotEmpty)
          _stmt('Recorded citation', cit, [doctrineId],
              'doctrine:$doctrineId.citations'),
      for (final ref in d.evidenceReferences)
        if (ref.trim().isNotEmpty)
          _stmt('Evidence reference', ref, [doctrineId],
              'doctrine:$doctrineId.evidenceReferences'),
      for (final e in entries)
        for (final ev in e.caseObject.evidenceIds)
          if (ev.trim().isNotEmpty)
            _stmt('Evidence — ${e.caseId}', _evidenceLabel(ev), [e.caseId, ev],
                'corpus:evidenceIds'),
    ];
    return stmts.isEmpty
        ? null
        : DoctrineSection(
            type: DoctrineSectionType.evidence,
            title: DoctrineSectionType.evidence.displayTitle,
            statements: stmts,
          );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  DoctrineKnowledgeObject? _doctrineById(String id) {
    for (final d in doctrines) {
      if (d.doctrineId == id) return d;
    }
    return null;
  }

  CaseKnowledgeObject? _caseById(String caseId) {
    for (final c in cases) {
      if (c.caseId == caseId) return c;
    }
    return null;
  }

  /// Deterministic structural overlap: other doctrines (sorted) that share a
  /// constituent case with [selfId], each with the shared case ID (sorted).
  List<({String doctrineId, String caseId})> _overlapsFor(
      String selfId, List<String> memberIds) {
    if (memberIds.isEmpty) return const [];
    final memberSet = memberIds.toSet();
    final out = <({String doctrineId, String caseId})>[];
    for (final otherId in doctrineMemberIds.keys) {
      if (otherId == selfId) continue;
      for (final cid in doctrineMemberIds[otherId]!) {
        if (memberSet.contains(cid)) {
          out.add((doctrineId: otherId, caseId: cid));
        }
      }
    }
    out.sort((a, b) {
      final byDoctrine = a.doctrineId.compareTo(b.doctrineId);
      if (byDoctrine != 0) return byDoctrine;
      return a.caseId.compareTo(b.caseId);
    });
    return List.unmodifiable(out);
  }

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

  DoctrineStatement _stmt(
          String label, String text, List<String> refs, String provenance) =>
      DoctrineStatement(
        label: label,
        text: text,
        sourceRefs: refs,
        provenance: provenance,
      );

  bool _nonEmpty(String s) => s.trim().isNotEmpty;
}

extension DoctrineCategoryDisplayName on DoctrineCategory {
  /// Deterministic human-readable label for a doctrine category.
  String get displayName => switch (this) {
        DoctrineCategory.fundamentalRights => 'Fundamental Rights',
        DoctrineCategory.amendingPower => 'Amending Power',
        DoctrineCategory.legislativeRelations => 'Legislative Relations',
        DoctrineCategory.environmentalJurisprudence =>
          'Environmental Jurisprudence',
        DoctrineCategory.executivePower => 'Executive Power',
        DoctrineCategory.administrativeLaw => 'Administrative Law',
        DoctrineCategory.constitutionalInterpretation =>
          'Constitutional Interpretation',
      };
}

extension DoctrineStatusDisplayName on DoctrineStatus {
  /// Deterministic human-readable label for a doctrine status.
  String get displayName => switch (this) {
        DoctrineStatus.settledLaw => 'Settled law',
        DoctrineStatus.evolvingJurisprudence => 'Evolving jurisprudence',
        DoctrineStatus.judiciallyEvolved => 'Judicially evolved',
        DoctrineStatus.modifiedByStatute => 'Modified by statute',
      };
}
