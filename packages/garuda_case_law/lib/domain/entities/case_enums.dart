library;

/// Legal status of a constitutional case precedent.
enum CaseStatus {
  landmarkPrecedent,
  overruled,
  partiallyOverruled,
  pendingReview,
  affirmed,
}

/// Level of court delivering the judgment.
enum CourtLevel {
  supremeCourt,
  highCourt,
  federalCourt,
  privyCouncil,
}

/// Broad legal domain of a judgment, used for analytics and search filtering.
enum CaseType {
  constitutionalLaw,
  federalism,
  criminalLaw,
  civilLaw,
  environmentalLaw,
  humanRights,
  socialJustice,
  electoralLaw,
  serviceMatter,
  economicLaw,
  commercialLaw,
  regulatoryLaw,
  taxationLaw,
  administrativeLaw,
  labourLaw,
  familyLaw,
  religiousLaw,
  mediaLaw,
  policeLaw,
  other,
}

/// UPSC / examination relevance level for a judgment.
enum RelevanceLevel {
  critical,
  high,
  medium,
  low,
  notApplicable,
}

/// Nature of the precedent relationship between two cases. Relationships are
/// only recorded where the source judgment itself establishes them.
enum PrecedentRelationshipType {
  followed,
  overruled,
  distinguished,
  affirmed,
  reversed,
  applied,
  expanded,
  limited,
  clarified,
  approved,
}

extension CaseTypeExtension on CaseType {
  String get displayName => switch (this) {
        CaseType.constitutionalLaw => 'Constitutional Law',
        CaseType.federalism => 'Federalism & Governance',
        CaseType.criminalLaw => 'Criminal Law & Procedure',
        CaseType.civilLaw => 'Civil Law',
        CaseType.environmentalLaw => 'Environmental Law',
        CaseType.humanRights => 'Human Rights',
        CaseType.socialJustice => 'Social Justice & Welfare',
        CaseType.electoralLaw => 'Elections & Democracy',
        CaseType.serviceMatter => 'Service Matters',
        CaseType.economicLaw => 'Economic Law',
        CaseType.commercialLaw => 'Commercial Law',
        CaseType.regulatoryLaw => 'Regulatory Law',
        CaseType.taxationLaw => 'Taxation',
        CaseType.administrativeLaw => 'Administrative Law',
        CaseType.labourLaw => 'Labour Law',
        CaseType.familyLaw => 'Family Law',
        CaseType.religiousLaw => 'Religious Law',
        CaseType.mediaLaw => 'Media & Speech Law',
        CaseType.policeLaw => 'Police & Custody',
        CaseType.other => 'Other',
      };
}
