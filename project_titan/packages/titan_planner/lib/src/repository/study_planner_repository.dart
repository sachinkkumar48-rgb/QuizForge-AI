import '../models/planner_models.dart';

/// Abstract repository interface for Daily Study Planner operations.
abstract class StudyPlannerRepository {
  /// Evaluates context snapshot and generates a new Daily Study Plan.
  Future<StudyPlan> generateStudyPlan(PlannerContext context);

  /// Retrieves the active or cached plan for the specified date.
  Future<StudyPlan?> getPlanForDate(DateTime date);

  /// Updates task completion status in a plan.
  Future<StudyPlan> updateTaskCompletion({
    required String planId,
    required String taskId,
    required bool isCompleted,
  });
}
