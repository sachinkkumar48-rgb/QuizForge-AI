import '../models/review_schedule_item.dart';

/// Deterministic spaced-review scheduler for question and topic reinforcement.
class ReviewScheduler {
  final List<Duration> intervalLadder;
  final Duration shortInterval;

  const ReviewScheduler({
    this.intervalLadder = const [
      Duration(days: 1),
      Duration(days: 3),
      Duration(days: 7),
      Duration(days: 14),
      Duration(days: 30),
    ],
    this.shortInterval = const Duration(days: 1),
  });

  /// Schedules a new review item.
  ReviewScheduleItem scheduleItem({
    required String id,
    required String topic,
    String? questionId,
    String? sourceChunkId,
    int? pageNumber,
    String? documentId,
    DateTime? scheduledAt,
    Duration? initialInterval,
  }) {
    final now = scheduledAt ?? DateTime.now();
    final interval = initialInterval ??
        (intervalLadder.isNotEmpty ? intervalLadder.first : shortInterval);
    return ReviewScheduleItem(
      id: id,
      topic: topic,
      questionId: questionId,
      status: ReviewStatus.learning,
      reviewInterval: interval,
      nextReviewAt: now.add(interval),
      lastAttemptAt: now,
      consecutiveCorrect: 0,
      sourceChunkId: sourceChunkId,
      pageNumber: pageNumber,
      documentId: documentId,
    );
  }

  /// Updates a review item based on attempt evaluation.
  ReviewScheduleItem markAttempt({
    required ReviewScheduleItem item,
    required bool isCorrect,
    DateTime? attemptTime,
  }) {
    final now = attemptTime ?? DateTime.now();

    if (!isCorrect) {
      // Incorrect attempt: reset ladder and schedule short review interval
      return item.copyWith(
        status: ReviewStatus.learning,
        reviewInterval: shortInterval,
        nextReviewAt: now.add(shortInterval),
        lastAttemptAt: now,
        consecutiveCorrect: 0,
      );
    } else {
      // Correct attempt: progress down interval ladder
      final nextStreak = item.consecutiveCorrect + 1;
      final ladderIndex = nextStreak.clamp(0, intervalLadder.length - 1);
      final nextInterval = intervalLadder[ladderIndex];
      final isMastered = nextStreak >= 3;

      return item.copyWith(
        status: isMastered ? ReviewStatus.mastered : ReviewStatus.learning,
        reviewInterval: nextInterval,
        nextReviewAt: now.add(nextInterval),
        lastAttemptAt: now,
        consecutiveCorrect: nextStreak,
      );
    }
  }

  /// Returns all items currently due for review as of [asOf], sorted by most overdue first.
  List<ReviewScheduleItem> getDueItems({
    required List<ReviewScheduleItem> items,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final due = items.where((item) => item.isDue(now)).toList()
      ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return List.unmodifiable(due);
  }

  /// Reschedules an item with an explicit interval override.
  ReviewScheduleItem rescheduleItem({
    required ReviewScheduleItem item,
    required Duration newInterval,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    return item.copyWith(
      reviewInterval: newInterval,
      nextReviewAt: now.add(newInterval),
    );
  }
}
