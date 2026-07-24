/// Responsible for cleaning, sanitizing, and normalizing raw input text
/// before chunking and knowledge object creation in the TITAN pipeline.
class TextNormalizer {
  /// Regular expression to match non-printable ASCII control characters
  /// except line feed (\n) and carriage return (\r) and tab (\t).
  static final RegExp _controlCharRegex =
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]');

  /// Regular expression matching multiple consecutive spaces or horizontal tabs.
  static final RegExp _horizontalSpacesRegex = RegExp(r'[ \t]+');

  /// Regular expression matching 3 or more consecutive newlines.
  static final RegExp _excessiveNewlinesRegex = RegExp(r'\n{3,}');

  /// Normalizes raw input text by stripping control characters, removing
  /// trailing line spaces, collapsing excessive empty lines to paragraph double-newlines,
  /// and preserving headings and paragraph boundaries.
  String normalize(String input) {
    if (input.isEmpty) {
      return '';
    }

    // 1. Remove non-printable control characters
    var cleaned = input.replaceAll(_controlCharRegex, '');

    // 2. Normalize Windows CRLF to standard \n
    cleaned = cleaned.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // 3. Trim trailing spaces from each line and collapse redundant horizontal spacing
    final lines = cleaned.split('\n');
    final processedLines = lines.map((line) {
      return line.replaceAll(_horizontalSpacesRegex, ' ').trim();
    });

    cleaned = processedLines.join('\n');

    // 4. Collapse 3+ consecutive newlines into semantic paragraph double-newlines (\n\n)
    cleaned = cleaned.replaceAll(_excessiveNewlinesRegex, '\n\n');

    return cleaned.trim();
  }
}
