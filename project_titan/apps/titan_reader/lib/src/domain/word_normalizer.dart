/// Single-word detection and normalization for dictionary lookups.
///
/// PDF selections arrive as raw text including punctuation, quotation
/// marks, line breaks and arbitrary capitalization. Dictionary lookup needs
/// a clean headword while meaningful inner punctuation (apostrophes inside
/// contractions and possessives, hyphens inside compounds) must survive.
abstract class WordNormalizer {
  /// Strips surrounding noise from [raw] and lowercases the remainder.
  ///
  /// Returns null when nothing word-like remains.
  ///
  /// Examples:
  /// * `"Ephemeral,"` -> `ephemeral`
  /// * `don't` stays `don't` (inner apostrophe preserved)
  /// * `short-lived.` stays `short-lived` (inner hyphen preserved)
  static String? normalizeWord(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;
    // Collapse internal whitespace/newlines so multi-line fragments do not
    // masquerade as single words.
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    // Repeatedly strip leading/trailing characters that are never part of
    // a headword: punctuation, quotes, brackets, digits-only edges.
    const trimmable = ' \t\r\n.,;:!?\'"“”‘’«»()[]{}<>—–-_/\\|~`@#\$%^&*+=';
    var start = 0;
    var end = text.length;
    while (start < end && trimmable.contains(text[start])) {
      start++;
    }
    while (end > start && trimmable.contains(text[end - 1])) {
      end--;
    }
    final candidate = text.substring(start, end).toLowerCase();
    if (candidate.isEmpty) return null;
    // A candidate containing spaces is a phrase, not a word.
    if (candidate.contains(' ')) return null;
    return candidate;
  }

  /// Whether [raw] selects exactly one word after normalization.
  static bool isSingleWord(String raw) {
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.isEmpty) return false;
    final tokens = collapsed.split(' ');
    if (tokens.length != 1) return false;
    return normalizeWord(collapsed) != null;
  }

  /// The normalized single word inside [raw], or null for phrases and
  /// empty selections.
  static String? singleWordFrom(String raw) =>
      isSingleWord(raw) ? normalizeWord(raw.trim()) : null;
}
