library;

import '../domain/entities/article_knowledge_object.dart';
import '../domain/entities/constitution_knowledge_object.dart';
import '../domain/entities/constitution_metadata.dart';
import '../domain/entities/part_knowledge_object.dart';
import '../domain/entities/preamble_knowledge_object.dart';
import '../domain/entities/schedule_knowledge_object.dart';

/// Abstract repository contract for retrieving constitutional knowledge assets.
abstract class ConstitutionRepository {
  Future<ConstitutionMetadata> getMetadata();
  Future<PreambleKnowledgeObject> getPreamble();
  Future<List<PartKnowledgeObject>> getParts();
  Future<List<ScheduleKnowledgeObject>> getSchedules();
  Future<List<ArticleKnowledgeObject>> getArticles();
  Future<PartKnowledgeObject?> findPart(String idOrNumber);
  Future<ScheduleKnowledgeObject?> findSchedule(String idOrNumber);
  Future<ArticleKnowledgeObject?> findArticle(String articleNumber);
  Future<List<ArticleKnowledgeObject>> getArticlesByPart(String partIdOrNumber);
  Future<List<ConstitutionKnowledgeObject>> findByArticle(String article);
  Future<List<ConstitutionKnowledgeObject>> findByAmendment(String amendment);
  Future<ConstitutionKnowledgeObject?> getObjectById(String objectId);
  Future<List<ConstitutionKnowledgeObject>> searchObjects(String query);
}

