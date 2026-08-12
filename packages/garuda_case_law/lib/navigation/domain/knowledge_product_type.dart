/// Knowledge product kinds for the Knowledge Product Navigator
/// (TITAN-KO-015.0 P16).
///
/// P16 navigates between the existing validated knowledge products:
/// P11 case explanations, P12 doctrine products, P13 statute products, P14
/// topic products and P15 question products. Each corresponds to one validated
/// knowledge-product layer and its canonical identifier. No new product kind is
/// introduced here — these are the kinds the existing P11–P15 services already
/// produce.
library;

/// The kind of knowledge product a navigation destination references.
///
/// The enum declaration order is also the deterministic sort order used to
/// group a [KnowledgeProductCollection] (case → doctrine → provision → topic →
/// question). Ordering is by product kind, never by legal importance.
enum KnowledgeProductType {
  /// A P11 `CaseExplanation` of one canonical corpus case (`caseId`).
  caseLaw,

  /// A P12 `DoctrineKnowledgeProduct` of one canonical doctrine (`doctrineId`).
  doctrine,

  /// A P13 `StatuteKnowledgeProduct` of one canonical provision
  /// (`ProvisionType` + provision key).
  provision,

  /// A P14 `TopicKnowledgeProduct` of one pedagogical topic (`topicId`).
  topic,

  /// A P15 `QuestionKnowledgeProduct` re-presenting a validated source.
  question,
}

extension KnowledgeProductTypeExtension on KnowledgeProductType {
  /// Deterministic human-readable label for the product kind.
  String get displayTitle => switch (this) {
        KnowledgeProductType.caseLaw => 'Case law',
        KnowledgeProductType.doctrine => 'Doctrine',
        KnowledgeProductType.provision => 'Provision',
        KnowledgeProductType.topic => 'Topic',
        KnowledgeProductType.question => 'Question',
      };

  /// The deterministic group-order of this kind within a navigation result.
  int get sortIndex => index;

  /// Parses a product type from its serialized enum name, defaulting to
  /// [KnowledgeProductType.caseLaw] for unknown values.
  static KnowledgeProductType fromName(String? name) =>
      KnowledgeProductType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => KnowledgeProductType.caseLaw,
      );
}
