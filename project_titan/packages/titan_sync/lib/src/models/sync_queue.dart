import 'dart:collection';

import 'sync_item.dart';
import 'sync_operation.dart';

/// Pure Dart offline queue manager maintaining pending sync operations and items.
class SyncQueue {
  final Queue<SyncOperation> _operations = Queue<SyncOperation>();
  final Map<String, SyncItem> _pendingItemMap = {};

  /// Total pending operations count.
  int get length => _operations.length;
  bool get isEmpty => _operations.isEmpty;
  bool get isNotEmpty => _operations.isNotEmpty;

  /// Enqueues an operation and updates pending item map.
  void enqueue(SyncOperation op, SyncItem item) {
    _operations.add(op);
    _pendingItemMap[item.entityId] = item;
  }

  /// Dequeues the next pending operation.
  SyncOperation? dequeue() {
    if (_operations.isEmpty) return null;
    return _operations.removeFirst();
  }

  /// Returns unmodifiable list of queued operations.
  List<SyncOperation> get queuedOperations =>
      List.unmodifiable(_operations.toList());

  /// Returns unmodifiable list of pending items.
  List<SyncItem> get pendingItems =>
      List.unmodifiable(_pendingItemMap.values.toList());

  /// Removes item from pending map by entityId.
  void removePendingItem(String entityId) {
    _pendingItemMap.remove(entityId);
  }

  /// Clears queue.
  void clear() {
    _operations.clear();
    _pendingItemMap.clear();
  }
}
