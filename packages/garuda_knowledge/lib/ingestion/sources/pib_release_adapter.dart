import '../extractors/default_knowledge_extractor.dart';
import '../extractors/knowledge_extractor.dart';
import '../mapping/default_knowledge_mapper.dart';
import '../mapping/knowledge_mapper.dart';
import '../models/knowledge_document_type.dart';
import '../parsers/knowledge_parser.dart';
import '../parsers/text_knowledge_parser.dart';
import 'knowledge_source_adapter.dart';

/// Source Adapter for PIB (Press Information Bureau) Releases.
class PibReleaseAdapter extends KnowledgeSourceAdapter {
  @override
  String get sourceId => 'PIB_RELEASE';

  @override
  String get title => 'PIB Press Release Adapter';

  @override
  KnowledgeDocumentType get supportedDocumentType => KnowledgeDocumentType.pibRelease;

  @override
  KnowledgeParser get parser => TextKnowledgeParser();

  @override
  KnowledgeExtractor get extractor => DefaultKnowledgeExtractor();

  @override
  KnowledgeMapper get mapper => DefaultKnowledgeMapper();
}
