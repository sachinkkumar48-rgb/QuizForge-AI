import '../extractors/default_knowledge_extractor.dart';
import '../extractors/knowledge_extractor.dart';
import '../mapping/default_knowledge_mapper.dart';
import '../mapping/knowledge_mapper.dart';
import '../models/knowledge_document_type.dart';
import '../parsers/knowledge_parser.dart';
import '../parsers/text_knowledge_parser.dart';
import 'knowledge_source_adapter.dart';

/// Source Adapter for the Constitution of India.
class ConstitutionSourceAdapter extends KnowledgeSourceAdapter {
  @override
  String get sourceId => 'CONSTITUTION_INDIA';

  @override
  String get title => 'Constitution of India Adapter';

  @override
  KnowledgeDocumentType get supportedDocumentType => KnowledgeDocumentType.constitution;

  @override
  KnowledgeParser get parser => TextKnowledgeParser();

  @override
  KnowledgeExtractor get extractor => DefaultKnowledgeExtractor();

  @override
  KnowledgeMapper get mapper => DefaultKnowledgeMapper();
}
