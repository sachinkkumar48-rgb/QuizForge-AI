import '../engine/assessment_engine.dart';
import '../models/assessment_models.dart';

/// Use case for recommending targeted revision based on performance analysis.
class RecommendRevisionUseCase {
  final AssessmentEngine engine;

  const RecommendRevisionUseCase({required this.engine});

  Future<List<AssessmentRecommendation>> execute({
    required AssessmentAnalysis analysis,
    required String assessmentId,
  }) async {
    return engine.generateRecommendations(
      analysis: analysis,
      assessmentId: assessmentId,
    );
  }
}
