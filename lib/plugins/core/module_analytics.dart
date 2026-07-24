import '../../models/quiz_analytics.dart';
import '../../models/quiz_attempt.dart';

/// Contract for module-tailored metrics, weakness calculation, and study guidance.
abstract class ModuleAnalytics {
  /// Calculate summary analytics for a list of module attempts.
  Future<QuizAnalytics> calculateAnalytics(List<QuizAttempt> attempts);

  /// Map topics/subjects to weakness scores (0.0 = strong, 1.0 = weak).
  Future<Map<String, double>> getTopicWeaknessScores(
      List<QuizAttempt> attempts);

  /// Get recommended focus areas or topics based on attempt history.
  Future<List<String>> getRecommendedFocusAreas(List<QuizAttempt> attempts);

  /// Custom module score or percentile estimation if applicable.
  Future<double> estimateCutoffProbability(List<QuizAttempt> attempts);
}
