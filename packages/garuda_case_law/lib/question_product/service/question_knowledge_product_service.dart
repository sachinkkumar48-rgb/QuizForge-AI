/// P15 Evidence-Backed Question-Answer Knowledge Product service
/// (TITAN-KO-015.0 P15).
///
/// A deterministic, offline-first knowledge-product composition layer that
/// transforms existing validated GARUDA Case Law knowledge into structured,
/// educational, provenance-preserving [QuestionKnowledgeProduct]s.
///
/// P15 is an ACTIVE-LEARNING knowledge-product layer, NOT a quiz engine, NOT an
/// AI question generator, NOT an interactive UI and NOT an assessment/grading
/// system. It never invents a question, never performs legal research and never
/// gives legal advice. Every question is derived deterministically from an
/// explicit validated source and every answer is composed only from already
/// validated P4 intelligence or P11–P14 knowledge products:
///
/// - **Issue-based** — P4 `JudgmentIssue` of a case (source hierarchy: P4
///   intelligence, no fallback that invents content).
/// - **Principle-based** — explicit P4 `JudgmentHolding.legalPrinciple`.
/// - **Doctrine-based** — the P12 `DoctrineKnowledgeProduct` re-presented
///   (recorded doctrine overview, recorded constituent cases).
/// - **Statute-based** — the P13 `StatuteKnowledgeProduct` re-presented
///   (provision kind, recorded overview, referenced cases).
/// - **Topic-based** — the P14 `TopicKnowledgeProduct` re-presented (editorial
///   topic overview, member cases, syllabus area).
///
/// Related cases on case questions come ONLY from explicit P5 `related` edges
/// (never called "similar"; never inferred from topic membership, chronology or
/// apparent relevance). Missing information produces an omitted question, never
/// a fabricated one. Output is deterministic: identical corpus + identical
/// services produce byte-identical serialized output (see
/// `P15_QUESTION_KNOWLEDGE_PRODUCT.md`).
library;

import 'package:garuda_acts/garuda_acts.dart' show ActKnowledgeObject;
import 'package:garuda_constitution/garuda_constitution.dart'
    show ArticleKnowledgeObject;
import 'package:garuda_doctrine/garuda_doctrine.dart'
    show DoctrineKnowledgeObject, DoctrineSeedData;
import 'package:meta/meta.dart';

import '../../data/case_seed_data.dart';
import '../../domain/entities/case_knowledge_object.dart';
import '../../doctrine_product/domain/doctrine_knowledge_product.dart';
import '../../doctrine_product/domain/doctrine_product_enums.dart'
    show DoctrineSectionType;
import '../../doctrine_product/service/doctrine_knowledge_product_service.dart';
import '../../graph/data/legal_graph_seed.dart';
import '../../graph/domain/legal_graph.dart';
import '../../graph/service/doctrine_relationship_service.dart';
import '../../graph/service/legal_graph_traversal_service.dart';
import '../../graph/service/precedent_graph_service.dart';
import '../../intelligence/domain/judgment_intelligence.dart'
    show JudgmentHolding, JudgmentIssue;
import '../../search/data/case_search_normalizer.dart';
import '../../statute_product/domain/statute_knowledge_product.dart';
import '../../statute_product/domain/statute_product_enums.dart'
    show ProvisionType, ProvisionTypeExtension, StatuteSectionType;
import '../../statute_product/service/statute_knowledge_product_service.dart';
import '../../topic_product/domain/topic_knowledge_product.dart';
import '../../topic_product/domain/topic_product_enums.dart'
    show TopicSectionType;
import '../../topic_product/service/topic_knowledge_product_service.dart';
import '../domain/legal_question.dart';
import '../domain/question_knowledge_product.dart';
import '../domain/question_product_enums.dart';
import '../domain/structured_answer.dart';

/// Builds evidence-backed question-answer knowledge products by deterministically
/// composing existing validated P4/P11–P14 data. No legal research is performed.
@immutable
class QuestionKnowledgeProductService {
  /// The full validated corpus this service reads from.
  final List<CaseKnowledgeObject> cases;

  /// The P5 legal graph snapshot (never modified).
  final LegalGraph graph;

  /// P5 precedent-graph read side (case → case edges; related cases).
  final PrecedentGraphService precedentService;

  /// P12 doctrine-product service (doctrine composition).
  final DoctrineKnowledgeProductService doctrineProductService;

  /// P13 statute-product service (provision composition).
  final StatuteKnowledgeProductService statuteProductService;

  /// P14 topic-product service (topic composition).
  final TopicKnowledgeProductService topicProductService;

  /// caseId → validated corpus record.
  final Map<String, CaseKnowledgeObject> _caseById;

  /// Deterministic educational framing surfaced on every question.
  static const String framing =
      'Historical / educational case-law information, not legal advice.';

  /// Builds a service over the shared corpus/services. All inputs are optional
  /// and default to the canonical offline corpus, so the default constructor is
  /// deterministic and offline-first.
  factory QuestionKnowledgeProductService({
    List<CaseKnowledgeObject>? cases,
    List<DoctrineKnowledgeObject>? doctrines,
    List<ArticleKnowledgeObject>? constitutionArticles,
    List<ActKnowledgeObject>? acts,
    LegalGraph? graph,
    PrecedentGraphService? precedentService,
    DoctrineRelationshipService? doctrineService,
    LegalGraphTraversalService? traversalService,
    DoctrineKnowledgeProductService? doctrineProductService,
    StatuteKnowledgeProductService? statuteProductService,
    TopicKnowledgeProductService? topicProductService,
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
    final dkps = doctrineProductService ??
        DoctrineKnowledgeProductService(
          cases: corpus,
          doctrines: doctrineRecords,
          graph: g,
          precedentService: ps,
          doctrineService: ds,
          traversalService: ts,
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
          traversalService: ts,
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
    final byId = {for (final c in corpus) c.caseId: c};
    return QuestionKnowledgeProductService._(
      cases: List<CaseKnowledgeObject>.unmodifiable(corpus),
      graph: g,
      precedentService: ps,
      doctrineProductService: dkps,
      statuteProductService: skps,
      topicProductService: tkps,
      caseById: Map<String, CaseKnowledgeObject>.unmodifiable(byId),
    );
  }

  const QuestionKnowledgeProductService._({
    required this.cases,
    required this.graph,
    required this.precedentService,
    required this.doctrineProductService,
    required this.statuteProductService,
    required this.topicProductService,
    required Map<String, CaseKnowledgeObject> caseById,
  }) : _caseById = caseById;

  // -------------------------------------------------------------------------
  // Resolution
  // -------------------------------------------------------------------------

  /// Whether [idOrName] resolves to a validated corpus case.
  bool hasCase(String idOrName) => _resolveCaseId(idOrName) != null;

  /// Whether [idOrName] resolves to a canonical doctrine.
  bool hasDoctrine(String idOrName) =>
      doctrineProductService.hasDoctrine(idOrName);

  /// Whether [ref] resolves to a validated [type] provision in the corpus.
  bool hasProvision(ProvisionType type, String ref) =>
      statuteProductService.hasProvision(type, ref);

  /// Whether [idOrName] resolves to a canonical topic.
  bool hasTopic(String idOrName) => topicProductService.hasTopic(idOrName);

  /// Resolves [idOrName] to a canonical corpus case ID (by canonical ID, by
  /// normalized case name, or by normalized alias), or null when unknown.
  ///
  /// Mirrors P11/P12 case resolution; no case is ever fabricated.
  String? resolveCaseId(String idOrName) => _resolveCaseId(idOrName);

  String? _resolveCaseId(String idOrName) {
    final q = idOrName.trim();
    if (q.isEmpty) return null;
    if (_caseById.containsKey(q)) return q;
    final norm = CaseSearchNormalizer.normalizeText(q);
    if (norm.isEmpty) return null;
    for (final c in cases) {
      if (CaseSearchNormalizer.normalizeText(c.caseName) == norm) {
        return c.caseId;
      }
      for (final a in c.aliases) {
        if (CaseSearchNormalizer.normalizeText(a) == norm) return c.caseId;
      }
    }
    return null;
  }

  CaseKnowledgeObject? _caseRecord(String caseId) => _caseById[caseId];

  // -------------------------------------------------------------------------
  // Product building — per source type
  // -------------------------------------------------------------------------

  /// Builds the question-answer product for one case (issue + principle
  /// questions from P4), or null when [idOrName] does not resolve or the case
  /// yields no eligible questions.
  QuestionKnowledgeProduct? buildForCase(String idOrName) {
    final id = _resolveCaseId(idOrName);
    if (id == null) return null;
    final c = _caseRecord(id)!;
    final questions = _caseQuestions(id, c);
    if (questions.isEmpty) return null;
    return QuestionKnowledgeProduct(
      productId: 'qa:case:$id',
      sourceType: QuestionSourceType.caseLaw,
      sourceId: id,
      sourceName: c.caseName,
      questions: List<LegalQuestion>.unmodifiable(questions),
    );
  }

  /// Builds the question-answer product for one doctrine, or null when
  /// [idOrName] does not resolve or the doctrine yields no eligible questions.
  QuestionKnowledgeProduct? buildForDoctrine(String idOrName) {
    final id = doctrineProductService.resolveDoctrineId(idOrName);
    if (id == null) return null;
    final p = doctrineProductService.build(id);
    if (p == null) return null;
    final questions = _doctrineQuestions(p);
    if (questions.isEmpty) return null;
    return QuestionKnowledgeProduct(
      productId: 'qa:doctrine:$id',
      sourceType: QuestionSourceType.doctrine,
      sourceId: id,
      sourceName: p.doctrineName,
      questions: List<LegalQuestion>.unmodifiable(questions),
    );
  }

  /// Builds the question-answer product for one provision, or null when [ref]
  /// does not resolve as a [type] provision or yields no eligible questions.
  QuestionKnowledgeProduct? buildForStatute(ProvisionType type, String ref) {
    final id = statuteProductService.resolveProvisionId(type, ref);
    if (id == null) return null;
    final p = statuteProductService.build(type, id);
    if (p == null) return null;
    final questions = _statuteQuestions(p);
    if (questions.isEmpty) return null;
    return QuestionKnowledgeProduct(
      productId: 'qa:statute:${type.name}:$id',
      sourceType: QuestionSourceType.statute,
      sourceId: id,
      sourceName: p.provisionName,
      questions: List<LegalQuestion>.unmodifiable(questions),
    );
  }

  /// Builds the question-answer product for one topic, or null when [idOrName]
  /// does not resolve or the topic yields no eligible questions.
  QuestionKnowledgeProduct? buildForTopic(String idOrName) {
    final identity = topicProductService.resolveTopic(idOrName);
    if (identity == null) return null;
    final p = topicProductService.build(identity.id);
    if (p == null) return null;
    final questions = _topicQuestions(p);
    if (questions.isEmpty) return null;
    return QuestionKnowledgeProduct(
      productId: 'qa:topic:${identity.id}',
      sourceType: QuestionSourceType.topic,
      sourceId: identity.id,
      sourceName: p.topicName,
      questions: List<LegalQuestion>.unmodifiable(questions),
    );
  }

  /// Builds the question-answer product for every eligible source over the
  /// corpus, in fixed deterministic order: cases (corpus order), then
  /// doctrines (canonical record order), then provisions (type order then key
  /// ascending), then topics (ID ascending). Sources that yield no eligible
  /// questions are omitted.
  List<QuestionKnowledgeProduct> buildAll() {
    final out = <QuestionKnowledgeProduct>[];
    for (final c in cases) {
      final p = buildForCase(c.caseId);
      if (p != null) out.add(p);
    }
    for (final id in doctrineProductService.doctrineIds) {
      final p = buildForDoctrine(id);
      if (p != null) out.add(p);
    }
    for (final type in ProvisionType.values) {
      for (final id in statuteProductService.provisionIds(type)) {
        final p = buildForStatute(type, id);
        if (p != null) out.add(p);
      }
    }
    for (final identity in topicProductService.topics) {
      final p = buildForTopic(identity.id);
      if (p != null) out.add(p);
    }
    return List<QuestionKnowledgeProduct>.unmodifiable(out);
  }

  // -------------------------------------------------------------------------
  // Case questions (P4)
  // -------------------------------------------------------------------------

  List<LegalQuestion> _caseQuestions(String id, CaseKnowledgeObject c) {
    final out = <LegalQuestion>[];
    final related = _relatedCaseIds(id);
    final intel = c.judgmentIntelligence;

    final issues = intel?.issues ?? const <JudgmentIssue>[];
    final multiIssue = issues.length > 1;
    for (var i = 0; i < issues.length; i++) {
      final issue = issues[i];
      final text = issue.issue.trim();
      if (text.isEmpty) continue; // missing data → omitted question
      final ordinal = multiIssue ? ' (${i + 1} of ${issues.length})' : '';
      out.add(LegalQuestion(
        questionId: 'qa:case:$id:issue:$i',
        questionText:
            'In ${c.caseName} (${c.year}), what legal issue did the Court '
            'consider?$ordinal',
        questionType: LegalQuestionType.issue,
        sourceRefs: [id, issue.issueId],
        answer: StructuredAnswer(
          answerText: text,
          evidenceRefs: [id, issue.issueId],
          relatedCaseIds: related,
          provenance: 'p4:issues',
        ),
        provenance: 'p4:issues',
        framing: framing,
      ));
    }

    final holdings = intel?.holdings ?? const <JudgmentHolding>[];
    final principles = <JudgmentHolding>[
      for (final h in holdings)
        if (h.legalPrinciple.trim().isNotEmpty) h,
    ];
    final multiPrinciple = principles.length > 1;
    for (var i = 0; i < principles.length; i++) {
      final h = principles[i];
      final ordinal =
          multiPrinciple ? ' (${i + 1} of ${principles.length})' : '';
      final refs = <String>[id, h.holdingId];
      if (h.evidence.evidenceId.trim().isNotEmpty) {
        refs.add(h.evidence.evidenceId);
      }
      out.add(LegalQuestion(
        questionId: 'qa:case:$id:principle:$i',
        questionText:
            'In ${c.caseName} (${c.year}), what legal principle did the Court '
            'state?$ordinal',
        questionType: LegalQuestionType.principle,
        sourceRefs: [id, h.holdingId],
        answer: StructuredAnswer(
          answerText: h.legalPrinciple.trim(),
          evidenceRefs: List<String>.unmodifiable(refs),
          relatedCaseIds: related,
          principles: [h.holding.trim()],
          provenance: 'p4:holdings.legalPrinciple',
        ),
        provenance: 'p4:holdings.legalPrinciple',
        framing: framing,
      ));
    }

    return out;
  }

  /// Explicit P5 `related` case IDs for [caseId], sorted and de-duplicated.
  ///
  /// Only explicit P5 related edges are used; the relationship is never
  /// labelled "similar" and never inferred.
  List<String> _relatedCaseIds(String caseId) {
    final out = <String>[];
    final seen = <String>{};
    for (final e in precedentService.relatedCases(caseId)) {
      final other = e.sourceId == caseId ? e.targetId : e.sourceId;
      if (other != caseId && seen.add(other)) out.add(other);
    }
    out.sort();
    return List<String>.unmodifiable(out);
  }

  // -------------------------------------------------------------------------
  // Doctrine questions (P12)
  // -------------------------------------------------------------------------

  List<LegalQuestion> _doctrineQuestions(DoctrineKnowledgeProduct p) {
    final out = <LegalQuestion>[];
    final id = p.doctrineId;

    final summary =
        _doctrineLabelText(p, DoctrineSectionType.overview, 'One-line summary');
    final definition = _doctrineLabelText(
        p, DoctrineSectionType.overview, 'Official definition');
    final overview = summary.trim().isNotEmpty ? summary : definition.trim();
    if (overview.isNotEmpty) {
      out.add(LegalQuestion(
        questionId: 'qa:doctrine:$id:definition',
        questionText: 'What is the doctrine ${p.doctrineName}?',
        questionType: LegalQuestionType.doctrine,
        sourceRefs: [id],
        answer: StructuredAnswer(
          answerText: overview,
          evidenceRefs: [id],
          provenance: 'p12:DoctrineKnowledgeProduct.overview',
        ),
        provenance: 'p12:DoctrineKnowledgeProduct.overview',
        framing: framing,
      ));
    }

    final memberIds =
        doctrineProductService.doctrineMemberIds[id] ?? const <String>[];
    final memberTexts =
        _doctrineSectionTexts(p, DoctrineSectionType.constituentCases);
    if (memberTexts.isNotEmpty) {
      out.add(LegalQuestion(
        questionId: 'qa:doctrine:$id:constituent-cases',
        questionText:
            'Which cases are recorded as constituent cases of the doctrine '
            '${p.doctrineName}?',
        questionType: LegalQuestionType.doctrine,
        sourceRefs: [id, ...memberIds],
        answer: StructuredAnswer(
          answerText: memberTexts.join('\n'),
          evidenceRefs: List<String>.unmodifiable([id, ...memberIds]),
          provenance: 'p5:caseDoctrineEdges; p10:doctrineAnalysis',
        ),
        provenance: 'p5:caseDoctrineEdges; p10:doctrineAnalysis',
        framing: framing,
      ));
    }

    return out;
  }

  // -------------------------------------------------------------------------
  // Statute questions (P13)
  // -------------------------------------------------------------------------

  List<LegalQuestion> _statuteQuestions(StatuteKnowledgeProduct p) {
    final out = <LegalQuestion>[];
    final id = p.provisionId;
    final name = p.provisionName.trim().isNotEmpty ? p.provisionName : id;

    // Provision kind — always supported by the validated provision type.
    out.add(LegalQuestion(
      questionId: 'qa:statute:${p.provisionType.name}:$id:kind',
      questionText: 'What kind of provision is $name?',
      questionType: LegalQuestionType.statute,
      sourceRefs: [id],
      answer: StructuredAnswer(
        answerText: p.provisionType.displayTitle,
        evidenceRefs: [id],
        provenance: 'p13:StatuteKnowledgeProduct.identity',
      ),
      provenance: 'p13:StatuteKnowledgeProduct.identity',
      framing: framing,
    ));

    // Referenced cases — from the P13 associated-cases section.
    final refs = _corpusCaseIds(p.referencedIds);
    final associatedTexts =
        _statuteSectionTexts(p, StatuteSectionType.associatedCases);
    if (associatedTexts.isNotEmpty) {
      out.add(LegalQuestion(
        questionId: 'qa:statute:${p.provisionType.name}:$id:associated-cases',
        questionText: 'Which validated corpus cases reference $name?',
        questionType: LegalQuestionType.statute,
        sourceRefs: List<String>.unmodifiable([id, ...refs]),
        answer: StructuredAnswer(
          answerText: associatedTexts.join('\n'),
          evidenceRefs: List<String>.unmodifiable([id, ...refs]),
          provenance: 'p13:StatuteKnowledgeProduct.associatedCases',
        ),
        provenance: 'p13:StatuteKnowledgeProduct.associatedCases',
        framing: framing,
      ));
    }

    // Provision overview — only when a recorded official title/name exists.
    final officialTitle =
        _statuteLabelText(p, StatuteSectionType.overview, 'Official title');
    final officialName =
        _statuteLabelText(p, StatuteSectionType.overview, 'Official name');
    final title =
        officialTitle.trim().isNotEmpty ? officialTitle : officialName.trim();
    if (title.isNotEmpty) {
      out.add(LegalQuestion(
        questionId: 'qa:statute:${p.provisionType.name}:$id:definition',
        questionText: 'What is $name?',
        questionType: LegalQuestionType.statute,
        sourceRefs: [id],
        answer: StructuredAnswer(
          answerText: title,
          evidenceRefs: [id],
          provenance: 'p13:StatuteKnowledgeProduct.overview',
        ),
        provenance: 'p13:StatuteKnowledgeProduct.overview',
        framing: framing,
      ));
    }

    return out;
  }

  // -------------------------------------------------------------------------
  // Topic questions (P14)
  // -------------------------------------------------------------------------

  List<LegalQuestion> _topicQuestions(TopicKnowledgeProduct p) {
    final out = <LegalQuestion>[];
    final id = p.topicId;

    final overview =
        _topicLabelText(p, TopicSectionType.overview, 'Topic overview');
    if (overview.trim().isNotEmpty) {
      out.add(LegalQuestion(
        questionId: 'qa:topic:$id:overview',
        questionText: 'What is the topic ${p.topicName} about?',
        questionType: LegalQuestionType.topic,
        sourceRefs: [id],
        answer: StructuredAnswer(
          answerText: overview.trim(),
          evidenceRefs: [id],
          provenance: 'p14:syllabusConfig.overview',
        ),
        provenance: 'p14:syllabusConfig.overview',
        framing: framing,
      ));
    }

    final memberTexts = _topicSectionTexts(p, TopicSectionType.memberCases);
    if (memberTexts.isNotEmpty) {
      final refs = _corpusCaseIds(p.referencedIds);
      out.add(LegalQuestion(
        questionId: 'qa:topic:$id:member-cases',
        questionText: 'Which cases are members of the topic ${p.topicName}?',
        questionType: LegalQuestionType.topic,
        sourceRefs: List<String>.unmodifiable([id, ...refs]),
        answer: StructuredAnswer(
          answerText: memberTexts.join('\n'),
          evidenceRefs: List<String>.unmodifiable([id, ...refs]),
          provenance: 'p14:membership',
        ),
        provenance: 'p14:membership',
        framing: framing,
      ));
    }

    final area = _topicLabelText(p, TopicSectionType.identity, 'Syllabus area');
    if (area.trim().isNotEmpty) {
      out.add(LegalQuestion(
        questionId: 'qa:topic:$id:syllabus-area',
        questionText: 'What syllabus area does the topic ${p.topicName} fall '
            'under?',
        questionType: LegalQuestionType.topic,
        sourceRefs: [id],
        answer: StructuredAnswer(
          answerText: area.trim(),
          evidenceRefs: [id],
          provenance: 'p4:syllabusAreas',
        ),
        provenance: 'p4:syllabusAreas',
        framing: framing,
      ));
    }

    return out;
  }

  // -------------------------------------------------------------------------
  // Referenced case resolution
  // -------------------------------------------------------------------------

  /// Canonical corpus case IDs referenced by [product], sorted and
  /// de-duplicated.
  ///
  /// Statement references also carry non-case identifiers (doctrine IDs,
  /// provision keys, holding/issue IDs, evidence IDs); only identifiers that
  /// resolve to a validated corpus case are returned here, so the result never
  /// fabricates a case ID.
  List<String> referencedCaseIds(QuestionKnowledgeProduct product) =>
      _corpusCaseIds(product.referencedIds);

  /// Filters raw canonical identifiers to those that resolve to a validated
  /// corpus case, sorted and de-duplicated. Never fabricates a case ID.
  List<String> _corpusCaseIds(Iterable<String> refs) {
    final corpus = {for (final c in cases) c.caseId};
    final seen = <String>{};
    final out = <String>[];
    for (final id in refs) {
      if (corpus.contains(id) && seen.add(id)) out.add(id);
    }
    out.sort();
    return List<String>.unmodifiable(out);
  }

  /// Case IDs referenced by [product] other than the product's own source ID
  /// (for a case product, the source case itself is excluded), sorted.
  List<String> otherCaseIds(QuestionKnowledgeProduct product) {
    final all = referencedCaseIds(product);
    return List<String>.unmodifiable(
        all.where((id) => id != product.sourceId).toList()..sort());
  }

  // -------------------------------------------------------------------------
  // Product-section readers
  // -------------------------------------------------------------------------

  String _doctrineLabelText(
          DoctrineKnowledgeProduct p, DoctrineSectionType type, String label) =>
      _labelText(p.sectionOf(type)?.statements, label);

  List<String> _doctrineSectionTexts(
          DoctrineKnowledgeProduct p, DoctrineSectionType type) =>
      _sectionTexts(p.sectionOf(type)?.statements);

  String _statuteLabelText(
          StatuteKnowledgeProduct p, StatuteSectionType type, String label) =>
      _labelText(p.sectionOf(type)?.statements, label);

  List<String> _statuteSectionTexts(
          StatuteKnowledgeProduct p, StatuteSectionType type) =>
      _sectionTexts(p.sectionOf(type)?.statements);

  String _topicLabelText(
          TopicKnowledgeProduct p, TopicSectionType type, String label) =>
      _labelText(p.sectionOf(type)?.statements, label);

  List<String> _topicSectionTexts(
          TopicKnowledgeProduct p, TopicSectionType type) =>
      _sectionTexts(p.sectionOf(type)?.statements);

  static String _labelText(List<dynamic>? statements, String label) {
    if (statements == null) return '';
    for (final s in statements) {
      // Doctrine/Statute/Topic statements all expose {label, text}.
      if (s.label == label) return s.text as String;
    }
    return '';
  }

  static List<String> _sectionTexts(List<dynamic>? statements) {
    if (statements == null) return const [];
    return [
      for (final s in statements)
        if ((s.text as String).trim().isNotEmpty) s.text as String,
    ];
  }
}
