/// Knowledge Intelligence Engine (KIE) Foundation Package for Project TITAN.
///
/// Exports core domain entities, value objects, repository contracts, infrastructure orchestrators,
/// and application ingestion pipelines.
library;

// Domain Layer Exports
export 'domain/entities/knowledge_object.dart';
export 'domain/entities/knowledge_relationship.dart';
export 'domain/factories/relationship_factory.dart';
export 'domain/repositories/knowledge_repository.dart';
export 'domain/repositories/relationship_repository.dart';
export 'domain/search/knowledge_search_query.dart';
export 'domain/search/knowledge_search_result.dart';
export 'domain/search/knowledge_search_service.dart';
export 'domain/search/search_ranking_strategy.dart';
export 'domain/services/knowledge_traversal_service.dart';
export 'domain/services/recommendation_service.dart';
export 'domain/services/relationship_query_service.dart';
export 'domain/services/traversal_result.dart';
export 'domain/value_objects/knowledge_identity.dart';
export 'domain/value_objects/knowledge_type.dart';
export 'domain/value_objects/relationship_type.dart';

// Application Layer Exports
export 'application/caie/current_affairs_article.dart';
export 'application/caie/current_affairs_ingestion_result.dart';
export 'application/caie/current_affairs_ingestion_service.dart';
export 'application/caie/current_affairs_item.dart';
export 'application/caie/current_affairs_mapper.dart';
export 'application/caie/current_affairs_parser.dart';
export 'application/caie/current_affairs_validation_result.dart';
export 'application/pipeline/knowledge_chunk_builder.dart';
export 'application/pipeline/knowledge_ingestion_pipeline.dart';
export 'application/pipeline/knowledge_object_factory.dart';
export 'application/pipeline/pipeline_result.dart';
export 'application/pipeline/text_normalizer.dart';
export 'application/pie/previous_year_question.dart';
export 'application/pie/pyq_ingestion_service.dart';
export 'application/pie/pyq_mapper.dart';
export 'application/pie/pyq_metadata_extractor.dart';
export 'application/pie/pyq_parser.dart';
export 'application/pie/pyq_validation_result.dart';
export 'application/aime/ai_mentor_service.dart';
export 'application/aime/learner_profile.dart';
export 'application/aime/mentor_recommendation.dart';
export 'application/aime/mentor_session.dart';
export 'application/aime/recommendation_reason.dart';

// Infrastructure Layer Exports
export 'infrastructure/data_sources/knowledge_cache_data_source.dart';
export 'infrastructure/data_sources/knowledge_local_data_source.dart';
export 'infrastructure/data_sources/knowledge_remote_data_source.dart';
export 'infrastructure/di/dependency_registration.dart';
export 'infrastructure/repositories/repository_coordinator.dart';
export 'infrastructure/sync/knowledge_sync_queue.dart';
