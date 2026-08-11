/// Enums for the Evidence-Backed Question-Answer Knowledge Product layer
/// (TITAN-KO-015.0 P15).
///
/// P15 is the active-learning knowledge-product composition layer above
/// P4/P11–P14: it transforms existing validated case-law knowledge into
/// deterministic, evidence-backed educational question-answer products. The
/// vocabulary below names the *kind of validated source* a question product is
/// built over and the *kind of question* it contains. Every question is
/// derived from an explicit, auditable source — nothing is invented (see
/// `P15_QUESTION_KNOWLEDGE_PRODUCT.md`).
library;

/// The kind of validated source a [QuestionKnowledgeProduct] is built over.
///
/// The source is the *validated knowledge product / intelligence* a product
/// re-presents as questions:
///
/// - [caseLaw] — a P3 `CaseKnowledgeObject` and its P4 validated
///   `JudgmentIntelligence` (issue-based and principle-based questions).
/// - [doctrine] — a P12 `DoctrineKnowledgeProduct`.
/// - [statute] — a P13 `StatuteKnowledgeProduct`.
/// - [topic] — a P14 `TopicKnowledgeProduct`.
///
/// A product built over a [caseLaw] source yields issue / principle questions;
/// a [doctrine] source yields doctrine questions; a [statute] source yields
/// statute questions; a [topic] source yields topic questions. The mapping is
/// fixed and deterministic.
enum QuestionSourceType {
  /// A canonical case and its P4 validated judgment intelligence.
  caseLaw,

  /// A P12 doctrine knowledge product.
  doctrine,

  /// A P13 statute / article knowledge product.
  statute,

  /// A P14 topic knowledge product.
  topic,
}

extension QuestionSourceTypeExtension on QuestionSourceType {
  /// Deterministic human-readable label for the source kind.
  String get displayTitle => switch (this) {
        QuestionSourceType.caseLaw => 'Case law',
        QuestionSourceType.doctrine => 'Doctrine',
        QuestionSourceType.statute => 'Statute / Article',
        QuestionSourceType.topic => 'Topic',
      };
}

/// The kind of an educational question.
///
/// A question is never invented from general knowledge: each type derives from
/// an explicit validated source and the answer is composed only from that
/// source (or the validated P4/P11–P14 knowledge product re-presented by the
/// source). Missing source information means an *omitted* question, never a
/// fabricated one.
enum LegalQuestionType {
  /// Derived from an explicit P4 `JudgmentIssue`.
  issue,

  /// Derived from an explicit P4 legal principle (`JudgmentHolding.legalPrinciple`).
  principle,

  /// Derived from explicit P12 doctrine content.
  doctrine,

  /// Derived from explicit P13 statute / article content.
  statute,

  /// Derived from explicit P14 topic content.
  topic,
}

extension LegalQuestionTypeExtension on LegalQuestionType {
  /// Deterministic human-readable label for the question kind.
  String get displayTitle => switch (this) {
        LegalQuestionType.issue => 'Issue',
        LegalQuestionType.principle => 'Principle',
        LegalQuestionType.doctrine => 'Doctrine',
        LegalQuestionType.statute => 'Statute / Article',
        LegalQuestionType.topic => 'Topic',
      };
}
