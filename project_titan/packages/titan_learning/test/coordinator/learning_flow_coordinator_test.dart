import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning/titan_learning.dart';

void main() {
  group('LearningFlowCoordinator Unit Tests', () {
    late LearningFlowCoordinator coordinator;

    setUp(() {
      coordinator = LearningFlowCoordinator();
    });

    tearDown(() async {
      await coordinator.dispose();
    });

    test('startSession initializes active session and initial checkpoint',
        () async {
      final session = await coordinator.startSession(
        userId: 'user_flow_1',
        courseId: 'course_polity_101',
        courseTitle: 'Indian Polity',
        lessonId: 'lesson_01',
        lessonTitle: 'Preamble',
      );

      expect(session.status, equals(LearningSessionStatus.active));
      expect(session.userId, equals('user_flow_1'));
      expect(session.courseTitle, equals('Indian Polity'));
      expect(coordinator.currentState.currentStep,
          equals(LearningFlowStep.learningContent));
    });

    test('pauseSession and resumeSession update session state', () async {
      await coordinator.startSession(
        userId: 'user_flow_1',
        courseId: 'c1',
        courseTitle: 'Course 1',
        lessonId: 'l1',
        lessonTitle: 'Lesson 1',
      );

      await coordinator.pauseSession();
      expect(coordinator.currentState.session?.status,
          equals(LearningSessionStatus.paused));
      expect(coordinator.currentState.isInterrupted, isTrue);

      await coordinator.resumeSession();
      expect(coordinator.currentState.session?.status,
          equals(LearningSessionStatus.active));
      expect(coordinator.currentState.isInterrupted, isFalse);
    });

    test('advanceCheckpoint appends checkpoint and updates step', () async {
      await coordinator.startSession(
        userId: 'user_flow_1',
        courseId: 'c1',
        courseTitle: 'Course 1',
        lessonId: 'l1',
        lessonTitle: 'Lesson 1',
      );

      await coordinator.advanceCheckpoint(
        targetStep: LearningFlowStep.smartNotes,
        progressPercentage: 0.4,
      );

      expect(coordinator.currentState.currentStep,
          equals(LearningFlowStep.smartNotes));
      expect(coordinator.currentState.session?.checkpoints.length, equals(2));
    });

    test('finishSession executes completion cascade and returns summary',
        () async {
      await coordinator.startSession(
        userId: 'user_flow_1',
        courseId: 'c1',
        courseTitle: 'Course 1',
        lessonId: 'l1',
        lessonTitle: 'Lesson 1',
      );

      final summary = await coordinator.finishSession();
      expect(summary.totalDurationMinutes, greaterThan(0));
      expect(summary.quizAccuracy, greaterThan(0));
      expect(coordinator.currentState.currentStep,
          equals(LearningFlowStep.completed));
    });
  });
}
