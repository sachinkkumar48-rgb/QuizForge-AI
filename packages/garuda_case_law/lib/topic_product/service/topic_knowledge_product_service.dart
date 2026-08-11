/// P14 Evidence-Bounded UPSC Topic Knowledge Product service
/// (TITAN-KO-015.0 P14).
///
/// A deterministic, offline-first knowledge-product composition layer that
/// organizes existing validated GARUDA Case Law knowledge into structured,
/// pedagogical, provenance-preserving [TopicKnowledgeProduct]s.
///
/// P14 is NOT a legal reasoning engine. It never infers legal similarity,
/// precedent, authority, overruling, refinement, extension, doctrinal
/// evolution, causation or current-law status. Every statement in every section
/// is composed from existing validated P3–P13 source data:
///
/// - **Topic identity / overview / declaration** — the versioned P14 syllabus
///   configuration (`TopicSyllabusConfig`), verbatim. The taxonomy is an
///   explicit pedagogical mapping, never a claim of official UPSC syllabus.
/// - **Member cases** — cases mapped through explicit P14
///   `TopicMembership`s citing validated P3/P4 signals. Membership is never
///   inferred from graph connectivity, chronology, doctrine membership alone,
///   discovery or apparent relevance.
/// - **Case-level knowledge** — one P11 [CaseExplanation] per member case,
///   reused directly (never re-implemented).
/// - **Doctrines** — P12 [DoctrineKnowledgeProduct]s composed under a strict
///   deterministic rule: a doctrine product appears only when every validated
///   corpus case it references is already a topic member.
/// - **Provisions** — P13 [StatuteKnowledgeProduct]s composed under the same
///   strict all-members rule (no second statute mapping engine).
/// - **Chronology / structural observations** — P10 ordering (position is never
///   causation).
/// - **UPSC relevance** — verbatim P4 `UpscJudgmentIntelligence` of the member
///   cases.
/// - **Evidence** — P8 `EvidenceEntry` registry resolution of the member cases.
///
/// Missing data is represented by an omitted section, never by fabricated
/// content. Output is deterministic: identical corpus + identical services
/// produce byte-identical structured output, in the fixed section order, with
/// sorted references (see `P14_TOPIC_KNOWLEDGE_PRODUCT.md`).
library;

import 'package:garuda_acts/garuda_acts.dart' show ActKnowledgeObject;
import 'package:garuda_constitution/garuda_constitution.dart'
    show ArticleKnowledgeObject;
import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineKnowledgeObject;
import 'package:meta/meta.dart';

import '../../analysis/service/cross_case_analysis_service.dart';
import '../../data/case_seed_data.dart';
import '../../doctrine_product/domain/doctrine_knowledge_product.dart';
import '../../doctrine_product/service/doctrine_knowledge_product_service.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../../explanation/domain/case_explanation.dart';
import '../../explanation/service/case_explanation_service.dart';
import '../../intelligence/domain/intelligence_enums.dart';
import '../../rendering/evidence_entry.dart';
import '../../statute_product/domain/statute_product_enums.dart';
import '../../statute_product/domain/statute_knowledge_product.dart';
import '../../statute_product/service/statute_knowledge_product_service.dart';
import '../data/topic_syllabus_config.dart';
import '../domain/topic_identity.dart';
import '../domain/topic_knowledge_product.dart';
import '../domain/topic_membership.dart';
import '../domain/topic_product_enums.dart';
import '../domain/topic_product_section.dart';

/// Builds evidence-bounded topic knowledge products by deterministically
/// composing existing validated P3–P13 data. No legal research is performed.
@immutable
class TopicKnowledgeProductService {
  /// The full validated corpus this service reads from.
  final List<CaseKnowledgeObject> cases;

  /// The versioned P14 syllabus configuration.
  final TopicSyllabusConfig config;

  /// P10 cross-case analysis (chronological ordering).
  final CrossCaseAnalysisService analysisService;

  /// P11 case-explanation service (one per member case).
  final CaseExplanationService explanationService;

  /// P12 doctrine-product service (doctrine composition).
  final DoctrineKnowledgeProductService doctrineProductService;

  /// P13 statute-product service (provision composition).
  final StatuteKnowledgeProductService statuteProductService;

  /// caseId → validated corpus record.
  final Map<String, CaseKnowledgeObject> _caseById;

  /// Builds a service over the shared corpus/services. All inputs are optional
  /// and default to the canonical offline corpus, so the default constructor is
  /// deterministic and offline-first.
  factory TopicKnowledgeProductService({
    List<CaseKnowledgeObject>? cases,
    TopicSyllabusConfig? config,
    List<DoctrineKnowledgeObject>? doctrines,
    List<ArticleKnowledgeObject>? constitutionArticles,
    List<ActKnowledgeObject>? acts,
    DoctrineKnowledgeProductService? doctrineProductService,
    StatuteKnowledgeProductService? statuteProductService,
    CaseExplanationService? explanationService,
    CrossCaseAnalysisService? analysisService,
  }) {
    final corpus = cases ?? CaseSeedData.cases;
    final cfg = config ?? UpscTopicSyllabus.config;
    final dkps = doctrineProductService ??
        DoctrineKnowledgeProductService(
          cases: corpus,
          doctrines: doctrines,
        );
    final skps = statuteProductService ??
        StatuteKnowledgeProductService(
          cases: corpus,
          doctrines: doctrines,
          constitutionArticles: constitutionArticles,
          acts: acts,
        );
    final ex = explanationService ?? CaseExplanationService(cases: corpus);
    final an = analysisService ?? CrossCaseAnalysisService(cases: corpus);
    final byId = {for (final c in corpus) c.caseId: c};
    return TopicKnowledgeProductService._(
      cases: List<CaseKnowledgeObject>.unmodifiable(corpus),
      config: cfg,
      analysisService: an,
      explanationService: ex,
      doctrineProductService: dkps,
      statuteProductService: skps,
      caseById: Map<String, CaseKnowledgeObject>.unmodifiable(byId),
    );
  }

  const TopicKnowledgeProductService._({
    required this.cases,
    required this.config,
    required this.analysisService,
    required this.explanationService,
    required this.doctrineProductService,
    required this.statuteProductService,
    required Map<String, CaseKnowledgeObject> caseById,
  }) : _caseById = caseById;

  // -------------------------------------------------------------------------
  // Resolution
  // -------------------------------------------------------------------------

  /// Resolves a topic identity by canonical topic ID or display name, or null
  /// when unknown. Nothing is fabricated for unknown input.
  TopicIdentity? resolveTopic(String idOrName) => config.identityFor(idOrName);

  /// Whether [topicId] is a canonical topic ID.
  bool hasTopic(String topicId) => config.hasTopic(topicId);

  /// All canonical topic identities, in deterministic (ID ascending) order.
  List<TopicIdentity> get topics => List.unmodifiable([
        for (final id in config.topicIds) config.identityFor(id)!,
      ]);

  /// The pedagogical topics a case is explicitly mapped to, sorted by topic ID.
  /// A case with no explicit mapping returns an empty list — membership is
  /// never inferred.
  List<TopicIdentity> topicForCase(String caseId) {
    final out = <TopicIdentity>[];
    for (final id in config.topicIds) {
      final has = config.membershipsForTopic(id).any((m) => m.caseId == caseId);
      if (has) out.add(config.identityFor(id)!);
    }
    return List.unmodifiable(out);
  }

  /// The explicit memberships that map [caseId] to topics, in config order.
  List<TopicMembership> membershipsForCase(String caseId) => List.unmodifiable([
        for (final m in config.memberships)
          if (m.caseId == caseId) m,
      ]);

  // -------------------------------------------------------------------------
  // Product building
  // -------------------------------------------------------------------------

  /// Builds the knowledge product for [idOrName], or null when the topic does
  /// not resolve. Member cases that do not resolve in the corpus are omitted
  /// (missing data is an absent section) — the mapping validator reports any
  /// such orphan explicitly.
  TopicKnowledgeProduct? build(String idOrName) {
    final identity = config.identityFor(idOrName);
    if (identity == null) return null;

    final configMemberIds = config.memberCaseIdsFor(identity.id);
    final resolvedMembers = <String>[
      for (final id in configMemberIds)
        if (_caseById.containsKey(id)) id,
    ];
    final memberIds = _chronologicalOrder(resolvedMembers);

    final sections = <TopicSection>[
      if (_identitySection(identity) case final TopicSection s) s,
      if (_overviewSection(identity) case final TopicSection s) s,
      if (_memberCasesSection(identity.id, memberIds) case final TopicSection s)
        s,
      if (_doctrinesSection(identity.id, memberIds) case final TopicSection s)
        s,
      if (_provisionsSection(identity.id, memberIds) case final TopicSection s)
        s,
      if (_chronologySection(memberIds) case final TopicSection s) s,
      if (_structuralObservationsSection(identity.id, memberIds)
          case final TopicSection s)
        s,
      if (_upscRelevanceSection(memberIds) case final TopicSection s) s,
      if (_evidenceSection(memberIds) case final TopicSection s) s,
    ];

    return TopicKnowledgeProduct(
      topicId: identity.id,
      topicName: identity.name,
      area: identity.area,
      pedagogicalPath: identity.pedagogicalPath,
      mappingKind: identity.mappingKind,
      configVersion: identity.configVersion,
      memberCaseIds: memberIds,
      sections: List<TopicSection>.unmodifiable(sections),
      caseExplanations: _explanationsFor(memberIds),
      doctrineProducts: _composedDoctrines(identity.id, memberIds),
      statuteProducts: _composedProvisions(identity.id, memberIds),
    );
  }

  /// Builds the knowledge product for every canonical topic, in deterministic
  /// (topic ID ascending) order. Every resolved topic produces a product.
  List<TopicKnowledgeProduct> buildAll() =>
      [for (final id in config.topicIds) build(id)!];

  /// Unique canonical case IDs referenced by [product] that resolve in the
  /// corpus — the member cases of the topic. Deterministic and sorted.
  List<String> referencedCaseIds(TopicKnowledgeProduct product) {
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
  // Section builders — every builder returns null when no validated evidence
  // exists for that section (missing data is an absent section).
  // -------------------------------------------------------------------------

  TopicSection? _identitySection(TopicIdentity identity) {
    final statements = <TopicStatement>[
      TopicStatement(
        label: 'Topic ID',
        text: identity.id,
        sourceRefs: const ['p14:syllabusConfig', 'p14:config.v1'],
        provenance: 'p14:syllabusConfig.identity',
      ),
      TopicStatement(
        label: 'Topic name',
        text: identity.name,
        sourceRefs: const ['p14:syllabusConfig', 'p14:config.v1'],
        provenance: 'p14:syllabusConfig.identity',
      ),
      TopicStatement(
        label: 'Syllabus area',
        text: '${identity.area.displayName} (${identity.area.name})',
        sourceRefs: const ['p4:syllabusAreas', 'p14:config.v1'],
        provenance: 'p4:syllabusAreas; p14:syllabusConfig.identity',
      ),
      TopicStatement(
        label: 'Pedagogical path',
        text: identity.pedagogicalPath,
        sourceRefs: const ['p14:syllabusConfig', 'p14:config.v1'],
        provenance: 'p14:syllabusConfig.pedagogicalPath',
      ),
      TopicStatement(
        label: 'Taxonomy status',
        text: identity.mappingKind.displayTitle,
        sourceRefs: const ['p14:config.v1'],
        provenance: 'p14:syllabusConfig.mappingKind',
      ),
      TopicStatement(
        label: 'Official syllabus status',
        text: identity.isOfficialSyllabus
            ? 'Official UPSC syllabus taxonomy'
            : 'Not an official UPSC syllabus taxonomy (pedagogical mapping)',
        sourceRefs: const ['p14:config.v1'],
        provenance: 'p14:syllabusConfig.mappingKind',
      ),
      TopicStatement(
        label: 'Config version',
        text: 'P14 syllabus configuration v${identity.configVersion}',
        sourceRefs: const ['p14:syllabusConfig', 'p14:config.v1'],
        provenance: 'p14:syllabusConfig.version',
      ),
      TopicStatement(
        label: 'Mapping declaration',
        text: config.mappingDeclaration,
        sourceRefs: const ['p14:config.v1'],
        provenance: 'p14:syllabusConfig.mappingDeclaration',
      ),
    ];
    return TopicSection(
      type: TopicSectionType.identity,
      title: TopicSectionType.identity.displayTitle,
      statements: List<TopicStatement>.unmodifiable(statements),
    );
  }

  TopicSection? _overviewSection(TopicIdentity identity) {
    final overview = config.overviewFor(identity.id);
    if (overview.isEmpty) return null;
    return TopicSection(
      type: TopicSectionType.overview,
      title: TopicSectionType.overview.displayTitle,
      statements: List<TopicStatement>.unmodifiable([
        TopicStatement(
          label: 'Topic overview',
          text: overview,
          sourceRefs: const ['p14:syllabusConfig', 'p14:config.v1'],
          provenance: 'p14:syllabusConfig.overview',
        ),
      ]),
    );
  }

  TopicSection? _memberCasesSection(String topicId, List<String> memberIds) {
    if (memberIds.isEmpty) return null;
    final statements = <TopicStatement>[];
    for (var i = 0; i < memberIds.length; i++) {
      final c = _caseById[memberIds[i]]!;
      final m = _firstMembership(topicId, c.caseId);
      final signal =
          m == null ? '' : ' (mapped via ${m.signalField}: "${m.signalValue}")';
      statements.add(TopicStatement(
        label: 'Member case ${i + 1}',
        text: '${c.caseId} — ${c.caseName} (${c.year})$signal',
        sourceRefs: [c.caseId, topicId],
        provenance: 'p14:membership; p14:syllabusConfig.memberships',
      ));
    }
    return TopicSection(
      type: TopicSectionType.memberCases,
      title: TopicSectionType.memberCases.displayTitle,
      statements: List<TopicStatement>.unmodifiable(statements),
    );
  }

  TopicSection? _doctrinesSection(String topicId, List<String> memberIds) {
    final products = _composedDoctrines(topicId, memberIds);
    if (products.isEmpty) return null;
    final statements = <TopicStatement>[];
    for (var i = 0; i < products.length; i++) {
      final d = products[i];
      statements.add(TopicStatement(
        label: 'Doctrine ${i + 1}',
        text: '${d.doctrineName} (${d.doctrineId})',
        sourceRefs: [d.doctrineId, ...d.referencedIds],
        provenance: 'p12:DoctrineKnowledgeProduct',
      ));
    }
    return TopicSection(
      type: TopicSectionType.doctrines,
      title: TopicSectionType.doctrines.displayTitle,
      statements: List<TopicStatement>.unmodifiable(statements),
    );
  }

  TopicSection? _provisionsSection(String topicId, List<String> memberIds) {
    final products = _composedProvisions(topicId, memberIds);
    if (products.isEmpty) return null;
    final statements = <TopicStatement>[];
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      statements.add(TopicStatement(
        label: 'Provision ${i + 1}',
        text: '${p.provisionName} [${p.provisionType.displayTitle}]',
        sourceRefs: [p.provisionId, ...p.referencedIds],
        provenance: 'p13:StatuteKnowledgeProduct',
      ));
    }
    return TopicSection(
      type: TopicSectionType.provisions,
      title: TopicSectionType.provisions.displayTitle,
      statements: List<TopicStatement>.unmodifiable(statements),
    );
  }

  TopicSection? _chronologySection(List<String> memberIds) {
    if (memberIds.isEmpty) return null;
    final statements = <TopicStatement>[];
    for (var i = 0; i < memberIds.length; i++) {
      final c = _caseById[memberIds[i]]!;
      statements.add(TopicStatement(
        label: 'Member case ${i + 1}',
        text: '${c.year} — ${c.caseId} — ${c.caseName}',
        sourceRefs: [c.caseId],
        provenance: 'p10:chronology',
      ));
    }
    return TopicSection(
      type: TopicSectionType.chronology,
      title: TopicSectionType.chronology.displayTitle,
      statements: List<TopicStatement>.unmodifiable(statements),
    );
  }

  TopicSection? _structuralObservationsSection(
      String topicId, List<String> memberIds) {
    if (memberIds.isEmpty) return null;
    final cases = [for (final id in memberIds) _caseById[id]!];
    final subjects = <String>{
      for (final c in cases)
        for (final s in c.subjects) s,
    }.toList()
      ..sort();
    final areas = <String>{
      for (final c in cases)
        if (c.judgmentIntelligence?.upscIntelligence != null)
          for (final a
              in c.judgmentIntelligence!.upscIntelligence!.relatedSyllabusAreas)
            a.name,
    }.toList()
      ..sort();
    final years = cases.map((c) => c.year).toList()..sort();
    final statements = <TopicStatement>[
      TopicStatement(
        label: 'Member case count',
        text: '${memberIds.length}',
        sourceRefs: [topicId, 'p14:config.v1'],
        provenance: 'p14:syllabusConfig.memberships',
      ),
      if (years.isNotEmpty)
        TopicStatement(
          label: 'Time span',
          text: '${years.first}–${years.last} '
              '(${years.last - years.first} years)',
          sourceRefs: [topicId, 'p14:config.v1'],
          provenance: 'p14:syllabusConfig.memberships; p10:chronology',
        ),
      if (subjects.isNotEmpty)
        TopicStatement(
          label: 'Distinct subjects',
          text: subjects.join(', '),
          sourceRefs: [for (final c in cases) c.caseId],
          provenance: 'p3:subjects',
        ),
      if (areas.isNotEmpty)
        TopicStatement(
          label: 'Syllabus areas',
          text: areas.join(', '),
          sourceRefs: [for (final c in cases) c.caseId],
          provenance: 'p4:syllabusAreas',
        ),
      TopicStatement(
        label: 'Mapped signals',
        text: '${config.membershipsForTopic(topicId).length} explicit '
            'memberships',
        sourceRefs: [topicId, 'p14:config.v1'],
        provenance: 'p14:syllabusConfig.memberships',
      ),
    ];
    return TopicSection(
      type: TopicSectionType.structuralObservations,
      title: TopicSectionType.structuralObservations.displayTitle,
      statements: List<TopicStatement>.unmodifiable(statements),
    );
  }

  TopicSection? _upscRelevanceSection(List<String> memberIds) {
    final statements = <TopicStatement>[];
    for (var i = 0; i < memberIds.length; i++) {
      final c = _caseById[memberIds[i]]!;
      final u = c.judgmentIntelligence?.upscIntelligence;
      if (u == null || u.mainsThemes.isEmpty) continue;
      statements.add(TopicStatement(
        label: 'Member case ${i + 1}',
        text: u.mainsThemes.join('; '),
        sourceRefs: [c.caseId],
        provenance: 'p4:upscIntelligence.mainsThemes',
      ));
    }
    if (statements.isEmpty) return null;
    return TopicSection(
      type: TopicSectionType.upscRelevance,
      title: TopicSectionType.upscRelevance.displayTitle,
      statements: List<TopicStatement>.unmodifiable(statements),
    );
  }

  TopicSection? _evidenceSection(List<String> memberIds) {
    final statements = <TopicStatement>[];
    for (var i = 0; i < memberIds.length; i++) {
      final c = _caseById[memberIds[i]]!;
      if (c.evidenceIds.isEmpty) continue;
      final labels = [
        for (final ev in c.evidenceIds) _evidenceLabel(ev),
      ];
      statements.add(TopicStatement(
        label: 'Member case ${i + 1}',
        text: 'Evidence — ${c.caseId}: '
            '${c.evidenceIds.join(', ')}'
            '${labels.where((l) => l.isNotEmpty).isNotEmpty ? ' (${labels.where((l) => l.isNotEmpty).join(', ')})' : ''}',
        sourceRefs: [c.caseId, ...c.evidenceIds],
        provenance: 'corpus:evidenceIds; p14:membership',
      ));
    }
    if (statements.isEmpty) return null;
    return TopicSection(
      type: TopicSectionType.evidence,
      title: TopicSectionType.evidence.displayTitle,
      statements: List<TopicStatement>.unmodifiable(statements),
    );
  }

  // -------------------------------------------------------------------------
  // Composition helpers
  // -------------------------------------------------------------------------

  /// The first explicit membership of [caseId] in [topicId], in config order.
  TopicMembership? _firstMembership(String topicId, String caseId) {
    for (final m in config.membershipsForTopic(topicId)) {
      if (m.caseId == caseId) return m;
    }
    return null;
  }

  /// Deterministic chronological order of the member case IDs (P10 ordering:
  /// year asc, judgment date asc, name asc, ID asc). Position is never
  /// causation.
  List<String> _chronologicalOrder(List<String> caseIds) {
    if (caseIds.isEmpty) return const [];
    final analysis = analysisService.chronologicalAnalysis(caseIds);
    return List<String>.unmodifiable([
      for (final e in analysis.entries) e.caseId,
    ]);
  }

  /// One P11 [CaseExplanation] per member case, in the same chronological
  /// order as the topic's member cases. Reuses P11 directly.
  List<CaseExplanation> _explanationsFor(List<String> memberIds) {
    final out = <CaseExplanation>[];
    for (final cid in memberIds) {
      final ex = explanationService.explain(cid);
      if (ex != null) out.add(ex);
    }
    return List<CaseExplanation>.unmodifiable(out);
  }

  /// Doctrines composed into the topic under the strict all-members rule: a P12
  /// doctrine product appears only when every *constituent* case of the
  /// doctrine (the P5 case → doctrine edge members, via the P12 service's
  /// `doctrineMemberIds`) is already a topic member. A doctrine with no
  /// resolvable constituent cases is never composed. No invented doctrine
  /// membership.
  List<DoctrineKnowledgeProduct> _composedDoctrines(
      String topicId, List<String> memberIds) {
    final memberSet = memberIds.toSet();
    final out = <DoctrineKnowledgeProduct>[];
    for (final d in doctrineProductService.buildAll()) {
      final members =
          doctrineProductService.doctrineMemberIds[d.doctrineId] ?? const [];
      if (members.isEmpty) continue;
      final allMembers = members.every(memberSet.contains);
      if (allMembers) out.add(d);
    }
    out.sort((a, b) => a.doctrineId.compareTo(b.doctrineId));
    return List<DoctrineKnowledgeProduct>.unmodifiable(out);
  }

  /// Provisions composed into the topic under the strict all-members rule: a
  /// P13 statute product appears only when every *associated* case of the
  /// provision (the P3 corpus references, via the P13 service's
  /// `provisionRefMap`) is already a topic member. Reuses P13's provision
  /// mapping directly — no second statute mapping engine.
  List<StatuteKnowledgeProduct> _composedProvisions(
      String topicId, List<String> memberIds) {
    final memberSet = memberIds.toSet();
    final out = <StatuteKnowledgeProduct>[];
    for (final p in statuteProductService.buildAll()) {
      final refMap = statuteProductService.provisionRefMap[p.provisionType]
          ?[p.provisionId];
      if (refMap == null || refMap.isEmpty) continue;
      final associated = <String>{
        for (final ids in refMap.values) ...ids,
      };
      if (associated.isEmpty) continue;
      final allMembers = associated.every(memberSet.contains);
      if (allMembers) out.add(p);
    }
    out.sort((a, b) {
      final byType = a.provisionType.index.compareTo(b.provisionType.index);
      if (byType != 0) return byType;
      return a.provisionId.compareTo(b.provisionId);
    });
    return List<StatuteKnowledgeProduct>.unmodifiable(out);
  }

  /// Registry-resolved evidence label (P8 `EvidenceEntry`), or '' when the ID
  /// does not resolve.
  String _evidenceLabel(String evidenceId) {
    final entry = EvidenceEntry.fromId(evidenceId);
    return entry.typeLabel.isEmpty ? '' : '${entry.typeLabel}: ${entry.url}';
  }
}
