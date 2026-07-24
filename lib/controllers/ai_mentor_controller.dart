import 'package:flutter/foundation.dart';

import '../domain/usecases/generate_study_plan_usecase.dart';
import '../repositories/ai_mentor_repository.dart';
import 'ai_mentor_state.dart';

/// Clean Architecture Controller managing state lifecycle and domain operations
/// for the QuizForge AI Mentor Panel.
class AIMentorController extends ValueNotifier<AIMentorState> {
  final AIMentorRepository _repository;
  final GenerateStudyPlanUseCase _generateStudyPlanUseCase;

  AIMentorController({
    AIMentorRepository? repository,
    GenerateStudyPlanUseCase? generateStudyPlanUseCase,
  })  : _repository = repository ?? AIMentorRepository(),
        _generateStudyPlanUseCase = generateStudyPlanUseCase ??
            GenerateStudyPlanUseCaseImpl(
              repository: repository ?? AIMentorRepository(),
            ),
        super(AIMentorState.loading()) {
    loadMentorData();
  }

  AIMentorState get state => value;

  /// Loads full AI Mentor overview.
  Future<void> loadMentorData() async {
    value = AIMentorState.loading();

    try {
      final overview = await _repository.getMentorOverview();
      value = AIMentorState.ready(overview);
    } catch (e) {
      value = AIMentorState.error(
        "Failed to load AI Mentor insights: ${e.toString()}",
      );
    }
  }

  /// Generates a customized study plan utilizing [GenerateStudyPlanUseCase].
  Future<void> generateCustomStudyPlan({
    int targetDays = 7,
    double dailyHours = 3.0,
  }) async {
    if (value.data == null) return;

    try {
      final updatedPlan = await _generateStudyPlanUseCase.execute(
        targetDays: targetDays,
        dailyHours: dailyHours,
      );

      final updatedData = value.data!.copyWith(
        studyPlan: updatedPlan,
        suggestedDailyStudyHours: dailyHours,
      );

      value = AIMentorState.ready(updatedData);
    } catch (e) {
      value = AIMentorState.error(
        "Failed to generate custom study plan: ${e.toString()}",
      );
    }
  }

  /// Toggles completion status of a specific study plan item.
  void toggleTaskCompletion(String itemId) {
    final currentData = value.data;
    if (currentData == null) return;

    final updatedPlan = currentData.studyPlan.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    value = AIMentorState.ready(
      currentData.copyWith(studyPlan: updatedPlan),
    );
  }

  /// Refreshes all mentor data.
  Future<void> refresh() async {
    await loadMentorData();
  }
}
