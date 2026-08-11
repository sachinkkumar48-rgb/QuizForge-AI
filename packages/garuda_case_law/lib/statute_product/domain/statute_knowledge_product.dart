/// StatuteKnowledgeProduct model for the Evidence-Backed Statute / Article
/// Knowledge Product layer (TITAN-KO-015.0 P13).
///
/// A deterministic, immutable, provenance-preserving knowledge product for one
/// canonical constitutional Article or statutory provision (Act or section). It
/// re-presents existing validated P3–P12 evidence as a structured, provision-
/// level product: identity and overview from the canonical `garuda_constitution`
/// / `garuda_acts` records where the provision resolves (and from the verbatim
/// P3 corpus references otherwise), the verified cases that reference the
/// provision (P3 `relatedArticles` / `relatedActs` / `sections`), safely
/// associated doctrines (via the recorded P5 case ↔ doctrine edges of those
/// cases), precedent relationships among the associated cases (P5 case → case
/// edges), chronology and structural observations (P10 ordering), UPSC
/// information already attached to the associated cases, evidence/provenance
/// from the P8 evidence registry, and one P11 [CaseExplanation] per associated
/// case. It never invents legal meaning — every statement traces to an existing
/// validated source (see `P13_STATUTE_KNOWLEDGE_PRODUCT.md`).
library;

import 'package:meta/meta.dart';

import '../../explanation/domain/case_explanation.dart';
import 'statute_product_enums.dart';
import 'statute_product_section.dart';

/// An immutable evidence-backed knowledge product of one provision.
@immutable
class StatuteKnowledgeProduct {
  /// Fixed marker of this knowledge-product kind.
  static const String statuteKind =
      'evidence-backed-statute-knowledge-product';

  /// Kind of provision the product is centered on.
  final ProvisionType provisionType;

  /// Canonical normalized provision key (e.g. `14`, `21a`,
  /// `representation of the people act 1951`, `section 154 crpc`).
  final String provisionId;

  /// Deterministic display name: the first verbatim corpus reference (sorted)
  /// that folds to [provisionId] (e.g. `Article 14`).
  final String provisionName;

  /// Every verbatim corpus reference that folds to [provisionId], unique and
  /// sorted. Never re-formatted, never invented.
  final List<String> rawReferences;

  /// Present sections in fixed deterministic order. A section is present only
  /// when validated evidence exists; missing data is represented by an absent
  /// section, never by fabricated content.
  final List<StatuteSection> sections;

  /// One P11 [CaseExplanation] per associated case, in the same chronological
  /// order as the `associatedCases` section. Reuses P11 directly — P13 never
  /// re-implements case explanation logic.
  final List<CaseExplanation> caseExplanations;

  const StatuteKnowledgeProduct({
    required this.provisionType,
    required this.provisionId,
    required this.provisionName,
    required this.rawReferences,
    required this.sections,
    required this.caseExplanations,
  });

  /// Whether the product carries no presentable sections.
  bool get isEmpty => sections.isEmpty;

  /// The section of [type], or null when absent (missing data).
  StatuteSection? sectionOf(StatuteSectionType type) {
    for (final s in sections) {
      if (s.type == type) return s;
    }
    return null;
  }

  /// Whether [type] is present in this product.
  bool hasSection(StatuteSectionType type) => sectionOf(type) != null;

  /// Unique canonical source identifiers referenced anywhere in the product,
  /// including the provision key itself, sorted.
  ///
  /// Identifiers are the raw canonical keys carried by statement references —
  /// provision keys, case IDs, edge IDs (`e:...`), doctrine IDs, evidence IDs —
  /// plus the referenced identifiers of each embedded P11 explanation, so this
  /// is NOT a list of case IDs. Consumers that need only the referenced *cases*
  /// must filter against the validated corpus via
  /// `StatuteKnowledgeProductService.referencedCaseIds`.
  List<String> get referencedIds {
    final seen = <String>{provisionId};
    final out = <String>[provisionId];
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
    out.sort();
    return List.unmodifiable(out);
  }

  Map<String, dynamic> toJson() => {
        'statuteKind': statuteKind,
        'provisionType': provisionType.name,
        'provisionId': provisionId,
        'provisionName': provisionName,
        'rawReferences': rawReferences,
        'sections': sections.map((s) => s.toJson()).toList(),
        'caseExplanations': caseExplanations.map((e) => e.toJson()).toList(),
      };

  factory StatuteKnowledgeProduct.fromJson(Map<String, dynamic> json) =>
      StatuteKnowledgeProduct(
        provisionType:
            ProvisionTypeExtension.fromName(json['provisionType'] as String?),
        provisionId: json['provisionId'] as String? ?? '',
        provisionName: json['provisionName'] as String? ?? '',
        rawReferences:
            (json['rawReferences'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList(),
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .map((e) =>
                StatuteSection.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        caseExplanations: (json['caseExplanations'] as List<dynamic>? ??
                const [])
            .map((e) =>
                CaseExplanation.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatuteKnowledgeProduct &&
          provisionType == other.provisionType &&
          provisionId == other.provisionId &&
          provisionName == other.provisionName &&
          _listEquals(rawReferences, other.rawReferences) &&
          _listEquals(sections, other.sections) &&
          _listEqualsExplanations(caseExplanations, other.caseExplanations);

  @override
  int get hashCode => Object.hash(provisionType, provisionId, provisionName);

  @override
  String toString() =>
      'StatuteKnowledgeProduct(${provisionType.name}:$provisionId)';

  static bool _listEquals(List<Object> a, List<Object> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _listEqualsExplanations(
      List<CaseExplanation> a, List<CaseExplanation> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
