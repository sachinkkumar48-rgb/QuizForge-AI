import '../engine/mentor_engine.dart';
import '../models/mentor_message.dart';

/// Clean Architecture Use Case for receiving AI-recommended revision priorities.
class SuggestRevisionUseCase {
  final MentorEngine _mentorEngine;

  const SuggestRevisionUseCase(this._mentorEngine);

  /// Triggers revision suggestion request based on spaced repetition status.
  Future<MentorMessage> execute({
    required String userId,
    required String userName,
    String? sessionId,
  }) {
    const prompt =
        'What pending topics and flashcards should I prioritize in my revision queue today?';
    return _mentorEngine.ask(
      userId: userId,
      userName: userName,
      prompt: prompt,
      sessionId: sessionId,
    );
  }
}
