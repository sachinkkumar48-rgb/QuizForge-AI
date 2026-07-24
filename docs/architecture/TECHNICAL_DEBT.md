# Project TITAN Technical Debt Register

This document registers known technical debt, design tradeoffs, and future architectural refactorings identified during the **Version 1.0 Foundation** release baseline.

---

## Technical Debt Items

### TD-001: Composition Root Dependency Injection Container
* **Module**: `packages/knowledge_engine/lib/infrastructure/di/dependency_registration.dart`
* **Severity**: Medium
* **Impact**: Service Locator pattern used in `KnowledgeDependencyContainer` is sufficient for singletons, but lacks scoped lifecycle management and factory instances needed for multi-tenant or concurrent operations.
* **Proposed Resolution**: Migrate to standard `get_it` or compile-time injectable dependency injection container in Sprint 2.

### TD-002: Typed Metadata Objects
* **Module**: `packages/knowledge_engine/lib/domain/entities/knowledge_object.dart`
* **Severity**: Low
* **Impact**: `metadata` field is currently represented as `Map<String, dynamic>`, which requires runtime type checking and parsing rather than compile-time type safety.
* **Proposed Resolution**: Introduce strongly-typed value objects (e.g. `KnowledgeMetadata`, `DocumentMetadata`, `SourceMetadata`) with explicit schemas.

### TD-003: Dedicated `KnowledgeSearchQuery` Value Object
* **Module**: `packages/knowledge_engine/lib/domain/repositories/knowledge_repository.dart`
* **Severity**: Low
* **Impact**: Repository `search()` methods accept raw `String query` parameter, limiting filtered queries (tags, date ranges, content types, confidence thresholds).
* **Proposed Resolution**: Create a structured `KnowledgeSearchQuery` value object with builder pattern for complex filtering.

### TD-004: Sync Metadata & Delta Tracking
* **Module**: `packages/knowledge_engine/lib/infrastructure/sync/knowledge_sync_queue.dart`
* **Severity**: Medium
* **Impact**: `KnowledgeSyncQueue` queues discrete operations (`save`, `update`, `delete`), but lacks vector clock/timestamp delta tracking for server-side conflict resolution during multi-device synchronization.
* **Proposed Resolution**: Add `syncMetadata`, sequence counters, and Conflict-Free Replicated Data Type (CRDT) payload headers to sync commands.

### TD-005: Metrics & Performance Collector
* **Module**: `packages/knowledge_engine/lib/application/pipeline/knowledge_ingestion_pipeline.dart`
* **Severity**: Low
* **Impact**: Pipeline execution duration and metrics are returned inside `PipelineResult`, but there is no centralized telemetry listener or metric aggregator across operations.
* **Proposed Resolution**: Create a `TelemetryService` abstraction in `titan_analytics` to automatically consume pipeline metrics.

### TD-006: Pipeline Event Bus & Real-Time Notifications
* **Module**: `packages/knowledge_engine/lib/application/pipeline/`
* **Severity**: Low
* **Impact**: Pipeline runs synchronously per document without publishing progress events (chunking progress, entity extraction progress).
* **Proposed Resolution**: Integrate `titan_events` `EventBus` to emit step progress events (`PipelineProgressEvent`, `PipelineFailedEvent`, `PipelineCompletedEvent`).

### TD-007: Domain & Schema Validation Service
* **Module**: `packages/knowledge_engine/lib/domain/entities/`
* **Severity**: Medium
* **Impact**: Validation logic (non-empty IDs, boundary checks) is embedded inside entity constructors via standard assertions.
* **Proposed Resolution**: Decouple validation into explicit `ValidationService` and `Specification<T>` pattern for extensible domain validation rules.

### TD-008: Dynamic Graph Relationship Confidence Scoring
* **Module**: `packages/knowledge_engine/lib/domain/factories/relationship_factory.dart`
* **Severity**: Medium
* **Impact**: Relationship confidence is set statically or passed directly during construction.
* **Proposed Resolution**: Implement automated co-occurrence and semantic similarity confidence scoring algorithms during relationship creation.

### TD-009: Graph Structural Constraints & Cycle Prevention Engine
* **Module**: `packages/knowledge_engine/lib/domain/entities/knowledge_relationship.dart`
* **Severity**: Medium
* **Impact**: Basic self-referential check (`sourceId != targetId`) prevents trivial loops, but does not detect multi-hop cyclic dependencies in directional knowledge graphs.
* **Proposed Resolution**: Implement graph cycle detection algorithm (Tarjan / Kosaraju) in `titan_domain` Knowledge Graph service in Sprint 2 (TITAN-KIE-004B).
