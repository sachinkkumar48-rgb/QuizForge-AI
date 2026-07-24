import '../engine/planner_rules.dart';
import '../engine/study_planner_engine.dart';
import '../models/planner_models.dart';
import 'study_planner_repository.dart';

/// Concrete implementation of [StudyPlannerRepository] using [StudyPlannerEngine].
class StudyPlannerRepositoryImpl implements StudyPlannerRepository {
  final StudyPlannerEngine _engine;
  final PlannerRules _rules;
  final Map<String, StudyPlan> _plansCache = {};

  StudyPlannerRepositoryImpl({
    StudyPlannerEngine engine = const StudyPlannerEngine(),
    PlannerRules rules = const PlannerRules(),
  })  : _engine = engine,
        _rules = rules;

  @override
  Future<StudyPlan> generateStudyPlan(PlannerContext context) async {
    final plan = _engine.generate(context);
    final cacheKey = _dateKey(plan.planDate);
    _plansCache[cacheKey] = plan;
    return plan;
  }

  @override
  Future<StudyPlan?> getPlanForDate(DateTime date) async {
    final cacheKey = _dateKey(date);
    return _plansCache[cacheKey];
  }

  @override
  Future<StudyPlan> updateTaskCompletion({
    required String planId,
    required String taskId,
    required bool isCompleted,
  }) async {
    StudyPlan? targetPlan;
    String? targetKey;

    for (final entry in _plansCache.entries) {
      if (entry.value.id == planId) {
        targetKey = entry.key;
        targetPlan = entry.value;
        break;
      }
    }

    if (targetPlan == null) {
      throw Exception('StudyPlan with id "$planId" not found.');
    }

    final updatedTasks = targetPlan.tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          isCompleted: isCompleted,
          completedAt: isCompleted ? DateTime.now() : null,
        );
      }
      return task;
    }).toList();

    final updatedSummary = _rules.calculateSummary(
      updatedTasks,
      targetPlan.targetStudyTimeMinutes,
    );

    final updatedPlan = targetPlan.copyWith(
      tasks: updatedTasks,
      summary: updatedSummary,
    );

    if (targetKey != null) {
      _plansCache[targetKey] = updatedPlan;
    }

    return updatedPlan;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
