import '../engine/dashboard_engine.dart';
import '../models/learning_insights.dart';

/// Clean Architecture Use Case for generating targeted executive insights.
class GenerateInsightsUseCase {
  final DashboardEngine _engine;

  const GenerateInsightsUseCase(this._engine);

  /// Executes AI insights extraction for [userId].
  Future<LearningInsights> execute({
    required String userId,
    required String userName,
  }) {
    return _engine.generateInsights(
      userId: userId,
      userName: userName,
    );
  }
}
