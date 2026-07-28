import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning/titan_learning.dart';

void main() {
  group('Learning Flow Integration Tests', () {
    test('End-to-End full flow sequence from start to completion summary',
        () async {
      final coordinator = LearningFlowCoordinator();

      // 1. Start Session
      await coordinator.startSession(
        userId: 'learner_int',
        courseId: 'course_e2e',
        courseTitle: 'Comprehensive GS',
        lessonId: 'lesson_e2e',
        lessonTitle: 'Basic Structure Doctrine',
      );

      expect(coordinator.currentState.currentStep,
          equals(LearningFlowStep.learningContent));

      // 2. Advance through checkpoints
      await coordinator.advanceCheckpoint(
        targetStep: LearningFlowStep.mediaPlayback,
        progressPercentage: 0.2,
      );
      await coordinator.advanceCheckpoint(
        targetStep: LearningFlowStep.smartNotes,
        progressPercentage: 0.4,
      );
      await coordinator.advanceCheckpoint(
        targetStep: LearningFlowStep.aiTutor,
        progressPercentage: 0.6,
      );
      await coordinator.advanceCheckpoint(
        targetStep: LearningFlowStep.quickQuiz,
        progressPercentage: 0.8,
      );

      // 3. Finish Session
      final summary = await coordinator.finishSession();

      expect(summary.totalDurationMinutes, greaterThan(0));
      expect(coordinator.currentState.currentStep,
          equals(LearningFlowStep.completed));

      await coordinator.dispose();
    });
  });
}
