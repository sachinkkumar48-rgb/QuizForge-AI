import '../extractors/default_knowledge_extractor.dart';
import '../extractors/knowledge_extractor.dart';
import '../mapping/default_knowledge_mapper.dart';
import '../mapping/knowledge_mapper.dart';
import '../models/knowledge_document_type.dart';
import '../parsers/knowledge_parser.dart';
import '../parsers/text_knowledge_parser.dart';
import 'knowledge_source_adapter.dart';

/// Source Adapter for Economic Survey of India.
class EconomicSurveyAdapter extends KnowledgeSourceAdapter {
  @override
  String get sourceId => 'ECONOMIC_SURVEY';

  @override
  String get title => 'Economic Survey Adapter';

  @override
  KnowledgeDocumentType get supportedDocumentType => KnowledgeDocumentType.economicSurvey;

  @override
  KnowledgeParser get parser => TextKnowledgeParser();

  @override
  KnowledgeExtractor get extractor => DefaultKnowledgeExtractor();

  @override
  KnowledgeMapper get mapper => DefaultKnowledgeMapper();
}
