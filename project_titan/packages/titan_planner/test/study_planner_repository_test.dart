import 'package:flutter_test/flutter_test.dart';
import 'package:titan_learning_profile/titan_learning_profile.dart';
import 'package:titan_planner/titan_planner.dart';
import 'package:titan_revision/titan_revision.dart';

void main() {
  group('StudyPlannerRepository & GenerateStudyPlanUseCase Unit Tests', () {
    late StudyPlannerRepository repository;
    late GenerateStudyPlanUseCase generateUseCase;

    final now = DateTime(2026, 7, 24);

    setUp(() {
      repository = StudyPlannerRepositoryImpl();
      generateUseCase = GenerateStudyPlanUseCase(repository);
    });

    test('Repository generates, retrieves, and updates task completion',
        () async {
      final profile = LearningProfile(
        userId: 'user_repo_test',
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
        weakTopics: const ['Economy'],
        lastActiveAt: now,
      );

      final queue = RevisionQueue(
        id: 'q_repo',
        userId: 'user_repo_test',
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

      final plan = await generateUseCase.execute(context);
      expect(plan.tasks, isNotEmpty);

      final cachedPlan = await generateUseCase.getForDate(now);
      expect(cachedPlan?.id, equals(plan.id));

      final firstTaskId = plan.tasks.first.id;
      final updatedPlan = await generateUseCase.toggleTaskCompletion(
        planId: plan.id,
        taskId: firstTaskId,
        isCompleted: true,
      );

      final updatedTask =
          updatedPlan.tasks.firstWhere((t) => t.id == firstTaskId);
      expect(updatedTask.isCompleted, isTrue);
      expect(updatedPlan.summary.completedTasksCount, equals(1));
    });
  });
}
