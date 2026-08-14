import 'review_item.dart';

/// Aggregate root representing the complete spaced repetition review schedule for a learner.
class ReviewSchedule {
  /// Unique identifier of the learner.
  final String learnerId;

  /// Map of P17 objective IDs to their corresponding [ReviewItem] states.
  final Map<String, ReviewItem> _items;

  /// UTC timestamp when this schedule aggregate was created.
  final DateTime createdAt;

  /// UTC timestamp when this schedule aggregate was last modified.
  final DateTime updatedAt;

  ReviewSchedule({
    required this.learnerId,
    Map<String, ReviewItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : _items = Map<String, ReviewItem>.from(items ?? {}),
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? DateTime.now()).toUtc();

  /// Unmodifiable view of all scheduled review items.
  Map<String, ReviewItem> get items => Map.unmodifiable(_items);

  /// Number of review items tracked in this schedule.
  int get itemCount => _items.length;

  /// Retrieves the [ReviewItem] for [objectiveId], if scheduled.
  ReviewItem? getItem(String objectiveId) => _items[objectiveId];

  /// Checks if [objectiveId] is present in this schedule.
  bool containsObjective(String objectiveId) => _items.containsKey(objectiveId);

  /// Adds a new [ReviewItem] to the schedule. Throws [ArgumentError] if already present.
  ReviewSchedule addItem(ReviewItem item, {DateTime? updatedAt}) {
    if (_items.containsKey(item.objectiveId)) {
      throw ArgumentError(
        'Objective ${item.objectiveId} already exists in learner schedule for $learnerId',
      );
    }
    final newItems = Map<String, ReviewItem>.from(_items);
    newItems[item.objectiveId] = item;
    return ReviewSchedule(
      learnerId: learnerId,
      items: newItems,
      createdAt: createdAt,
      updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Updates or inserts a [ReviewItem] in the schedule.
  ReviewSchedule updateItem(ReviewItem item, {DateTime? updatedAt}) {
    final newItems = Map<String, ReviewItem>.from(_items);
    newItems[item.objectiveId] = item;
    return ReviewSchedule(
      learnerId: learnerId,
      items: newItems,
      createdAt: createdAt,
      updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Removes an item by [objectiveId] from the schedule.
  ReviewSchedule removeItem(String objectiveId, {DateTime? updatedAt}) {
    if (!_items.containsKey(objectiveId)) return this;
    final newItems = Map<String, ReviewItem>.from(_items);
    newItems.remove(objectiveId);
    return ReviewSchedule(
      learnerId: learnerId,
      items: newItems,
      createdAt: createdAt,
      updatedAt: (updatedAt ?? DateTime.now()).toUtc(),
    );
  }

  /// Retrieves all items due for review as of [asOfDate], ordered by priority score descending.
  List<ReviewItem> getDueItems({DateTime? asOfDate}) {
    final effectiveAsOf = (asOfDate ?? DateTime.now()).toUtc();
    final dueItems = _items.values
        .where((item) => item.isDue(asOfDate: effectiveAsOf))
        .toList();

    dueItems.sort((a, b) {
      final pA = a.priorityScore(asOfDate: effectiveAsOf);
      final pB = b.priorityScore(asOfDate: effectiveAsOf);
      // Higher priority first (overdue items prioritized)
      final cmp = pB.compareTo(pA);
      if (cmp != 0) return cmp;
      return a.objectiveId.compareTo(b.objectiveId);
    });

    return dueItems;
  }

  Map<String, dynamic> toJson() {
    return {
      'learnerId': learnerId,
      'items': _items.map((k, v) => MapEntry(k, v.toJson())),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReviewSchedule.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as Map<String, dynamic>? ?? {};
    final parsedItems = rawItems.map(
      (k, v) => MapEntry(k, ReviewItem.fromJson(v as Map<String, dynamic>)),
    );
    return ReviewSchedule(
      learnerId: json['learnerId'] as String,
      items: parsedItems,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReviewSchedule) return false;
    if (other.learnerId != learnerId ||
        other.itemCount != itemCount ||
        other.createdAt != createdAt ||
        other.updatedAt != updatedAt) {
      return false;
    }
    for (final key in _items.keys) {
      if (other._items[key] != _items[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      learnerId,
      Object.hashAll(_items.entries),
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'ReviewSchedule(learnerId: $learnerId, itemCount: $itemCount, updatedAt: $updatedAt)';
  }
}
