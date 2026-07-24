import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('Study Planner Models Unit Tests', () {
    final now = DateTime(2026, 7, 24);

    const sampleTask = StudyTask(
      id: 'task_1',
      title: 'Active Recall: Indian Polity',
      topic: 'Indian Polity',
      category: 'Revision',
      priority: 'Urgent',
      estimatedDurationMinutes: 15,
    );

    test('StudyTask equality and copyWith', () {
      final copy = sampleTask.copyWith(isCompleted: true);

      expect(copy.isCompleted, isTrue);
      expect(copy.title, equals('Active Recall: Indian Polity'));
      expect(sampleTask == copy, isFalse);
    });

    test('StudySummary calculation and copyWith', () {
      const summary = StudySummary(
        totalTasksCount: 4,
        completedTasksCount: 2,
        totalAllocatedMinutes: 120,
        completedMinutes: 60,
        revisionMinutes: 30,
        learningMinutes: 45,
        practiceMinutes: 30,
        currentAffairsMinutes: 15,
        completionPercentage: 50.0,
        topFocusTopic: 'Polity',
      );

      final copy =
          summary.copyWith(completedTasksCount: 3, completionPercentage: 75.0);

      expect(copy.completedTasksCount, equals(3));
      expect(copy.completionPercentage, equals(75.0));
      expect(summary == copy, isFalse);
    });

    test('PlannerContext immutability', () {
      final profile = LearningProfile(
        userId: 'user_plan_01',
        learnerLevel: 'Consistent Learner',
        overallAccuracy: 75.0,
        totalQuizzesAttempted: 10,
        totalQuestionsAnswered: 100,
        totalStudyTimeMinutes: 300,
        topicMasteries: const [],
        studyHabit: const StudyHabit(
          peakStudyHour: 20,
          preferredSubject: 'Polity',
          avgSessionDurationMinutes: 30,
          totalSessionsCompleted: 10,
          consistencyScore: 80.0,
          activeDaysCount: 10,
        ),
        streak: LearningStreak(
          currentStreakDays: 5,
          longestStreakDays: 10,
          lastActivityDate: now,
          streakFreezeCount: 0,
          isStreakActive: true,
        ),
        weakTopics: const ['Environment'],
        lastActiveAt: now,
      );

      final queue = RevisionQueue(
        id: 'q_plan',
        userId: 'user_plan_01',
        generatedAt: now,
        items: const [],
        dueTodayCount: 0,
        overdueCount: 0,
        masteredCount: 0,
        summary: 'Clean',
      );

      final context = PlannerContext(
        profile: profile,
        revisionQueue: queue,
        recommendations: const [],
        availableTimeMinutes: 180,
        planDate: now,
      );

      expect(context.availableTimeMinutes, equals(180));
      expect(context.profile.userId, equals('user_plan_01'));
    });
  });
}
