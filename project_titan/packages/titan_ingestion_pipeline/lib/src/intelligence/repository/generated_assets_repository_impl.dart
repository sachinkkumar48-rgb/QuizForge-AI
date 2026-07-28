import 'dart:convert';
import 'package:titan_storage/titan_storage.dart';
import '../models/generated_learning_assets.dart';
import 'generated_assets_repository.dart';

/// Implementation of [GeneratedAssetsRepository] using titan_storage.
class GeneratedAssetsRepositoryImpl implements GeneratedAssetsRepository {
  final StorageService storageService;
  static const String _namespace = 'k3_assets';
  final Map<String, GeneratedKnowledgeAssets> _inMemoryCache = {};

  GeneratedAssetsRepositoryImpl({required this.storageService});

  @override
  Future<void> saveGeneratedAssets(GeneratedKnowledgeAssets assets) async {
    _inMemoryCache[assets.id] = assets;
    final jsonStr = jsonEncode(assets.toJson());
    final key = StorageKey(assets.id, namespace: _namespace);
    await storageService.write<String>(key, jsonStr);
  }

  @override
  Future<GeneratedKnowledgeAssets?> getAssetsById(String id) async {
    if (_inMemoryCache.containsKey(id)) {
      return _inMemoryCache[id];
    }
    final key = StorageKey(id, namespace: _namespace);
    final jsonStr = await storageService.read<String>(key);
    if (jsonStr == null) return null;

    // Fast memory return once loaded
    return _inMemoryCache[id];
  }

  @override
  Future<GeneratedKnowledgeAssets?> getAssetsByKnowledgeObjectId(
      String knowledgeObjectId) async {
    for (final asset in _inMemoryCache.values) {
      if (asset.sourceKnowledgeObjectId == knowledgeObjectId) {
        return asset;
      }
    }
    return null;
  }

  @override
  Future<List<GeneratedKnowledgeAssets>> getAllGeneratedAssets() async {
    return _inMemoryCache.values.toList();
  }

  @override
  Future<void> deleteAssets(String id) async {
    _inMemoryCache.remove(id);
    final key = StorageKey(id, namespace: _namespace);
    await storageService.delete(key);
  }
}
