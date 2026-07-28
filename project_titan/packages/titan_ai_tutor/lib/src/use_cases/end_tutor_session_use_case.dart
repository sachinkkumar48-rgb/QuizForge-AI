import '../engine/tutor_engine.dart';
import '../models/tutor_models.dart';
import '../repository/tutor_repository.dart';

/// Use case for ending a tutor session and producing a final summary evaluation.
class EndTutorSessionUseCase {
  final TutorRepository repository;
  final TutorEngine engine;

  const EndTutorSessionUseCase({
    required this.repository,
    required this.engine,
  });

  Future<TutorSession> execute(String sessionId) async {
    final session = await repository.getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    final now = DateTime.now();
    final evaluation = TutorEvaluation(
      id: 'eval_end_${session.id}_${now.millisecondsSinceEpoch}',
      targetId: session.id,
      score: 80.0,
      grade: EvaluationGrade.good,
      feedbackText: 'Session completed successfully.',
      masteredConcepts: [session.conceptId],
      evaluatedAt: now,
    );

    final completedSession = session.copyWith(
      status: TutorSessionStatus.completed,
      evaluation: evaluation,
      updatedAt: now,
    );

    return repository.updateSession(completedSession);
  }
}
