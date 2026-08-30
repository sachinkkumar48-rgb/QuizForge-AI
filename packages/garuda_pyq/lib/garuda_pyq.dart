// Domain Models
export 'models/answer_model.dart';
export 'models/editorial_review_model.dart';
export 'models/editorial_status.dart';
export 'models/exam_model.dart';
export 'models/option_model.dart';
export 'models/paper_model.dart';
export 'models/question_analytics_model.dart';
export 'models/question_model.dart';
export 'models/source_model.dart';
export 'models/topic_mapping_model.dart';

// Concept Engine Domain Models & Enums (TITAN-PYQ-002)
export 'concepts/cognitive_level.dart';
export 'concepts/concept_evidence_model.dart';
export 'concepts/concept_group_model.dart';
export 'concepts/concept_model.dart';
export 'concepts/concept_relationship_model.dart';
export 'concepts/confidence_score.dart';
export 'concepts/mapping_method.dart';
export 'concepts/question_nature.dart';

// Editorial Production & Traps (TITAN-PYQ-003)
export 'editorial/learning_objectives_model.dart';
export 'editorial/question_trap_model.dart';

// Mappings (TITAN-PYQ-002)
export 'mappings/question_concept_mapping_model.dart';

// Repositories
export 'repositories/concept_repository.dart';
export 'repositories/concept_repository_interface.dart';
export 'repositories/question_concept_repository.dart';
export 'repositories/question_concept_repository_interface.dart';
export 'repository/offline_pyq_repository.dart';
export 'repository/pyq_repository_interface.dart';

// Services (TITAN-PYQ-002 & TITAN-PYQ-003)
export 'application/pyq_service.dart';
export 'services/concept_mapping_service.dart';
export 'services/concept_search_service.dart';
export 'services/editorial_workflow_service.dart';

// Datasets (TITAN-PYQ-003 & TITAN-KO-007.4)
export 'datasets/upsc_cse_polity_dataset.dart';
export 'datasets/upsc_master_corpus_1995_2025.dart';

// Ingestion Layer (TITAN-KO-007.5 Mass PYQ Pipeline)
export 'ingestion/answer_keys/official_answer_key_merger.dart';
export 'ingestion/batch_importer.dart';
export 'ingestion/csv_ingestion.dart';
export 'ingestion/duplicate_detector.dart';
export 'ingestion/json_ingestion.dart';
export 'ingestion/manual_entry_ingestion.dart';
export 'ingestion/ocr/ocr_pipeline_architecture.dart';
export 'ingestion/ocr_pipeline_stub.dart';
export 'ingestion/official_paper_ingestion.dart';
export 'ingestion/parser/metadata_extractor.dart';
export 'ingestion/parser/official_paper_parser.dart';
export 'ingestion/parser/option_extractor.dart';
export 'ingestion/parser/question_extractor.dart';
export 'ingestion/parser/question_normalizer.dart';
export 'ingestion/pdf/official_paper_loader.dart';
export 'ingestion/pdf_import_stub.dart';
export 'ingestion/progress/import_progress_tracker.dart';
export 'ingestion/progress/resume_manager.dart';
export 'ingestion/pyq_mass_ingestion_service.dart';
export 'ingestion/reporting/coverage_report.dart';
export 'ingestion/reporting/import_report.dart';
export 'ingestion/validation/pyq_ingestion_validator.dart';

// Search Layer
export 'search/pyq_search_engine.dart';

// Analytics Layer
export 'analytics/pyq_analytics_engine.dart';

// Validators Layer
export 'validators/concept_validation_service.dart';
export 'validators/pyq_validator.dart';

// Assets & Infrastructure Layer
export 'assets/pyq_assets_registry.dart';
export 'infrastructure/local_pyq_storage.dart';

// Multi-Exam PYQ Intelligence Foundation (TITAN P29)
export 'multi_exam/multi_exam_pyq_intelligence.dart';

// Multi-Exam PYQ Acquisition & Ingestion Engine (TITAN P30)
export 'acquisition/multi_exam_pyq_acquisition.dart';

// Multi-Exam PYQ Historical Intelligence Engine (TITAN P31)
export 'intelligence/pyq_historical_intelligence.dart';
