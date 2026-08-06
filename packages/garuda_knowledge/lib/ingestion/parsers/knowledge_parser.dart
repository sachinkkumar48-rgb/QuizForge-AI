import '../models/knowledge_document.dart';

/// Result produced by a KnowledgeParser.
class ParseResult {
  final bool isSuccess;
  final String title;
  final String content;
  final Map<String, dynamic> parsedMetadata;
  final List<String> sections;
  final String? errorMessage;

  const ParseResult({
    required this.isSuccess,
    required this.title,
    required this.content,
    this.parsedMetadata = const {},
    this.sections = const [],
    this.errorMessage,
  });

  factory ParseResult.success({
    required String title,
    required String content,
    Map<String, dynamic> metadata = const {},
    List<String> sections = const [],
  }) {
    return ParseResult(
      isSuccess: true,
      title: title,
      content: content,
      parsedMetadata: metadata,
      sections: sections,
    );
  }

  factory ParseResult.failure(String message) {
    return ParseResult(
      isSuccess: false,
      title: '',
      content: '',
      errorMessage: message,
    );
  }
}

/// Abstract contract for parsing document payloads into structured sections and metadata.
abstract class KnowledgeParser {
  String get version;
  ParseResult parse(KnowledgeDocument document);
}
