/// PDF domain module for importing, validating, extracting, chunking, and managing PDF documents in Project TITAN.
library titan_pdf;

export 'src/bootstrap/titan_pdf_bootstrap.dart';
export 'src/bridge/assessment_document_bridge.dart';
export 'src/exceptions/pdf_exception.dart';
export 'src/models/chunk_options.dart';
export 'src/models/document_ingestion_result.dart';
export 'src/models/document_source.dart';
export 'src/models/learning_document.dart';
export 'src/models/learning_document_chunk.dart';
export 'src/models/learning_page.dart';
export 'src/models/pdf_chunk.dart';
export 'src/models/pdf_document.dart';
export 'src/models/pdf_import_result.dart';
export 'src/models/pdf_metadata.dart';
export 'src/models/pdf_status.dart';
export 'src/models/text_provenance.dart';
export 'src/navigation/reader_deep_link_handler.dart';
export 'src/navigation/reader_deep_link_request.dart';
export 'src/repository/pdf_repository.dart';
export 'src/repository/pdf_repository_impl.dart';
export 'src/services/document_intelligence_service.dart';
export 'src/services/pdf_chunk_service.dart';
export 'src/services/pdf_import_service.dart';
export 'src/services/pdf_text_extractor.dart';
export 'src/services/pdf_validation_service.dart';
export 'src/services/token_estimator.dart';
