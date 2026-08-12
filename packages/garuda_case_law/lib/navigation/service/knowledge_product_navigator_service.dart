/// Knowledge Product Navigator service (TITAN-KO-015.0 P16).
///
/// A deterministic, offline-first **composition / read / navigation** layer that
/// navigates between the existing validated knowledge products (P11 case
/// explanations, P12 doctrine products, P13 statute products, P14 topic
/// products, P15 question products) through relationships that are already
/// explicitly supported by validated repository data.
///
/// P16 does NOT create a new graph, a new search engine, a new evidence
/// registry or a new legal relationship. It reuses the existing P5 graph
/// services and the existing P11–P15 product services, emitting only
/// [KnowledgeProductReference]s that trace to an existing validated source:
///
/// - **Case ↔ Case** — validated P5 `PrecedentGraphService` edges (direction,
///   type and edge identity preserved verbatim; incoming and outgoing exposed
///   explicitly).
/// - **Case ↔ Doctrine** — validated P5 `DoctrineRelationshipService` edges.
/// - **Case ↔ Provision** — the validated P3/P13 provision-association
///   mechanism (`StatuteKnowledgeProductService.provisionRefMap`); never a
///   fabricated P5 edge.
/// - **Case ↔ Topic** — the validated P14 topic-membership configuration
///   (pedagogical; never confused with legal precedent).
/// - **Question ↔ Source** — the P15 question product's own `sourceType` /
///   `sourceId`.
///
/// Every destination is resolved through the existing product services; a
/// destination that cannot currently be resolved is safely omitted (never
/// fabricated, never a placeholder). Output is deterministic: identical inputs
/// produce structurally identical collections, and the P5 graph is never
/// mutated (see `P16_KNOWLEDGE_PRODUCT_NAVIGATOR.md`).
library;

import 'package:garuda_acts/garuda_acts.dart' show ActKnowledgeObject;
import 'package:garuda_constitution/garuda_constitution.dart'
    show ArticleKnowledgeObject;
import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineKnowledgeObject, DoctrineSeedData;

import '../../data/case_seed_data.dart';
import '../../doctrine_product/service/doctrine_knowledge_product_service.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../../explanation/service/case_explanation_service.dart';
import '../../graph/data/legal_graph_seed.dart';
import '../../graph/domain/legal_graph.dart';
import '../../graph/service/doctrine_relationship_service.dart';
import '../../graph/service/precedent_graph_service.dart';
import '../../question_product/domain/question_knowledge_product.dart';
import '../../question_product/domain/question_product_enums.dart';
import '../../question_product/service/question_knowledge_product_service.dart';
import '../../statute_product/domain/statute_product_enums.dart'
    show ProvisionType;
import '../../statute_product/service/statute_knowledge_product_service.dart';
import '../../topic_product/domain/topic_identity.dart';
import '../../topic_product/domain/topic_membership.dart';
import '../../topic_product/service/topic_knowledge_product_service.dart';
import '../domain/knowledge_product_collection.dart';
import '../domain/knowledge_product_reference.dart';
import '../domain/knowledge_product_type.dart';
import '../domain/navigation_direction.dart';
import '../domain/navigation_relationship_type.dart';

/// Read-side navigator over the existing P11–P15 knowledge products.
class KnowledgeProductNavigatorService {
  final List<CaseKnowledgeObject> cases;
  final List<DoctrineKnowledgeObject> doctrines;
  final LegalGraph graph;
  final PrecedentGraphService precedentService;
  final DoctrineRelationshipService doctrineService;
  final CaseExplanationService explanationService;
  final DoctrineKnowledgeProductService doctrineProductService;
  final StatuteKnowledgeProductService statuteProductService;
  final TopicKnowledgeProductService topicProductService;
  final QuestionKnowledgeProductService questionProductService;

  final Map<String, CaseKnowledgeObject> _caseById;
  final Map<String, String> _doctrineNameById;

  /// Lazy cache of all P15 question products, keyed by product ID.
  List<QuestionKnowledgeProduct>? _allQuestions;

  /// Builds a navigator over the shared offline corpus/services. All inputs are
  /// optional and default to the canonical offline corpus, so the default
  /// constructor is deterministic and offline-first.
  factory KnowledgeProductNavigatorService({
    List<CaseKnowledgeObject>? cases,
    List<DoctrineKnowledgeObject>? doctrines,
    List<ArticleKnowledgeObject>? constitutionArticles,
    List<ActKnowledgeObject>? acts,
    LegalGraph? graph,
    PrecedentGraphService? precedentService,
    DoctrineRelationshipService? doctrineService,
    CaseExplanationService? explanationService,
    DoctrineKnowledgeProductService? doctrineProductService,
    StatuteKnowledgeProductService? statuteProductService,
    TopicKnowledgeProductService? topicProductService,
    QuestionKnowledgeProductService? questionProductService,
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
    final exp = explanationService ??
        CaseExplanationService(
          cases: corpus,
          graph: g,
          precedentService: ps,
          doctrineService: ds,
        );
    final dkps = doctrineProductService ??
        DoctrineKnowledgeProductService(
          cases: corpus,
          doctrines: doctrineRecords,
          graph: g,
          precedentService: ps,
          doctrineService: ds,
        );
    final skps = statuteProductService ??
        StatuteKnowledgeProductService(
          cases: corpus,
          doctrines: doctrineRecords,
          constitutionArticles: constitutionArticles,
          acts: acts,
          graph: g,
          precedentService: ps,
          doctrineService: ds,
        );
    final tkps = topicProductService ??
        TopicKnowledgeProductService(
          cases: corpus,
          doctrines: doctrineRecords,
          constitutionArticles: constitutionArticles,
          acts: acts,
          doctrineProductService: dkps,
          statuteProductService: skps,
        );
    final qkps = questionProductService ??
        QuestionKnowledgeProductService(
          cases: corpus,
          doctrines: doctrineRecords,
          constitutionArticles: constitutionArticles,
          acts: acts,
          graph: g,
          precedentService: ps,
          doctrineService: ds,
          doctrineProductService: dkps,
          statuteProductService: skps,
          topicProductService: tkps,
        );
    return KnowledgeProductNavigatorService._(
      cases: List<CaseKnowledgeObject>.unmodifiable(corpus),
      doctrines: List<DoctrineKnowledgeObject>.unmodifiable(doctrineRecords),
      graph: g,
      precedentService: ps,
      doctrineService: ds,
      explanationService: exp,
      doctrineProductService: dkps,
      statuteProductService: skps,
      topicProductService: tkps,
      questionProductService: qkps,
      caseById: {for (final c in corpus) c.caseId: c},
      doctrineNameById: {for (final d in doctrineRecords) d.doctrineId: d.name},
    );
  }

  KnowledgeProductNavigatorService._({
    required this.cases,
    required this.doctrines,
    required this.graph,
    required this.precedentService,
    required this.doctrineService,
    required this.explanationService,
    required this.doctrineProductService,
    required this.statuteProductService,
    required this.topicProductService,
    required this.questionProductService,
    required Map<String, CaseKnowledgeObject> caseById,
    required Map<String, String> doctrineNameById,
  })  : _caseById = caseById,
        _doctrineNameById = doctrineNameById;

  // -------------------------------------------------------------------------
  // Resolution
  // -------------------------------------------------------------------------

  /// Whether [idOrName] resolves to a validated corpus case.
  bool hasCase(String idOrName) => _caseId(idOrName) != null;

  /// Whether [idOrName] resolves to a canonical doctrine.
  bool hasDoctrine(String idOrName) =>
      doctrineProductService.hasDoctrine(idOrName);

  /// Whether [ref] resolves to a validated [type] provision.
  bool hasProvision(ProvisionType type, String ref) =>
      statuteProductService.hasProvision(type, ref);

  /// Whether [idOrName] resolves to a configured P14 topic.
  bool hasTopic(String idOrName) => topicProductService.hasTopic(idOrName);

  /// Resolves [idOrName] to a canonical case ID, or null when unknown.
  String? resolveCaseId(String idOrName) => _caseId(idOrName);

  /// Resolves [idOrName] to a canonical doctrine ID, or null when unknown.
  String? resolveDoctrineId(String idOrName) =>
      doctrineProductService.resolveDoctrineId(idOrName);

  /// Resolves [ref] to a canonical provision key, or null when unknown.
  String? resolveProvisionId(ProvisionType type, String ref) =>
      statuteProductService.resolveProvisionId(type, ref);

  /// Resolves [idOrName] to a configured [TopicIdentity], or null when unknown.
  TopicIdentity? resolveTopic(String idOrName) =>
      topicProductService.resolveTopic(idOrName);

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  /// All validated knowledge products reachable from a case: the case's own
  /// P11 explanation, its P5 precedent edges (incoming and outgoing), the P5
  /// doctrines it engages, the provisions it references (P3/P13), the topics it
  /// belongs to (P14) and its P15 question product.
  ///
  /// Returns an empty collection when [caseIdOrName] does not resolve.
  KnowledgeProductCollection findAllProductsForCase(String caseIdOrName) {
    final id = _caseId(caseIdOrName);
    if (id == null) return _empty(KnowledgeProductType.caseLaw);
    final c = _caseById[id]!;
    return KnowledgeProductCollection.fromReferences(
      originProductType: KnowledgeProductType.caseLaw,
      originProductId: id,
      refs: [
        _ref(
          originType: KnowledgeProductType.caseLaw,
          originId: id,
          toType: KnowledgeProductType.caseLaw,
          toId: c.caseId,
          toName: c.caseName,
          toYear: c.year,
          relationship: NavigationRelationshipType.primary,
          provenance: 'p16:primary:CaseExplanationService',
        ),
        ..._precedentRefs(id, KnowledgeProductType.caseLaw),
        ..._doctrineRefs(id, KnowledgeProductType.caseLaw),
        ..._provisionRefs(id, KnowledgeProductType.caseLaw),
        ..._topicRefs(id, KnowledgeProductType.caseLaw),
        ..._questionRef(questionProductService.buildForCase(id),
            KnowledgeProductType.caseLaw, id),
      ],
    );
  }

  /// All validated knowledge products reachable from a doctrine: the doctrine's
  /// own P12 product, its constituent cases (P5 reverse doctrine edges) and its
  /// P15 question product.
  ///
  /// Returns an empty collection when [doctrineIdOrName] does not resolve.
  KnowledgeProductCollection findAllProductsForDoctrine(
      String doctrineIdOrName) {
    final id = doctrineProductService.resolveDoctrineId(doctrineIdOrName);
    if (id == null) return _empty(KnowledgeProductType.doctrine);
    return KnowledgeProductCollection.fromReferences(
      originProductType: KnowledgeProductType.doctrine,
      originProductId: id,
      refs: [
        _ref(
          originType: KnowledgeProductType.doctrine,
          originId: id,
          toType: KnowledgeProductType.doctrine,
          toId: id,
          toName: _doctrineName(id),
          relationship: NavigationRelationshipType.primary,
          provenance: 'p16:primary:DoctrineKnowledgeProductService',
        ),
        ..._constituentCaseRefs(id),
        ..._questionRef(questionProductService.buildForDoctrine(id),
            KnowledgeProductType.doctrine, id),
      ],
    );
  }

  /// All validated knowledge products reachable from a provision: the
  /// provision's own P13 product, the cases that reference it (P3/P13) and its
  /// P15 question product.
  ///
  /// Returns an empty collection when the provision does not resolve.
  KnowledgeProductCollection findAllProductsForProvision(
      ProvisionType type, String ref) {
    final id = statuteProductService.resolveProvisionId(type, ref);
    if (id == null) return _empty(KnowledgeProductType.provision);
    return KnowledgeProductCollection.fromReferences(
      originProductType: KnowledgeProductType.provision,
      originProductId: id,
      refs: [
        _ref(
          originType: KnowledgeProductType.provision,
          originId: id,
          toType: KnowledgeProductType.provision,
          toId: id,
          toName: id,
          provisionType: type,
          relationship: NavigationRelationshipType.primary,
          provenance: 'p16:primary:StatuteKnowledgeProductService',
        ),
        ..._referencingCaseRefs(type, id),
        ..._questionRef(questionProductService.buildForStatute(type, id),
            KnowledgeProductType.provision, id),
      ],
    );
  }

  /// All validated knowledge products reachable from a topic: the topic's own
  /// P14 product, its member cases (P14) and its P15 question product.
  ///
  /// Returns an empty collection when [topicIdOrName] does not resolve.
  KnowledgeProductCollection findAllProductsForTopic(String topicIdOrName) {
    final id = topicProductService.resolveTopic(topicIdOrName)?.id;
    if (id == null) return _empty(KnowledgeProductType.topic);
    return KnowledgeProductCollection.fromReferences(
      originProductType: KnowledgeProductType.topic,
      originProductId: id,
      refs: [
        _ref(
          originType: KnowledgeProductType.topic,
          originId: id,
          toType: KnowledgeProductType.topic,
          toId: id,
          toName: _topicName(id),
          relationship: NavigationRelationshipType.primary,
          provenance: 'p16:primary:TopicKnowledgeProductService',
        ),
        ..._memberCaseRefs(id),
        ..._questionRef(questionProductService.buildForTopic(id),
            KnowledgeProductType.topic, id),
      ],
    );
  }

  /// Generalised navigation dispatch to the typed queries.
  ///
  /// For [KnowledgeProductType.provision], [provisionType] must be provided.
  KnowledgeProductCollection findAllProductsFor(
    KnowledgeProductType type,
    String id, {
    ProvisionType? provisionType,
  }) {
    switch (type) {
      case KnowledgeProductType.caseLaw:
        return findAllProductsForCase(id);
      case KnowledgeProductType.doctrine:
        return findAllProductsForDoctrine(id);
      case KnowledgeProductType.provision:
        return findAllProductsForProvision(
            provisionType ?? ProvisionType.article, id);
      case KnowledgeProductType.topic:
        return findAllProductsForTopic(id);
      case KnowledgeProductType.question:
        return findAllProductsForQuestion(id);
    }
  }

  /// All validated knowledge products reachable from a question product.
  KnowledgeProductCollection findAllProductsForQuestion(String productId) {
    final q = _questionByProductId(productId);
    if (q == null) return _empty(KnowledgeProductType.question);
    return KnowledgeProductCollection.fromReferences(
      originProductType: KnowledgeProductType.question,
      originProductId: q.productId,
      refs: [
        _ref(
          originType: KnowledgeProductType.question,
          originId: q.productId,
          toType: KnowledgeProductType.question,
          toId: q.productId,
          toName: q.sourceName,
          relationship: NavigationRelationshipType.primary,
          provenance: 'p16:primary:QuestionKnowledgeProductService',
        ),
        _ref(
          originType: KnowledgeProductType.question,
          originId: q.productId,
          toType: _sourceTypeFor(q),
          toId: q.sourceId,
          toName: q.sourceName,
          provisionType: _sourceProvisionType(q),
          relationship: NavigationRelationshipType.questionSource,
          direction: NavigationDirection.incoming,
          provenance: 'p15:questionProduct:${q.sourceType.name}',
          evidence: [q.productId],
        ),
      ],
    );
  }

  /// All navigation edges from the origin, excluding the origin's own primary
  /// product.
  ///
  /// Same as [findAllProductsFor] but drops the
  /// [NavigationRelationshipType.primary] root reference.
  KnowledgeProductCollection findRelatedProducts(
    KnowledgeProductType type,
    String id, {
    ProvisionType? provisionType,
  }) {
    final all = findAllProductsFor(type, id, provisionType: provisionType);
    return KnowledgeProductCollection.fromReferences(
      originProductType: all.originProductType,
      originProductId: all.originProductId,
      refs: all.references.where(
          (r) => r.relationshipType != NavigationRelationshipType.primary),
    );
  }

  /// Filters a collection to references of [relationship], preserving order.
  KnowledgeProductCollection navigateRelationship(
    KnowledgeProductCollection collection,
    NavigationRelationshipType relationship,
  ) =>
      KnowledgeProductCollection.fromReferences(
        originProductType: collection.originProductType,
        originProductId: collection.originProductId,
        refs: collection.references
            .where((r) => r.relationshipType == relationship),
      );

  // -------------------------------------------------------------------------
  // Product resolution
  // -------------------------------------------------------------------------

  /// Whether [ref] resolves to an actual existing knowledge product.
  bool resolvable(KnowledgeProductReference ref) => resolve(ref) != null;

  /// Resolves [ref] to the actual knowledge product produced by the P11–P15
  /// services, or null when the destination cannot currently be resolved.
  ///
  /// Never fabricates or constructs a placeholder.
  Object? resolve(KnowledgeProductReference ref) {
    switch (ref.toProductType) {
      case KnowledgeProductType.caseLaw:
        return explanationService.explain(ref.toProductId);
      case KnowledgeProductType.doctrine:
        return doctrineProductService.build(ref.toProductId);
      case KnowledgeProductType.provision:
        return statuteProductService.build(
            ref.provisionType ?? ProvisionType.article, ref.toProductId);
      case KnowledgeProductType.topic:
        return topicProductService.build(ref.toProductId);
      case KnowledgeProductType.question:
        return _questionByProductId(ref.toProductId);
    }
  }

  /// Resolves every reference in [collection], dropping any that no longer
  /// resolve. Deterministic order is preserved.
  List<Object> resolveAll(KnowledgeProductCollection collection) {
    final out = <Object>[];
    for (final r in collection.references) {
      final resolved = resolve(r);
      if (resolved != null) out.add(resolved);
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // Reference builders
  // -------------------------------------------------------------------------

  KnowledgeProductCollection _empty(KnowledgeProductType type) =>
      KnowledgeProductCollection.fromReferences(
        originProductType: type,
        originProductId: '',
        refs: const [],
      );

  /// The case → case P5 precedent edges (incoming and outgoing), with direction
  /// and P5 type preserved verbatim.
  List<KnowledgeProductReference> _precedentRefs(
      String caseId, KnowledgeProductType originType) {
    final out = <KnowledgeProductReference>[];
    for (final e in precedentService.outgoingRelationships(caseId)) {
      final target = _caseById[e.targetId];
      if (target == null) continue; // never emit a non-corpus case
      out.add(_ref(
        originType: originType,
        originId: caseId,
        toType: KnowledgeProductType.caseLaw,
        toId: target.caseId,
        toName: target.caseName,
        toYear: target.year,
        relationship: NavigationRelationshipType.precedent,
        specificTypeLabel: e.typeLabel,
        direction: NavigationDirection.outgoing,
        provenance: e.provenance,
        evidence: [e.edgeId, ...e.evidenceIds],
      ));
    }
    for (final e in precedentService.incomingRelationships(caseId)) {
      final source = _caseById[e.sourceId];
      if (source == null) continue;
      out.add(_ref(
        originType: originType,
        originId: caseId,
        toType: KnowledgeProductType.caseLaw,
        toId: source.caseId,
        toName: source.caseName,
        toYear: source.year,
        relationship: NavigationRelationshipType.precedent,
        specificTypeLabel: e.typeLabel,
        direction: NavigationDirection.incoming,
        provenance: e.provenance,
        evidence: [e.edgeId, ...e.evidenceIds],
      ));
    }
    return out;
  }

  /// The P5 case → doctrine edges for a case (outgoing from the case).
  List<KnowledgeProductReference> _doctrineRefs(
          String caseId, KnowledgeProductType originType) =>
      [
        for (final e in doctrineService.getDoctrinesForCase(caseId))
          _ref(
            originType: originType,
            originId: caseId,
            toType: KnowledgeProductType.doctrine,
            toId: e.targetId,
            toName: _doctrineName(e.targetId),
            relationship: NavigationRelationshipType.engagesDoctrine,
            specificTypeLabel: e.typeLabel,
            direction: NavigationDirection.outgoing,
            provenance: e.provenance,
            evidence: [e.edgeId, ...e.evidenceIds],
          ),
      ];

  /// The provisions a case references, from the validated P3/P13
  /// provision-association map. Never a fabricated P5 edge.
  List<KnowledgeProductReference> _provisionRefs(
      String caseId, KnowledgeProductType originType) {
    final out = <KnowledgeProductReference>[];
    for (final type in ProvisionType.values) {
      final byKey = statuteProductService.provisionRefMap[type];
      if (byKey == null) continue;
      for (final entry in byKey.entries) {
        final key = entry.key;
        // rawRef -> caseIds; the case must genuinely carry one of these refs.
        final carried = entry.value.entries
            .where((e) => e.value.contains(caseId))
            .map((e) => e.key)
            .toList();
        if (carried.isEmpty) continue;
        carried.sort();
        out.add(_ref(
          originType: originType,
          originId: caseId,
          toType: KnowledgeProductType.provision,
          toId: key,
          toName: carried.first,
          provisionType: type,
          relationship: NavigationRelationshipType.referencesProvision,
          direction: NavigationDirection.outgoing,
          provenance: 'p13:provisionRefMap',
          evidence: [carried.first],
        ));
      }
    }
    return out;
  }

  /// The P14 topics a case belongs to (pedagogical, never legal).
  List<KnowledgeProductReference> _topicRefs(
      String caseId, KnowledgeProductType originType) {
    final byTopic = <String, List<TopicMembership>>{};
    for (final m in topicProductService.membershipsForCase(caseId)) {
      byTopic.putIfAbsent(m.topicId, () => []).add(m);
    }
    return [
      for (final t in topicProductService.topicForCase(caseId))
        _ref(
          originType: originType,
          originId: caseId,
          toType: KnowledgeProductType.topic,
          toId: t.id,
          toName: t.name,
          relationship: NavigationRelationshipType.topicMembership,
          direction: NavigationDirection.outgoing,
          provenance: 'p14:membership',
          evidence: [
            for (final m in byTopic[t.id] ?? const <TopicMembership>[])
              '${m.signalField}:${m.signalValue}',
          ],
        ),
    ];
  }

  /// The P15 question product for a source, as a single outgoing reference.
  ///
  /// [q] is resolved by the caller against the matching P15 builder
  /// (buildForCase / buildForDoctrine / buildForStatute / buildForTopic), so the
  /// question ↔ source relationship always uses the P15 product's own source.
  /// Returns no reference when the source has no resolvable question product
  /// (missing product → omitted, never fabricated).
  List<KnowledgeProductReference> _questionRef(QuestionKnowledgeProduct? q,
      KnowledgeProductType originType, String originId) {
    if (q == null) return const [];
    return [
      _ref(
        originType: originType,
        originId: originId,
        toType: KnowledgeProductType.question,
        toId: q.productId,
        toName: q.sourceName,
        relationship: NavigationRelationshipType.questionSource,
        direction: NavigationDirection.outgoing,
        provenance: 'p15:questionProduct',
        evidence: [q.productId],
      ),
    ];
  }

  /// The reverse case → doctrine edges for a doctrine (its constituent cases).
  List<KnowledgeProductReference> _constituentCaseRefs(String doctrineId) => [
        for (final e in doctrineService.getCasesForDoctrine(doctrineId))
          _ref(
            originType: KnowledgeProductType.doctrine,
            originId: doctrineId,
            toType: KnowledgeProductType.caseLaw,
            toId: e.sourceId,
            toName: _caseName(e.sourceId),
            toYear: _caseYear(e.sourceId),
            relationship: NavigationRelationshipType.engagesDoctrine,
            specificTypeLabel: e.typeLabel,
            direction: NavigationDirection.incoming,
            provenance: e.provenance,
            evidence: [e.edgeId, ...e.evidenceIds],
          ),
      ];

  /// The cases that reference a provision (reverse of the P3/P13 map).
  List<KnowledgeProductReference> _referencingCaseRefs(
      ProvisionType type, String key) {
    final caseIds = <String>{
      for (final e in (statuteProductService.provisionRefMap[type]?[key] ??
              const <String, List<String>>{})
          .entries)
        ...e.value,
    };
    return [
      for (final id in caseIds)
        if (_caseById[id] != null)
          _ref(
            originType: KnowledgeProductType.provision,
            originId: key,
            toType: KnowledgeProductType.caseLaw,
            toId: id,
            toName: _caseName(id),
            toYear: _caseYear(id),
            relationship: NavigationRelationshipType.referencesProvision,
            direction: NavigationDirection.incoming,
            provenance: 'p13:provisionRefMap',
            evidence: [key],
          ),
    ];
  }

  /// The P14 member cases of a topic.
  List<KnowledgeProductReference> _memberCaseRefs(String topicId) => [
        for (final id in topicProductService.config.memberCaseIdsFor(topicId))
          if (_caseById[id] != null)
            _ref(
              originType: KnowledgeProductType.topic,
              originId: topicId,
              toType: KnowledgeProductType.caseLaw,
              toId: id,
              toName: _caseName(id),
              toYear: _caseYear(id),
              relationship: NavigationRelationshipType.topicMembership,
              direction: NavigationDirection.incoming,
              provenance: 'p14:membership',
            ),
      ];

  KnowledgeProductReference _ref({
    required KnowledgeProductType originType,
    required String originId,
    required KnowledgeProductType toType,
    required String toId,
    required String toName,
    ProvisionType? provisionType,
    required NavigationRelationshipType relationship,
    String specificTypeLabel = '',
    NavigationDirection? direction,
    required String provenance,
    List<String>? evidence,
    int? toYear,
  }) =>
      KnowledgeProductReference(
        originProductType: originType,
        originProductId: originId,
        toProductType: toType,
        toProductId: toId,
        toProductName: toName,
        provisionType: provisionType,
        relationshipType: relationship,
        specificTypeLabel: specificTypeLabel,
        direction: direction,
        provenance: provenance,
        evidenceRefs: List<String>.unmodifiable(evidence ?? const []),
        toProductYear: toYear,
      );

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String? _caseId(String idOrName) {
    final q = idOrName.trim();
    if (_caseById.containsKey(q)) return q;
    final norm = q.toLowerCase();
    for (final c in cases) {
      if (c.caseId.toLowerCase() == norm) return c.caseId;
      if (c.caseName.toLowerCase() == norm) return c.caseId;
      for (final a in c.aliases) {
        if (a.toLowerCase() == norm) return c.caseId;
      }
    }
    return null;
  }

  String _caseName(String id) => _caseById[id]?.caseName ?? id;

  int? _caseYear(String id) => _caseById[id]?.year;

  String _doctrineName(String id) => _doctrineNameById[id] ?? id;

  String _topicName(String id) =>
      topicProductService.resolveTopic(id)?.name ?? id;

  KnowledgeProductType _sourceTypeFor(QuestionKnowledgeProduct q) =>
      switch (q.sourceType) {
        QuestionSourceType.caseLaw => KnowledgeProductType.caseLaw,
        QuestionSourceType.doctrine => KnowledgeProductType.doctrine,
        QuestionSourceType.statute => KnowledgeProductType.provision,
        QuestionSourceType.topic => KnowledgeProductType.topic,
      };

  ProvisionType? _sourceProvisionType(QuestionKnowledgeProduct q) {
    if (q.sourceType != QuestionSourceType.statute) return null;
    for (final type in ProvisionType.values) {
      if (statuteProductService.hasProvision(type, q.sourceId)) return type;
    }
    return null;
  }

  QuestionKnowledgeProduct? _questionByProductId(String productId) {
    _allQuestions ??= questionProductService.buildAll();
    for (final q in _allQuestions!) {
      if (q.productId == productId) return q;
    }
    return null;
  }
}
