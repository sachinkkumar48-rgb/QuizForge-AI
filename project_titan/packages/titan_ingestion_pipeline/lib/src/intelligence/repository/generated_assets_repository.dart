import '../models/generated_learning_assets.dart';

/// Repository interface for persisting generated educational assets.
abstract class GeneratedAssetsRepository {
  Future<void> saveGeneratedAssets(GeneratedKnowledgeAssets assets);
  Future<GeneratedKnowledgeAssets?> getAssetsById(String id);
  Future<GeneratedKnowledgeAssets?> getAssetsByKnowledgeObjectId(
      String knowledgeObjectId);
  Future<List<GeneratedKnowledgeAssets>> getAllGeneratedAssets();
  Future<void> deleteAssets(String id);
}
