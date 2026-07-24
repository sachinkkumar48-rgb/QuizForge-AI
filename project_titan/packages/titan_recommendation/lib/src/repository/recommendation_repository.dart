import '../models/recommendation_models.dart';

/// Abstract repository interface defining recommendation engine operations.
abstract class RecommendationRepository {
  /// Evaluates context and generates active study recommendations.
  Future<List<Recommendation>> generateRecommendations(
      RecommendationContext context);

  /// Retrieves cached or latest generated recommendations.
  Future<List<Recommendation>> getLatestRecommendations();
}
