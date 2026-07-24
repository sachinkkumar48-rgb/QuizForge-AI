import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_analytics/titan_analytics.dart';
import 'package:titan_revision/titan_revision.dart';

import '../states/revision_state.dart';

/// Provider exposing the abstract [RevisionRepository] contract.
final revisionRepositoryProvider = Provider<RevisionRepository>((ref) {
  return RevisionRepositoryImpl();
});

/// Provider exposing [GenerateRevisionQueueUseCase].
final generateRevisionQueueUseCaseProvider =
    Provider<GenerateRevisionQueueUseCase>((ref) {
  final repository = ref.watch(revisionRepositoryProvider);
  return GenerateRevisionQueueUseCase(repository);
});

/// Provider exposing [ProcessRevisionAttemptUseCase].
final processRevisionAttemptUseCaseProvider =
    Provider<ProcessRevisionAttemptUseCase>((ref) {
  final repository = ref.watch(revisionRepositoryProvider);
  return ProcessRevisionAttemptUseCase(repository);
});

/// Riverpod Controller managing presentation state for the Adaptive Revision Engine.
///
/// Adheres strictly to Clean Architecture by interacting exclusively with
/// [GenerateRevisionQueueUseCase] and [ProcessRevisionAttemptUseCase].
class RevisionController extends Notifier<RevisionState> {
  @override
  RevisionState build() {
    return const RevisionState.initial();
  }

  /// Loads or refreshes the personalized adaptive revision queue and topic mastery levels.
  Future<void> loadRevisionQueue({ResultAnalytics? quizAnalytics}) async {
    state = state.copyWith(status: RevisionStateStatus.loading);
    try {
      final generateUseCase = ref.read(generateRevisionQueueUseCaseProvider);

      final isOverdueOnly = state.filterOption == 'Overdue';
      final queue = await generateUseCase.execute(
        category: state.selectedCategory,
        overdueOnly: isOverdueOnly,
        quizAnalytics: quizAnalytics,
      );
      final mastery = await generateUseCase.getTopicMastery();

      state = state.copyWith(
        status: RevisionStateStatus.success,
        queue: queue,
        topicMastery: mastery,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: RevisionStateStatus.error,
        errorMessage: 'Failed to load Adaptive Revision Queue: ${e.toString()}',
      );
    }
  }

  /// Filters revision queue by subject category.
  Future<void> selectCategory(String category) async {
    state = state.copyWith(selectedCategory: category);
    await loadRevisionQueue();
  }

  /// Filters revision queue by urgency option ('All', 'Overdue', 'Due Today').
  Future<void> selectFilterOption(String option) async {
    state = state.copyWith(filterOption: option);
    await loadRevisionQueue();
  }

  /// Records a user's recall rating (0 to 5) for a revision item using the SM-2 algorithm.
  Future<void> recordRecallAttempt(String itemId, int qualityRating) async {
    try {
      final processUseCase = ref.read(processRevisionAttemptUseCaseProvider);
      await processUseCase.execute(itemId, qualityRating);
      await loadRevisionQueue();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unable to record recall attempt: ${e.toString()}',
      );
    }
  }
}

/// Riverpod provider for [RevisionController].
final revisionControllerProvider =
    NotifierProvider<RevisionController, RevisionState>(RevisionController.new);
