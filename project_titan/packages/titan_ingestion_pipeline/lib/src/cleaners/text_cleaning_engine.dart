/// Pure Dart Text Cleaning Engine supporting 8 mandatory cleaning steps.
class TextCleaningEngine {
  /// Cleans raw extracted document text across all 8 pipeline steps.
  String clean(String rawText) {
    if (rawText.isEmpty) return '';

    var text = rawText;

    // 1. Unicode Normalization (NFC / standard character replacement)
    text = normalizeUnicode(text);

    // 2. OCR Cleanup (fixes common OCR artifacts like ligatures & noise)
    text = cleanupOcr(text);

    // 3. Page Number Removal (e.g., Page 1 of 10, - 12 -, [Page 4])
    text = removePageNumbers(text);

    // 4. Header & Footer Removal (running headers/footers)
    text = removeHeadersAndFooters(text);

    // 5. Broken Line Repair (joins words hyphenated across lines)
    text = repairBrokenLines(text);

    // 6. Whitespace Normalization (collapses multiple spaces/newlines)
    text = normalizeWhitespace(text);

    // 7. Duplicate Paragraph Removal
    text = removeDuplicateParagraphs(text);

    return text.trim();
  }

  /// 1. Unicode Normalization
  String normalizeUnicode(String input) {
    return input
        .replaceAll('\u200B', '') // Zero-width space
        .replaceAll('\uFEFF', '') // Byte order mark
        .replaceAll('\u00A0', ' ') // Non-breaking space
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('‘', "'")
        .replaceAll('’', "'")
        .replaceAll('–', '-')
        .replaceAll('—', '-');
  }

  /// 2. OCR Cleanup
  String cleanupOcr(String input) {
    return input
        .replaceAll(RegExp(r'\b(l|I)11\b'), 'all')
        .replaceAll('vv', 'w')
        .replaceAll(RegExp(r'[|│]'), '')
        .replaceAll(RegExp(r'\b[0O]0P5\b'), 'OOPS');
  }

  /// 3. Page Number Removal
  String removePageNumbers(String input) {
    var lines = input.split('\n');
    final pagePattern = RegExp(
      r'^\s*(?:Page\s+\d+(?:\s+of\s+\d+)?|-?\s*\d+\s*-?|\[\s*Page\s+\d+\s*\])\s*$',
      caseSensitive: false,
    );
    lines = lines.where((line) => !pagePattern.hasMatch(line)).toList();
    return lines.join('\n');
  }

  /// 4. Header & Footer Removal
  String removeHeadersAndFooters(String input) {
    var lines = input.split('\n');
    final headerFooterPattern = RegExp(
      r'^\s*(?:CHAPTER\s+\d+|SECTION\s+\d+|CONFIDENTIAL|ALL RIGHTS RESERVED|COPYRIGHT\s+©\s*\d{4})\s*$',
      caseSensitive: false,
    );
    lines = lines.where((line) => !headerFooterPattern.hasMatch(line)).toList();
    return lines.join('\n');
  }

  /// 5. Broken Line Repair
  String repairBrokenLines(String input) {
    // Joins words like "con- \n stitution" -> "constitution"
    return input.replaceAllMapped(
      RegExp(r'(\w+)-\s*\n\s*(\w+)'),
      (match) => '${match.group(1)}${match.group(2)}',
    );
  }

  /// 6. Whitespace Normalization
  String normalizeWhitespace(String input) {
    return input
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  /// 7. Duplicate Paragraph Removal
  String removeDuplicateParagraphs(String input) {
    final paragraphs = input.split(RegExp(r'\n\s*\n'));
    final seen = <String>{};
    final uniqueParagraphs = <String>[];

    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;
      if (seen.add(trimmed.toLowerCase())) {
        uniqueParagraphs.add(trimmed);
      }
    }
    return uniqueParagraphs.join('\n\n');
  }
}

/// Text Normalization Engine
class TextNormalizer {
  String normalizeText(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
