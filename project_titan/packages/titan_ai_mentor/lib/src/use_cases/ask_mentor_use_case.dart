import '../engine/mentor_engine.dart';
import '../models/mentor_message.dart';

/// Clean Architecture Use Case for sending a standalone question to AI Mentor.
class AskMentorUseCase {
  final MentorEngine _mentorEngine;

  const AskMentorUseCase(this._mentorEngine);

  /// Submits prompt and receives mentor response.
  Future<MentorMessage> execute({
    required String userId,
    required String userName,
    required String prompt,
  }) {
    return _mentorEngine.ask(
      userId: userId,
      userName: userName,
      prompt: prompt,
    );
  }
}
