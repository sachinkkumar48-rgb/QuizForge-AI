import '../../domain/entities/knowledge_object.dart';
import '../../domain/entities/knowledge_relationship.dart';
import '../extractors/knowledge_extractor.dart';
import '../models/knowledge_document.dart';

/// Aggregated output of KnowledgeMapper.
class KnowledgeMappingResult {
  final KnowledgeObject knowledgeObject;
  final List<KnowledgeRelationship> relationships;

  const KnowledgeMappingResult({
    required this.knowledgeObject,
    this.relationships = const [],
  });
}

/// Abstract contract for mapping extracted document details into GARUDA Knowledge Objects.
abstract class KnowledgeMapper {
  KnowledgeMappingResult map({
    required KnowledgeDocument document,
    required ExtractionResult extraction,
  });
}
