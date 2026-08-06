import '../extractors/default_knowledge_extractor.dart';
import '../extractors/knowledge_extractor.dart';
import '../mapping/default_knowledge_mapper.dart';
import '../mapping/knowledge_mapper.dart';
import '../models/knowledge_document_type.dart';
import '../parsers/json_knowledge_parser.dart';
import '../parsers/knowledge_parser.dart';
import 'knowledge_source_adapter.dart';

/// Source Adapter for UPSC Previous Year Question Papers.
class UpscQuestionPaperAdapter extends KnowledgeSourceAdapter {
  @override
  String get sourceId => 'UPSC_QP';

  @override
  String get title => 'UPSC Question Papers Adapter';

  @override
  KnowledgeDocumentType get supportedDocumentType => KnowledgeDocumentType.upscQuestionPaper;

  @override
  KnowledgeParser get parser => JsonKnowledgeParser();

  @override
  KnowledgeExtractor get extractor => DefaultKnowledgeExtractor();

  @override
  KnowledgeMapper get mapper => DefaultKnowledgeMapper();
}
