/// GARUDA Government Schemes Knowledge Library Package for Project TITAN.
/// India's comprehensive, structured repository of Central Sector Schemes,
/// Centrally Sponsored Schemes, Flagship Missions and PLI/Industrial
/// initiatives - every scheme a living Knowledge Object linked to the
/// Constitution, Acts, Committees, Reports, Case Law, Doctrines, Current
/// Affairs, PYQs, Ministries and SDGs.
library;

// Domain Entities & Enums
export 'domain/entities/scheme_enums.dart';
export 'domain/entities/scheme_ministry.dart';
export 'domain/entities/scheme_beneficiary.dart';
export 'domain/entities/scheme_funding.dart';
export 'domain/entities/scheme_benefit.dart';
export 'domain/entities/scheme_component.dart';
export 'domain/entities/scheme_relationship.dart';
export 'domain/entities/scheme_timeline.dart';
export 'domain/entities/scheme_knowledge_object.dart';

// Data Seed Corpus
export 'data/scheme_seed_corpus.dart';

// Repositories
export 'repositories/scheme_repository.dart';
export 'repositories/in_memory_scheme_repository.dart';

// Search & Analytics Engines
export 'search/scheme_search_engine.dart';
export 'analytics/scheme_analytics_engine.dart';

// Validators & Ingestion Pipeline
export 'validators/scheme_validator.dart';
export 'ingestion/scheme_ingestion_pipeline.dart';

// Services & Editorial Integration
export 'services/scheme_editorial_service.dart';
