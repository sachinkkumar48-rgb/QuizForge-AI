import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_quiz_ai/titan_quiz_ai.dart';
import '../../coordinator/application_coordinator.dart';
import 'application_provider.dart';

/// State representing learner mastery, spaced reviews, and adaptive study next recommendations.
class AdaptiveLearningState {
  final LearnerProfile profile;
  final StudyNextRecommendation? studyNext;
  final List<ReviewScheduleItem> dueReviewItems;
  final bool isLoading;
  final String? errorMessage;

  const AdaptiveLearningState({
    required this.profile,
    this.studyNext,
    this.dueReviewItems = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  factory AdaptiveLearningState.initial(
      {String learnerId = 'default_learner'}) {
    return AdaptiveLearningState(
      profile: LearnerProfile.empty(learnerId: learnerId),
      isLoading: true,
    );
  }

  AdaptiveLearningState copyWith({
    LearnerProfile? profile,
    StudyNextRecommendation? studyNext,
    List<ReviewScheduleItem>? dueReviewItems,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AdaptiveLearningState(
      profile: profile ?? this.profile,
      studyNext: studyNext ?? this.studyNext,
      dueReviewItems: dueReviewItems ?? this.dueReviewItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Controller managing adaptive learning state and interactions.
class AdaptiveLearningController extends StateNotifier<AdaptiveLearningState> {
  final ApplicationCoordinator? _coordinator;
  final String _learnerId;

  AdaptiveLearningController({
    required ApplicationCoordinator coordinator,
    String learnerId = 'default_learner',
  })  : _coordinator = coordinator,
        _learnerId = learnerId,
        super(AdaptiveLearningState.initial(learnerId: learnerId)) {
    loadLearnerState();
  }

  AdaptiveLearningController.fallback({
    String learnerId = 'default_learner',
  })  : _coordinator = null,
        _learnerId = learnerId,
        super(AdaptiveLearningState(
          profile: LearnerProfile.empty(learnerId: learnerId),
          isLoading: false,
        ));

  /// Loads learner profile, due reviews, and study next recommendation.
  Future<void> loadLearnerState() async {
    final coordinator = _coordinator;
    if (coordinator == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile =
          await coordinator.getLearnerProfile(learnerId: _learnerId);
      final dueItems = await coordinator.reviewScheduleRepository
          .getDueItems(learnerId: _learnerId);
      final studyNext =
          await coordinator.getStudyNextRecommendation(learnerId: _learnerId);

      state = state.copyWith(
        profile: profile,
        dueReviewItems: dueItems,
        studyNext: studyNext,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Refreshes all adaptive metrics.
  Future<void> refresh() => loadLearnerState();
}

/// Riverpod provider for [AdaptiveLearningController].
final adaptiveLearningProvider =
    StateNotifierProvider<AdaptiveLearningController, AdaptiveLearningState>(
        (ref) {
  try {
    final coordinator = ref.watch(applicationCoordinatorProvider);
    return AdaptiveLearningController(coordinator: coordinator);
  } catch (_) {
    return AdaptiveLearningController.fallback();
  }
});
