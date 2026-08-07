library;

import '../domain/entities/case_knowledge_object.dart';

/// Abstract Contract for Constitutional Case Repository.
abstract class CaseRepository {
  /// Get all registered case knowledge objects.
  Future<List<CaseKnowledgeObject>> getCases();

  /// Find a specific case by caseId, objectId, or exact title.
  Future<CaseKnowledgeObject?> findCase(String idOrName);

  /// Find cases related to a specific constitutional Article (e.g., "14", "21").
  Future<List<CaseKnowledgeObject>> getCasesByArticle(String articleNumber);

  /// Find cases related to a specific Constitutional Amendment (e.g., "42nd Amendment", "24th").
  Future<List<CaseKnowledgeObject>> getCasesByAmendment(String amendment);

  /// Find cases decided by a specific judge.
  Future<List<CaseKnowledgeObject>> getCasesByJudge(String judgeName);

  /// Search cases using multi-criteria query (Name, Citation, Article, Legal Principle, Doctrine, Judge).
  Future<List<CaseKnowledgeObject>> searchCases(String query);
}
