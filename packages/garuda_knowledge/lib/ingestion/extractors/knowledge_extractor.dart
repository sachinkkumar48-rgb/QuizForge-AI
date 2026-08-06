import '../../domain/entities/knowledge_evidence_reference.dart';
import '../models/knowledge_document.dart';
import '../parsers/knowledge_parser.dart';

/// Extracted content, metadata, concepts, and evidence objects from a parsed document.
class ExtractionResult {
  final String title;
  final String content;
  final Map<String, dynamic> metadata;
  final List<String> tags;
  final List<String> concepts;
  final List<KnowledgeEvidenceReference> evidenceReferences;
  final List<Map<String, dynamic>> extractedRelationships;

  const ExtractionResult({
    required this.title,
    required this.content,
    this.metadata = const {},
    this.tags = const [],
    this.concepts = const [],
    this.evidenceReferences = const [],
    this.extractedRelationships = const [],
  });
}

/// Abstract contract for extracting structured entities, tags, evidence, and relationships.
abstract class KnowledgeExtractor {
  ExtractionResult extract({
    required KnowledgeDocument document,
    required ParseResult parseResult,
  });
}
