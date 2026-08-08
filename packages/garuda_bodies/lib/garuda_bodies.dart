/// GARUDA Government Commissions & Statutory Bodies Knowledge Library Package
/// for Project TITAN. India's comprehensive, structured repository of
/// Constitutional bodies, Statutory bodies, Regulatory bodies, National
/// Commissions, Authorities, Boards and Tribunals - every body a living
/// Knowledge Object linked to the Constitution, Acts, Cases, Doctrines,
/// Committees, Reports, Schemes, Current Affairs, PYQs, SDGs and related
/// Bodies.
library;

// Domain Entities & Enums
export 'domain/entities/body_enums.dart';
export 'domain/entities/body_relationship.dart';
export 'domain/entities/body_knowledge_object.dart';

// Data Seed Corpus
export 'data/body_seed_corpus.dart';

// Repositories
export 'repositories/body_repository.dart';
export 'repositories/in_memory_body_repository.dart';

// Search & Analytics Engines
export 'search/body_search_engine.dart';
export 'analytics/body_analytics_engine.dart';

// Validators & Ingestion Pipeline
export 'validators/body_validator.dart';
export 'ingestion/body_ingestion_pipeline.dart';

// Services & Editorial Integration
export 'services/body_editorial_service.dart';
