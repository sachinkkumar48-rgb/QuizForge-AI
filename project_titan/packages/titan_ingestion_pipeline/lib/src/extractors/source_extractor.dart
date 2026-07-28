import '../models/ingestion_source.dart';

/// Interface for raw source content extractors.
abstract class SourceExtractor {
  Future<String> extractText(RawDocumentInput input);
}

/// Extractor for Markdown content.
class MarkdownExtractor implements SourceExtractor {
  @override
  Future<String> extractText(RawDocumentInput input) async {
    return input.rawTextContent;
  }
}

/// Extractor for HTML content.
class HtmlExtractor implements SourceExtractor {
  @override
  Future<String> extractText(RawDocumentInput input) async {
    // Strip simple HTML tags while preserving text block boundaries
    final html = input.rawTextContent;
    final cleaned = html
        .replaceAll(
            RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'</?(p|h[1-6]|li|tr|div)[^>]*>', caseSensitive: false),
            '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '');
    return cleaned;
  }
}

/// Extractor for Plain Text content.
class PlainTextExtractor implements SourceExtractor {
  @override
  Future<String> extractText(RawDocumentInput input) async {
    return input.rawTextContent;
  }
}

/// Extractor for PDF content (Pure Dart abstraction).
class PdfExtractor implements SourceExtractor {
  @override
  Future<String> extractText(RawDocumentInput input) async {
    return input.rawTextContent;
  }
}

/// Extractor for DOCX content (Pure Dart abstraction).
class DocxExtractor implements SourceExtractor {
  @override
  Future<String> extractText(RawDocumentInput input) async {
    return input.rawTextContent;
  }
}

/// Extractor for EPUB content (Future-ready).
class EpubExtractor implements SourceExtractor {
  @override
  Future<String> extractText(RawDocumentInput input) async {
    return input.rawTextContent;
  }
}

/// Factory to obtain appropriate extractor for source type.
class ExtractorFactory {
  static SourceExtractor getExtractor(IngestionSourceType type) {
    switch (type) {
      case IngestionSourceType.markdown:
        return MarkdownExtractor();
      case IngestionSourceType.html:
        return HtmlExtractor();
      case IngestionSourceType.plainText:
        return PlainTextExtractor();
      case IngestionSourceType.pdf:
        return PdfExtractor();
      case IngestionSourceType.docx:
        return DocxExtractor();
      case IngestionSourceType.epub:
        return EpubExtractor();
    }
  }
}
