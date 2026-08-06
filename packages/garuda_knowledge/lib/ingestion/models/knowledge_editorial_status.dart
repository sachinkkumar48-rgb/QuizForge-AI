/// Editorial Status Lifecycle for GARUDA Knowledge Ingestion Framework.
enum KnowledgeEditorialStatus {
  draft,
  editorialReview,
  approved,
  published,
  archived;

  String get label {
    switch (this) {
      case KnowledgeEditorialStatus.draft:
        return 'Draft';
      case KnowledgeEditorialStatus.editorialReview:
        return 'Editorial Review';
      case KnowledgeEditorialStatus.approved:
        return 'Approved';
      case KnowledgeEditorialStatus.published:
        return 'Published';
      case KnowledgeEditorialStatus.archived:
        return 'Archived';
    }
  }

  factory KnowledgeEditorialStatus.fromJson(String json) {
    return KnowledgeEditorialStatus.values.firstWhere(
      (e) => e.name == json,
      orElse: () => KnowledgeEditorialStatus.draft,
    );
  }

  String toJson() => name;
}
