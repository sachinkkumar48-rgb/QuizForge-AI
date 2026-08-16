/// Recommendation Repository Interface (TITAN-KO-021.0 P21).
///
/// Clean Architecture contract for persisting and querying generated [RecommendationQueue]s.
library;

import '../domain/entities/learning_recommendation.dart';
import '../domain/entities/recommendation_queue.dart';
import '../domain/entities/recommendation_type.dart';

abstract class RecommendationRepository {
  /// Persists a generated [RecommendationQueue] for a learner.
  Future<void> saveQueue(RecommendationQueue queue);

  /// Retrieves the latest [RecommendationQueue] for a learner, or null if absent.
  Future<RecommendationQueue?> getQueue(String learnerId);

  /// Retrieves all recommendations for a learner, optionally filtered by [type].
  Future<List<LearningRecommendation>> getRecommendationsForLearner(
    String learnerId, {
    RecommendationType? type,
  });

  /// Deletes the recommendation queue for a learner.
  Future<void> clearQueue(String learnerId);

  /// Clears all persisted recommendation queues.
  Future<void> clearAll();
}
