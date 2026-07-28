import '../models/live_models.dart';
import '../engine/live_session_engine.dart';

/// Use case for submitting a poll vote in a live session.
class SubmitPollUseCase {
  const SubmitPollUseCase();

  Poll? execute({
    required LiveSessionEngine engine,
    required String userId,
    required String optionId,
  }) {
    return engine.votePoll(userId: userId, optionId: optionId);
  }
}
