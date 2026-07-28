import '../engine/mentor_engine.dart';
import '../models/mentor_message.dart';

/// Clean Architecture Use Case for requesting AI Mentor concept explanation.
class ExplainConceptUseCase {
  final MentorEngine _mentorEngine;

  const ExplainConceptUseCase(this._mentorEngine);

  /// Requests detailed concept breakdown for [conceptName].
  Future<MentorMessage> execute({
    required String userId,
    required String userName,
    required String conceptName,
    String? sessionId,
  }) {
    final prompt =
        'Please explain the concept of "$conceptName" in detail with UPSC CSE exam relevance and key examples.';
    return _mentorEngine.ask(
      userId: userId,
      userName: userName,
      prompt: prompt,
      sessionId: sessionId,
    );
  }
}
