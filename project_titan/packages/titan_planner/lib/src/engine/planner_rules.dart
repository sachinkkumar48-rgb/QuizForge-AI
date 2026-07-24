import '../models/planner_models.dart';

/// Pure domain rule evaluator for the Study Planner.
class PlannerRules {
  const PlannerRules();

  /// Rule 1: Prioritize Urgent Revisions from SM-2 overdue queue & Urgent recommendations.
  List<StudyTask> selectUrgentRevisions(PlannerContext context) {
    final tasks = <StudyTask>[];
    final overdueItems =
        context.revisionQueue.items.where((i) => i.isOverdue).toList();

    for (var i = 0; i < overdueItems.length; i++) {
      final item = overdueItems[i];
      tasks.add(
        StudyTask(
          id: 'task_rev_urgent_${item.id}',
          title: 'Active Recall: ${item.subtopic ?? item.topic}',
          topic: item.topic,
          category: 'Revision',
          priority: 'Urgent',
          estimatedDurationMinutes: 15,
        ),
      );
    }

    // Also include Urgent recommendations
    final urgentRecs = context.recommendations
        .where((r) => r.priority.toLowerCase() == 'urgent')
        .toList();

    for (final rec in urgentRecs) {
      if (!tasks.any((t) => t.topic == rec.topic)) {
        tasks.add(
          StudyTask(
            id: 'task_rec_urgent_${rec.id}',
            title: rec.title,
            topic: rec.topic,
            category: 'Revision',
            priority: 'Urgent',
            estimatedDurationMinutes: rec.estimatedStudyTimeMinutes,
            sourceRecommendationId: rec.id,
          ),
        );
      }
    }

    return tasks;
  }

  /// Rule 2: Carry forward uncompleted non-critical tasks from previous study plan.
  List<StudyTask> selectRolloverTasks(PlannerContext context) {
    final tasks = <StudyTask>[];

    for (final task in context.previousUncompletedTasks) {
      if (!task.isCompleted) {
        tasks.add(
          task.copyWith(
            id: 'task_rollover_${task.id}',
            isRollover: true,
          ),
        );
      }
    }

    return tasks;
  }

  /// Rule 3: Balance remaining time budget across Revision, Concept Learning, Practice & PYQ, and Current Affairs.
  List<StudyTask> selectBalancedTasks(
    PlannerContext context,
    int remainingMinutes,
  ) {
    final tasks = <StudyTask>[];
    if (remainingMinutes <= 0) return tasks;

    // 1. Concept Learning Tasks from weak topics & High recommendations
    final weakTopics = context.profile.weakTopics;
    for (var i = 0; i < weakTopics.length; i++) {
      final topic = weakTopics[i];
      tasks.add(
        StudyTask(
          id: 'task_learn_weak_$i',
          title: 'Concept Deep Dive: $topic',
          topic: topic,
          category: 'Concept Learning',
          priority: 'High',
          estimatedDurationMinutes: 30,
        ),
      );
    }

    // 2. Practice & PYQ Tasks from recommendations
    final practiceRecs = context.recommendations
        .where((r) =>
            r.actionType.toLowerCase().contains('pyq') ||
            r.actionType.toLowerCase().contains('quiz') ||
            r.actionType.toLowerCase().contains('practice'))
        .toList();

    for (final rec in practiceRecs) {
      if (!tasks
          .any((t) => t.topic == rec.topic && t.category == 'Practice & PYQ')) {
        tasks.add(
          StudyTask(
            id: 'task_practice_${rec.id}',
            title: rec.title,
            topic: rec.topic,
            category: 'Practice & PYQ',
            priority: rec.priority,
            estimatedDurationMinutes: rec.estimatedStudyTimeMinutes,
            sourceRecommendationId: rec.id,
          ),
        );
      }
    }

    // 3. Current Affairs Task guarantee for UPSC prep
    final caTopic = context.profile.studyHabit.preferredSubject.isNotEmpty
        ? 'Current Affairs - ${context.profile.studyHabit.preferredSubject}'
        : 'Daily Current Affairs & Editorial Analysis';

    tasks.add(
      StudyTask(
        id: 'task_ca_daily',
        title: caTopic,
        topic: 'Current Affairs',
        category: 'Current Affairs',
        priority: 'Medium',
        estimatedDurationMinutes: 25,
      ),
    );

    return tasks;
  }

  /// Rule 4: Respect available study time budget by selecting tasks up to available time limit.
  List<StudyTask> enforceTimeBudget(
    List<StudyTask> candidates,
    int timeBudgetMinutes,
  ) {
    final selected = <StudyTask>[];
    var accumulatedTime = 0;

    // Sort by priority rank: Urgent > High > Medium > Low
    final sorted = List<StudyTask>.from(candidates)
      ..sort((a, b) {
        final pOrder = {'Urgent': 0, 'High': 1, 'Medium': 2, 'Low': 3};
        final pA = pOrder[a.priority] ?? 4;
        final pB = pOrder[b.priority] ?? 4;
        return pA.compareTo(pB);
      });

    for (final task in sorted) {
      if (accumulatedTime + task.estimatedDurationMinutes <=
              timeBudgetMinutes ||
          selected.isEmpty) {
        selected.add(task);
        accumulatedTime += task.estimatedDurationMinutes;
      }
    }

    return selected;
  }

  /// Computes aggregate StudySummary metrics for a list of tasks.
  StudySummary calculateSummary(
    List<StudyTask> tasks,
    int targetStudyTimeMinutes,
  ) {
    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isCompleted).length;
    final totalAllocated =
        tasks.fold<int>(0, (sum, t) => sum + t.estimatedDurationMinutes);
    final completedMinutes = tasks.fold<int>(
      0,
      (sum, t) => t.isCompleted ? sum + t.estimatedDurationMinutes : sum,
    );

    final revisionMins = _sumCategory(tasks, 'Revision');
    final learningMins = _sumCategory(tasks, 'Concept Learning');
    final practiceMins = _sumCategory(tasks, 'Practice & PYQ');
    final caMins = _sumCategory(tasks, 'Current Affairs');

    final completionPct =
        totalTasks > 0 ? (completedTasks / totalTasks) * 100.0 : 0.0;

    final topTopic = tasks.isNotEmpty ? tasks.first.topic : 'General Study';

    return StudySummary(
      totalTasksCount: totalTasks,
      completedTasksCount: completedTasks,
      totalAllocatedMinutes: totalAllocated,
      completedMinutes: completedMinutes,
      revisionMinutes: revisionMins,
      learningMinutes: learningMins,
      practiceMinutes: practiceMins,
      currentAffairsMinutes: caMins,
      completionPercentage: completionPct,
      topFocusTopic: topTopic,
    );
  }

  int _sumCategory(List<StudyTask> tasks, String category) {
    return tasks
        .where((t) => t.category.toLowerCase() == category.toLowerCase())
        .fold<int>(0, (sum, t) => sum + t.estimatedDurationMinutes);
  }
}
