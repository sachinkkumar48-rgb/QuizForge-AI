import 'dart:convert';
import 'package:titan_storage/titan_storage.dart';
import '../models/knowledge_object.dart';
import 'knowledge_repository.dart';

/// Implementation of [KnowledgeRepository] reusing titan_storage for offline-first persistence.
class KnowledgeRepositoryImpl implements KnowledgeRepository {
  final StorageService storageService;
  static const String _namespace = 'k2_knowledge';
  final Map<String, KnowledgeObject> _inMemoryCache = {};

  KnowledgeRepositoryImpl({required this.storageService});

  @override
  Future<void> saveKnowledgeObject(KnowledgeObject object) async {
    _inMemoryCache[object.id] = object;
    final jsonStr = jsonEncode(object.toJson());
    final key = StorageKey(object.id, namespace: _namespace);
    await storageService.write<String>(key, jsonStr);
  }

  @override
  Future<KnowledgeObject?> getKnowledgeObjectById(String id) async {
    if (_inMemoryCache.containsKey(id)) {
      return _inMemoryCache[id];
    }
    final key = StorageKey(id, namespace: _namespace);
    final jsonStr = await storageService.read<String>(key);
    if (jsonStr == null) return null;
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final obj = KnowledgeObject.fromJson(map);
    _inMemoryCache[id] = obj;
    return obj;
  }

  @override
  Future<List<KnowledgeObject>> getAllKnowledgeObjects() async {
    final storageKeys = await storageService.keys(namespace: _namespace);
    final objects = <KnowledgeObject>[];
    for (final key in storageKeys) {
      final obj = await getKnowledgeObjectById(key.rawKey);
      if (obj != null) {
        objects.add(obj);
      }
    }
    return objects;
  }

  @override
  Future<void> deleteKnowledgeObject(String id) async {
    _inMemoryCache.remove(id);
    final key = StorageKey(id, namespace: _namespace);
    await storageService.delete(key);
  }

  @override
  Future<void> clearAll() async {
    _inMemoryCache.clear();
    final storageKeys = await storageService.keys(namespace: _namespace);
    for (final key in storageKeys) {
      await storageService.delete(key);
    }
  }
}
