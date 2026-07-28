import '../engine/tutor_engine.dart';
import '../models/tutor_models.dart';
import '../repository/tutor_repository.dart';

/// Use case for explaining a concept tailored to persona and difficulty.
class ExplainConceptUseCase {
  final TutorEngine engine;
  final TutorRepository repository;

  const ExplainConceptUseCase({
    required this.engine,
    required this.repository,
  });

  Future<TutorLesson> execute({
    required TutorConcept concept,
    required TutorPersona persona,
    TutorDifficultyLevel difficulty = TutorDifficultyLevel.intermediate,
  }) async {
    final lesson = engine.explainConcept(
      concept: concept,
      persona: persona,
      difficulty: difficulty,
    );
    await repository.saveLesson(lesson);
    return lesson;
  }
}
