library;

class QuestionNormalizer {
  /// Cleans and normalizes question text, removes trailing junk, fixes whitespace.
  static String normalizeText(String rawText) {
    var cleaned = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^(?:Q(?:uestion)?\.?\s*\d+[\.\:\)]?|\d+\.|\d+\))\s*'), '');
    return cleaned;
  }
}
