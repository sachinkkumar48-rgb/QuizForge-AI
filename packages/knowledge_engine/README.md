# Knowledge Intelligence Engine (KIE) Foundation

`knowledge_engine` is a core domain package for Project TITAN. It introduces the **Canonical Knowledge Object (CKO)**, serving as the common domain contract used across all intelligent engines in the TITAN platform.

---

## 1. Purpose

The Knowledge Intelligence Engine provides a clean, decoupled foundation for representing, indexing, and querying domain knowledge items (PDFs, PYQs, Articles, Notes, Books, Reports, Videos, etc.) across the TITAN ecosystem without binding to specific UI components or concrete storage drivers.

---

## 2. Architecture

`knowledge_engine` strictly follows Clean Architecture and Domain-Driven Design (DDD) principles:

```
packages/knowledge_engine/
├── lib/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── knowledge_object.dart            # Canonical Knowledge Object (CKO)
│   │   │   └── knowledge_relationship.dart      # Directed relationship edge entity
│   │   ├── factories/
│   │   │   └── relationship_factory.dart        # Factory constructing validated relationships
│   │   ├── repositories/
│   │   │   ├── knowledge_repository.dart        # Abstract knowledge object repository contract
│   │   │   └── relationship_repository.dart     # Abstract relationship repository contract
│   │   ├── search/
│   │   │   ├── knowledge_search_query.dart       # Unified query value object
│   │   │   ├── knowledge_search_result.dart      # Search execution result payload
│   │   │   ├── knowledge_search_service.dart     # Storage-agnostic, deterministic search orchestrator
│   │   │   └── search_ranking_strategy.dart      # Non-AI deterministic ranking strategy
│   │   ├── services/
│   │   │   ├── knowledge_traversal_service.dart # Deterministic BFS graph traversal & cycle detection
│   │   │   ├── recommendation_service.dart       # Non-AI graph relationship recommendation engine
│   │   │   ├── relationship_query_service.dart   # Directional relationship edge queries
│   │   │   └── traversal_result.dart             # Immutable graph traversal execution value object
│   │   └── value_objects/
│   │       ├── knowledge_identity.dart          # Versioned canonical identity value object
│   │       ├── knowledge_type.dart              # Knowledge source type enum
│   │       └── relationship_type.dart           # Semantic relationship category enum
│   ├── application/
│   │   ├── caie/
│   │   │   ├── current_affairs_ingestion_service.dart # CAIE ingestion orchestrator
│   │   │   ├── current_affairs_item.dart              # CAIE domain entity model
│   │   │   ├── current_affairs_mapper.dart            # CAIE to KnowledgeObject mapper
│   │   │   ├── current_affairs_parser.dart            # CAIE validator, normalizer & category identifier
│   │   │   └── current_affairs_validation_result.dart # CAIE validation result value object
│   │   ├── pie/
│   │   │   ├── previous_year_question.dart            # PIE domain entity model
│   │   │   ├── pyq_ingestion_service.dart             # PIE ingestion orchestrator
│   │   │   ├── pyq_mapper.dart                        # PIE to KnowledgeObject mapper
│   │   │   ├── pyq_metadata_extractor.dart            # PIE subject, topic & difficulty extractor
│   │   │   ├── pyq_parser.dart                        # PIE parser, validator & normalizer
│   │   │   └── pyq_validation_result.dart             # PIE validation result value object
│   │   ├── aime/
│   │   │   ├── ai_mentor_service.dart                 # AIME mentor orchestration service
│   │   │   ├── learner_profile.dart                   # AIME learner profile model
│   │   │   ├── mentor_recommendation.dart             # AIME recommendation payload
│   │   │   ├── mentor_session.dart                    # AIME mentor session cycle model
│   │   │   └── recommendation_reason.dart             # AIME recommendation reason value object
│   │   └── pipeline/
│   │       ├── knowledge_chunk_builder.dart     # Deterministic text chunker
│   │       ├── knowledge_ingestion_pipeline.dart# Main ingestion pipeline orchestrator
│   │       ├── knowledge_object_factory.dart    # Factory building CKO entities from chunks
│   │       ├── pipeline_result.dart             # Immutable pipeline execution metrics
│   │       └── text_normalizer.dart             # Whitespace & character sanitizer
│   ├── infrastructure/
│   │   ├── data_sources/
│   │   │   ├── knowledge_cache_data_source.dart  # Abstract in-memory cache contract
│   │   │   ├── knowledge_local_data_source.dart  # Abstract local database contract
│   │   │   └── knowledge_remote_data_source.dart # Abstract remote cloud contract
│   │   ├── di/
│   │   │   └── dependency_registration.dart     # Service locator DI container
│   │   ├── repositories/
│   │   │   └── repository_coordinator.dart       # Storage-agnostic repository orchestrator
│   │   └── sync/
│   │       └── knowledge_sync_queue.dart        # Abstract offline outbox sync queue
│   └── knowledge_engine.dart                    # Main library export point
├── test/
│   ├── application/
│   │   └── pipeline/
│   │       ├── knowledge_chunk_builder_test.dart
│   │       ├── knowledge_ingestion_pipeline_test.dart
│   │       ├── knowledge_object_factory_test.dart
│   │       └── text_normalizer_test.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── knowledge_object_test.dart
│   │   │   └── knowledge_relationship_test.dart
│   │   ├── factories/
│   │   │   └── relationship_factory_test.dart
│   │   └── value_objects/
│   │       ├── knowledge_identity_test.dart
│   │       ├── knowledge_type_test.dart
│   │       └── relationship_type_test.dart
│   ├── infrastructure/
│   │   ├── repositories/
│   │   │   └── repository_coordinator_test.dart
│   │   └── sync/
│   │       └── knowledge_sync_queue_test.dart
│   └── knowledge_engine_test.dart
├── pubspec.yaml
└── README.md
```

---

## 3. Responsibilities

- **Canonical Knowledge Representation (`KnowledgeObject`)**: An immutable domain entity capturing content identity, type, summary, metadata, language, subjects, topics, and keywords.
- **Knowledge Identity (`KnowledgeIdentity`)**: Stable, versioned value object capturing canonical ID, source reference ID, and schema revision version.
- **Semantic Relationships (`KnowledgeRelationship`, `RelationshipType`)**: Graph-ready directed edges connecting knowledge entities (`relatedTo`, `explains`, `prerequisiteOf`, `derivedFrom`, `appearedIn`, `references`, `contradicts`, `expands`, `summarizes`).
- **Relationship Factory (`RelationshipFactory`)**: Constructs validated relationship instances enforcing non-self loops, non-empty IDs, and confidence score range rules (0.0 to 1.0).
- **Ingestion Pipeline (`KnowledgeIngestionPipeline`)**: Transforms raw extracted text into normalized, chunked `KnowledgeObject` entities with processing statistics (`PipelineResult`).
- **Domain Contracts (`KnowledgeRepository`, `RelationshipRepository`)**: Abstract persistence contracts for knowledge entities and graph relationships.
- **Repository Coordinator (`RepositoryCoordinator`)**: Storage-agnostic orchestrator managing multi-tier data flow (L1 Cache -> L2 Local DB -> L3 Remote Cloud API) and offline sync queueing.
- **Infrastructure Contracts**: Decoupled abstract data source interfaces (`KnowledgeLocalDataSource`, `KnowledgeRemoteDataSource`, `KnowledgeCacheDataSource`, `KnowledgeSyncQueue`).
- **Dependency Container (`KnowledgeDependencyContainer`)**: Clean DI container for binding storage providers and orchestrators.

---

## 4. Future Roadmap

- **TITAN-KIE-004B**: Knowledge Graph Services (Graph traversal, neighbor discovery, relationship queries, recommendation hooks).
- **Current Affairs Engine**: Ingest and index daily news/articles as `KnowledgeType.article`.
- **PYQ Intelligence Engine**: Tag and structure past year questions into `KnowledgeType.pyq`.
- **Learning Memory & Recommendation Engines**: Track user interaction and retention state against `KnowledgeObject` IDs.
- **AI Mentor Engine**: Provide context-grounded retrieval across indexed `KnowledgeObject` records.
