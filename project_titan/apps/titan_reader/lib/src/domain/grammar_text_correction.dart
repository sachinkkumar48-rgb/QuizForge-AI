/// Offset-safe application of grammar replacements to a checked text.
///
/// Grammar engines report spans as `[startOffset, endOffset)` character
/// offsets into the checked text. Applying replacements must never shift
/// the spans that are still pending, therefore accepted replacements are
/// applied right-to-left.
abstract class GrammarTextCorrection {
  /// Applies [replacements] (offset span → replacement text) to [text].
  ///
  /// Overlapping or out-of-bounds spans are skipped deterministically
  /// (earlier span wins) instead of corrupting the text. Returns the
  /// corrected text; returns [text] unchanged when no replacement applies.
  static String apply(
    String text,
    Map<(int start, int end), String> replacements,
  ) {
    if (replacements.isEmpty) return text;
    final spans = replacements.entries
        .where((entry) =>
            entry.key.$1 >= 0 &&
            entry.key.$2 >= entry.key.$1 &&
            entry.key.$2 <= text.length)
        .toList()
      ..sort((a, b) {
        final byStart = a.key.$1.compareTo(b.key.$1);
        if (byStart != 0) return byStart;
        return a.key.$2.compareTo(b.key.$2);
      });

    // Drop spans overlapping an already accepted span (earlier span wins).
    final accepted = <MapEntry<(int, int), String>>[];
    var lastEnd = -1;
    for (final span in spans) {
      if (span.key.$1 < lastEnd) continue;
      accepted.add(span);
      lastEnd = span.key.$2;
    }

    final result = StringBuffer();
    var cursor = 0;
    for (final span in accepted) {
      result.write(text.substring(cursor, span.key.$1));
      result.write(span.value);
      cursor = span.key.$2;
    }
    result.write(text.substring(cursor));
    return result.toString();
  }
}
