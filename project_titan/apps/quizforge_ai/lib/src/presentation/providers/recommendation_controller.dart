import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_recommendation/titan_recommendation.dart';

import '../states/recommendation_state.dart';

/// Provider exposing [RecommendationRepository].
final recommendationRepositoryProvider =
    Provider<RecommendationRepository>((ref) {
  return RecommendationRepositoryImpl();
});

/// Provider exposing [GenerateRecommendationsUseCase].
final generateRecommendationsUseCaseProvider =
    Provider<GenerateRecommendationsUseCase>((ref) {
  final repo = ref.watch(recommendationRepositoryProvider);
  return GenerateRecommendationsUseCase(repo);
});

/// Riverpod Controller managing presentation state for the Recommendation Engine.
class RecommendationController extends Notifier<RecommendationState> {
  @override
  RecommendationState build() {
    return const RecommendationState.initial();
  }

  /// Generates or refreshes personalized recommendations given context.
  Future<void> fetchRecommendations(RecommendationContext context) async {
    state = state.copyWith(status: RecommendationStatus.loading);
    try {
      final useCase = ref.read(generateRecommendationsUseCaseProvider);
      final list = await useCase.execute(context);
      state = state.copyWith(
        status: RecommendationStatus.success,
        recommendations: list,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: RecommendationStatus.error,
        errorMessage: 'Failed to generate recommendations: ${e.toString()}',
      );
    }
  }
}

/// Riverpod provider for [RecommendationController].
final recommendationControllerProvider =
    NotifierProvider<RecommendationController, RecommendationState>(
        RecommendationController.new);
