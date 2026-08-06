import '../models/knowledge_document.dart';
import '../models/knowledge_document_type.dart';
import '../parsers/knowledge_parser.dart';
import '../extractors/knowledge_extractor.dart';
import '../mapping/knowledge_mapper.dart';

/// Abstract adapter defining domain-specific ingestion strategy for official knowledge sources.
abstract class KnowledgeSourceAdapter {
  /// Unique source identifier (e.g. 'CONSTITUTION_INDIA', 'GAZETTE_GOI', 'UPSC_QP').
  String get sourceId;

  /// Human-readable title of the source.
  String get title;

  /// Associated document type for this adapter.
  KnowledgeDocumentType get supportedDocumentType;

  /// Custom Parser strategy for this adapter.
  KnowledgeParser get parser;

  /// Custom Extractor strategy for this adapter.
  KnowledgeExtractor get extractor;

  /// Custom Mapper strategy for this adapter.
  KnowledgeMapper get mapper;

  /// Validates whether a document can be handled by this source adapter.
  bool supports(KnowledgeDocument document) {
    return document.type == supportedDocumentType ||
        document.source.sourceId.toUpperCase() == sourceId.toUpperCase();
  }
}
