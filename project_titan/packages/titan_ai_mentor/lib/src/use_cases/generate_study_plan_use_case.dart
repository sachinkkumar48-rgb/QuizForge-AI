import '../engine/mentor_engine.dart';
import '../models/mentor_message.dart';

/// Clean Architecture Use Case for requesting an AI-generated study plan.
class GenerateStudyPlanUseCase {
  final MentorEngine _mentorEngine;

  const GenerateStudyPlanUseCase(this._mentorEngine);

  /// Triggers study plan generation tailored to current learning profile and exam target.
  Future<MentorMessage> execute({
    required String userId,
    required String userName,
    String? targetExam,
    String? sessionId,
  }) {
    final prompt =
        'Generate a personalized study plan for ${targetExam ?? "UPSC CSE"} targeting my weak subjects and study hours.';
    return _mentorEngine.ask(
      userId: userId,
      userName: userName,
      prompt: prompt,
      sessionId: sessionId,
    );
  }
}
