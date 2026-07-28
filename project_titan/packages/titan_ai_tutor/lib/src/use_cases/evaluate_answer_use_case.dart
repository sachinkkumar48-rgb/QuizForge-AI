import '../engine/tutor_engine.dart';
import '../models/tutor_models.dart';
import '../repository/tutor_repository.dart';

/// Use case for evaluating student answers and updating progress.
class EvaluateAnswerUseCase {
  final TutorEngine engine;
  final TutorRepository repository;

  const EvaluateAnswerUseCase({
    required this.engine,
    required this.repository,
  });

  Future<TutorEvaluation> execute({
    required TutorExercise exercise,
    required String studentResponse,
    required TutorConcept concept,
  }) async {
    final evaluation = engine.evaluateAnswer(
      exercise: exercise,
      studentResponse: studentResponse,
      concept: concept,
    );

    final existingProgress = await repository.getProgress(concept.id) ??
        TutorProgress(
          conceptId: concept.id,
          masteryLevel: 0.0,
          confidenceLevel: 0.5,
          lastAttemptAt: DateTime.now(),
        );

    final newMastery = engine.estimateMastery(
      currentMastery: existingProgress.masteryLevel,
      newScore: evaluation.score,
    );

    final updatedProgress = existingProgress.copyWith(
      masteryLevel: newMastery,
      exercisesAttempted: existingProgress.exercisesAttempted + 1,
      exercisesPassed: evaluation.score >= 60.0
          ? existingProgress.exercisesPassed + 1
          : existingProgress.exercisesPassed,
      consecutiveSuccesses: evaluation.score >= 60.0
          ? existingProgress.consecutiveSuccesses + 1
          : 0,
      lastAttemptAt: DateTime.now(),
    );

    await repository.updateProgress(updatedProgress);
    return evaluation;
  }
}
