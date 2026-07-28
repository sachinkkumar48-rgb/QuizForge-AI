/// Manages token estimation, context window trimming, budget tracking,
/// and maximum context length enforcement for pure Dart AI pipelines.
class TokenBudgetManager {
  final int defaultMaxContextTokens;
  final int maxOutputTokens;
  int _accumulatedTokenUsage = 0;

  TokenBudgetManager({
    this.defaultMaxContextTokens = 8192,
    this.maxOutputTokens = 2048,
  });

  /// Total tokens tracked during the current manager lifecycle.
  int get accumulatedTokenUsage => _accumulatedTokenUsage;

  /// Records token consumption.
  void trackUsage(int tokens) {
    if (tokens > 0) {
      _accumulatedTokenUsage += tokens;
    }
  }

  /// Resets cumulative token counter.
  void resetUsage() {
    _accumulatedTokenUsage = 0;
  }

  /// Fast pure-Dart token estimator heuristic (~4 characters per token).
  int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    // Approximates token count based on standard ~4 char/token for English text.
    final charCount = text.length;
    final wordCount = text.split(RegExp(r'\s+')).length;
    return ((charCount / 4) + (wordCount / 2)).ceil();
  }

  /// Trims prompt to stay within [maxTokens] limit.
  String trimPrompt(String prompt, {int? maxTokens}) {
    final limit = maxTokens ?? (defaultMaxContextTokens - maxOutputTokens);
    final currentEstimate = estimateTokens(prompt);
    if (currentEstimate <= limit) return prompt;

    // Proportionally slice text from start if context exceeds token budget
    final targetLength = ((prompt.length * limit) / currentEstimate).floor();
    if (targetLength <= 0) return '';
    return prompt.substring(prompt.length - targetLength);
  }

  /// Trims conversation messages list to fit inside [maxTokens] budget,
  /// preserving system messages or latest turns.
  List<Map<String, String>> trimConversationHistory(
    List<Map<String, String>> history, {
    int? maxTokens,
  }) {
    final limit = maxTokens ?? (defaultMaxContextTokens - maxOutputTokens);
    if (history.isEmpty) return const [];

    final result = <Map<String, String>>[];
    int currentTokens = 0;

    // Preserve system messages at top if present
    final systemMsgs = history.where((msg) => msg['role'] == 'system').toList();
    for (final sys in systemMsgs) {
      final t = estimateTokens(sys['content'] ?? '');
      currentTokens += t;
      result.add(sys);
    }

    final nonSystemMsgs =
        history.where((msg) => msg['role'] != 'system').toList();

    // Iterate backwards from newest to oldest messages
    final keptNonSystem = <Map<String, String>>[];
    for (int i = nonSystemMsgs.length - 1; i >= 0; i--) {
      final msg = nonSystemMsgs[i];
      final text = msg['content'] ?? '';
      final tokens = estimateTokens(text);

      if (currentTokens + tokens > limit) {
        break;
      }
      currentTokens += tokens;
      keptNonSystem.insert(0, msg);
    }

    result.addAll(keptNonSystem);
    return result;
  }

  /// Evaluates whether the given [prompt] and [history] fit within token capacity.
  bool fitsWithinBudget({
    required String prompt,
    List<Map<String, String>>? history,
    int? maxContextTokens,
  }) {
    final limit = maxContextTokens ?? defaultMaxContextTokens;
    int total = estimateTokens(prompt) + maxOutputTokens;
    if (history != null) {
      for (final msg in history) {
        total += estimateTokens(msg['content'] ?? '');
      }
    }
    return total <= limit;
  }
}
