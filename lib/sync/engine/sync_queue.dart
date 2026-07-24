import '../core/sync_entity.dart';

/// Item in the offline change queue.
class SyncQueueItem {
  final String queueId;
  final SyncEntity<Map<String, dynamic>> entity;
  final DateTime queuedAt;

  SyncQueueItem({
    required this.queueId,
    required this.entity,
    DateTime? queuedAt,
  }) : queuedAt = queuedAt ?? DateTime.now().toUtc();

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      queueId: json['queueId'] as String? ?? '',
      entity: SyncEntity<Map<String, dynamic>>.fromJson(
        Map<String, dynamic>.from(json['entity'] as Map),
        (p) => p,
      ),
      queuedAt: json['queuedAt'] != null
          ? DateTime.parse(json['queuedAt'] as String).toUtc()
          : DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queueId': queueId,
      'entity': entity.toJson((p) => p),
      'queuedAt': queuedAt.toIso8601String(),
    };
  }
}

/// In-memory and persistent offline change queue manager.
class SyncQueue {
  final List<SyncQueueItem> _queue = [];

  /// Add entity mutation to queue.
  void enqueue(SyncEntity<Map<String, dynamic>> entity) {
    // Deduplicate by entityId + entityType (replace older mutation with newer)
    _queue.removeWhere((item) =>
        item.entity.metadata.entityId == entity.metadata.entityId &&
        item.entity.metadata.entityType == entity.metadata.entityType);

    _queue.add(SyncQueueItem(
      queueId:
          '${entity.metadata.entityType.name}_${entity.metadata.entityId}_${DateTime.now().millisecondsSinceEpoch}',
      entity: entity,
    ));
  }

  /// Get pending offline items in queue.
  List<SyncQueueItem> get pendingItems => List.unmodifiable(_queue);

  /// Number of pending mutations.
  int get length => _queue.length;

  /// Check if queue is empty.
  bool get isEmpty => _queue.isEmpty;

  /// Clear applied items from queue.
  void clear() {
    _queue.clear();
  }

  /// Remove specific items from queue by IDs.
  void removeItems(Set<String> queueIds) {
    _queue.removeWhere((item) => queueIds.contains(item.queueId));
  }
}
