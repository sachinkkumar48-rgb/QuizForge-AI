import 'dart:convert';

import 'package:titan_storage/titan_storage.dart';

import '../models/sync_conflict.dart';
import '../models/sync_item.dart';
import 'sync_repository.dart';

/// Concrete implementation of [SyncRepository] managing local offline sync storage.
class SyncRepositoryImpl implements SyncRepository {
  final StorageService? _storageService;
  static const StorageKey _queueKey =
      StorageKey('sync_queue', namespace: 'sync');
  static const StorageKey _conflictsKey =
      StorageKey('sync_conflicts', namespace: 'sync');

  final Map<String, SyncItem> _queueMap = {};
  final Map<String, SyncConflict> _conflictMap = {};

  SyncRepositoryImpl({StorageService? storageService})
      : _storageService = storageService;

  Future<void> _persist() async {
    if (_storageService == null) return;
    try {
      final queueJson =
          jsonEncode(_queueMap.values.map((item) => item.toJson()).toList());
      await _storageService.write<String>(_queueKey, queueJson);

      final conflictsJson = jsonEncode(
          _conflictMap.values.map((conflict) => conflict.toJson()).toList());
      await _storageService.write<String>(_conflictsKey, conflictsJson);
    } catch (_) {}
  }

  Future<void> _hydrate() async {
    if (_storageService == null) return;
    try {
      final queueJson = await _storageService.read<String>(_queueKey);
      if (queueJson != null && queueJson.isNotEmpty) {
        final List list = jsonDecode(queueJson) as List;
        for (final item in list) {
          final syncItem =
              SyncItem.fromJson(Map<String, dynamic>.from(item as Map));
          _queueMap[syncItem.id] = syncItem;
        }
      }

      final conflictsJson = await _storageService.read<String>(_conflictsKey);
      if (conflictsJson != null && conflictsJson.isNotEmpty) {
        final List list = jsonDecode(conflictsJson) as List;
        for (final item in list) {
          final conflict =
              SyncConflict.fromJson(Map<String, dynamic>.from(item as Map));
          _conflictMap[conflict.conflictId] = conflict;
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> queueItem(SyncItem item) async {
    await _hydrate();
    _queueMap[item.id] = item;
    await _persist();
  }

  @override
  Future<List<SyncItem>> getPendingItems() async {
    await _hydrate();
    return _queueMap.values
        .where((item) =>
            item.status == SyncItemStatus.pending ||
            item.status == SyncItemStatus.failed)
        .toList();
  }

  @override
  Future<List<SyncItem>> getAllItems() async {
    await _hydrate();
    return _queueMap.values.toList();
  }

  @override
  Future<void> updateItem(SyncItem item) async {
    await _hydrate();
    _queueMap[item.id] = item;
    await _persist();
  }

  @override
  Future<void> removeItem(String itemId) async {
    await _hydrate();
    _queueMap.remove(itemId);
    await _persist();
  }

  @override
  Future<void> saveConflict(SyncConflict conflict) async {
    await _hydrate();
    _conflictMap[conflict.conflictId] = conflict;
    await _persist();
  }

  @override
  Future<List<SyncConflict>> getConflicts() async {
    await _hydrate();
    return _conflictMap.values
        .where((conflict) => !conflict.isResolved)
        .toList();
  }

  @override
  Future<void> resolveConflict(String conflictId, SyncItem resolvedItem) async {
    await _hydrate();
    final conflict = _conflictMap[conflictId];
    if (conflict != null) {
      _conflictMap[conflictId] = conflict.copyWith(
        isResolved: true,
        resolvedItem: resolvedItem,
      );
    }
    _queueMap[resolvedItem.id] = resolvedItem;
    await _persist();
  }

  @override
  Future<void> clearSyncedItems() async {
    await _hydrate();
    _queueMap.removeWhere((_, item) => item.status == SyncItemStatus.synced);
    await _persist();
  }
}
