/// GARUDA International Organisations, Groupings & Global Institutions Knowledge
/// Library Package for Project TITAN. Structured Knowledge Objects for the UN
/// System, Bretton Woods institutions, trade/economic governance, regional &
/// political groupings, security organisations and climate/environment
/// institutions - every organisation a living Knowledge Object with
/// evidence-backed links to the Constitution, Acts, Cases, Doctrines,
/// Committees, Reports, Schemes, Current Affairs, PYQs, treaties, SDGs and
/// related organisations.
library;

// Domain Entities & Enums
export 'domain/entities/international_enums.dart';
export 'domain/entities/international_relationship.dart';
export 'domain/entities/international_knowledge_object.dart';

// Data Seed Corpus
export 'data/international_seed_corpus.dart';

// Repositories
export 'repositories/international_repository.dart';
export 'repositories/in_memory_international_repository.dart';

// Search & Analytics Engines
export 'search/international_search_engine.dart';
export 'analytics/international_analytics_engine.dart';

// Validators & Ingestion Pipeline
export 'validators/international_validator.dart';
export 'ingestion/international_ingestion_pipeline.dart';

// Services & Editorial Integration
export 'services/international_editorial_service.dart';
