import '../engine/tutor_engine.dart';
import '../models/tutor_models.dart';
import '../repository/tutor_repository.dart';

/// Use case for starting a new AI Tutor session.
class StartTutorSessionUseCase {
  final TutorRepository repository;
  final TutorEngine engine;

  const StartTutorSessionUseCase({
    required this.repository,
    required this.engine,
  });

  Future<TutorSession> execute({
    required String learnerId,
    required String conceptId,
    TutorPersona persona = TutorPersona.intermediate,
  }) async {
    final now = DateTime.now();
    final session = TutorSession(
      id: 'session_${learnerId}_${conceptId}_${now.millisecondsSinceEpoch}',
      learnerId: learnerId,
      conceptId: conceptId,
      status: TutorSessionStatus.active,
      persona: persona,
      startedAt: now,
      updatedAt: now,
      progress: TutorProgress(
        conceptId: conceptId,
        masteryLevel: 0.0,
        confidenceLevel: 0.5,
        lastAttemptAt: now,
      ),
    );

    return repository.createSession(session);
  }
}
