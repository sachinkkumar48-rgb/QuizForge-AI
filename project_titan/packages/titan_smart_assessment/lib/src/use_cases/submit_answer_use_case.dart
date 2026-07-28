import '../engine/assessment_engine.dart';
import '../models/assessment_models.dart';
import '../repository/assessment_repository.dart';

/// Use case for submitting an answer to a question within an assessment session.
class SubmitAnswerUseCase {
  final AssessmentRepository repository;
  final AssessmentEngine engine;

  const SubmitAnswerUseCase({
    required this.repository,
    required this.engine,
  });

  Future<AssessmentSession> execute({
    required String sessionId,
    required String questionId,
    String selectedOptionId = '',
    String textResponse = '',
    bool isCorrect = false,
    int timeSpentSeconds = 30,
    double confidenceLevel = 0.8,
  }) async {
    final session = await repository.getSession(sessionId);
    if (session == null) {
      throw ArgumentError('Session not found: $sessionId');
    }

    final now = DateTime.now();
    final attempt = AssessmentAttempt(
      id: 'att_${questionId}_${now.millisecondsSinceEpoch}',
      sessionId: sessionId,
      questionId: questionId,
      selectedOptionId: selectedOptionId,
      textResponse: textResponse,
      isCorrect: isCorrect,
      timeSpentSeconds: timeSpentSeconds,
      confidenceLevel: confidenceLevel,
      timestamp: now,
    );

    await repository.recordAttempt(attempt);

    final updatedAttempts = List<AssessmentAttempt>.from(session.attempts)
      ..add(attempt);
    final updatedSession = session.copyWith(
      attempts: updatedAttempts,
      currentQuestionIndex: session.currentQuestionIndex + 1,
      updatedAt: now,
    );

    return repository.updateSession(updatedSession);
  }
}
