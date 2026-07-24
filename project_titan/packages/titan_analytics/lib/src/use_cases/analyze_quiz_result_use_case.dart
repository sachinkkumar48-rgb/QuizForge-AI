import 'package:titan_quiz/titan_quiz.dart';
import '../models/result_analytics_models.dart';
import '../repository/result_analytics_repository.dart';

/// Clean Architecture Use Case encapsulating the business logic for analyzing quiz attempt results.
class AnalyzeQuizResultUseCase {
  final ResultAnalyticsRepository _repository;

  const AnalyzeQuizResultUseCase(this._repository);

  /// Executes the analysis workflow for a given [QuizResult] and optional [Quiz].
  Future<ResultAnalytics> execute(
    QuizResult result, {
    Quiz? quiz,
  }) {
    return _repository.analyzeResult(result, quiz: quiz);
  }
}
