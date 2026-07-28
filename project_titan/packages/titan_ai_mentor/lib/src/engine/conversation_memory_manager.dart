import '../models/mentor_message.dart';

/// Conversation Memory Manager handling persistence, sliding context window,
/// auto-summarization, session recovery, and token trimming.
class ConversationMemoryManager {
  final int maxWindowSize;
  final Map<String, List<MentorMessage>> _sessionStore = {};
  final Map<String, String> _sessionSummaries = {};

  ConversationMemoryManager({this.maxWindowSize = 10});

  /// Adds a message turn to session memory.
  void addMessage(String sessionId, MentorMessage message) {
    _sessionStore.putIfAbsent(sessionId, () => []).add(message);
  }

  /// Returns full history for [sessionId].
  List<MentorMessage> getFullHistory(String sessionId) {
    return List.unmodifiable(_sessionStore[sessionId] ?? const []);
  }

  /// Returns sliding context window of recent [maxWindowSize] messages for token efficiency.
  List<MentorMessage> getWindowedHistory(String sessionId, {int? windowSize}) {
    final history = _sessionStore[sessionId] ?? const [];
    final size = windowSize ?? maxWindowSize;
    if (history.length <= size) {
      return List.unmodifiable(history);
    }
    return List.unmodifiable(history.sublist(history.length - size));
  }

  /// Trims history to stay within max token budget.
  List<MentorMessage> trimToTokenBudget(
    String sessionId, {
    int maxTokens = 2000,
  }) {
    final history = getWindowedHistory(sessionId);
    int currentChars = 0;
    final kept = <MentorMessage>[];

    for (int i = history.length - 1; i >= 0; i--) {
      final msg = history[i];
      final charLen = msg.content.length;
      if ((currentChars + charLen) / 4 > maxTokens) break;
      currentChars += charLen;
      kept.insert(0, msg);
    }

    return kept;
  }

  /// Checks if background auto-summarization should be triggered.
  bool shouldSummarize(String sessionId) {
    final history = _sessionStore[sessionId] ?? const [];
    return history.length >= maxWindowSize && history.length % 5 == 0;
  }

  /// Updates summary for session.
  void setSummary(String sessionId, String summary) {
    _sessionSummaries[sessionId] = summary;
  }

  /// Gets stored summary for session.
  String? getSummary(String sessionId) => _sessionSummaries[sessionId];

  /// Recovers a conversation session with pre-existing history.
  void recoverSession(String sessionId, List<MentorMessage> history,
      {String? summary}) {
    _sessionStore[sessionId] = List.from(history);
    if (summary != null) {
      _sessionSummaries[sessionId] = summary;
    }
  }

  /// Clears session memory.
  void clearSession(String sessionId) {
    _sessionStore.remove(sessionId);
    _sessionSummaries.remove(sessionId);
  }
}
