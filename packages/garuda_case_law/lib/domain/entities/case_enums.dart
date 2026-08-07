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
