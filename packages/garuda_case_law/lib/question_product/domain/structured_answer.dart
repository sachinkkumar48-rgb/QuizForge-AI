/// StructuredAnswer model for the Evidence-Backed Question-Answer Knowledge
/// Product layer (TITAN-KO-015.0 P15).
///
/// A deterministic, immutable, provenance-preserving answer to one
/// [LegalQuestion]. The answer is composed ONLY from already validated P4
/// judgment intelligence or P11–P14 knowledge products — never from general
/// knowledge, inference or fabrication. Every answer carries non-empty
/// evidence/source references and a non-empty provenance field that records
/// which validated source field the content traces to (see
/// `P15_QUESTION_KNOWLEDGE_PRODUCT.md`).
library;

import 'package:meta/meta.dart';

/// An immutable, evidence-backed answer to an educational question.
@immutable
class StructuredAnswer {
  /// The composed answer content, verbatim from validated source data.
  final String answerText;

  /// Canonical identifiers that establish the answer. Never empty.
  final List<String> evidenceRefs;

  /// Related case IDs, present ONLY where an explicit P5 relationship supports
  /// them. Never inferred from topic membership, chronology or apparent
  /// similarity; never labelled as "similar".
  final List<String> relatedCaseIds;

  /// Relevant legal principles / context included only where the validated
  /// source explicitly provides them (e.g. a P4 `legalPrinciple` or a
  /// doctrine's recorded overview).
  final List<String> principles;

  /// Provenance of the answer content (e.g. `p4:holdings.legalPrinciple`,
  /// `p12:DoctrineKnowledgeProduct.overview`). Never empty.
  final String provenance;

  const StructuredAnswer({
    required this.answerText,
    required this.evidenceRefs,
    this.relatedCaseIds = const [],
    this.principles = const [],
    required this.provenance,
  })  : assert(evidenceRefs.length > 0, 'an answer needs evidence references'),
        assert(provenance.length > 0, 'an answer needs provenance');

  /// Whether the answer carries any explicit related-case references.
  bool get hasRelatedCases => relatedCaseIds.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'answerText': answerText,
        'evidenceRefs': evidenceRefs,
        'relatedCaseIds': relatedCaseIds,
        'principles': principles,
        'provenance': provenance,
      };

  factory StructuredAnswer.fromJson(Map<String, dynamic> json) =>
      StructuredAnswer(
        answerText: json['answerText'] as String? ?? '',
        evidenceRefs: (json['evidenceRefs'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        relatedCaseIds: (json['relatedCaseIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        principles: (json['principles'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        provenance: json['provenance'] as String? ?? '',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuredAnswer &&
          answerText == other.answerText &&
          _listEquals(evidenceRefs, other.evidenceRefs) &&
          _listEquals(relatedCaseIds, other.relatedCaseIds) &&
          _listEquals(principles, other.principles) &&
          provenance == other.provenance;

  @override
  int get hashCode =>
      Object.hash(answerText, provenance, Object.hashAll(evidenceRefs));

  @override
  String toString() => 'StructuredAnswer(${evidenceRefs.length} evidence refs)';

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
