import '../domain/entities/performance_rating.dart';
import '../domain/entities/review_item.dart';
import '../domain/entities/review_result.dart';
import '../domain/entities/review_schedule.dart';
import '../repository/review_schedule_repository.dart';

/// Application service implementing evidence-backed, deterministic spaced repetition
/// review scheduling using SuperMemo-2 (SM-2).
class SpacedRepetitionService {
  final ReviewScheduleRepository _repository;

  SpacedRepetitionService({
    ReviewScheduleRepository? repository,
  }) : _repository = repository ?? InMemoryReviewScheduleRepository();

  /// Adds a P17 Learning Objective to a learner's review schedule with initial 1-day interval.
  /// If the objective is already scheduled, returns the existing [ReviewItem].
  Future<ReviewItem> addToSchedule(
    String learnerId,
    String objectiveId, {
    DateTime? now,
  }) async {
    final existing = await _repository.getReviewItem(learnerId, objectiveId);
    if (existing != null) return existing;

    final initialItem = ReviewItem.initial(objectiveId, now: now);
    await _repository.saveReviewItem(learnerId, initialItem);
    return initialItem;
  }

  /// Calculates next review interval and ease factor after completing a review attempt
  /// using SuperMemo-2 (SM-2) deterministic algorithm rules.
  Future<ReviewItem> updateAfterReview({
    required String learnerId,
    required String objectiveId,
    required double assessmentScore,
    PerformanceRating? explicitRating,
    DateTime? timestamp,
  }) async {
    final effectiveNow = (timestamp ?? DateTime.now()).toUtc();
    final rating =
        explicitRating ?? PerformanceRating.fromScore(assessmentScore);

    // Retrieve or initialize review item
    final currentItem =
        await _repository.getReviewItem(learnerId, objectiveId) ??
            ReviewItem.initial(objectiveId, now: effectiveNow);

    final updatedItem = calculateNextState(
      item: currentItem,
      result: ReviewResult(
        objectiveId: objectiveId,
        rating: rating,
        assessmentScore: assessmentScore,
        timestamp: effectiveNow,
      ),
      now: effectiveNow,
    );

    await _repository.saveReviewItem(learnerId, updatedItem);
    return updatedItem;
  }

  /// Deterministically calculates the next [ReviewItem] state based on SM-2 rules.
  ReviewItem calculateNextState({
    required ReviewItem item,
    required ReviewResult result,
    DateTime? now,
  }) {
    final effectiveNow = (now ?? result.timestamp).toUtc();
    final q = result.rating.grade;

    // 1. Calculate new Ease Factor (EF)
    // Formula: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    final efDelta = 0.1 - (5 - q) * (0.08 + (5 - q) * 0.02);
    final rawEf = item.easeFactor + efDelta;
    final newEaseFactor = rawEf.clamp(1.3, 2.5);

    // 2. Calculate new Interval in Days
    int newInterval;
    if (q < 3) {
      // Failure (Again): reset interval to 1 day
      newInterval = 1;
    } else {
      // Success (Hard, Good, Easy)
      if (item.reviewCount == 0 || item.intervalDays <= 1) {
        if (q == 5) {
          newInterval = 4; // Easy start boost
        } else if (q == 4) {
          newInterval = 3; // Good start standard
        } else {
          newInterval = 1; // Hard start conservative
        }
      } else {
        if (q == 3) {
          // Hard: slight interval growth
          newInterval = (item.intervalDays * 1.2).round();
        } else if (q == 4) {
          // Good: standard SM-2 growth
          newInterval = (item.intervalDays * newEaseFactor).round();
        } else {
          // Easy: accelerated SM-2 growth
          newInterval = (item.intervalDays * newEaseFactor * 1.3).round();
        }
      }
    }

    // Clamp interval between 1 and 180 days
    final clampedInterval = newInterval.clamp(1, 180);
    final nextDueDate = effectiveNow.add(Duration(days: clampedInterval));

    return item.copyWith(
      intervalDays: clampedInterval,
      easeFactor: newEaseFactor,
      nextReviewDate: nextDueDate,
      lastReviewed: effectiveNow,
      reviewCount: item.reviewCount + 1,
    );
  }

  /// Retrieves all review items due for review as of [asOfDate] for [learnerId].
  Future<List<ReviewItem>> getDueItems(
    String learnerId, {
    DateTime? asOf,
  }) async {
    final schedule = await _repository.getSchedule(learnerId);
    if (schedule == null) return [];
    return schedule.getDueItems(asOfDate: asOf);
  }

  /// Retrieves the full schedule for a learner.
  Future<ReviewSchedule?> getSchedule(String learnerId) async {
    return _repository.getSchedule(learnerId);
  }
}
