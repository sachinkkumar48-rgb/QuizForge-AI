import '../engine/tutor_engine.dart';
import '../models/tutor_models.dart';
import '../repository/tutor_repository.dart';

/// Use case for recommending the next optimal lesson based on mastery and prerequisites.
class RecommendNextLessonUseCase {
  final TutorRepository repository;
  final TutorEngine engine;

  const RecommendNextLessonUseCase({
    required this.repository,
    required this.engine,
  });

  Future<String> execute({
    required String learnerId,
    required List<TutorConcept> availableConcepts,
    required Map<String, double> userMasteries,
  }) async {
    for (final concept in availableConcepts) {
      final missingPrereqs = engine.checkPrerequisites(
        concept: concept,
        userMasteries: userMasteries,
      );
      if (missingPrereqs.isEmpty) {
        final mastery = userMasteries[concept.id] ?? 0.0;
        if (mastery < 80.0) {
          return concept.id;
        }
      }
    }
    return availableConcepts.isNotEmpty ? availableConcepts.first.id : '';
  }
}
