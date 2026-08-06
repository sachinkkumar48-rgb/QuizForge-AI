import '../domain/entities/knowledge_object.dart';
import '../domain/entities/knowledge_version.dart';
import '../domain/value_objects/knowledge_object_id.dart';
import '../repositories/knowledge_repository.dart';

class KnowledgeVersionService {
  final KnowledgeRepository _repository;

  KnowledgeVersionService(this._repository);

  Future<KnowledgeObject> createNewVersion(
    KnowledgeObjectId id, {
    required String updatedContent,
    required String commitMessage,
    required String author,
  }) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw StateError('KnowledgeObject with ID $id not found.');
    }

    final newVerNumber = existing.currentVersion.versionNumber + 1;
    final newVersion = KnowledgeVersion(
      versionNumber: newVerNumber,
      commitMessage: commitMessage,
      author: author,
      timestamp: DateTime.now(),
    );

    final updated = existing.copyWith(
      content: updatedContent,
      currentVersion: newVersion,
    );

    await _repository.update(updated);
    return updated;
  }

  Future<List<KnowledgeVersion>> getVersionHistory(KnowledgeObjectId id) async {
    return _repository.versionHistory(id);
  }
}
