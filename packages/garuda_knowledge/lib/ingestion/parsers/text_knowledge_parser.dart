import '../models/knowledge_document.dart';
import 'knowledge_parser.dart';

/// Structured Text/Markdown KnowledgeParser implementation.
class TextKnowledgeParser implements KnowledgeParser {
  @override
  String get version => '1.0.0';

  @override
  ParseResult parse(KnowledgeDocument document) {
    try {
      final raw = document.content.trim();
      if (raw.isEmpty) {
        return ParseResult.failure('Document content is empty');
      }

      // Split into sections by headers (# or ## or double newlines)
      final lines = raw.split('\n');
      final sections = <String>[];
      final currentSection = StringBuffer();

      for (final line in lines) {
        if (line.startsWith('#') || line.startsWith('SECTION:')) {
          if (currentSection.isNotEmpty) {
            sections.add(currentSection.toString().trim());
            currentSection.clear();
          }
        }
        currentSection.writeln(line);
      }
      if (currentSection.isNotEmpty) {
        sections.add(currentSection.toString().trim());
      }

      return ParseResult.success(
        title: document.title,
        content: raw,
        metadata: {
          'parserType': 'TextKnowledgeParser',
          'lineCount': lines.length,
          'sectionCount': sections.length,
        },
        sections: sections.isNotEmpty ? sections : [raw],
      );
    } catch (e) {
      return ParseResult.failure('Failed to parse text document: $e');
    }
  }
}
