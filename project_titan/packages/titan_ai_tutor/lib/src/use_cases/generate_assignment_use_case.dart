import '../engine/tutor_engine.dart';
import '../models/tutor_models.dart';

/// Use case for generating multi-question assignments.
class GenerateAssignmentUseCase {
  final TutorEngine engine;

  const GenerateAssignmentUseCase({required this.engine});

  Future<List<TutorExercise>> execute({
    required TutorConcept concept,
    required TutorPersona persona,
    int count = 3,
  }) async {
    return engine.generateAssignment(
      concept: concept,
      persona: persona,
      count: count,
    );
  }
}
