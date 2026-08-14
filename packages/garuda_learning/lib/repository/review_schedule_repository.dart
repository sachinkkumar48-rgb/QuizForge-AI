import '../domain/entities/review_item.dart';
import '../domain/entities/review_schedule.dart';

/// Abstract repository interface for persisting and querying spaced repetition schedules.
abstract class ReviewScheduleRepository {
  /// Retrieves the complete [ReviewSchedule] for [learnerId], or null if none exists.
  Future<ReviewSchedule?> getSchedule(String learnerId);

  /// Persists or updates a complete [ReviewSchedule].
  Future<void> saveSchedule(ReviewSchedule schedule);

  /// Retrieves a specific [ReviewItem] for a learner and objective.
  Future<ReviewItem?> getReviewItem(String learnerId, String objectiveId);

  /// Saves or updates a single [ReviewItem] within a learner's schedule.
  Future<void> saveReviewItem(String learnerId, ReviewItem item);

  /// Clears stored schedules (primarily for testing).
  Future<void> clear();
}

/// In-memory implementation of [ReviewScheduleRepository] for offline execution.
class InMemoryReviewScheduleRepository implements ReviewScheduleRepository {
  final Map<String, ReviewSchedule> _schedules = {};

  @override
  Future<ReviewSchedule?> getSchedule(String learnerId) async {
    return _schedules[learnerId];
  }

  @override
  Future<void> saveSchedule(ReviewSchedule schedule) async {
    _schedules[schedule.learnerId] = schedule;
  }

  @override
  Future<ReviewItem?> getReviewItem(
      String learnerId, String objectiveId) async {
    final schedule = _schedules[learnerId];
    return schedule?.getItem(objectiveId);
  }

  @override
  Future<void> saveReviewItem(String learnerId, ReviewItem item) async {
    final schedule = _schedules[learnerId] ??
        ReviewSchedule(
          learnerId: learnerId,
          items: {},
        );
    final updatedSchedule = schedule.updateItem(item);
    _schedules[learnerId] = updatedSchedule;
  }

  @override
  Future<void> clear() async {
    _schedules.clear();
  }
}
