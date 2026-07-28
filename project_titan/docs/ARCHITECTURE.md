# Project TITAN 2.0 — System Architecture

## Architecture Overview
Project TITAN follows a **Clean Architecture** & **Modular Package Monorepo** design with strict dependency boundaries:

```mermaid
graph TD
    App[QuizForge AI App] --> Presentation[Material 3 UI Layer]
    Presentation --> UseCases[Domain Use Cases & Engines]
    UseCases --> Core[titan_core: Config, Telemetry, Optimization]
    UseCases --> Security[titan_security: SecretManager, Keychain, Encryption]
    UseCases --> Repositories[Repository Interfaces]
    Repositories ..|> Storage[titan_storage: Offline-First Hive & Multi-Tier Cache]
    UseCases --> Providers[Provider Abstractions: Gemini, OpenAI]
    Providers --> External[External REST APIs & Secure Storage]
```

## Layer Guidelines & Clean Architecture Boundaries
1. **Domain Layer (`titan_domain`)**: Pure immutable entities decorated with `@immutable`, unmodifiable collections (`List.unmodifiable`), value objects, domain specifications, and abstract repository contracts. Free of Flutter framework dependencies.
2. **Core Foundation (`titan_core`)**: Service locator DI, global error handler, crash telemetry, multi-sink logger, subsystem health monitor, feature flag service, and the performance optimization suite (`StartupOptimizer`, `MemoryManager`, `LazyLoader`, `BackgroundWorker`, `TitanCacheOptimizer`).
3. **Security Layer (`titan_security`)**: Keychain integration, AES encryption, certificate pinning, secret hashing, and permission management.
4. **Engine Layer (`titan_ai`, `titan_quiz_ai`, `titan_ai_mentor`, `titan_dashboard`)**: Contains orchestration logic, metrics aggregation, prompt context assembly, and conversation memory.
5. **Storage Layer (`titan_storage`)**: Offline-first persistence backed by Hive, multi-tier caching, and sync queueing.
6. **Presentation Layer (`apps/quizforge_ai`)**: Flutter Riverpod state management, GoRouter navigation, and Material 3 adaptive widgets.
