import 'dart:convert';
import 'package:titan_storage/titan_storage.dart';
import '../models/editorial_models.dart';
import 'editorial_repository.dart';

/// Implementation of [EditorialRepository] using titan_storage.
class EditorialRepositoryImpl implements EditorialRepository {
  final StorageService storageService;
  static const String _namespace = 'k3_5_editorial';
  final Map<String, EditorialAssetRecord> _inMemoryCache = {};

  EditorialRepositoryImpl({required this.storageService});

  @override
  Future<void> saveRecord(EditorialAssetRecord record) async {
    _inMemoryCache[record.id] = record;
    final jsonStr = jsonEncode(record.toJson());
    final key = StorageKey(record.id, namespace: _namespace);
    await storageService.write<String>(key, jsonStr);
  }

  @override
  Future<EditorialAssetRecord?> getRecordById(String id) async {
    if (_inMemoryCache.containsKey(id)) {
      return _inMemoryCache[id];
    }
    final key = StorageKey(id, namespace: _namespace);
    final jsonStr = await storageService.read<String>(key);
    if (jsonStr == null) return null;
    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final record = EditorialAssetRecord.fromJson(decoded);
      _inMemoryCache[id] = record;
      return record;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<EditorialAssetRecord>> getAllRecords(
      {EditorialStatus? statusFilter}) async {
    final keys = await storageService.keys(namespace: _namespace);
    for (final key in keys) {
      if (!_inMemoryCache.containsKey(key.rawKey)) {
        final jsonStr = await storageService.read<String>(key);
        if (jsonStr != null) {
          try {
            final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
            final record = EditorialAssetRecord.fromJson(decoded);
            _inMemoryCache[record.id] = record;
          } catch (_) {}
        }
      }
    }
    final list = _inMemoryCache.values.toList();
    if (statusFilter == null) return list;
    return list.where((r) => r.status == statusFilter).toList();
  }

  @override
  Future<void> deleteRecord(String id) async {
    _inMemoryCache.remove(id);
    final key = StorageKey(id, namespace: _namespace);
    await storageService.delete(key);
  }

  @override
  Future<void> clearAll() async {
    _inMemoryCache.clear();
    final keys = await storageService.keys(namespace: _namespace);
    for (final k in keys) {
      await storageService.delete(k);
    }
  }
}
