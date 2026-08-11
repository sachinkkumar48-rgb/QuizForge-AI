/// Enums for the Evidence-Backed Statute / Article Knowledge Product layer
/// (TITAN-KO-015.0 P13).
///
/// P13 is the knowledge-product composition layer centered on a verified
/// constitutional Article or statutory provision: it transforms existing
/// validated P3–P12 case-law, doctrine, constitution and acts evidence into a
/// structured, provenance-preserving, provision-level knowledge product. The
/// vocabulary below names the *provision kinds* and *sections* a statute
/// product is composed of. Every section carries only the evidence the existing
/// P3–P12 models already provide — P13 never infers new legal meaning (see
/// `P13_STATUTE_KNOWLEDGE_PRODUCT.md`).
library;

/// The kinds of statutory / constitutional provisions a statute knowledge
/// product may be centered on. Each maps to an existing validated corpus field:
/// a constitutional Article (`CaseKnowledgeObject.relatedArticles`), an Act /
/// Statute (`CaseKnowledgeObject.relatedActs`), or a statutory section construed
/// (`CaseKnowledgeObject.sections`). P13 never fabricates a provision kind.
enum ProvisionType {
  /// A constitutional Article (e.g. `Article 14`, `Article 21A`).
  article,

  /// An Act / Statute (e.g. `Representation of the People Act, 1951`).
  act,

  /// A statutory section construed by a case (e.g. `Section 154 CrPC`).
  section,
}

extension ProvisionTypeExtension on ProvisionType {
  /// Deterministic human-readable label for the provision kind.
  String get displayTitle => switch (this) {
        ProvisionType.article => 'Constitutional Article',
        ProvisionType.act => 'Act / Statute',
        ProvisionType.section => 'Statutory Section',
      };

  /// Parses a provision type from its serialized enum name, defaulting to
  /// [ProvisionType.article] for unknown values.
  static ProvisionType fromName(String? name) => ProvisionType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ProvisionType.article,
      );
}

/// The fixed, deterministically ordered set of sections a statute knowledge
/// product may contain. Ordering is fixed for deterministic serialization; a
/// section is present only when the underlying validated evidence exists.
enum StatuteSectionType {
  /// Provision identity: provision kind, canonical normalized key, resolution
  /// status and every verbatim corpus reference that folds to the key.
  identity,

  /// Canonical provision metadata where the provision resolves to the
  /// `garuda_constitution` / `garuda_acts` corpus (official title, part,
  /// chapter, name, year), verbatim. Never contains legal interpretation.
  overview,

  /// The verified cases whose own validated corpus fields reference the
  /// provision (P3 `relatedArticles` / `relatedActs` / `sections`), in
  /// deterministic chronological order.
  associatedCases,

  /// Doctrines safely associated through validated evidence: a case that
  /// references the provision AND is a recorded P5 member of the doctrine.
  /// Roles are verbatim P5 edge evidence; nothing is inferred.
  doctrines,

  /// Precedent (case → case) relationships among the associated cases, from
  /// P5 edges verbatim.
  precedentRelationships,

  /// Chronological position of the associated cases, from P10 ordering.
  chronology,

  /// Deterministic structural observations over the associated cases (count,
  /// span). Chronology is position, never causation.
  structuralObservations,

  /// UPSC relevance already attached to the associated cases, verbatim.
  upscRelevance,

  /// Evidence and provenance: the P8 `EvidenceEntry` resolution of each
  /// associated case's evidence IDs, plus any provision-corpus evidence refs.
  evidence,
}

extension StatuteSectionTypeExtension on StatuteSectionType {
  /// Deterministic human-readable heading for the section.
  String get displayTitle => switch (this) {
        StatuteSectionType.identity => 'Provision Identity',
        StatuteSectionType.overview => 'Provision Overview',
        StatuteSectionType.associatedCases => 'Associated Cases',
        StatuteSectionType.doctrines => 'Safely Associated Doctrines',
        StatuteSectionType.precedentRelationships => 'Precedent Relationships',
        StatuteSectionType.chronology => 'Chronology',
        StatuteSectionType.structuralObservations => 'Structural Observations',
        StatuteSectionType.upscRelevance => 'UPSC Relevance',
        StatuteSectionType.evidence => 'Evidence & Provenance',
      };

  /// Parses a section type from its serialized enum name, defaulting to
  /// [StatuteSectionType.identity] for unknown values.
  static StatuteSectionType fromName(String? name) =>
      StatuteSectionType.values.firstWhere(
        (e) => e.name == name,
        orElse: () => StatuteSectionType.identity,
      );
}
