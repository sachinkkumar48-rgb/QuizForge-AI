import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/dataset_manifest.dart';
import '../dataset_repository.dart';

class HiveDatasetRepository implements DatasetRepository {
  static const String _boxName = 'engine_dataset_manifests';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<void> saveManifest(DatasetManifest manifest) async {
    final box = await _getBox();
    await box.put(manifest.datasetId, jsonEncode(manifest.toJson()));
  }

  @override
  Future<DatasetManifest?> getManifest(String datasetId) async {
    final box = await _getBox();
    final jsonStr = box.get(datasetId);
    if (jsonStr == null) return null;
    try {
      return DatasetManifest.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DatasetManifest>> getAllManifests() async {
    final box = await _getBox();
    final List<DatasetManifest> list = [];
    for (final key in box.keys) {
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          list.add(DatasetManifest.fromJson(jsonDecode(jsonStr)));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  @override
  Future<void> deleteManifest(String datasetId) async {
    final box = await _getBox();
    await box.delete(datasetId);
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
