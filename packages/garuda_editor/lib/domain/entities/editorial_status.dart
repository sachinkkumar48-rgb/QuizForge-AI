library;

/// Complete editorial lifecycle status enum for Knowledge Objects in GARUDA Editorial Studio.
/// Strict 10-state progression required by Prompt TITAN-KO-008.0.
enum EditorialStatus {
  imported,
  pendingReview,
  inReview,
  evidenceVerified,
  factVerified,
  technicalReview,
  seniorEditorialReview,
  approved,
  published,
  archived,
  // Backwards compatibility aliases
  draft,
  reviewPending,
  needsRevision,
  rejected,
}

extension EditorialStatusExtension on EditorialStatus {
  String get displayName {
    switch (this) {
      case EditorialStatus.imported:
        return 'Imported';
      case EditorialStatus.pendingReview:
      case EditorialStatus.reviewPending:
        return 'Pending Review';
      case EditorialStatus.inReview:
        return 'In Review';
      case EditorialStatus.evidenceVerified:
        return 'Evidence Verified';
      case EditorialStatus.factVerified:
        return 'Fact Verified';
      case EditorialStatus.technicalReview:
        return 'Technical Review';
      case EditorialStatus.seniorEditorialReview:
        return 'Senior Editorial Review';
      case EditorialStatus.approved:
        return 'Approved';
      case EditorialStatus.published:
        return 'Published';
      case EditorialStatus.archived:
        return 'Archived';
      case EditorialStatus.draft:
        return 'Draft';
      case EditorialStatus.needsRevision:
        return 'Needs Revision';
      case EditorialStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isPublished => this == EditorialStatus.published;
  bool get isArchived => this == EditorialStatus.archived;
  bool get isApproved => this == EditorialStatus.approved;
}
