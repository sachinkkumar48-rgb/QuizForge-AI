/// Domain entity representing the item-level spaced repetition state for a learning objective.
class ReviewItem {
  /// Unique identifier of the schedulable P17 Learning Objective.
  final String objectiveId;

  /// Current scheduled review interval in days (range: [1, 180]).
  final int intervalDays;

  /// SM-2 ease factor determining interval growth speed (range: [1.3, 2.5]).
  final double easeFactor;

  /// UTC timestamp indicating when this objective is next due for review.
  final DateTime nextReviewDate;

  /// Optional UTC timestamp of the last completed review attempt.
  final DateTime? lastReviewed;

  /// Total number of review attempts completed for this item.
  final int reviewCount;

  /// UTC timestamp when this review item was initialized.
  final DateTime createdAt;

  ReviewItem({
    required this.objectiveId,
    required int intervalDays,
    required double easeFactor,
    required DateTime nextReviewDate,
    this.lastReviewed,
    this.reviewCount = 0,
    DateTime? createdAt,
  })  : intervalDays = intervalDays.clamp(1, 180),
        easeFactor = easeFactor.clamp(1.3, 2.5),
        nextReviewDate = nextReviewDate.toUtc(),
        createdAt = (createdAt ?? DateTime.now()).toUtc();

  /// Creates a initial review item for a newly completed objective with a default
  /// 1-day interval and 2.5 SM-2 ease factor.
  factory ReviewItem.initial(String objectiveId, {DateTime? now}) {
    final effectiveNow = (now ?? DateTime.now()).toUtc();
    return ReviewItem(
      objectiveId: objectiveId,
      intervalDays: 1,
      easeFactor: 2.5,
      nextReviewDate: effectiveNow.add(const Duration(days: 1)),
      lastReviewed: null,
      reviewCount: 0,
      createdAt: effectiveNow,
    );
  }

  /// Checks if this item is due for review as of [asOfDate].
  bool isDue({DateTime? asOfDate}) {
    final effectiveAsOf = (asOfDate ?? DateTime.now()).toUtc();
    return nextReviewDate.isBefore(effectiveAsOf) ||
        nextReviewDate.isAtSameMomentAs(effectiveAsOf);
  }

  /// Calculates priority score for review (higher value = more overdue).
  double priorityScore({DateTime? asOfDate}) {
    final effectiveAsOf = (asOfDate ?? DateTime.now()).toUtc();
    final overdueHours =
        effectiveAsOf.difference(nextReviewDate).inMinutes / 60.0;
    return overdueHours.clamp(0.0, 10000.0);
  }

  ReviewItem copyWith({
    String? objectiveId,
    int? intervalDays,
    double? easeFactor,
    DateTime? nextReviewDate,
    DateTime? lastReviewed,
    int? reviewCount,
    DateTime? createdAt,
  }) {
    return ReviewItem(
      objectiveId: objectiveId ?? this.objectiveId,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'objectiveId': objectiveId,
      'intervalDays': intervalDays,
      'easeFactor': easeFactor,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    return ReviewItem(
      objectiveId: json['objectiveId'] as String,
      intervalDays: json['intervalDays'] as int,
      easeFactor: (json['easeFactor'] as num).toDouble(),
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.parse(json['lastReviewed'] as String)
          : null,
      reviewCount: json['reviewCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReviewItem &&
        other.objectiveId == objectiveId &&
        other.intervalDays == intervalDays &&
        (other.easeFactor - easeFactor).abs() < 0.001 &&
        other.nextReviewDate == nextReviewDate &&
        other.lastReviewed == lastReviewed &&
        other.reviewCount == reviewCount &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      objectiveId,
      intervalDays,
      easeFactor,
      nextReviewDate,
      lastReviewed,
      reviewCount,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'ReviewItem(objectiveId: $objectiveId, intervalDays: $intervalDays, '
        'easeFactor: ${easeFactor.toStringAsFixed(2)}, nextReviewDate: $nextReviewDate, '
        'reviewCount: $reviewCount)';
  }
}
