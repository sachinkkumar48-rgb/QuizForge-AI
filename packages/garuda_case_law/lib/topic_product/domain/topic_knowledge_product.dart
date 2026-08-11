/// TopicKnowledgeProduct model for the Evidence-Bounded UPSC Topic Knowledge
/// Product layer (TITAN-KO-015.0 P14).
///
/// A deterministic, immutable, provenance-preserving knowledge product for one
/// pedagogical UPSC topic. It organizes existing validated P3–P13 evidence as a
/// structured, topic-level product: topic identity and the pedagogical-mapping
/// declaration (P14 syllabus configuration), an editorial overview (P14 config,
/// surfaced as editorial), the member cases with the P4/P3 signals that justify
/// membership (P14 explicit mapping over validated P3/P4 data), safely composed
/// doctrines (P12 products whose constituent cases are all topic members) and
/// provisions (P13 products whose associated cases are all topic members),
/// chronology (P10 ordering), structural observations, UPSC relevance (verbatim
/// P4 intelligence), evidence/provenance (P8 evidence registry + P14 mapping),
/// and one P11 [CaseExplanation] per member case.
///
/// P14 NEVER infers legal meaning. Topic membership is a pedagogical grouping
/// and does NOT establish a legal relationship (precedent, legal similarity,
/// authority, overruling, refinement, extension, doctrinal evolution,
/// causation or current-law status) between the included entities — those are
/// established only by the P5 graph. Every statement traces to an existing
/// validated source (see `P14_TOPIC_KNOWLEDGE_PRODUCT.md`).
library;

import 'package:meta/meta.dart';

import '../../doctrine_product/domain/doctrine_knowledge_product.dart';
import '../../explanation/domain/case_explanation.dart';
import '../../intelligence/domain/intelligence_enums.dart';
import '../../statute_product/domain/statute_knowledge_product.dart';
import 'topic_identity.dart';
import 'topic_product_enums.dart';
import 'topic_product_section.dart';

/// An immutable evidence-bounded knowledge product of one pedagogical topic.
@immutable
class TopicKnowledgeProduct {
  /// Fixed marker of this knowledge-product kind.
  static const String topicKind =
      'evidence-bounded-upsc-topic-knowledge-product';

  /// Canonical P14 topic ID.
  final String topicId;

  /// Deterministic display topic name.
  final String topicName;

  /// The normalized P4 syllabus area the topic is grouped under.
  final UpscSyllabusArea area;

  /// Editorial pedagogical path (e.g. `GS Paper II → Constitutional Governance
  /// → Basic Structure Doctrine`). A pedagogical mapping, never a legal fact.
  final String pedagogicalPath;

  /// The kind of taxonomy this topic belongs to (always pedagogical).
  final TopicMappingKind mappingKind;

  /// Version of the P14 syllabus configuration that defined this topic.
  final String configVersion;

  /// Member case IDs in chronological order (P10 ordering; position is never
  /// causation). Unique and deterministic.
  final List<String> memberCaseIds;

  /// Present sections in fixed deterministic order. A section is present only
  /// when validated evidence exists; missing data is represented by an absent
  /// section, never by fabricated content.
  final List<TopicSection> sections;

  /// One P11 [CaseExplanation] per member case, in the same chronological
  /// order as [memberCaseIds]. Reuses P11 directly — P14 never re-implements
  /// case explanation logic.
  final List<CaseExplanation> caseExplanations;

  /// P12 [DoctrineKnowledgeProduct]s composed into the topic, in deterministic
  /// order (doctrine ID ascending). A doctrine appears only when every corpus
  /// case it references is a topic member.
  final List<DoctrineKnowledgeProduct> doctrineProducts;

  /// P13 [StatuteKnowledgeProduct]s composed into the topic, in deterministic
  /// order (provision kind, then key ascending). A provision appears only when
  /// every corpus case it references is a topic member.
  final List<StatuteKnowledgeProduct> statuteProducts;

  const TopicKnowledgeProduct({
    required this.topicId,
    required this.topicName,
    required this.area,
    required this.pedagogicalPath,
    required this.mappingKind,
    required this.configVersion,
    required this.memberCaseIds,
    required this.sections,
    required this.caseExplanations,
    required this.doctrineProducts,
    required this.statuteProducts,
  });

  /// The immutable identity value object of this topic.
  TopicIdentity get identity => TopicIdentity(
        id: topicId,
        name: topicName,
        area: area,
        pedagogicalPath: pedagogicalPath,
        mappingKind: mappingKind,
        configVersion: configVersion,
      );

  /// Whether the topic claims official UPSC syllabus status. Always false (see
  /// [TopicIdentity.isOfficialSyllabus]).
  bool get isOfficialSyllabus => false;

  /// Whether the product carries no presentable sections.
  bool get isEmpty => sections.isEmpty;

  /// The section of [type], or null when absent (missing data).
  TopicSection? sectionOf(TopicSectionType type) {
    for (final s in sections) {
      if (s.type == type) return s;
    }
    return null;
  }

  /// Whether [type] is present in this product.
  bool hasSection(TopicSectionType type) => sectionOf(type) != null;

  /// Unique canonical source identifiers referenced anywhere in the product,
  /// including the topic ID and every member case ID, sorted.
  ///
  /// Identifiers are the raw canonical keys carried by statement references —
  /// topic IDs, case IDs, edge IDs (`e:...`), article keys, doctrine IDs,
  /// evidence IDs — plus the referenced identifiers of each embedded P11/P12/P13
  /// product, so this is NOT a list of case IDs. Consumers that need only the
  /// member *cases* should use [memberCaseIds].
  List<String> get referencedIds {
    final seen = <String>{topicId};
    final out = <String>[topicId];
    for (final id in memberCaseIds) {
      if (seen.add(id)) out.add(id);
    }
    for (final s in sections) {
      for (final r in s.references) {
        if (seen.add(r)) out.add(r);
      }
    }
    for (final e in caseExplanations) {
      for (final r in e.referencedIds) {
        if (seen.add(r)) out.add(r);
      }
    }
    for (final d in doctrineProducts) {
      for (final r in d.referencedIds) {
        if (seen.add(r)) out.add(r);
      }
    }
    for (final p in statuteProducts) {
      for (final r in p.referencedIds) {
        if (seen.add(r)) out.add(r);
      }
    }
    out.sort();
    return List.unmodifiable(out);
  }

  Map<String, dynamic> toJson() => {
        'topicKind': topicKind,
        'topicId': topicId,
        'topicName': topicName,
        'area': area.name,
        'pedagogicalPath': pedagogicalPath,
        'mappingKind': mappingKind.name,
        'configVersion': configVersion,
        'isOfficialSyllabus': isOfficialSyllabus,
        'memberCaseIds': memberCaseIds,
        'sections': sections.map((s) => s.toJson()).toList(),
        'caseExplanations': caseExplanations.map((e) => e.toJson()).toList(),
        'doctrineProducts': doctrineProducts.map((d) => d.toJson()).toList(),
        'statuteProducts': statuteProducts.map((p) => p.toJson()).toList(),
      };

  factory TopicKnowledgeProduct.fromJson(Map<String, dynamic> json) =>
      TopicKnowledgeProduct(
        topicId: json['topicId'] as String? ?? '',
        topicName: json['topicName'] as String? ?? '',
        area: UpscSyllabusArea.values.firstWhere(
          (a) => a.name == json['area'],
          orElse: () => UpscSyllabusArea.gs2,
        ),
        pedagogicalPath: json['pedagogicalPath'] as String? ?? '',
        mappingKind: TopicMappingKind.values.firstWhere(
          (k) => k.name == json['mappingKind'],
          orElse: () => TopicMappingKind.pedagogicalMapping,
        ),
        configVersion: json['configVersion'] as String? ?? '',
        memberCaseIds: (json['memberCaseIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .map((e) =>
                TopicSection.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        caseExplanations: (json['caseExplanations'] as List<dynamic>? ??
                const [])
            .map((e) =>
                CaseExplanation.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        doctrineProducts:
            (json['doctrineProducts'] as List<dynamic>? ?? const [])
                .map((e) => DoctrineKnowledgeProduct.fromJson(
                    Map<String, dynamic>.from(e as Map)))
                .toList(),
        statuteProducts: (json['statuteProducts'] as List<dynamic>? ?? const [])
            .map((e) => StatuteKnowledgeProduct.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicKnowledgeProduct &&
          topicId == other.topicId &&
          topicName == other.topicName &&
          area == other.area &&
          pedagogicalPath == other.pedagogicalPath &&
          mappingKind == other.mappingKind &&
          configVersion == other.configVersion &&
          _stringListEquals(memberCaseIds, other.memberCaseIds) &&
          _sectionListEquals(sections, other.sections) &&
          _explanationListEquals(caseExplanations, other.caseExplanations) &&
          _doctrineListEquals(doctrineProducts, other.doctrineProducts) &&
          _statuteListEquals(statuteProducts, other.statuteProducts);

  @override
  int get hashCode => Object.hash(
      topicId, topicName, area, pedagogicalPath, mappingKind, configVersion);

  @override
  String toString() =>
      'TopicKnowledgeProduct($topicId, ${sections.map((s) => s.type.name).join(', ')})';

  static bool _stringListEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sectionListEquals(List<TopicSection> a, List<TopicSection> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _explanationListEquals(
      List<CaseExplanation> a, List<CaseExplanation> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _doctrineListEquals(
      List<DoctrineKnowledgeProduct> a, List<DoctrineKnowledgeProduct> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _statuteListEquals(
      List<StatuteKnowledgeProduct> a, List<StatuteKnowledgeProduct> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
