import '../domain/entities/knowledge_category.dart';
import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_tag.dart';
import '../domain/enums/knowledge_object_type.dart';
import '../domain/value_objects/knowledge_object_id.dart';
import '../repositories/knowledge_repository.dart';

class KnowledgeLookupService {
  final KnowledgeRepository _repository;

  KnowledgeLookupService(this._repository);

  Future<KnowledgeObject?> getById(KnowledgeObjectId id) async {
    return _repository.findById(id);
  }

  Future<List<KnowledgeObject>> getByType(KnowledgeObjectType type) async {
    return _repository.findByType(type);
  }

  Future<List<KnowledgeObject>> getByTag(KnowledgeTag tag) async {
    return _repository.findByTag(tag);
  }

  Future<List<KnowledgeObject>> getByCategory(KnowledgeCategory category) async {
    final all = await _repository.bulkExport();
    return all.where((obj) => obj.category?.id == category.id).toList();
  }
}
