/// GARUDA Current Affairs Intelligence Engine Package for Project TITAN.
/// Dynamic knowledge layer converting verified official government sources into permanent,
/// interconnected Knowledge Objects with knowledge graph linking, UPSC intelligence scoring,
/// timelines, digests, search, analytics, and GARUDA Editorial Production Engine integration.
library;

// Domain Entities & Enums
export 'domain/entities/current_affairs_enums.dart';
export 'domain/entities/current_affairs_knowledge_object.dart';
export 'domain/entities/news_event.dart';

// Repositories
export 'repositories/current_affairs_repository.dart';
export 'repositories/in_memory_current_affairs_repository.dart';

// Official Source Adapters & Parsers
export 'sources/official_adapters.dart';
export 'sources/source_adapter.dart';
export 'parser/current_affairs_parser.dart';
export 'ingestion/current_affairs_ingestion_pipeline.dart';


// Classification & Automated Knowledge Mapping
export 'classification/current_affairs_classifier.dart';
export 'mapping/current_affairs_mapper.dart';
export 'mapping/current_affairs_relationship_builder.dart';

// Services & Intelligence Engines
export 'services/current_affairs_digest_engine.dart';
export 'services/current_affairs_editorial_service.dart';
export 'services/current_affairs_scoring_engine.dart';

// Timeline, Search & Analytics
export 'timeline/current_affairs_timeline.dart';
export 'search/current_affairs_search_engine.dart';
export 'analytics/current_affairs_analytics.dart';
export 'analytics/current_affairs_trend_engine.dart';

// Validators
export 'validators/current_affairs_validator.dart';
