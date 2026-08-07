/// GARUDA National Committee & Commission Library Package for Project TITAN.
/// India's comprehensive, structured repository of Committees, Commissions, Task Forces,
/// Expert Bodies, Recommendations, Terms of Reference, and multi-dimensional syllabus links.
library;

// Domain Entities & Enums
export 'domain/entities/committee_enums.dart';
export 'domain/entities/committee_knowledge_object.dart';
export 'domain/entities/committee_member.dart';
export 'domain/entities/committee_relationship.dart';
export 'domain/entities/committee_report.dart';
export 'domain/entities/committee_timeline.dart';
export 'domain/entities/recommendation.dart';
export 'domain/entities/terms_of_reference.dart';

// Data Seed Corpus
export 'data/committee_seed_corpus.dart';

// Repositories
export 'repositories/committee_repository.dart';
export 'repositories/in_memory_committee_repository.dart';

// Search & Analytics Engines
export 'search/committee_search_engine.dart';
export 'analytics/committee_analytics_engine.dart';

// Validators & Ingestion Pipeline
export 'validators/committee_validator.dart';
export 'ingestion/committee_ingestion_pipeline.dart';

// Services & Editorial Integration
export 'services/committee_editorial_service.dart';
