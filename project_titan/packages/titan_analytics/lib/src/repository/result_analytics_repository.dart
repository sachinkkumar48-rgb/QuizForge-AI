import 'package:titan_quiz/titan_quiz.dart';
import '../models/result_analytics_models.dart';

/// Abstract repository interface for generating intelligent analytics from quiz results.
abstract class ResultAnalyticsRepository {
  /// Analyzes a [QuizResult] and optional [Quiz] to produce comprehensive [ResultAnalytics].
  Future<ResultAnalytics> analyzeResult(
    QuizResult result, {
    Quiz? quiz,
  });
}
