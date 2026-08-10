/// Enums for the Evidence-Backed Case Explanation layer
/// (TITAN-KO-015.0 P11).
///
/// P11 is the knowledge-product composition layer above P10: it transforms
/// existing validated P3–P10 case-law evidence into a structured,
/// human-readable, provenance-preserving [CaseExplanation]. The vocabulary
/// below names the *sections* an explanation is composed of. Every section
/// carries only the evidence the existing P3–P10 models already provide —
/// P11 never infers new legal meaning.
library;

/// The fixed, deterministically ordered set of sections an explanation may
/// contain. Ordering is fixed for deterministic serialization; a section is
/// present only when the underlying validated evidence exists.
enum ExplanationSectionType {
  /// Canonical case identity, from the P3 corpus.
  identity,

  /// Case overview (summaries, facts, context), from the P3 corpus.
  overview,

  /// Framed issues, from P4 judgment intelligence (P3 fallback).
  issues,

  /// Validated holdings, from P4 judgment intelligence.
  holdings,

  /// Judicial reasoning, from P4 judgment intelligence.
  reasoning,

  /// Case outcome / operative result, from P4 judgment intelligence
  /// (P3 decision fallback).
  outcome,

  /// Legal significance, from P4 judgment intelligence (P3 fallback).
  legalSignificance,

  /// Doctrines engaged by the case, from P5 case → doctrine edges.
  doctrines,

  /// Constitutional Articles referenced, from the P3 corpus.
  articles,

  /// Acts referenced, from the P3 corpus.
  acts,

  /// Cases discovered as related, from P9 related-case discovery.
  relatedCases,

  /// Direct precedent relationships, from P5 case → case edges.
  precedentContext,

  /// Comparative / cross-case context, from P10 analysis.
  crossCaseContext,

  /// UPSC relevance already present in P3/P4 records.
  upscRelevance,

  /// Evidence and provenance, from the P3 corpus evidence registry.
  evidence,
}

extension ExplanationSectionTypeExtension on ExplanationSectionType {
  /// Deterministic human-readable heading for the section.
  String get displayTitle => switch (this) {
        ExplanationSectionType.identity => 'Case Identity',
        ExplanationSectionType.overview => 'Overview',
        ExplanationSectionType.issues => 'Issues',
        ExplanationSectionType.holdings => 'Holdings',
        ExplanationSectionType.reasoning => 'Reasoning',
        ExplanationSectionType.outcome => 'Outcome',
        ExplanationSectionType.legalSignificance => 'Legal Significance',
        ExplanationSectionType.doctrines => 'Doctrines',
        ExplanationSectionType.articles => 'Relevant Articles',
        ExplanationSectionType.acts => 'Relevant Acts',
        ExplanationSectionType.relatedCases => 'Related Cases',
        ExplanationSectionType.precedentContext => 'Precedent Context',
        ExplanationSectionType.crossCaseContext => 'Cross-Case Context',
        ExplanationSectionType.upscRelevance => 'UPSC Relevance',
        ExplanationSectionType.evidence => 'Evidence & Provenance',
      };

  /// Parses a section type from its serialized enum name, defaulting to
  /// [ExplanationSectionType.identity] for unknown values.
  static ExplanationSectionType fromName(String? name) =>
      ExplanationSectionType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ExplanationSectionType.identity,
      );
}
