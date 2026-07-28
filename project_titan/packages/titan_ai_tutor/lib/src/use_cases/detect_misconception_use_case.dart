import '../engine/tutor_engine.dart';
import '../models/tutor_models.dart';

/// Use case for detecting misconceptions in learner input.
class DetectMisconceptionUseCase {
  final TutorEngine engine;

  const DetectMisconceptionUseCase({required this.engine});

  Future<List<String>> execute({
    required String studentResponse,
    required TutorConcept concept,
  }) async {
    return engine.detectMisconceptions(
      studentResponse: studentResponse,
      concept: concept,
    );
  }
}
