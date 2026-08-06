import 'dart:convert';
import '../models/knowledge_document.dart';
import 'knowledge_parser.dart';

/// Structured JSON KnowledgeParser implementation.
class JsonKnowledgeParser implements KnowledgeParser {
  @override
  String get version => '1.0.0';

  @override
  ParseResult parse(KnowledgeDocument document) {
    try {
      final raw = document.content.trim();
      if (raw.isEmpty) {
        return ParseResult.failure('Document content is empty');
      }

      final Map<String, dynamic> jsonMap = json.decode(raw) as Map<String, dynamic>;
      final parsedTitle = jsonMap['title'] as String? ?? document.title;
      final parsedBody = jsonMap['body'] as String? ?? jsonMap['content'] as String? ?? raw;

      final sectionsRaw = jsonMap['sections'];
      final sections = <String>[];
      if (sectionsRaw is List) {
        for (final sec in sectionsRaw) {
          sections.add(sec.toString());
        }
      }

      return ParseResult.success(
        title: parsedTitle,
        content: parsedBody,
        metadata: {
          'parserType': 'JsonKnowledgeParser',
          ...jsonMap,
        },
        sections: sections.isNotEmpty ? sections : [parsedBody],
      );
    } catch (e) {
      return ParseResult.failure('Failed to parse JSON document: $e');
    }
  }
}
