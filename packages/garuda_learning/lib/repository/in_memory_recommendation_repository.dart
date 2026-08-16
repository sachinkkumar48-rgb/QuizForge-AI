/// In-Memory Recommendation Repository (TITAN-KO-021.0 P21).
///
/// Thread-safe in-memory implementation of [RecommendationRepository] for offline execution.
library;

import '../domain/entities/learning_recommendation.dart';
import '../domain/entities/recommendation_queue.dart';
import '../domain/entities/recommendation_type.dart';
import 'recommendation_repository.dart';

class InMemoryRecommendationRepository implements RecommendationRepository {
  final Map<String, RecommendationQueue> _store = {};

  @override
  Future<void> saveQueue(RecommendationQueue queue) async {
    _store[queue.learnerId] = queue;
  }

  @override
  Future<RecommendationQueue?> getQueue(String learnerId) async {
    return _store[learnerId];
  }

  @override
  Future<List<LearningRecommendation>> getRecommendationsForLearner(
    String learnerId, {
    RecommendationType? type,
  }) async {
    final queue = _store[learnerId];
    if (queue == null) return const [];
    if (type == null) return queue.items;
    return queue.items.where((item) => item.type == type).toList();
  }

  @override
  Future<void> clearQueue(String learnerId) async {
    _store.remove(learnerId);
  }

  @override
  Future<void> clearAll() async {
    _store.clear();
  }
}
