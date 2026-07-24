import '../engine/recommendation_engine.dart';
import '../models/recommendation_models.dart';
import 'recommendation_repository.dart';

/// Concrete implementation of [RecommendationRepository] using [RecommendationEngine].
class RecommendationRepositoryImpl implements RecommendationRepository {
  final RecommendationEngine _engine;
  List<Recommendation> _cachedRecommendations = [];

  RecommendationRepositoryImpl({
    RecommendationEngine engine = const RecommendationEngine(),
  }) : _engine = engine;

  @override
  Future<List<Recommendation>> generateRecommendations(
      RecommendationContext context) async {
    final list = _engine.generate(context);
    _cachedRecommendations = list;
    return list;
  }

  @override
  Future<List<Recommendation>> getLatestRecommendations() async {
    return _cachedRecommendations;
  }
}
