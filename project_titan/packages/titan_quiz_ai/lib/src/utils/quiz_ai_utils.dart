/// Helper utilities for AI quiz generation text processing and formatting.
abstract final class QuizAIUtils {
  /// Sanitizes raw input text by removing control characters while preserving newlines.
  static String sanitizeInputText(String text) {
    return text
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .trim();
  }

  /// Estimates approximate token count for prompt text (~4 chars per token).
  static int estimateTokenCount(String text) {
    if (text.isEmpty) return 0;
    return (text.length / 4).ceil();
  }
}
