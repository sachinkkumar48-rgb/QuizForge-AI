import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coordinator/learning_flow_coordinator.dart';
import '../models/learning_session_models.dart';

/// Provider for the singleton LearningFlowCoordinator instance.
final learningFlowCoordinatorProvider =
    Provider<LearningFlowCoordinator>((ref) {
  final coordinator = LearningFlowCoordinator();
  ref.onDispose(() {
    coordinator.dispose();
  });
  return coordinator;
});

/// StateNotifier wrapping LearningFlowCoordinator for Flutter Riverpod integration.
class LearningFlowStateNotifier extends StateNotifier<LearningFlowState> {
  final LearningFlowCoordinator _coordinator;

  LearningFlowStateNotifier(this._coordinator)
      : super(LearningFlowState.initial()) {
    _init();
  }

  void _init() {
    state = _coordinator.currentState;
    _coordinator.stateStream.listen((newState) {
      if (mounted) {
        state = newState;
      }
    });
  }

  Future<LearningSession> startSession({
    required String userId,
    required String courseId,
    required String courseTitle,
    required String lessonId,
    required String lessonTitle,
  }) {
    return _coordinator.startSession(
      userId: userId,
      courseId: courseId,
      courseTitle: courseTitle,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
    );
  }

  Future<void> pauseSession() => _coordinator.pauseSession();

  Future<void> resumeSession() => _coordinator.resumeSession();

  Future<void> advanceCheckpoint({
    required LearningFlowStep targetStep,
    required double progressPercentage,
    Map<String, dynamic> metadata = const {},
  }) {
    return _coordinator.advanceCheckpoint(
      targetStep: targetStep,
      progressPercentage: progressPercentage,
      metadata: metadata,
    );
  }

  Future<LearningFlowSummary> finishSession() => _coordinator.finishSession();

  Future<void> abandonSession() => _coordinator.abandonSession();

  Future<LearningSession?> recoverSession() => _coordinator.recoverSession();
}

/// Provider exposing LearningFlowStateNotifier.
final learningFlowStateNotifierProvider =
    StateNotifierProvider<LearningFlowStateNotifier, LearningFlowState>((ref) {
  final coordinator = ref.watch(learningFlowCoordinatorProvider);
  return LearningFlowStateNotifier(coordinator);
});

/// Provider exposing current active LearningSession if present.
final activeLearningSessionProvider = Provider<LearningSession?>((ref) {
  final state = ref.watch(learningFlowStateNotifierProvider);
  return state.session;
});
