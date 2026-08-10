/// DoctrineKnowledgeProduct model for the Evidence-Backed Doctrine Knowledge
/// Product layer (TITAN-KO-015.0 P12).
///
/// A deterministic, immutable, provenance-preserving knowledge product for one
/// canonical Constitutional Doctrine. It re-presents existing validated P3–P11
/// evidence as a structured, doctrine-level product: identity and overview from
/// the canonical `garuda_doctrine` record, constituent cases from the P5
/// case → doctrine edges (via the P10 doctrine analysis), Articles/Acts from the
/// P3 corpus, precedent relationships from P5, chronology and structural
/// observations from P10, UPSC information already attached to the constituent
/// cases, evidence/provenance from the P8 evidence registry and the doctrine
/// record, and one P11 [CaseExplanation] per constituent case. It never invents
/// legal meaning — every statement traces to an existing validated source (see
/// `P12_DOCTRINE_KNOWLEDGE_PRODUCT.md`).
library;

import 'package:meta/meta.dart';

import '../../explanation/domain/case_explanation.dart';
import 'doctrine_product_enums.dart';
import 'doctrine_product_section.dart';

/// An immutable evidence-backed knowledge product of one canonical doctrine.
@immutable
class DoctrineKnowledgeProduct {
  /// Fixed marker of this knowledge-product kind.
  static const String doctrineKind =
      'evidence-backed-doctrine-knowledge-product';

  /// Canonical `garuda_doctrine` doctrine ID.
  final String doctrineId;

  /// Display doctrine name.
  final String doctrineName;

  /// Present sections in fixed deterministic order. A section is present only
  /// when validated evidence exists; missing data is represented by an absent
  /// section, never by fabricated content.
  final List<DoctrineSection> sections;

  /// One P11 [CaseExplanation] per constituent case, in the same chronological
  /// order as the `constituentCases` section. Reuses P11 directly — P12 never
  /// re-implements case explanation logic.
  final List<CaseExplanation> caseExplanations;

  const DoctrineKnowledgeProduct({
    required this.doctrineId,
    required this.doctrineName,
    required this.sections,
    required this.caseExplanations,
  });

  /// Whether the product carries no presentable sections.
  bool get isEmpty => sections.isEmpty;

  /// The section of [type], or null when absent (missing data).
  DoctrineSection? sectionOf(DoctrineSectionType type) {
    for (final s in sections) {
      if (s.type == type) return s;
    }
    return null;
  }

  /// Whether [type] is present in this product.
  bool hasSection(DoctrineSectionType type) => sectionOf(type) != null;

  /// Unique canonical source identifiers referenced anywhere in the product,
  /// including the doctrine's own ID, sorted.
  ///
  /// Identifiers are the raw canonical keys carried by statement references —
  /// doctrine IDs, case IDs, edge IDs (`e:...`), article keys, evidence IDs —
  /// plus the referenced identifiers of each embedded P11 explanation, so this
  /// is NOT a list of case IDs. Consumers that need only the referenced *cases*
  /// must filter against the validated corpus via
  /// `DoctrineKnowledgeProductService.referencedCaseIds`.
  List<String> get referencedIds {
    final seen = <String>{doctrineId};
    final out = <String>[doctrineId];
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
        'doctrineKind': doctrineKind,
        'doctrineId': doctrineId,
        'doctrineName': doctrineName,
        'sections': sections.map((s) => s.toJson()).toList(),
        'caseExplanations': caseExplanations.map((e) => e.toJson()).toList(),
      };

  factory DoctrineKnowledgeProduct.fromJson(Map<String, dynamic> json) =>
      DoctrineKnowledgeProduct(
        doctrineId: json['doctrineId'] as String? ?? '',
        doctrineName: json['doctrineName'] as String? ?? '',
        sections: (json['sections'] as List<dynamic>? ?? const [])
            .map((e) =>
                DoctrineSection.fromJson(Map<String, dynamic>.from(e as Map)))
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
      other is DoctrineKnowledgeProduct &&
          doctrineId == other.doctrineId &&
          doctrineName == other.doctrineName &&
          _listEquals(sections, other.sections) &&
          _listEqualsExplanations(caseExplanations, other.caseExplanations);

  @override
  int get hashCode => Object.hash(doctrineId, doctrineName);

  @override
  String toString() =>
      'DoctrineKnowledgeProduct($doctrineId, ${sections.map((s) => s.type.name).join(', ')})';

  static bool _listEquals(List<DoctrineSection> a, List<DoctrineSection> b) {
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
