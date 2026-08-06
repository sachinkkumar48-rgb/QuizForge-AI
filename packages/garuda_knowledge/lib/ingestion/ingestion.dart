/// GARUDA National Knowledge Ingestion Framework Library Entrypoint.
library;

// Models
export 'models/knowledge_document.dart';
export 'models/knowledge_document_type.dart';
export 'models/knowledge_editorial_status.dart';
export 'models/knowledge_import_result.dart';
export 'models/knowledge_import_session.dart';
export 'models/knowledge_import_statistics.dart';
export 'models/knowledge_ingestion_report.dart';

// Sources & Adapters
export 'sources/constitution_source_adapter.dart';
export 'sources/economic_survey_adapter.dart';
export 'sources/gazette_notification_adapter.dart';
export 'sources/knowledge_source_adapter.dart';
export 'sources/ministry_report_adapter.dart';
export 'sources/pib_release_adapter.dart';
export 'sources/prs_report_adapter.dart';
export 'sources/supreme_court_judgment_adapter.dart';
export 'sources/union_budget_adapter.dart';
export 'sources/upsc_answer_key_adapter.dart';
export 'sources/upsc_question_paper_adapter.dart';

// Parsers
export 'parsers/json_knowledge_parser.dart';
export 'parsers/knowledge_parser.dart';
export 'parsers/text_knowledge_parser.dart';

// Extractors
export 'extractors/default_knowledge_extractor.dart';
export 'extractors/knowledge_extractor.dart';

// Processors
export 'processors/default_knowledge_processor.dart';
export 'processors/knowledge_processor.dart';

// Validators
export 'validators/checksum_validator.dart';
export 'validators/composite_ingestion_validator.dart';
export 'validators/content_validator.dart';
export 'validators/duplicate_document_validator.dart';
export 'validators/format_validator.dart';
export 'validators/ingestion_document_validator.dart';
export 'validators/metadata_validator.dart';
export 'validators/reference_validator.dart';
export 'validators/version_validator.dart';

// Mapping
export 'mapping/default_knowledge_mapper.dart';
export 'mapping/knowledge_mapper.dart';

// Publication
export 'publication/knowledge_publication_service.dart';

// Services
export 'services/knowledge_ingestion_service.dart';
