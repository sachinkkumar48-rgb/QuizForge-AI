/// Knowledge Document Types for GARUDA National Knowledge Ingestion Framework.
enum KnowledgeDocumentType {
  constitution,
  gazetteNotification,
  upscQuestionPaper,
  upscAnswerKey,
  pibRelease,
  prsReport,
  supremeCourtJudgment,
  ministryReport,
  economicSurvey,
  unionBudget,
  generic;

  String get displayName {
    switch (this) {
      case KnowledgeDocumentType.constitution:
        return 'Constitution of India';
      case KnowledgeDocumentType.gazetteNotification:
        return 'Gazette Notification';
      case KnowledgeDocumentType.upscQuestionPaper:
        return 'UPSC Question Paper';
      case KnowledgeDocumentType.upscAnswerKey:
        return 'UPSC Official Answer Key';
      case KnowledgeDocumentType.pibRelease:
        return 'PIB Press Release';
      case KnowledgeDocumentType.prsReport:
        return 'PRS Legislative Report';
      case KnowledgeDocumentType.supremeCourtJudgment:
        return 'Supreme Court Judgment';
      case KnowledgeDocumentType.ministryReport:
        return 'Ministry Report';
      case KnowledgeDocumentType.economicSurvey:
        return 'Economic Survey';
      case KnowledgeDocumentType.unionBudget:
        return 'Union Budget';
      case KnowledgeDocumentType.generic:
        return 'Generic Knowledge Document';
    }
  }

  factory KnowledgeDocumentType.fromJson(String json) {
    return KnowledgeDocumentType.values.firstWhere(
      (e) => e.name == json,
      orElse: () => KnowledgeDocumentType.generic,
    );
  }

  String toJson() => name;
}
