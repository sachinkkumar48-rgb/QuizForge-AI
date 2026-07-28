import 'package:meta/meta.dart';

/// Supported raw document types for Knowledge Ingestion Pipeline.
enum IngestionSourceType {
  pdf,
  docx,
  markdown,
  html,
  plainText,
  epub,
}

/// Immutable input container for raw educational resources.
@immutable
class RawDocumentInput {
  final String id;
  final String fileName;
  final IngestionSourceType sourceType;
  final String rawTextContent;
  final Map<String, dynamic> initialMetadata;
  final DateTime importedAt;

  RawDocumentInput({
    required this.id,
    required this.fileName,
    required this.sourceType,
    required this.rawTextContent,
    Map<String, dynamic>? initialMetadata,
    DateTime? importedAt,
  })  : initialMetadata = Map.unmodifiable(initialMetadata ?? {}),
        importedAt = importedAt ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawDocumentInput &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fileName == other.fileName &&
          sourceType == other.sourceType &&
          rawTextContent == other.rawTextContent;

  @override
  int get hashCode => Object.hash(id, fileName, sourceType, rawTextContent);
}
