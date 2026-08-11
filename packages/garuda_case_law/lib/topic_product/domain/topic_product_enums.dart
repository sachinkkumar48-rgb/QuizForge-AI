/// Enums for the Evidence-Bounded UPSC Topic Knowledge Product layer
/// (TITAN-KO-015.0 P14).
///
/// P14 is the pedagogical composition layer above P11/P12/P13: it organizes
/// existing validated case-law knowledge into deterministic, evidence-bounded
/// UPSC topic groupings. The vocabulary below names the *kind* of P14 mapping
/// and the *sections* a topic product is composed of.
///
/// **Conceptual boundary:** a P14 topic is a PEDAGOGICAL GROUPING, never a
/// legal relationship. Topic membership does not imply legal similarity,
/// precedent, authority, overruling, refinement, extension, doctrinal
/// evolution, causation or current-law status — those are established only by
/// the P5 precedent/doctrine graph. Every section carries only the evidence the
/// existing validated P3–P13 models already provide (see
/// `P14_TOPIC_KNOWLEDGE_PRODUCT.md`).
library;

/// The kind of taxonomy a P14 topic belongs to.
///
/// Only [pedagogicalMapping] is ever used by the current syllabus configuration:
/// the repository contains no authoritative UPSC syllabus source, so the P14
/// taxonomy is explicitly an editorial pedagogical grouping over validated P4
/// UPSC data — never a claim that the grouping is official UPSC syllabus
/// wording. The enum exists so the distinction is explicit and testable.
enum TopicMappingKind {
  /// An editorial, versioned pedagogical grouping of existing validated
  /// case-law knowledge for UPSC preparation. Not an official syllabus source.
  pedagogicalMapping,
}

extension TopicMappingKindExtension on TopicMappingKind {
  /// Deterministic human-readable label for the mapping kind.
  String get displayTitle => switch (this) {
        TopicMappingKind.pedagogicalMapping =>
          'Pedagogical mapping (not an official UPSC syllabus taxonomy)',
      };
}

/// The fixed, deterministically ordered set of sections a topic knowledge
/// product may contain. Ordering is fixed for deterministic serialization; a
/// section is present only when the underlying validated evidence exists.
enum TopicSectionType {
  /// Topic identity: canonical topic ID, name, syllabus area, pedagogical path,
  /// taxonomy status and the explicit pedagogical-mapping declaration.
  identity,

  /// Editorial pedagogical overview of the topic grouping (from the versioned
  /// P14 syllabus configuration; surfaced as editorial, never as legal fact).
  overview,

  /// The member cases of the topic: cases whose validated P4 UPSC data is
  /// explicitly mapped to the topic, in chronological order, each with the P14
  /// mapping signal that justifies membership.
  memberCases,

  /// Doctrines composed from P12 knowledge products whose constituent cases are
  /// already topic members (strict all-members rule — no invented doctrine
  /// membership).
  doctrines,

  /// Provisions (Articles / Acts / Sections) composed from P13 knowledge
  /// products whose associated cases are already topic members (no second
  /// statute mapping engine).
  provisions,

  /// Chronological position of the member cases (P10 ordering; position is
  /// never causation).
  chronology,

  /// Deterministic structural observations over the topic (member count,
  /// time span, distinct P3 subjects, distinct syllabus areas, mapping count).
  structuralObservations,

  /// UPSC relevance of the member cases, verbatim from the P4 intelligence that
  /// justified the mapping.
  upscRelevance,

  /// Evidence / provenance of the topic mapping: the P14 syllabus-config source
  /// and P8 evidence resolution for each member case.
  evidence,
}

extension TopicSectionTypeExtension on TopicSectionType {
  /// Deterministic human-readable title for the section type.
  String get displayTitle => switch (this) {
        TopicSectionType.identity => 'Topic Identity',
        TopicSectionType.overview => 'Topic Overview',
        TopicSectionType.memberCases => 'Member Cases',
        TopicSectionType.doctrines => 'Related Doctrines',
        TopicSectionType.provisions => 'Related Provisions',
        TopicSectionType.chronology => 'Chronology',
        TopicSectionType.structuralObservations => 'Structural Observations',
        TopicSectionType.upscRelevance => 'UPSC Relevance',
        TopicSectionType.evidence => 'Evidence & Provenance',
      };
}
