import '../engine/tutor_engine.dart';
import '../models/tutor_models.dart';
import '../repository/tutor_repository.dart';

/// Use case for continuing an active AI Tutor session with student response.
class ContinueTutorSessionUseCase {
  final TutorRepository repository;
  final TutorEngine engine;

  const ContinueTutorSessionUseCase({
    required this.repository,
    required this.engine,
  });

  Future<TutorSession> execute({
    required String sessionId,
    required String userResponse,
  }) async {
    final session = await repository.getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    final misconceptions = engine.detectMisconceptions(
      studentResponse: userResponse,
      concept: TutorConcept(
        id: session.conceptId,
        title: 'Current Topic',
        description: 'Concept being taught',
        subjectCategory: 'General Studies',
        prerequisiteConceptIds: const [],
        relatedTopicIds: const [],
      ),
    );

    final updatedExercises = List<TutorExercise>.from(session.exercises);
    if (updatedExercises.isNotEmpty) {
      final last = updatedExercises.last;
      updatedExercises[updatedExercises.length - 1] = last.copyWith(
        userSubmission: userResponse,
        status: TutorExerciseStatus.completed,
        evaluationId:
            misconceptions.isNotEmpty ? 'has_misconceptions' : 'clean',
      );
    }

    final updated = session.copyWith(
      exercises: updatedExercises,
      updatedAt: DateTime.now(),
      status: TutorSessionStatus.active,
    );

    return repository.updateSession(updated);
  }
}
