import '../../models/ai_mentor_models.dart';
import '../../repositories/ai_mentor_repository.dart';

/// Clean Architecture Domain contract for generating a personalized study plan.
abstract class GenerateStudyPlanUseCase {
  Future<List<StudyPlanItem>> execute({
    int targetDays = 7,
    double dailyHours = 3.0,
  });
}

/// Concrete implementation of [GenerateStudyPlanUseCase] delegating to [AIMentorRepository].
class GenerateStudyPlanUseCaseImpl implements GenerateStudyPlanUseCase {
  final AIMentorRepository _repository;

  GenerateStudyPlanUseCaseImpl({AIMentorRepository? repository})
      : _repository = repository ?? AIMentorRepository();

  @override
  Future<List<StudyPlanItem>> execute({
    int targetDays = 7,
    double dailyHours = 3.0,
  }) async {
    return await _repository.generateStudyPlan(
      targetDays: targetDays,
      dailyHours: dailyHours,
    );
  }
}
