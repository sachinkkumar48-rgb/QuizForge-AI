import '../engine/assessment_engine.dart';
import '../models/assessment_models.dart';
import '../repository/assessment_repository.dart';

/// Use case for starting a new assessment session.
class StartAssessmentUseCase {
  final AssessmentRepository repository;
  final AssessmentEngine engine;

  const StartAssessmentUseCase({
    required this.repository,
    required this.engine,
  });

  Future<AssessmentSession> execute({
    required String assessmentId,
    required String userId,
  }) async {
    final now = DateTime.now();
    final session = AssessmentSession(
      id: 'session_${assessmentId}_${userId}_${now.millisecondsSinceEpoch}',
      assessmentId: assessmentId,
      userId: userId,
      status: AssessmentStatus.inProgress,
      currentQuestionIndex: 0,
      startedAt: now,
      updatedAt: now,
    );

    return repository.createSession(session);
  }
}
