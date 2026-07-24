import '../models/planner_models.dart';
import 'planner_rules.dart';

/// Pure domain Study Planner Engine orchestrating rule evaluation, time budgeting,
/// category balancing, and chronological task scheduling.
class StudyPlannerEngine {
  final PlannerRules _rules;

  const StudyPlannerEngine({
    PlannerRules rules = const PlannerRules(),
  }) : _rules = rules;

  /// Generates a complete, balanced, and time-budgeted Daily Study Plan.
  StudyPlan generate(PlannerContext context) {
    final candidateTasks = <StudyTask>[];

    // 1. Prioritize Urgent Revisions
    final urgentTasks = _rules.selectUrgentRevisions(context);
    candidateTasks.addAll(urgentTasks);

    // 2. Include Rollover Tasks from previous uncompleted plan
    final rolloverTasks = _rules.selectRolloverTasks(context);
    for (final task in rolloverTasks) {
      if (!candidateTasks
          .any((t) => t.topic == task.topic && t.title == task.title)) {
        candidateTasks.add(task);
      }
    }

    // Calculate remaining time budget
    final usedTime = candidateTasks.fold<int>(
      0,
      (sum, t) => sum + t.estimatedDurationMinutes,
    );
    final remainingMinutes = context.availableTimeMinutes - usedTime;

    // 3. Select Balanced Learning, Practice, and Current Affairs tasks
    final balancedTasks = _rules.selectBalancedTasks(context, remainingMinutes);
    for (final task in balancedTasks) {
      if (!candidateTasks
          .any((t) => t.topic == task.topic && t.category == task.category)) {
        candidateTasks.add(task);
      }
    }

    // 4. Enforce user's available time budget
    final budgetedTasks = _rules.enforceTimeBudget(
      candidateTasks,
      context.availableTimeMinutes,
    );

    // 5. Assign chronological start times starting from 09:00 AM on planDate
    final scheduledTasks = _assignScheduleTimes(
      budgetedTasks,
      context.planDate,
    );

    // 6. Compute aggregate summary
    final summary = _rules.calculateSummary(
      scheduledTasks,
      context.availableTimeMinutes,
    );

    final planId =
        'plan_${context.planDate.year}${context.planDate.month.toString().padLeft(2, '0')}${context.planDate.day.toString().padLeft(2, '0')}';

    return StudyPlan(
      id: planId,
      userId: context.profile.userId,
      planDate: context.planDate,
      targetStudyTimeMinutes: context.availableTimeMinutes,
      tasks: scheduledTasks,
      summary: summary,
      generatedAt: DateTime.now(),
    );
  }

  List<StudyTask> _assignScheduleTimes(
    List<StudyTask> tasks,
    DateTime planDate,
  ) {
    // Default start time: 9:00 AM on planDate
    var currentTime = DateTime(
      planDate.year,
      planDate.month,
      planDate.day,
      9,
      0,
    );

    final scheduled = <StudyTask>[];

    for (final task in tasks) {
      scheduled.add(
        task.copyWith(scheduledStartTime: currentTime),
      );

      // Add task duration + 10 min rest break
      currentTime = currentTime.add(
        Duration(minutes: task.estimatedDurationMinutes + 10),
      );
    }

    return scheduled;
  }
}
