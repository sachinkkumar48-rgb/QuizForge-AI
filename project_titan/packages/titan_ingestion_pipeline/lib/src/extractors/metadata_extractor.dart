import '../models/ingestion_source.dart';
import '../models/knowledge_object_metadata.dart';

/// Metadata Extractor for Knowledge Ingestion Pipeline.
class MetadataExtractor {
  /// Extracts metadata from raw document input and cleaned content text.
  KnowledgeObjectMetadata extract({
    required RawDocumentInput input,
    required String cleanedText,
    required String detectedLanguage,
    String? titleFromStructure,
  }) {
    final title = titleFromStructure ??
        input.initialMetadata['title'] as String? ??
        input.fileName
            .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
            .replaceAll('_', ' ');

    final author = input.initialMetadata['author'] as String? ??
        _extractPattern(cleanedText, r'(?:Author|Written by):\s*(.+)') ??
        'Unknown';
    final publisher = input.initialMetadata['publisher'] as String? ??
        _extractPattern(cleanedText, r'(?:Publisher|Published by):\s*(.+)') ??
        'Project TITAN';
    final edition = input.initialMetadata['edition'] as String? ??
        _extractPattern(cleanedText, r'(?:Edition):\s*(.+)') ??
        '1st';
    final yearStr = input.initialMetadata['year']?.toString() ??
        _extractPattern(cleanedText, r'(?:Year|Copyright\s+©?)\s*(\d{4})');
    final year = yearStr != null ? int.tryParse(yearStr) : null;
    final copyright = input.initialMetadata['copyright'] as String? ??
        _extractPattern(cleanedText, r'(Copyright\s+©?[^.\n]+)') ??
        '';
    final license = input.initialMetadata['license'] as String? ??
        _extractPattern(cleanedText, r'(License:\s*[^.\n]+)');

    return KnowledgeObjectMetadata(
      title: title,
      author: author,
      publisher: publisher,
      edition: edition,
      year: year,
      language: detectedLanguage,
      sourceType: input.sourceType.name,
      copyright: copyright,
      license: license,
      extra: input.initialMetadata,
    );
  }

  String? _extractPattern(String text, String pattern) {
    final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
    return match?.group(1)?.trim();
  }
}
