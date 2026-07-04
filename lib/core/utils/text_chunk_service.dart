class TextChunkService {
  TextChunkService._();

  /// Cleans extracted PDF text.
  static String cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\r\n'), '\n')
        .replaceAll(RegExp(r'\n{2,}'), '\n\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  /// Splits long text into chunks.
  ///
  /// Default chunk size is 8000 characters,
  /// which is safe for Gemini requests while
  /// keeping enough context.
  static List<String> splitIntoChunks(
      String text, {
        int chunkSize = 8000,
      }) {
    final cleaned = cleanText(text);

    if (cleaned.length <= chunkSize) {
      return [cleaned];
    }

    final List<String> chunks = [];

    int start = 0;

    while (start < cleaned.length) {
      int end = start + chunkSize;

      if (end >= cleaned.length) {
        chunks.add(cleaned.substring(start));
        break;
      }

      // Try not to cut words.
      while (end > start && cleaned[end] != ' ') {
        end--;
      }

      chunks.add(
        cleaned.substring(start, end).trim(),
      );

      start = end;
    }

    return chunks;
  }
}