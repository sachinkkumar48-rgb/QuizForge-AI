import '../models/knowledge_object.dart';

/// Repository interface for persisting canonical Knowledge Objects.
abstract class KnowledgeRepository {
  Future<void> saveKnowledgeObject(KnowledgeObject object);
  Future<KnowledgeObject?> getKnowledgeObjectById(String id);
  Future<List<KnowledgeObject>> getAllKnowledgeObjects();
  Future<void> deleteKnowledgeObject(String id);
  Future<void> clearAll();
}
