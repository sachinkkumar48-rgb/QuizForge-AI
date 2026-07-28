import '../engine/tutor_engine.dart';
import '../models/tutor_models.dart';

/// Use case for generating practice exercises for a concept.
class GeneratePracticeUseCase {
  final TutorEngine engine;

  const GeneratePracticeUseCase({required this.engine});

  Future<TutorExercise> execute({
    required TutorConcept concept,
    required TutorMemory memory,
  }) async {
    return engine.generateReinforcementDrill(
      concept: concept,
      memory: memory,
    );
  }
}
