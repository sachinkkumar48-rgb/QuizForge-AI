import '../engine/mentor_engine.dart';
import '../models/mentor_message.dart';

/// Clean Architecture Use Case for continuing an existing mentor conversation session.
class ContinueConversationUseCase {
  final MentorEngine _mentorEngine;

  const ContinueConversationUseCase(this._mentorEngine);

  /// Continues conversation in [sessionId].
  Future<MentorMessage> execute({
    required String userId,
    required String userName,
    required String sessionId,
    required String prompt,
  }) {
    return _mentorEngine.ask(
      userId: userId,
      userName: userName,
      prompt: prompt,
      sessionId: sessionId,
    );
  }
}
