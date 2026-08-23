import '../models/review_schedule_item.dart';

/// Repository contract managing scheduled spaced review items for learners.
abstract class ReviewScheduleRepository {
  Future<List<ReviewScheduleItem>> getItems(
      {String learnerId = 'default_learner'});
  Future<List<ReviewScheduleItem>> getDueItems(
      {DateTime? asOf, String learnerId = 'default_learner'});
  Future<void> saveItem(ReviewScheduleItem item,
      {String learnerId = 'default_learner'});
  Future<void> deleteItem(String itemId,
      {String learnerId = 'default_learner'});
  Future<void> clearAll({String? learnerId});
}

/// In-memory implementation of [ReviewScheduleRepository] for local test and runtime environments.
class InMemoryReviewScheduleRepository implements ReviewScheduleRepository {
  final _storage = <String, Map<String, ReviewScheduleItem>>{};

  @override
  Future<List<ReviewScheduleItem>> getItems(
      {String learnerId = 'default_learner'}) async {
    final userMap = _storage[learnerId] ?? {};
    return List.unmodifiable(userMap.values.toList());
  }

  @override
  Future<List<ReviewScheduleItem>> getDueItems({
    DateTime? asOf,
    String learnerId = 'default_learner',
  }) async {
    final now = asOf ?? DateTime.now();
    final items = await getItems(learnerId: learnerId);
    final due = items.where((item) => item.isDue(now)).toList()
      ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return List.unmodifiable(due);
  }

  @override
  Future<void> saveItem(ReviewScheduleItem item,
      {String learnerId = 'default_learner'}) async {
    final userMap =
        _storage.putIfAbsent(learnerId, () => <String, ReviewScheduleItem>{});
    userMap[item.id] = item;
  }

  @override
  Future<void> deleteItem(String itemId,
      {String learnerId = 'default_learner'}) async {
    _storage[learnerId]?.remove(itemId);
  }

  @override
  Future<void> clearAll({String? learnerId}) async {
    if (learnerId != null) {
      _storage.remove(learnerId);
    } else {
      _storage.clear();
    }
  }
}
