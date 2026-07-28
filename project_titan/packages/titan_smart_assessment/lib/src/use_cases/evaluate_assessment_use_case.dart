import 'package:titan_quiz/titan_quiz.dart';
import '../engine/assessment_engine.dart';
import '../models/assessment_models.dart';
import '../repository/assessment_repository.dart';

/// Use case for scoring and evaluating a completed assessment session.
class EvaluateAssessmentUseCase {
  final AssessmentRepository repository;
  final AssessmentEngine engine;

  const EvaluateAssessmentUseCase({
    required this.repository,
    required this.engine,
  });

  Future<AssessmentResult> execute({
    required String sessionId,
    required AssessmentBlueprint blueprint,
    required List<QuizQuestion> questions,
  }) async {
    final session = await repository.getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    final result = engine.scoreAssessment(
      session: session,
      blueprint: blueprint,
      questions: questions,
    );

    await repository.saveResult(result);

    final evaluatedSession = session.copyWith(
      status: AssessmentStatus.evaluated,
      updatedAt: DateTime.now(),
    );
    await repository.updateSession(evaluatedSession);

    return result;
  }
}
