import '../models/mentor_context.dart';
import '../models/mentor_message.dart';

/// Abstract provider interface for AI completion engines (Gemini, OpenAI, Mock).
abstract class MentorProvider {
  /// Generates a response message given [context], conversation [history], and [userPrompt].
  Future<MentorMessage> generateResponse({
    required MentorContext context,
    required List<MentorMessage> history,
    required String userPrompt,
  });

  /// Summarizes a conversation history into a concise summary string.
  Future<String> summarizeConversation(List<MentorMessage> messages);
}
