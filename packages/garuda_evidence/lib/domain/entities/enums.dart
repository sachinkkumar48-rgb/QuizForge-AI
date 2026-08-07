library;

/// Primary source types for evidence ingestion.
enum EvidenceSourceType {
  government,
  judiciary,
  legislature,
  gazette,
  committee,
  commission,
  report,
  research,
  internationalOrganisation,
  ministry,
  other,
}

/// Verification status of an evidence object.
enum VerificationStatus {
  unverified,
  pending,
  verified,
  disputed,
  deprecated,
}

/// Editorial status for evidence lifecycle management.
enum EditorialStatus {
  draft,
  submitted,
  underReview,
  approved,
  published,
  archived,
}

/// Types of relationship between two evidence objects.
enum RelationshipType {
  supersedes,
  references,
  amends,
  confirms,
  contradicts,
  complements,
  cites,
}

/// Supported Knowledge Graph Object Link types in Project TITAN.
enum KnowledgeObjectType {
  constitutionArticles,
  caseLaws,
  acts,
  amendments,
  committees,
  reports,
  schemes,
  people,
  institutions,
  lessons,
  pyqs,
  maps,
  timeline,
  currentAffairs,
}
