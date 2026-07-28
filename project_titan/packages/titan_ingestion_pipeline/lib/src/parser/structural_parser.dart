import '../models/content_block.dart';

/// Result of structural parsing of a document.
class ParsedStructure {
  final String? course;
  final String? module;
  final String? chapter;
  final String title;
  final List<ContentBlock> blocks;
  final List<String> sections;
  final List<String> topics;
  final List<String> subtopics;

  ParsedStructure({
    this.course,
    this.module,
    this.chapter,
    required this.title,
    required this.blocks,
    required this.sections,
    required this.topics,
    required this.subtopics,
  });
}

/// Structural Parser for extracting document hierarchy and content blocks.
class StructuralParser {
  /// Parses cleaned text into a structured document representation.
  ParsedStructure parse(String cleanedText,
      {String fallbackTitle = 'Untitled Lesson'}) {
    final lines = cleanedText.split('\n');
    final blocks = <ContentBlock>[];
    final sections = <String>[];
    final topics = <String>[];
    final subtopics = <String>[];

    String? course;
    String? module;
    String? chapter;
    String title = fallbackTitle;

    var blockIdCounter = 1;
    String generateId() => 'b_${blockIdCounter++}';

    var index = 0;
    while (index < lines.length) {
      final line = lines[index].trim();
      if (line.isEmpty) {
        index++;
        continue;
      }

      // Detect Course / Module / Chapter metadata headers
      final courseMatch =
          RegExp(r'^(?:Course|Subject):\s*(.+)$', caseSensitive: false)
              .firstMatch(line);
      if (courseMatch != null) {
        course = courseMatch.group(1)?.trim();
        index++;
        continue;
      }

      final moduleMatch =
          RegExp(r'^(?:Module|Unit)\s*\d*:\s*(.+)$', caseSensitive: false)
              .firstMatch(line);
      if (moduleMatch != null) {
        module = moduleMatch.group(1)?.trim();
        index++;
        continue;
      }

      final chapterMatch =
          RegExp(r'^(?:Chapter)\s*\d*:\s*(.+)$', caseSensitive: false)
              .firstMatch(line);
      if (chapterMatch != null) {
        chapter = chapterMatch.group(1)?.trim();
        index++;
        continue;
      }

      // Detect Headings (Markdown style # or H1-H6)
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final headingText = headingMatch.group(2)!.trim();

        if (level == 1 && title == fallbackTitle) {
          title = headingText;
        }

        if (level == 2) sections.add(headingText);
        if (level == 3) topics.add(headingText);
        if (level >= 4) subtopics.add(headingText);

        blocks.add(
            HeadingBlock(id: generateId(), level: level, text: headingText));
        index++;
        continue;
      }

      // Detect Code Block (```)
      if (line.startsWith('```')) {
        final language = line.substring(3).trim();
        final codeLines = <String>[];
        index++;
        while (index < lines.length && !lines[index].trim().startsWith('```')) {
          codeLines.add(lines[index]);
          index++;
        }
        if (index < lines.length) index++; // skip closing ```
        blocks.add(CodeBlock(
          id: generateId(),
          code: codeLines.join('\n'),
          language: language.isEmpty ? 'plain' : language,
        ));
        continue;
      }

      // Detect Formula ($$ ... $$ or \[ ... \])
      if (line.startsWith(r'$$') || line.startsWith(r'\[')) {
        final formulaText =
            line.replaceAll(RegExp(r'^(\$\$|\\\[)|(\$\$|\\\])$'), '').trim();
        blocks.add(FormulaBlock(
            id: generateId(), latex: formulaText, isInline: false));
        index++;
        continue;
      }

      // Detect Bullet List (- or * or •)
      if (RegExp(r'^[-*•]\s+').hasMatch(line)) {
        final listItems = <String>[];
        while (index < lines.length &&
            RegExp(r'^[-*•]\s+').hasMatch(lines[index].trim())) {
          listItems
              .add(lines[index].trim().replaceFirst(RegExp(r'^[-*•]\s+'), ''));
          index++;
        }
        blocks.add(BulletListBlock(id: generateId(), items: listItems));
        continue;
      }

      // Detect Table (| ... |)
      if (line.startsWith('|') && line.endsWith('|')) {
        final headers = line
            .split('|')
            .where((s) => s.trim().isNotEmpty)
            .map((s) => s.trim())
            .toList();
        index++;
        // Skip separator line if present (e.g. |---|---|)
        if (index < lines.length && lines[index].contains('---')) {
          index++;
        }
        final rows = <List<String>>[];
        while (index < lines.length && lines[index].trim().startsWith('|')) {
          final row = lines[index]
              .split('|')
              .where((s) => s.trim().isNotEmpty)
              .map((s) => s.trim())
              .toList();
          rows.add(row);
          index++;
        }
        blocks.add(TableBlock(id: generateId(), headers: headers, rows: rows));
        continue;
      }

      // Detect Quote (> ...)
      if (line.startsWith('>')) {
        final quoteText = line.replaceFirst(RegExp(r'^>\s*'), '').trim();
        blocks.add(QuoteBlock(id: generateId(), quote: quoteText));
        index++;
        continue;
      }

      // Detect Example (Example: ...)
      if (line.toLowerCase().startsWith('example:')) {
        final exampleContent = line.substring(8).trim();
        blocks.add(ExampleBlock(
            id: generateId(), title: 'Example', content: exampleContent));
        index++;
        continue;
      }

      // Detect Activity (Activity: ...)
      if (line.toLowerCase().startsWith('activity:')) {
        final activityContent = line.substring(9).trim();
        blocks.add(ActivityBlock(
            id: generateId(),
            title: 'Activity',
            instructions: activityContent));
        index++;
        continue;
      }

      // Detect Image Reference (![alt](url))
      final imageMatch = RegExp(r'^!\[([^\]]*)\]\(([^)]+)\)$').firstMatch(line);
      if (imageMatch != null) {
        blocks.add(ImageReferenceBlock(
          id: generateId(),
          altText: imageMatch.group(1) ?? '',
          url: imageMatch.group(2) ?? '',
        ));
        index++;
        continue;
      }

      // Default to Paragraph Block
      blocks.add(ParagraphBlock(id: generateId(), text: line));
      index++;
    }

    return ParsedStructure(
      course: course,
      module: module,
      chapter: chapter,
      title: title,
      blocks: blocks,
      sections: sections,
      topics: topics,
      subtopics: subtopics,
    );
  }
}
