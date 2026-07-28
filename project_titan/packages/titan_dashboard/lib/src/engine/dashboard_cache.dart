import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../models/dashboard_snapshot.dart';

/// Offline-first cache service for [DashboardSnapshot] with TTL support and `titan_storage` integration.
class DashboardCache {
  final StorageService? _storageService;
  final Duration cacheTtl;

  static const StorageKey _snapshotKey =
      StorageKey('dashboard_snapshot', namespace: 'dashboard');

  DashboardCache({
    StorageService? storageService,
    this.cacheTtl = const Duration(minutes: 15),
  }) : _storageService = storageService;

  /// Retrieves cached snapshot if available and not expired.
  Future<DashboardSnapshot?> getCachedSnapshot(String userId) async {
    if (_storageService == null) return null;
    try {
      final jsonStr = await _storageService.read<String>(_snapshotKey);
      if (jsonStr == null || jsonStr.isEmpty) return null;
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final snapshot = DashboardSnapshot.fromJson(map);

      if (snapshot.userId != userId) return null;

      final age = DateTime.now().difference(snapshot.generatedAt);
      if (age > cacheTtl) return null; // Expired

      return snapshot;
    } catch (_) {
      return null;
    }
  }

  /// Writes [snapshot] to persistent offline storage.
  Future<void> saveSnapshot(DashboardSnapshot snapshot) async {
    if (_storageService == null) return;
    try {
      final jsonStr = jsonEncode(snapshot.toJson());
      await _storageService.write<String>(_snapshotKey, jsonStr);
    } catch (_) {}
  }

  /// Clears cached snapshot.
  Future<void> clearCache() async {
    if (_storageService == null) return;
    try {
      await _storageService.delete(_snapshotKey);
    } catch (_) {}
  }
}
