# Project TITAN & QuizForge AI Changelog

All notable changes to Project TITAN and QuizForge AI are documented in this file in accordance with [Semantic Versioning](https://semver.org/).

---

## [v1.0.0-foundation] - 2026-07-23

### Project TITAN Version 1.0 Foundation Baseline Release

This release establishes the baseline enterprise architecture, multi-tier knowledge repository, ingestion pipeline, domain entities, and QuizForge AI integration for Project TITAN.

#### Completed Milestones:
- **KIE-001 (Canonical Knowledge Object)**: Created the pure domain entity specification for `KnowledgeObject`, value object `KnowledgeIdentity`, immutable attributes, content hashing, and domain serialization contracts.
- **KIE-002A (Repository Strategy)**: Formulated the architectural repository strategy (`TITAN-KIE-002`), establishing multi-tiered caching, local storage, remote synchronization, and offline queueing rules.
- **KIE-003 (Knowledge Ingestion Pipeline)**: Built the application ingestion pipeline (`KnowledgeIngestionPipeline`), including `TextNormalizer`, `KnowledgeChunkBuilder`, `KnowledgeObjectFactory`, and pipeline execution result objects (`PipelineResult`).
- **KIE-002B (Repository Infrastructure)**: Implemented concrete infrastructure adapters (`KnowledgeCacheDataSource`, `KnowledgeLocalDataSource`, `KnowledgeRemoteDataSource`, `KnowledgeSyncQueue`, `RepositoryCoordinator`, and `KnowledgeDependencyContainer`).
- **KIE-004A (Knowledge Identity & Relationships)**: Introduced directional graph entity `KnowledgeRelationship`, relationship types (`RelationshipType`), identity specifications, and `RelationshipFactory` with deterministic ID generation.
- **QFAI-001 (QuizForge Integration)**: Integrated Knowledge Intelligence Engine with QuizForge AI app (`KnowledgeIntegrationService` & `QuizGenerationAdapter`), enabling structured text normalization, chunking, canonical object generation, and LLM prompt adaptation.
- **TITAN-STAB-001 (Release Baseline & Stabilization)**: Validated clean architecture compliance, reviewed exported APIs, registered technical debt (`TD-001` through `TD-009`), generated foundation report (`FOUNDATION_REPORT.md`), and confirmed 100% test & static analysis passing.

---

## [1.4.0] - 2026-07-19

### Added
- **AI Learning Coach Subsystem**: Decoupled LLM interface (`LearningCoach`) supporting multiple AI backends (`GeminiLearningCoach`, `OpenAiLearningCoach`, `ClaudeLearningCoach`, `LocalLlmLearningCoach`).
- **Dynamic Provider Factory**: `LearningCoachFactory` for runtime AI provider selection.
- **6 Core AI Coach Features**: Weekly performance summary, weak topics explainer, PYQ recommendations, AI quiz recommendations, daily study hours allocation, mindset insights.
- **AI Learning Coach Dashboard**: `AiLearningCoachPage`.
- **Engineering Documentation Suite**: Published architecture, database, API, data specification, roadmap, AI guidelines under `docs/`.

---

## [1.3.0] - 2026-07-19

### Added
- **Analytics Engine**: Learning insights engine tracking 17 metrics.
- **Analytics Exporter**: Multi-format exports (`JSON`, `CSV`, printable `Text`).
- **Intelligent Revision Engine**: Spaced repetition scheduler (`AdaptiveRevisionStrategy`).
- **Interactive Revision UI**: `PyqSmartRevisionPage` featuring 4 revision queues and calendar.

---

## [1.2.0] - 2026-07-18

### Added
- **Plugin Architecture**: Modular plugin framework (`BaseModule`, `ModuleRepository`, `ModuleImporter`, `ModuleAnalytics`, `ModuleUI`).
- **Module Explorer UI**: `ModuleExplorerPage`.

---

## [1.1.0] - 2026-07-17

### Added
- **UPSC PYQ Architecture**: Standardized `PyqQuestionModel` with multi-source explanations.
- **Fast Full-Text Search Engine**: `PyqSearchEngine` with inverted indices.

---

## [1.0.0] - 2026-07-15

### Added
- Initial public release of QuizForge AI.
- PDF Document Text Extraction via Syncfusion engine.
- Gemini REST API integration for UPSC question generation.
- Local Hive storage for generated quizzes and attempt history.
