import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/analytics_engine_models.dart';
import '../analytics_repository.dart';

/// Hive box implementation of [AnalyticsRepository].
class HiveAnalyticsRepository implements AnalyticsRepository {
  static const String _boxName = 'engine_analytics_snapshots';
  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<void> saveSnapshot(AnalyticsSnapshot snapshot) async {
    final box = await _getBox();
    await box.put(snapshot.snapshotId, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<List<AnalyticsSnapshot>> getSnapshots() async {
    final box = await _getBox();
    final List<AnalyticsSnapshot> snapshots = [];

    for (final key in box.keys) {
      final str = box.get(key);
      if (str != null) {
        try {
          snapshots.add(AnalyticsSnapshot.fromJson(jsonDecode(str)));
        } catch (_) {}
      }
    }

    snapshots.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return snapshots;
  }

  @override
  Future<AnalyticsSnapshot?> getLatestSnapshot() async {
    final snapshots = await getSnapshots();
    return snapshots.isNotEmpty ? snapshots.last : null;
  }

  @override
  Future<void> deleteSnapshot(String snapshotId) async {
    final box = await _getBox();
    await box.delete(snapshotId);
  }

  @override
  Future<void> clear() async {
    final box = await _getBox();
    await box.clear();
  }
}
