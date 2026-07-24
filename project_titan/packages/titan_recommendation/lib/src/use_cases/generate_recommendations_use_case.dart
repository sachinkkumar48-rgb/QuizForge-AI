import '../models/recommendation_models.dart';
import '../repository/recommendation_repository.dart';

/// Clean Architecture Use Case for generating personalized recommendations.
class GenerateRecommendationsUseCase {
  final RecommendationRepository _repository;

  const GenerateRecommendationsUseCase(this._repository);

  /// Generates prioritized, explainable recommendations for the given context.
  Future<List<Recommendation>> execute(RecommendationContext context) {
    return _repository.generateRecommendations(context);
  }

  /// Retrieves previously computed recommendations.
  Future<List<Recommendation>> getLatest() {
    return _repository.getLatestRecommendations();
  }
}
