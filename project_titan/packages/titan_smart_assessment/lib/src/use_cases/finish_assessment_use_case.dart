import '../engine/assessment_engine.dart';
import '../models/assessment_models.dart';
import '../repository/assessment_repository.dart';

/// Use case for finishing an active assessment session.
class FinishAssessmentUseCase {
  final AssessmentRepository repository;
  final AssessmentEngine engine;

  const FinishAssessmentUseCase({
    required this.repository,
    required this.engine,
  });

  Future<AssessmentSession> execute(String sessionId) async {
    final session = await repository.getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    final now = DateTime.now();
    final finished = session.copyWith(
      status: AssessmentStatus.completed,
      completedAt: now,
      updatedAt: now,
    );

    return repository.updateSession(finished);
  }
}
