/// Enums for the Evidence-Backed Doctrine Knowledge Product layer
/// (TITAN-KO-015.0 P12).
///
/// P12 is the knowledge-product composition layer above P11: it transforms
/// existing validated P3–P11 case-law and doctrine evidence into a structured,
/// provenance-preserving, doctrine-level knowledge product. The vocabulary
/// below names the *sections* a doctrine product is composed of. Every section
/// carries only the evidence the existing P3–P11 models already provide — P12
/// never infers new legal meaning (see `P12_DOCTRINE_KNOWLEDGE_PRODUCT.md`).
library;

/// The fixed, deterministically ordered set of sections a doctrine knowledge
/// product may contain. Ordering is fixed for deterministic serialization; a
/// section is present only when the underlying validated evidence exists.
enum DoctrineSectionType {
  /// Canonical doctrine identity, from the `garuda_doctrine` record.
  identity,

  /// Canonical doctrine description (definition, explanation, purpose, scope,
  /// recorded current position), verbatim from the `garuda_doctrine` record.
  overview,

  /// The validated constituent cases of the doctrine, from P5 case → doctrine
  /// edges via the P10 doctrine analysis. Roles are verbatim P5 edge evidence.
  constituentCases,

  /// Constitutional Articles referenced by the constituent cases, from the
  /// P3 corpus `relatedArticles` fields.
  articles,

  /// Acts referenced by the constituent cases, from the P3 corpus
  /// `relatedActs` fields.
  acts,

  /// Precedent (case → case) relationships among the constituent cases, from
  /// P5 edges verbatim (via P10 doctrine analysis).
  precedentRelationships,

  /// Chronological position of the constituent cases, from P10 chronology.
  chronology,

  /// Deterministic structural observations over the constituent cases (from
  /// P10, plus shared-constituent-case doctrine overlap). Never legal
  /// conclusions.
  structuralObservations,

  /// UPSC information already attached to the constituent cases (P3/P4
  /// records), presented per case — never ranked.
  upscRelevance,

  /// Evidence and provenance: doctrine-record evidence (verbatim) and the
  /// P8 `EvidenceEntry` resolution of each constituent case's evidence IDs.
  evidence,
}

extension DoctrineSectionTypeExtension on DoctrineSectionType {
  /// Deterministic human-readable heading for the section.
  String get displayTitle => switch (this) {
        DoctrineSectionType.identity => 'Doctrine Identity',
        DoctrineSectionType.overview => 'Doctrine Overview',
        DoctrineSectionType.constituentCases => 'Constituent Cases',
        DoctrineSectionType.articles => 'Relevant Articles',
        DoctrineSectionType.acts => 'Relevant Acts',
        DoctrineSectionType.precedentRelationships => 'Precedent Relationships',
        DoctrineSectionType.chronology => 'Chronology',
        DoctrineSectionType.structuralObservations => 'Structural Observations',
        DoctrineSectionType.upscRelevance => 'UPSC Relevance',
        DoctrineSectionType.evidence => 'Evidence & Provenance',
      };

  /// Parses a section type from its serialized enum name, defaulting to
  /// [DoctrineSectionType.identity] for unknown values.
  static DoctrineSectionType fromName(String? name) =>
      DoctrineSectionType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => DoctrineSectionType.identity,
      );
}
