import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_revision/titan_revision.dart';

import '../states/learning_profile_state.dart';

/// Provider exposing [LearningProfileRepository].
final learningProfileRepositoryProvider =
    Provider<LearningProfileRepository>((ref) {
  return LearningProfileRepositoryImpl();
});

/// Provider exposing [GetLearningProfileUseCase].
final getLearningProfileUseCaseProvider =
    Provider<GetLearningProfileUseCase>((ref) {
  final repo = ref.watch(learningProfileRepositoryProvider);
  return GetLearningProfileUseCase(repo);
});

/// Provider exposing [UpdateLearningProfileUseCase].
final updateLearningProfileUseCaseProvider =
    Provider<UpdateLearningProfileUseCase>((ref) {
  final repo = ref.watch(learningProfileRepositoryProvider);
  return UpdateLearningProfileUseCase(repo);
});

/// Riverpod Controller managing presentation state for the Learning Profile Engine.
class LearningProfileController extends Notifier<LearningProfileState> {
  @override
  LearningProfileState build() {
    return const LearningProfileState.initial();
  }

  /// Loads current learner profile.
  Future<void> loadProfile({String userId = 'user_titan'}) async {
    state = state.copyWith(status: LearningProfileStatus.loading);
    try {
      final useCase = ref.read(getLearningProfileUseCaseProvider);
      final profile = await useCase.execute(userId: userId);
      state = state.copyWith(
        status: LearningProfileStatus.success,
        profile: profile,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: LearningProfileStatus.error,
        errorMessage: 'Failed to load learning profile: ${e.toString()}',
      );
    }
  }

  /// Updates profile with fresh quiz session analytics.
  Future<void> updateFromQuizAnalytics(ResultAnalytics analytics) async {
    try {
      final updateUseCase = ref.read(updateLearningProfileUseCaseProvider);
      final updated = await updateUseCase.fromQuizAnalytics(analytics);
      state = state.copyWith(
        status: LearningProfileStatus.success,
        profile: updated,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage:
            'Unable to update profile from analytics: ${e.toString()}',
      );
    }
  }

  /// Updates profile with active revision queue state.
  Future<void> updateFromRevisionQueue(RevisionQueue queue) async {
    try {
      final updateUseCase = ref.read(updateLearningProfileUseCaseProvider);
      final updated = await updateUseCase.fromRevisionQueue(queue);
      state = state.copyWith(
        status: LearningProfileStatus.success,
        profile: updated,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unable to update profile from revision: ${e.toString()}',
      );
    }
  }
}

/// Riverpod provider for [LearningProfileController].
final learningProfileControllerProvider =
    NotifierProvider<LearningProfileController, LearningProfileState>(
        LearningProfileController.new);
