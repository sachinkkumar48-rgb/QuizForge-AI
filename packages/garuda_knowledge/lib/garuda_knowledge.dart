/// GARUDA Unified Knowledge Engine Foundation Package for Project TITAN.
/// Single source of truth for all knowledge assets across Project TITAN.
library;

// Domain Entities
export 'domain/entities/knowledge_category.dart';
export 'domain/entities/knowledge_citation.dart';
export 'domain/entities/knowledge_evidence_reference.dart';
export 'domain/entities/knowledge_metadata.dart';
export 'domain/entities/knowledge_object.dart';
export 'domain/entities/knowledge_reference.dart';
export 'domain/entities/knowledge_relationship.dart';
export 'domain/entities/knowledge_source.dart';
export 'domain/entities/knowledge_tag.dart';
export 'domain/entities/knowledge_version.dart';

// Value Objects & Enums
export 'domain/enums/knowledge_object_type.dart';
export 'domain/enums/relationship_type.dart';
export 'domain/value_objects/knowledge_object_id.dart';

// Repositories & Infrastructure
export 'infrastructure/in_memory_knowledge_repository.dart';
export 'repositories/knowledge_repository.dart';

// Services
export 'services/knowledge_graph_service.dart';
export 'services/knowledge_integrity_service.dart';
export 'services/knowledge_lookup_service.dart';
export 'services/knowledge_traversal_service.dart';
export 'services/knowledge_version_service.dart';

// Validators
export 'validators/broken_reference_validator.dart';
export 'validators/circular_reference_validator.dart';
export 'validators/duplicate_id_validator.dart';
export 'validators/duplicate_relationship_validator.dart';
export 'validators/invalid_relationship_validator.dart';
export 'validators/invalid_version_validator.dart';
export 'validators/missing_evidence_validator.dart';
export 'validators/validation_result.dart';

// Search & Analytics
export 'analytics/knowledge_analytics_engine.dart';
export 'analytics/knowledge_search_analytics.dart';
export 'search/knowledge_search_engine.dart';

// Text Processing & Tokenization
export 'text/knowledge_normalizer.dart';
export 'text/knowledge_synonym_dictionary.dart';
export 'text/knowledge_tokenizer.dart';

// Indexing Engine
export 'indexing/knowledge_index.dart';
export 'indexing/knowledge_index_manager.dart';
export 'indexing/knowledge_indexer.dart';

// Filters & Query Engine
export 'autocomplete/knowledge_autocomplete.dart';
export 'autocomplete/knowledge_suggestion_engine.dart';
export 'cache/knowledge_cache.dart';
export 'filters/knowledge_filter.dart';
export 'query/knowledge_query.dart';
export 'query/knowledge_query_builder.dart';
export 'query/knowledge_query_engine.dart';
export 'query/knowledge_search_hit.dart';
export 'query/knowledge_search_result.dart';
export 'ranking/knowledge_ranking_engine.dart';

// Serialization & Subgraphs
export 'graph/knowledge_subgraph.dart';
export 'serialization/knowledge_serializer.dart';

// Integration Layer (TITAN-KO-006.2)
export 'integration/integration.dart';

// Registration Pipeline Layer (TITAN-KO-006.3)
export 'audit/knowledge_audit_trail.dart';
export 'batch/knowledge_batch_processor.dart';
export 'integration/events/pipeline_events.dart';
export 'middleware/knowledge_pipeline_middleware.dart';
export 'pipeline/knowledge_pipeline_context.dart';
export 'pipeline/knowledge_pipeline_metrics.dart';
export 'pipeline/knowledge_pipeline_result.dart';
export 'pipeline/knowledge_pipeline_stage.dart';
export 'pipeline/knowledge_registration_pipeline.dart';
export 'transactions/knowledge_rollback_manager.dart';
export 'transactions/knowledge_transaction.dart';

// Ingestion Framework Layer (TITAN-KO-007.0)
export 'ingestion/ingestion.dart';
