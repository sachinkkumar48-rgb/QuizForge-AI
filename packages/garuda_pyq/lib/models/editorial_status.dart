/// Life cycle editorial status for PYQ entries.
enum EditorialStatus {
  imported,
  ocrPending,
  verificationPending,
  verified,
  answerVerified,
  conceptTagged,
  knowledgeLinked,
  readyForPublication,
  mapped,
  published,
  archived,
}

extension EditorialStatusX on EditorialStatus {
  String get label {
    switch (this) {
      case EditorialStatus.imported:
        return 'Imported';
      case EditorialStatus.ocrPending:
        return 'OCR Pending';
      case EditorialStatus.verificationPending:
        return 'Verification Pending';
      case EditorialStatus.verified:
        return 'Verified';
      case EditorialStatus.answerVerified:
        return 'Answer Verified';
      case EditorialStatus.conceptTagged:
        return 'Concept Tagged';
      case EditorialStatus.knowledgeLinked:
        return 'Knowledge Linked';
      case EditorialStatus.readyForPublication:
        return 'Ready For Publication';
      case EditorialStatus.mapped:
        return 'Mapped';
      case EditorialStatus.published:
        return 'Published';
      case EditorialStatus.archived:
        return 'Archived';
    }
  }
}
