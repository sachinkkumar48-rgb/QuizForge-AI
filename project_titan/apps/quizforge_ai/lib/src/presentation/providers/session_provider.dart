import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';
import 'application_provider.dart';

/// AsyncNotifier managing active quiz session interactions.
class SessionAsyncNotifier extends AsyncNotifier<QuizSession?> {
  @override
  Future<QuizSession?> build() async {
    final appState = ref.watch(applicationStateProvider);
    return appState.currentSession;
  }

  /// Attempts a question in the current quiz session.
  Future<void> submitAnswer({
    required String sessionId,
    required String questionId,
    required String? selectedOptionId,
    Duration timeSpent = Duration.zero,
    required QuizSessionService sessionService,
  }) async {
    state = const AsyncValue.loading();
    try {
      final coordinator = ref.read(applicationCoordinatorProvider);
      final updatedSession = await coordinator.answerQuestion(
        sessionId: sessionId,
        questionId: questionId,
        selectedOptionId: selectedOptionId,
        timeSpent: timeSpent,
        sessionService: sessionService,
      );
      ref.read(applicationStateProvider.notifier).updateState();
      state = AsyncValue.data(updatedSession);
    } catch (e, st) {
      ref.read(applicationStateProvider.notifier).updateState();
      state = AsyncValue.error(e, st);
    }
  }

  /// Finalizes and submits the quiz session.
  Future<QuizResultSummary?> completeSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final coordinator = ref.read(applicationCoordinatorProvider);
      final summary = await coordinator.completeSession(sessionId: sessionId);
      ref.read(applicationStateProvider.notifier).updateState();
      return summary;
    } catch (e, st) {
      ref.read(applicationStateProvider.notifier).updateState();
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Provider for active quiz session UI state.
final sessionProvider =
    AsyncNotifierProvider<SessionAsyncNotifier, QuizSession?>(
        SessionAsyncNotifier.new);
