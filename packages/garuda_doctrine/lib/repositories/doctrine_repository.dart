library;

import '../domain/entities/doctrine_enums.dart';
import '../domain/entities/doctrine_knowledge_object.dart';

/// Abstract Contract for Constitutional Doctrine Repository.
abstract class DoctrineRepository {
  /// Get all registered doctrine knowledge objects.
  Future<List<DoctrineKnowledgeObject>> getDoctrines();

  /// Find a specific doctrine by doctrineId, objectId, or exact name.
  Future<DoctrineKnowledgeObject?> findDoctrine(String idOrName);

  /// Find doctrines by category.
  Future<List<DoctrineKnowledgeObject>> getDoctrinesByCategory(DoctrineCategory category);

  /// Find doctrines referencing a specific constitutional Article (e.g. "14", "21", "368").
  Future<List<DoctrineKnowledgeObject>> getDoctrinesByArticle(String articleNumber);

  /// Find doctrines originating from or associated with a specific case.
  Future<List<DoctrineKnowledgeObject>> getDoctrinesByCase(String caseNameOrId);

  /// Search doctrines using multi-criteria query (Name, Alias, Case, Article, Keyword, Explanation).
  Future<List<DoctrineKnowledgeObject>> searchDoctrines(String query);
}
