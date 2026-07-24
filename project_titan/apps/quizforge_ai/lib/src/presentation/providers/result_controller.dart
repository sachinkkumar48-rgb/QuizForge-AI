import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_quiz/titan_quiz.dart';

import '../states/result_state.dart';

/// Provider exposing the abstract [ResultAnalyticsRepository] contract.
final resultAnalyticsRepositoryProvider =
    Provider<ResultAnalyticsRepository>((ref) {
  return ResultAnalyticsRepositoryImpl();
});

/// Provider exposing the Clean Architecture [AnalyzeQuizResultUseCase].
final analyzeQuizResultUseCaseProvider =
    Provider<AnalyzeQuizResultUseCase>((ref) {
  final repository = ref.watch(resultAnalyticsRepositoryProvider);
  return AnalyzeQuizResultUseCase(repository);
});

/// Riverpod Controller managing presentation state for the Intelligent Results Dashboard.
///
/// Adheres strictly to Clean Architecture by interacting exclusively with
/// [AnalyzeQuizResultUseCase] to keep presentation independent of infrastructure.
class ResultController extends Notifier<ResultState> {
  @override
  ResultState build() {
    return const ResultState.initial();
  }

  /// Triggers the evaluation workflow for a [QuizResult] and optional [Quiz].
  Future<void> analyzeQuizResult(QuizResult result, {Quiz? quiz}) async {
    state = const ResultState.loading();
    try {
      final useCase = ref.read(analyzeQuizResultUseCaseProvider);
      final analytics = await useCase.execute(result, quiz: quiz);
      state = ResultState.success(analytics);
    } catch (e) {
      state =
          ResultState.error('Failed to analyze quiz results: ${e.toString()}');
    }
  }
}

/// Riverpod provider for [ResultController].
final resultControllerProvider =
    NotifierProvider<ResultController, ResultState>(ResultController.new);
