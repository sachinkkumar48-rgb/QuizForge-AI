/// Recommendation Engine Contract (TITAN-KO-021.0 P21).
///
/// Application service contract for evaluating learning objectives and generating
/// multi-criteria, prioritized recommendation queues.
library;

import '../domain/entities/learning_recommendation.dart';
import '../domain/entities/recommendation_policy.dart';
import '../domain/entities/recommendation_queue.dart';

abstract class RecommendationEngine {
  /// Generates a prioritized recommendation queue for a learner.
  Future<RecommendationQueue> generateRecommendations({
    required String learnerId,
    RecommendationPolicy policy = const RecommendationPolicy(),
    DateTime? asOfDate,
  });

  /// Evaluates a single objective and returns its recommendation breakdown.
  Future<LearningRecommendation?> evaluateObjective({
    required String learnerId,
    required String objectiveId,
    RecommendationPolicy policy = const RecommendationPolicy(),
    DateTime? asOfDate,
  });
}
