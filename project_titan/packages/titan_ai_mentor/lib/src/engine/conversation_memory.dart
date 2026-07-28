import '../models/mentor_message.dart';
import '../providers/mentor_provider.dart';

/// Conversation Memory service managing sliding context windows and auto-summarization.
class ConversationMemory {
  final int maxWindowSize;

  const ConversationMemory({this.maxWindowSize = 10});

  /// Trims history to the most recent [maxWindowSize] messages for token efficiency.
  List<MentorMessage> getWindowedHistory(List<MentorMessage> messages) {
    if (messages.length <= maxWindowSize) {
      return List.unmodifiable(messages);
    }
    return List.unmodifiable(messages.sublist(messages.length - maxWindowSize));
  }

  /// Determines if automatic session summarization should be triggered.
  bool shouldSummarize(List<MentorMessage> messages) {
    return messages.length >= maxWindowSize && messages.length % 5 == 0;
  }

  /// Generates conversation summary using [provider].
  Future<String> summarize(
    MentorProvider provider,
    List<MentorMessage> messages,
  ) {
    return provider.summarizeConversation(messages);
  }
}
