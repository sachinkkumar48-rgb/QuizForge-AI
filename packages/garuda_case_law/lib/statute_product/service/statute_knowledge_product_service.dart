/// P13 Evidence-Backed Statute / Article Knowledge Product service
/// (TITAN-KO-015.0 P13).
///
/// A deterministic, offline-first knowledge-product composition layer that
/// transforms existing validated GARUDA Case Law + Constitution + Acts +
/// Doctrine evidence into a structured, provision-level, provenance-preserving
/// [StatuteKnowledgeProduct], centered on one verified constitutional Article
/// or statutory provision (Act or section).
///
/// P13 is NOT a legal reasoning engine. It never invents provision text,
/// citation, case association, doctrine association, precedent, overruling,
/// refinement, extension, doctrinal evolution, current-law status or legal
/// conclusions. Every statement in every section is composed from existing
/// validated P3–P12 source data:
///
/// - **Provision identity** — the verbatim P3 corpus references that fold to
///   the canonical key (`relatedArticles` / `relatedActs` / `sections`), plus
///   the canonical key itself (P6 `CaseSearchNormalizer` normalization).
/// - **Provision overview** — the canonical `garuda_constitution`
///   `ArticleKnowledgeObject` / `garuda_acts` `ActKnowledgeObject` metadata,
///   verbatim, ONLY where the key resolves to that corpus. No legal
///   interpretation, no current-law status.
/// - **Associated cases** — cases whose own validated P3 fields reference the
///   provision. No inference from doctrine, graph connectivity, legal
///   similarity, chronology or P9 discovery.
/// - **Doctrines** — doctrines safely associated through a validated two-step
///   path: an associated case that is also a recorded P5 member of the
///   doctrine. Roles are verbatim P5 edge evidence.
/// - **Precedent relationships / chronology / structural observations** —
///   P5 case → case edges among the associated cases and P10
///   `chronologicalAnalysis` ordering. Chronology is position, never
///   causation.
/// - **Case-level knowledge** — one P11 [CaseExplanation] per associated case,
///   reused directly (never re-implemented).
/// - **Evidence / provenance** — P8 `EvidenceEntry` resolution of each
///   associated case's evidence IDs, plus the provision-corpus record's own
///   recorded citations / evidence references where resolvable.
///
/// Source hierarchy (documented in `P13_STATUTE_KNOWLEDGE_PRODUCT.md`):
/// P3 corpus fields → P6 normalization → P5 graph edges → P10 chronology →
/// P11 case explanations → P8 evidence registry → `garuda_constitution` /
/// `garuda_acts` identity records.
///
/// Missing data is represented by an omitted section, never by fabricated
/// content. Output is deterministic: identical corpus + identical services
/// produce byte-identical structured output, in the fixed section order, with
/// sorted references and sorted statements.
library;

import 'package:garuda_acts/garuda_acts.dart'
    show ActKnowledgeObject, Phase1ActsCorpus;
import 'package:garuda_constitution/garuda_constitution.dart'
    show ArticleKnowledgeObject, ConstitutionSeedData;
import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineKnowledgeObject, DoctrineSeedData;
import 'package:meta/meta.dart';

import '../../analysis/service/cross_case_analysis_service.dart';
import '../../data/case_seed_data.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../../explanation/domain/case_explanation.dart';
import '../../explanation/service/case_explanation_service.dart';
import '../../graph/data/legal_graph_seed.dart';
import '../../graph/domain/legal_graph.dart';
import '../../graph/domain/legal_graph_edge.dart';
import '../../graph/service/doctrine_relationship_service.dart';
import '../../graph/service/legal_graph_traversal_service.dart';
import '../../graph/service/precedent_graph_service.dart';
import '../../rendering/evidence_entry.dart';
import '../../search/data/case_search_normalizer.dart';
import '../../search/service/case_search_engine.dart';
import '../domain/statute_knowledge_product.dart';
import '../domain/statute_product_enums.dart';
import '../domain/statute_product_section.dart';

/// Builds evidence-backed statute knowledge products by deterministically
/// composing existing validated P3–P12 data. No legal research is performed.
@immutable
class StatuteKnowledgeProductService {
  /// The full validated corpus this service reads from.
  final List<CaseKnowledgeObject> cases;

  /// The canonical `garuda_constitution` article records.
  final List<ArticleKnowledgeObject> constitutionArticles;

  /// The canonical `garuda_acts` act records.
  final List<ActKnowledgeObject> acts;

  /// The canonical `garuda_doctrine` records.
  final List<DoctrineKnowledgeObject> doctrines;

  /// The P5 legal graph snapshot (never modified).
  final LegalGraph graph;

  /// P6 search engine used for canonical case resolution.
  final CaseSearchEngine searchEngine;

  /// P5 precedent-graph read side (case → case edges).
  final PrecedentGraphService precedentService;

  /// P5 case ↔ doctrine navigation.
  final DoctrineRelationshipService doctrineService;

  /// P5 graph traversal.
  final LegalGraphTraversalService traversalService;

  /// P10 cross-case analysis (chronology ordering).
  final CrossCaseAnalysisService analysisService;

  /// P11 case-explanation service (one explanation per associated case).
  final CaseExplanationService explanationService;

  /// Provision key → (verbatim reference → sorted case IDs carrying it), for
  /// each provision kind. Derived from the validated corpus at construction.
  final Map<ProvisionType, Map<String, Map<String, List<String>>>>
      provisionRefMap;

  /// Builds a service over the shared corpus/services. All inputs are optional
  /// and default to the canonical offline corpus, so the default constructor is
  /// deterministic and offline-first.
  factory StatuteKnowledgeProductService({
    List<CaseKnowledgeObject>? cases,
    List<ArticleKnowledgeObject>? constitutionArticles,
    List<ActKnowledgeObject>? acts,
    List<DoctrineKnowledgeObject>? doctrines,
    LegalGraph? graph,
    CaseSearchEngine? searchEngine,
    PrecedentGraphService? precedentService,
    DoctrineRelationshipService? doctrineService,
    LegalGraphTraversalService? traversalService,
    CrossCaseAnalysisService? analysisService,
    CaseExplanationService? explanationService,
  }) {
    final corpus = cases ?? CaseSeedData.cases;
    final constitutionRecords =
        constitutionArticles ?? ConstitutionSeedData.articles;
    final actRecords = acts ?? Phase1ActsCorpus.phase1Acts;
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
    final an = analysisService ??
        CrossCaseAnalysisService(
          cases: corpus,
          graph: g,
          searchEngine: se,
          precedentService: ps,
          doctrineService: ds,
          traversalService: ts,
        );
    final ex = explanationService ??
        CaseExplanationService(
          cases: corpus,
          graph: g,
          searchEngine: se,
          precedentService: ps,
          doctrineService: ds,
          traversalService: ts,
          analysisService: an,
        );
    return StatuteKnowledgeProductService._(
      cases: List<CaseKnowledgeObject>.unmodifiable(corpus),
      constitutionArticles:
          List<ArticleKnowledgeObject>.unmodifiable(constitutionRecords),
      acts: List<ActKnowledgeObject>.unmodifiable(actRecords),
      doctrines: List<DoctrineKnowledgeObject>.unmodifiable(doctrineRecords),
      graph: g,
      searchEngine: se,
      precedentService: ps,
      doctrineService: ds,
      traversalService: ts,
      analysisService: an,
      explanationService: ex,
      provisionRefMap: _buildProvisionRefMap(corpus),
    );
  }

  const StatuteKnowledgeProductService._({
    required this.cases,
    required this.constitutionArticles,
    required this.acts,
    required this.doctrines,
    required this.graph,
    required this.searchEngine,
    required this.precedentService,
    required this.doctrineService,
    required this.traversalService,
    required this.analysisService,
    required this.explanationService,
    required this.provisionRefMap,
  });

  /// Derives the provision → references → cases map deterministically from the
  /// validated corpus. Only references present in a case's own field are
  /// recorded; nothing is inferred.
  static Map<ProvisionType, Map<String, Map<String, List<String>>>>
      _buildProvisionRefMap(List<CaseKnowledgeObject> corpus) {
    final articles = <String, Map<String, List<String>>>{};
    final actMap = <String, Map<String, List<String>>>{};
    final sections = <String, Map<String, List<String>>>{};
    for (final c in corpus) {
      for (final ref in c.relatedArticles) {
        _addRef(articles, c.caseId, ref, _normalizeArticleKey(ref));
      }
      for (final ref in c.relatedActs) {
        _addRef(actMap, c.caseId, ref, _normalizeActKey(ref));
      }
      for (final ref in c.sections) {
        _addRef(sections, c.caseId, ref, _normalizeSectionKey(ref));
      }
    }
    return {
      ProvisionType.article: _sortedRefMap(articles),
      ProvisionType.act: _sortedRefMap(actMap),
      ProvisionType.section: _sortedRefMap(sections),
    };
  }

  static void _addRef(Map<String, Map<String, List<String>>> byKey,
      String caseId, String rawRef, String key) {
    if (key.isEmpty || rawRef.trim().isEmpty) return;
    final refs =
        byKey.putIfAbsent(key, () => <String, List<String>>{});
    refs.putIfAbsent(rawRef.trim(), () => <String>[]).add(caseId);
  }

  /// Sorts every collection deterministically (keys, references, case IDs).
  static Map<String, Map<String, List<String>>> _sortedRefMap(
      Map<String, Map<String, List<String>>> byKey) {
    final out = <String, Map<String, List<String>>>{};
    for (final key in byKey.keys.toList()..sort()) {
      final refMap = <String, List<String>>{};
      for (final ref in byKey[key]!.keys.toList()..sort()) {
        final ids = byKey[key]![ref]!.toSet().toList()..sort();
        refMap[ref] = List<String>.unmodifiable(ids);
      }
      out[key] = Map<String, List<String>>.unmodifiable(refMap);
    }
    return Map<String, Map<String, List<String>>>.unmodifiable(out);
  }

  // -------------------------------------------------------------------------
  // Canonical normalization
  // -------------------------------------------------------------------------

  /// Canonical article key via P6 `CaseSearchNormalizer` (`Article 21A`,
  /// `Art. 21A`, `21A` → `21a`).
  static String _normalizeArticleKey(String ref) =>
      CaseSearchNormalizer.normalizeArticle(ref);

  /// Canonical act key: P6 text normalization with a leading article-word
  /// `the ` folded so `The X, 1951` and `X, 1951` normalize consistently.
  /// Purely textual; never merges legally distinct provisions.
  static String _normalizeActKey(String ref) =>
      _stripLeadingThe(CaseSearchNormalizer.normalizeText(ref));

  /// Canonical section key: P6 text normalization.
  static String _normalizeSectionKey(String ref) =>
      CaseSearchNormalizer.normalizeText(ref);

  static String _stripLeadingThe(String s) =>
      s.startsWith('the ') ? s.substring(4) : s;

  static String _keyFor(ProvisionType type, String ref) => switch (type) {
        ProvisionType.article => _normalizeArticleKey(ref),
        ProvisionType.act => _normalizeActKey(ref),
        ProvisionType.section => _normalizeSectionKey(ref),
      };

  static String _fieldFor(ProvisionType type) => switch (type) {
        ProvisionType.article => 'relatedArticles',
        ProvisionType.act => 'relatedActs',
        ProvisionType.section => 'sections',
      };

  // -------------------------------------------------------------------------
  // Convenience accessors
  // -------------------------------------------------------------------------

  /// Canonical provision keys present in the corpus for [type], sorted.
  List<String> provisionIds(ProvisionType type) {
    final refMap = provisionRefMap[type] ?? const {};
    return List<String>.unmodifiable(refMap.keys.toList()..sort());
  }

  /// Whether any corpus case references [ref] as a [type] provision.
  bool hasProvision(ProvisionType type, String ref) =>
      resolveProvisionId(type, ref) != null;

  /// Resolves [ref] to the canonical provision key for [type], or null when no
  /// corpus case references it. Equivalent textual forms normalize
  /// consistently; unknown input resolves to nothing and never fabricates a
  /// provision.
  String? resolveProvisionId(ProvisionType type, String ref) {
    final q = ref.trim();
    if (q.isEmpty) return null;
    final key = _keyFor(type, q);
    if (key.isEmpty) return null;
    final refMap = provisionRefMap[type] ?? const {};
    return refMap.containsKey(key) ? key : null;
  }

  /// Canonical corpus case IDs referenced by [product], sorted and
  /// de-duplicated.
  ///
  /// Statement references also carry non-case identifiers (provision keys,
  /// doctrine IDs, edge IDs, evidence IDs); only identifiers that resolve to a
  /// validated corpus case are returned here, so the result never fabricates a
  /// case ID.
  List<String> referencedCaseIds(StatuteKnowledgeProduct product) {
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

  /// Builds the knowledge product for a [type] provision referenced as [ref],
  /// or null when the provision does not resolve. Missing data is represented
  /// by an absent section — nothing is fabricated.
  StatuteKnowledgeProduct? build(ProvisionType type, String ref) {
    final id = resolveProvisionId(type, ref);
    if (id == null) return null;
    final refMap = provisionRefMap[type] ?? const {};
    final refs = refMap[id];
    if (refs == null) return null;
    final rawRefs = refs.keys.toList()..sort();
    if (rawRefs.isEmpty) return null;
    final caseIds = <String>{
      for (final ids in refs.values)
        for (final cid in ids) cid,
    }.toList()
      ..sort();
    if (caseIds.isEmpty) return null;
    final ordered = _chronologicalOrder(caseIds);
    final sections = <StatuteSection>[
      if (_identitySection(type, id, rawRefs, caseIds) case final StatuteSection s)
        s,
      if (_overviewSection(type, id) case final StatuteSection s) s,
      if (_associatedCasesSection(type, id, ordered) case final StatuteSection s)
        s,
      if (_doctrinesSection(id, ordered) case final StatuteSection s) s,
      if (_precedentRelationshipsSection(id, ordered)
          case final StatuteSection s)
        s,
      if (_chronologySection(id, ordered) case final StatuteSection s) s,
      if (_structuralObservationsSection(type, id, ordered)
          case final StatuteSection s)
        s,
      if (_upscRelevanceSection(id, ordered) case final StatuteSection s) s,
      if (_evidenceSection(type, id, ordered) case final StatuteSection s) s,
    ];
    return StatuteKnowledgeProduct(
      provisionType: type,
      provisionId: id,
      provisionName: rawRefs.first,
      rawReferences: List<String>.unmodifiable(rawRefs),
      sections: List<StatuteSection>.unmodifiable(sections),
      caseExplanations: _explanationsFor(ordered),
    );
  }

  /// Builds the knowledge product for every provision present in the corpus,
  /// across all provision kinds, in deterministic order (article, act, section;
  /// then provision key ascending).
  List<StatuteKnowledgeProduct> buildAll() {
    final out = <StatuteKnowledgeProduct>[];
    for (final type in ProvisionType.values) {
      for (final id in provisionIds(type)) {
        out.add(build(type, id)!);
      }
    }
    return List<StatuteKnowledgeProduct>.unmodifiable(out);
  }

  /// Deterministic chronological order of the case IDs (P10 ordering: year asc,
  /// judgment date asc, name asc, ID asc). Position is never causation.
  List<String> _chronologicalOrder(List<String> caseIds) {
    final analysis = analysisService.chronologicalAnalysis(caseIds);
    return List<String>.unmodifiable([
      for (final e in analysis.entries) e.caseId,
    ]);
  }

  /// One P11 [CaseExplanation] per associated case, in the same chronological
  /// order as the `associatedCases` section. Reuses P11 directly.
  List<CaseExplanation> _explanationsFor(List<String> orderedCaseIds) {
    final out = <CaseExplanation>[];
    for (final cid in orderedCaseIds) {
      final ex = explanationService.explain(cid);
      if (ex != null) out.add(ex);
    }
    return List<CaseExplanation>.unmodifiable(out);
  }

  // -------------------------------------------------------------------------
  // Section builders — every builder returns null when no validated evidence
  // exists for that section (missing data is an absent section).
  // -------------------------------------------------------------------------

  StatuteSection? _identitySection(ProvisionType type, String id,
      List<String> rawRefs, List<String> caseIds) {
    final field = _fieldFor(type);
    final stmts = <StatuteStatement>[
      _stmt('Provision kind', type.displayTitle, [id], 'statute:provisionType'),
      _stmt('Provision key', id, [id], 'statute:provisionId'),
      _stmt(
          'Resolution',
          _resolutionLabel(type, id),
          [id, ...caseIds],
          'statute:resolution'),
      for (var i = 0; i < rawRefs.length; i++)
        _stmt(
          'Reference ${i + 1}',
          rawRefs[i],
          [id, ...caseIds],
          'corpus:$field',
        ),
    ];
    return stmts.isEmpty
        ? null
        : StatuteSection(
            type: StatuteSectionType.identity,
            title: StatuteSectionType.identity.displayTitle,
            statements: stmts,
          );
  }

  /// Whether the provision resolves to the canonical `garuda_constitution` /
  /// `garuda_acts` corpus (used for resolution labeling and overview).
  String _resolutionLabel(ProvisionType type, String id) => switch (type) {
        ProvisionType.article =>
          _articleFor(id) != null
              ? 'Resolved to the constitutional corpus'
              : 'Verbatim corpus reference only (no constitutional record)',
        ProvisionType.act =>
          _actFor(id) != null
              ? 'Resolved to the central-acts corpus'
              : 'Verbatim corpus reference only (no acts record)',
        ProvisionType.section =>
          'Verbatim corpus reference only (no section corpus)',
      };

  StatuteSection? _overviewSection(ProvisionType type, String id) {
    final stmts = <StatuteStatement>[];
    switch (type) {
      case ProvisionType.article:
        final a = _articleFor(id);
        if (a != null) {
          stmts.add(_stmt(
              'Article number', a.articleNumber, [id],
              'constitution:ArticleKnowledgeObject'));
          if (_nonEmpty(a.officialTitle)) {
            stmts.add(_stmt('Official title', a.officialTitle, [id],
                'constitution:ArticleKnowledgeObject'));
          }
          if (_nonEmpty(a.part)) {
            stmts.add(_stmt('Part', a.part, [id],
                'constitution:ArticleKnowledgeObject'));
          }
          if (_nonEmpty(a.chapter)) {
            stmts.add(_stmt('Chapter', a.chapter, [id],
                'constitution:ArticleKnowledgeObject'));
          }
        }
      case ProvisionType.act:
        final act = _actFor(id);
        if (act != null) {
          stmts.add(_stmt('Official name', act.metadata.officialName, [id],
              'acts:ActKnowledgeObject'));
          stmts.add(_stmt('Short title', act.metadata.shortTitle, [id],
              'acts:ActKnowledgeObject'));
          stmts.add(_stmt('Year', '${act.metadata.year}', [id],
              'acts:ActKnowledgeObject'));
          if (_nonEmpty(act.metadata.actNumber)) {
            stmts.add(_stmt('Act number', act.metadata.actNumber, [id],
                'acts:ActKnowledgeObject'));
          }
        }
      case ProvisionType.section:
        // No section corpus exists; identity is verbatim-only. Never fabricate
        // a section overview.
        return null;
    }
    return stmts.isEmpty
        ? null
        : StatuteSection(
            type: StatuteSectionType.overview,
            title: StatuteSectionType.overview.displayTitle,
            statements: stmts,
          );
  }

  StatuteSection? _associatedCasesSection(
      ProvisionType type, String id, List<String> ordered) {
    if (ordered.isEmpty) return null;
    final field = _fieldFor(type);
    final stmts = <StatuteStatement>[];
    for (var i = 0; i < ordered.length; i++) {
      final c = _caseById(ordered[i]);
      if (c == null) continue;
      final refsUsed = <String>[
        for (final e in (provisionRefMap[type]?[id] ?? const {}).entries)
          if (e.value.contains(c.caseId)) e.key,
      ]..sort();
      stmts.add(_stmt(
        'Associated case ${i + 1}',
        '${c.caseName} (${c.year}) — ${refsUsed.join(', ')}',
        [c.caseId],
        'corpus:$field|key:$id',
      ));
    }
    return stmts.isEmpty
        ? null
        : StatuteSection(
            type: StatuteSectionType.associatedCases,
            title: StatuteSectionType.associatedCases.displayTitle,
            statements: stmts,
          );
  }

  StatuteSection? _doctrinesSection(String id, List<String> ordered) {
    if (ordered.isEmpty) return null;
    // Only doctrines established by a recorded P5 case → doctrine edge from an
    // associated case, AND resolvable to a canonical doctrine record. A
    // doctrine is never inferred from an article mention alone.
    final byDoctrine = <String, Map<String, String>>{};
    for (final cid in ordered) {
      for (final edge in doctrineService.getDoctrinesForCase(cid)) {
        if (_doctrineById(edge.targetId) == null) continue;
        byDoctrine
            .putIfAbsent(edge.targetId, () => <String, String>{})[cid] =
            edge.typeLabel;
      }
    }
    if (byDoctrine.isEmpty) return null;
    final doctrineIds = byDoctrine.keys.toList()..sort();
    final stmts = <StatuteStatement>[];
    for (final did in doctrineIds) {
      final record = _doctrineById(did)!;
      final roles = byDoctrine[did]!.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final roleText = roles
          .map((e) => '${_caseName(e.key)} (${e.value})')
          .join('; ');
      final caseIds = roles.map((e) => e.key).toSet().toList()..sort();
      stmts.add(_stmt(
        record.name,
        '$did — $roleText',
        [did, ...caseIds],
        'p5:caseDoctrineEdges',
      ));
    }
    return stmts.isEmpty
        ? null
        : StatuteSection(
            type: StatuteSectionType.doctrines,
            title: StatuteSectionType.doctrines.displayTitle,
            statements: stmts,
          );
  }

  StatuteSection? _precedentRelationshipsSection(
      String id, List<String> ordered) {
    if (ordered.isEmpty) return null;
    final memberSet = ordered.toSet();
    final edges = <PrecedentGraphEdge>{};
    for (final cid in ordered) {
      for (final e in precedentService.outgoingRelationships(cid)) {
        if (memberSet.contains(e.targetId)) edges.add(e);
      }
    }
    if (edges.isEmpty) return null;
    final sorted = edges.toList()
      ..sort((a, b) {
        final bySource = a.sourceId.compareTo(b.sourceId);
        if (bySource != 0) return bySource;
        final byType = a.typeLabel.compareTo(b.typeLabel);
        if (byType != 0) return byType;
        return a.targetId.compareTo(b.targetId);
      });
    final stmts = <StatuteStatement>[];
    for (var i = 0; i < sorted.length; i++) {
      final e = sorted[i];
      stmts.add(_stmt(
        'Precedent relationship ${i + 1}',
        '${_caseName(e.sourceId)} → ${_caseName(e.targetId)} (${e.typeLabel})',
        [e.edgeId, e.sourceId, e.targetId],
        e.provenance,
      ));
    }
    return stmts.isEmpty
        ? null
        : StatuteSection(
            type: StatuteSectionType.precedentRelationships,
            title: StatuteSectionType.precedentRelationships.displayTitle,
            statements: stmts,
          );
  }

  StatuteSection? _chronologySection(String id, List<String> ordered) {
    if (ordered.isEmpty) return null;
    final ch = analysisService.chronologicalAnalysis(ordered);
    if (ch.isEmpty) return null;
    final stmts = <StatuteStatement>[
      if (ch.earliest != null)
        _stmt(
            'Earliest', '${ch.earliest!.caseName} (${ch.earliest!.year})',
            [ch.earliest!.caseId], 'p10:chronology'),
      if (ch.latest != null)
        _stmt('Latest', '${ch.latest!.caseName} (${ch.latest!.year})',
            [ch.latest!.caseId], 'p10:chronology'),
      if (ch.earliest != null && ch.latest != null)
        _stmt('Year span', '${ch.earliest!.year}–${ch.latest!.year}', [id],
            'p10:chronology'),
    ];
    return stmts.isEmpty
        ? null
        : StatuteSection(
            type: StatuteSectionType.chronology,
            title: StatuteSectionType.chronology.displayTitle,
            statements: stmts,
          );
  }

  StatuteSection? _structuralObservationsSection(
      ProvisionType type, String id, List<String> ordered) {
    if (ordered.isEmpty) return null;
    final field = _fieldFor(type);
    final stmts = <StatuteStatement>[
      _stmt('Associated cases', '${ordered.length}', ordered, 'corpus:$field'),
      _stmt(
          'Case IDs',
          ordered.join(', '),
          ordered,
          'corpus:$field|key:$id'),
    ];
    return stmts.isEmpty
        ? null
        : StatuteSection(
            type: StatuteSectionType.structuralObservations,
            title: StatuteSectionType.structuralObservations.displayTitle,
            statements: stmts,
          );
  }

  StatuteSection? _upscRelevanceSection(String id, List<String> ordered) {
    if (ordered.isEmpty) return null;
    final stmts = <StatuteStatement>[];
    for (final cid in ordered) {
      final c = _caseById(cid);
      if (c == null) continue;
      stmts.add(_stmt(
        'UPSC relevance — ${c.caseId}',
        'Prelims: ${c.prelimsRelevance.name}; Mains: ${c.mainsRelevance.name}; '
            'Essay: ${c.essayRelevance.name}; Interview: ${c.interviewRelevance.name}',
        [c.caseId],
        'corpus:upscRelevance',
      ));
    }
    return stmts.isEmpty
        ? null
        : StatuteSection(
            type: StatuteSectionType.upscRelevance,
            title: StatuteSectionType.upscRelevance.displayTitle,
            statements: stmts,
          );
  }

  StatuteSection? _evidenceSection(
      ProvisionType type, String id, List<String> ordered) {
    final stmts = <StatuteStatement>[];
    switch (type) {
      case ProvisionType.article:
        final a = _articleFor(id);
        if (a != null) {
          for (final cit in a.citations) {
            if (cit.trim().isNotEmpty) {
              stmts.add(_stmt('Recorded citation — Article', cit, [id],
                  'constitution:ArticleKnowledgeObject'));
            }
          }
        }
      case ProvisionType.act:
        final act = _actFor(id);
        if (act != null) {
          for (final ref in act.evidenceReferences) {
            if (ref.trim().isNotEmpty) {
              stmts.add(_stmt('Evidence reference — Act', ref, [id],
                  'acts:ActKnowledgeObject'));
            }
          }
        }
      case ProvisionType.section:
        break;
    }
    for (final cid in ordered) {
      final c = _caseById(cid);
      if (c == null) continue;
      for (final ev in c.evidenceIds) {
        if (ev.trim().isNotEmpty) {
          stmts.add(_stmt('Evidence — ${c.caseId}', _evidenceLabel(ev),
              [c.caseId, ev], 'corpus:evidenceIds'));
        }
      }
    }
    return stmts.isEmpty
        ? null
        : StatuteSection(
            type: StatuteSectionType.evidence,
            title: StatuteSectionType.evidence.displayTitle,
            statements: stmts,
          );
  }

  // -------------------------------------------------------------------------
  // Canonical corpus resolution (identity enrichment only — never the source
  // of truth for case association).
  // -------------------------------------------------------------------------

  /// Resolves a normalized article key to its canonical `garuda_constitution`
  /// record, or null. Exact key match only — a clause-form key (`191a`) never
  /// merges into its base article (`19`).
  ArticleKnowledgeObject? _articleFor(String key) {
    for (final a in constitutionArticles) {
      if (_normalizeArticleKey(a.articleNumber) == key) return a;
    }
    return null;
  }

  /// Resolves a normalized act key to its canonical `garuda_acts` record, or
  /// null. Matches the normalized official name or short title; collisions
  /// resolve to the record with the smallest `actId` (deterministic).
  ActKnowledgeObject? _actFor(String key) {
    ActKnowledgeObject? best;
    for (final a in acts) {
      if (!_actCandidateKeys(a).contains(key)) continue;
      if (best == null || a.actId.compareTo(best.actId) < 0) best = a;
    }
    return best;
  }

  Set<String> _actCandidateKeys(ActKnowledgeObject a) => {
        _normalizeActKey(a.metadata.officialName),
        _normalizeActKey(a.metadata.shortTitle),
      }..removeWhere((k) => k.isEmpty);

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

  String _caseName(String caseId) =>
      _caseById(caseId)?.caseName ?? caseId;

  /// Presents one evidence ID through the P8 [EvidenceEntry] registry
  /// resolution — the same predicate P7 uses. Nothing is guessed.
  String _evidenceLabel(String evidenceId) {
    final entry = EvidenceEntry.fromId(evidenceId);
    if (entry.typeLabel.isEmpty) {
      return entry.verified
          ? 'registered (verified)'
          : 'registered (unresolved)';
    }
    return '${entry.typeLabel}${entry.verified ? '' : ' (unverified)'}';
  }

  StatuteStatement _stmt(
          String label, String text, List<String> refs, String provenance) =>
      StatuteStatement(
        label: label,
        text: text,
        sourceRefs: refs,
        provenance: provenance,
      );

  bool _nonEmpty(String s) => s.trim().isNotEmpty;
}
