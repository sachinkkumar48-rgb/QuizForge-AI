/// GARUDA National Reports & Indices Library Package for Project TITAN.
/// India's comprehensive, structured repository of Reports, Surveys and Indices for
/// UPSC and State PSC examinations. Every report is a first-class Knowledge Object
/// connected to the Constitution, Acts, Committees, Case Law, Doctrines, Schemes,
/// Current Affairs and PYQs.
library;

// Domain Entities & Enums
export 'domain/entities/report_enums.dart';
export 'domain/entities/report_knowledge_object.dart';
export 'domain/entities/index_knowledge_object.dart';
export 'domain/entities/survey_knowledge_object.dart';
export 'domain/entities/chapter_knowledge_object.dart';
export 'domain/entities/indicator_knowledge_object.dart';
export 'domain/entities/recommendation_knowledge_object.dart';
export 'domain/entities/report_statistic.dart';
export 'domain/entities/report_table.dart';
export 'domain/entities/report_chart.dart';
export 'domain/entities/report_relationship.dart';

// Data Seed Corpus
export 'data/report_seed_corpus.dart';

// Repositories
export 'repositories/report_repository.dart';
export 'repositories/in_memory_report_repository.dart';

// Search & Analytics Engines
export 'search/report_search_engine.dart';
export 'analytics/report_analytics_engine.dart';

// Validators & Ingestion Pipeline
export 'validators/report_validator.dart';
export 'ingestion/report_ingestion_pipeline.dart';

// Services & Editorial Integration
export 'services/report_editorial_service.dart';
