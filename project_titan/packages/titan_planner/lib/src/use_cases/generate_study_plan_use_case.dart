import '../models/planner_models.dart';
import '../repository/study_planner_repository.dart';

/// Clean Architecture Use Case for generating and managing daily study plans.
class GenerateStudyPlanUseCase {
  final StudyPlannerRepository _repository;

  const GenerateStudyPlanUseCase(this._repository);

  /// Generates a personalized daily study plan for the given context.
  Future<StudyPlan> execute(PlannerContext context) {
    return _repository.generateStudyPlan(context);
  }

  /// Retrieves an existing study plan for a specific date.
  Future<StudyPlan?> getForDate(DateTime date) {
    return _repository.getPlanForDate(date);
  }

  /// Toggles task completion in a study plan.
  Future<StudyPlan> toggleTaskCompletion({
    required String planId,
    required String taskId,
    required bool isCompleted,
  }) {
    return _repository.updateTaskCompletion(
      planId: planId,
      taskId: taskId,
      isCompleted: isCompleted,
    );
  }
}
