library;

/// Classification types of Constitutional Parts.
enum PartType {
  preamble,
  corePart,
  amendedPart,
  repealedPart,
  specialProvisionPart,
}

/// Classification types of Constitutional Schedules.
enum ScheduleType {
  territorial,
  emoluments,
  oaths,
  representation,
  tribalAdministration,
  legislativeLists,
  officialLanguages,
  landReforms,
  antiDefection,
  localGovernance,
}

/// Constitutional status designation.
enum ConstitutionStatus {
  active,
  amended,
  repealed,
  substituted,
}
