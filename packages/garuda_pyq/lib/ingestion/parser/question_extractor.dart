library;

class RawQuestionBlock {
  final int questionNumber;
  final String questionText;
  final List<String> rawOptions;
  final String? tablePlaceholder;
  final String? imagePlaceholder;

  const RawQuestionBlock({
    required this.questionNumber,
    required this.questionText,
    required this.rawOptions,
    this.tablePlaceholder,
    this.imagePlaceholder,
  });
}

class QuestionExtractor {
  /// Detects question boundaries and extracts blocks from raw paper text.
  static List<RawQuestionBlock> extractBlocks(String rawText) {
    final blocks = <RawQuestionBlock>[];
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return blocks;

    // Check if text uses explicit Q/Question headers
    final qHeaderRegex = RegExp(r'(?:^|\n)\s*Q(?:uestion)?\.?\s*(\d+)[\.\:\)]?', caseSensitive: false);
    final hasQHeaders = qHeaderRegex.hasMatch(trimmed);

    final headerRegex = hasQHeaders
        ? qHeaderRegex
        : RegExp(r'(?:^|\n)\s*(\d+)[\.\:]\s+', caseSensitive: false);

    final matches = headerRegex.allMatches(trimmed).toList();

    if (matches.isEmpty) {
      final optSplit = _extractOptionsFromBlock(trimmed);
      blocks.add(RawQuestionBlock(
        questionNumber: 1,
        questionText: optSplit.$1.trim(),
        rawOptions: optSplit.$2,
      ));
      return blocks;
    }

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final start = match.start;
      final end = (i + 1 < matches.length) ? matches[i + 1].start : trimmed.length;

      final blockText = trimmed.substring(start, end).trim();
      final qNumStr = match.group(1) ?? '${i + 1}';
      final qNum = int.tryParse(qNumStr) ?? (i + 1);

      final optSplit = _extractOptionsFromBlock(blockText);
      blocks.add(RawQuestionBlock(
        questionNumber: qNum,
        questionText: optSplit.$1.trim(),
        rawOptions: optSplit.$2,
        tablePlaceholder: blockText.contains('[TABLE]') ? '[TABLE_DETECTED]' : null,
        imagePlaceholder: blockText.contains('[IMAGE]') ? '[IMAGE_DETECTED]' : null,
      ));
    }

    return blocks;
  }

  static (String, List<String>) _extractOptionsFromBlock(String text) {
    final optRegex = RegExp(r'\b([A-D])[\.\)]\s*(.*?)(?=\b[A-D][\.\)]|$)', dotAll: true);
    final matches = optRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return (text, const []);
    }

    final firstOptIndex = matches.first.start;
    final qText = text.substring(0, firstOptIndex);
    final options = matches.map((m) => '${m.group(1)}: ${m.group(2)?.trim()}').toList();

    return (qText, options);
  }
}
