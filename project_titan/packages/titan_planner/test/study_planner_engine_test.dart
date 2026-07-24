import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_recommendation/titan_recommendation.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('StudyPlannerEngine & Rules Unit Tests', () {
    late StudyPlannerEngine engine;
    final now = DateTime(2026, 7, 24);

    setUp(() {
      engine = const StudyPlannerEngine();
    });

    test('StudyPlannerEngine prioritizes Urgent Revision items from SM-2 queue',
        () {
      final overdueItem = RevisionItem(
        id: 'rev_polity_01',
        topic: 'Indian Polity',
        subtopic: 'Writs & Fundamental Rights',
        nextReviewDate: now.subtract(const Duration(hours: 4)),
        lastReviewedAt: now.subtract(const Duration(days: 2)),
        qualityRating: 2,
        priority: 'Urgent',
      );

      final queue = RevisionQueue(
        id: 'q_overdue',
        userId: 'user_titan',
        generatedAt: now,
        items: [overdueItem],
        dueTodayCount: 1,
        overdueCount: 1,
        masteredCount: 0,
        summary: '1 overdue item',
      );

      final profile = LearningProfile(
        userId: 'user_titan',
        learnerLevel: 'Consistent Learner',
        overallAccuracy: 70.0,
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
        weakTopics: const ['Indian Polity'],
        lastActiveAt: now,
      );

      final context = PlannerContext(
        profile: profile,
        revisionQueue: queue,
        recommendations: const [],
        availableTimeMinutes: 120,
        planDate: now,
      );

      final plan = engine.generate(context);

      expect(plan.tasks, isNotEmpty);
      final firstTask = plan.tasks.first;
      expect(firstTask.priority, equals('Urgent'));
      expect(firstTask.category, equals('Revision'));
      expect(firstTask.topic, equals('Indian Polity'));
    });

    test(
        'StudyPlannerEngine carries forward (rollover) previous uncompleted tasks',
        () {
      final previousTask = const StudyTask(
        id: 'prev_task_1',
        title: 'Complete PYQs on Climate Change',
        topic: 'Environment',
        category: 'Practice & PYQ',
        priority: 'High',
        estimatedDurationMinutes: 25,
        isCompleted: false,
      );

      final profile = LearningProfile(
        userId: 'user_titan',
        learnerLevel: 'Consistent Learner',
        overallAccuracy: 75.0,
        totalQuizzesAttempted: 10,
        totalQuestionsAnswered: 100,
        totalStudyTimeMinutes: 300,
        topicMasteries: const [],
        studyHabit: const StudyHabit(
          peakStudyHour: 20,
          preferredSubject: 'Environment',
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
        weakTopics: const [],
        lastActiveAt: now,
      );

      final queue = RevisionQueue(
        id: 'q_empty',
        userId: 'user_titan',
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
        previousUncompletedTasks: [previousTask],
        availableTimeMinutes: 120,
        planDate: now,
      );

      final plan = engine.generate(context);

      final rolloverTask = plan.tasks.firstWhere((t) => t.isRollover);
      expect(rolloverTask.title, equals('Complete PYQs on Climate Change'));
      expect(rolloverTask.isRollover, isTrue);
    });

    test('StudyPlannerEngine respects available study time budget', () {
      final rec = Recommendation(
        id: 'rec_long',
        title: 'Masterclass: Modern History',
        topic: 'Modern History',
        actionType: 'Concept Deep Dive',
        priority: 'Medium',
        confidence: 0.85,
        source: 'Learning Profile',
        reasons: const [],
        estimatedStudyTimeMinutes: 90,
      );

      final profile = LearningProfile(
        userId: 'user_titan',
        learnerLevel: 'Consistent Learner',
        overallAccuracy: 70.0,
        totalQuizzesAttempted: 10,
        totalQuestionsAnswered: 100,
        totalStudyTimeMinutes: 300,
        topicMasteries: const [],
        studyHabit: const StudyHabit(
          peakStudyHour: 20,
          preferredSubject: 'History',
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
        weakTopics: const ['Modern History'],
        lastActiveAt: now,
      );

      final queue = RevisionQueue(
        id: 'q_empty',
        userId: 'user_titan',
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
        recommendations: [rec],
        availableTimeMinutes: 60, // 1 hour budget limit
        planDate: now,
      );

      final plan = engine.generate(context);

      final totalAllocated = plan.summary.totalAllocatedMinutes;
      expect(totalAllocated, lessThanOrEqualTo(60));
    });
  });
}
