library;

import '../../domain/entities/editorial_status.dart';
import '../../domain/entities/knowledge_object.dart';

/// Item wrapper in the Editorial Queue.
class EditorialQueueItem {
  final KnowledgeObject object;
  final DateTime queuedAt;
  final int priority; // 1 (Highest) to 5 (Lowest)
  final String? assignedReviewerId;

  EditorialQueueItem({
    required this.object,
    required this.queuedAt,
    this.priority = 3,
    this.assignedReviewerId,
  });

  EditorialQueueItem copyWith({
    KnowledgeObject? object,
    DateTime? queuedAt,
    int? priority,
    String? assignedReviewerId,
  }) {
    return EditorialQueueItem(
      object: object ?? this.object,
      queuedAt: queuedAt ?? this.queuedAt,
      priority: priority ?? this.priority,
      assignedReviewerId: assignedReviewerId ?? this.assignedReviewerId,
    );
  }
}

/// Queue manager for objects awaiting review/verification at each editorial stage.
class EditorialQueue {
  final Map<String, EditorialQueueItem> _items = {};

  void enqueue(KnowledgeObject object, {int priority = 3, String? assignedReviewerId}) {
    _items[object.id] = EditorialQueueItem(
      object: object,
      queuedAt: DateTime.now(),
      priority: priority,
      assignedReviewerId: assignedReviewerId,
    );
  }

  bool dequeue(String objectId) {
    return _items.remove(objectId) != null;
  }

  EditorialQueueItem? getItem(String objectId) => _items[objectId];

  List<EditorialQueueItem> getPendingByStage(EditorialStatus status) {
    return _items.values.where((item) => item.object.status == status).toList()
      ..sort((a, b) {
        final priorityComp = a.priority.compareTo(b.priority);
        if (priorityComp != 0) return priorityComp;
        return a.queuedAt.compareTo(b.queuedAt);
      });
  }

  List<EditorialQueueItem> getItemsByReviewer(String reviewerId) {
    return _items.values
        .where((item) => item.assignedReviewerId == reviewerId)
        .toList();
  }

  int get count => _items.length;

  void clear() => _items.clear();
}
