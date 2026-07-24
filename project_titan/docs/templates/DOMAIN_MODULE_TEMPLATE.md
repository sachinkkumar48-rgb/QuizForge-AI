# TITAN Domain Module Specification & Blueprint Template

This document defines the mandatory architectural specification and file layout blueprint for all present and future **Project TITAN Domain Modules** (e.g. `titan_quiz`, `titan_pdf`, `titan_chat`, `titan_notes`, `titan_analytics`).

---

## 1. Recommended Package Structure

Every TITAN domain module MUST strictly adhere to the following package directory structure:

```
project_titan/packages/titan_<module>/
├── lib/
│   ├── titan_<module>.dart            # SINGLE PUBLIC ENTRYPOINT (Exports only public contracts)
│   └── src/                           # INTERNAL PRIVATE IMPLEMENTATIONS
│       ├── bootstrap/
│       │   └── titan_<module>_bootstrap.dart # Implements TitanModuleBootstrap
│       ├── config/
│       │   └── titan_<module>_config.dart    # Implements TitanModuleConfig
│       ├── repository/
│       │   ├── <module>_repository.dart       # Contract extending Repository<T>
│       │   └── <module>_repository_impl.dart  # Concrete implementation extending BaseRepository<T>
│       ├── models/
│       │   └── <module>_models.dart           # Immutable domain entities and value objects
│       ├── services/
│       │   └── <module>_service.dart          # Internal domain services
│       ├── exceptions/
│       │   └── <module>_exceptions.dart       # Module-specific exceptions extending RepositoryException
│       └── utils/
│           └── <module>_utils.dart            # Internal helper utilities
├── test/
│   └── titan_<module>_test.dart       # Unit test suite covering bootstrap, repositories, and models
├── README.md                           # Module developer documentation (from template below)
├── CHANGELOG.md                        # Module version release notes
└── pubspec.yaml                        # Package manifest
```

---

## 2. Public Export Strategy

- **Single Entrypoint**: The top-level `lib/titan_<module>.dart` file is the **only** file allowed to be exported or imported by external consumer packages.
- **Private Implementations**: All files inside `lib/src/` are private. External packages (such as UI applications or other domain packages) MUST NOT import `src/` files directly.

---

## 3. Module Bootstrap Contract

Every domain module MUST implement `TitanModuleBootstrap`:

```dart
class TitanQuizBootstrap implements TitanModuleBootstrap {
  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  void registerDependencies(TitanServiceLocator locator) {
    locator.registerLazySingleton<QuizRepository>(
      () => QuizRepositoryImpl(
        aiService: locator.get<AIService>(),
        storageService: locator.get<StorageService>(),
        networkService: locator.get<NetworkService>(),
      ),
    );
  }

  @override
  void validate() {
    TitanModuleValidator.validateRegisteredServices(
      TitanServiceLocator.instance,
      [AIService, StorageService, NetworkService],
    );
  }

  @override
  Future<void> initialize() async {
    validate();
    registerDependencies(TitanServiceLocator.instance);
    _isInitialized = true;
  }

  @override
  Future<void> dispose() async {
    _isInitialized = false;
  }
}
```

---

## 4. Dependency Rules & Architecture Boundaries

### Allowed Dependencies
- `titan_core` (DI locator, config, logging, error handling)
- `titan_domain` (BaseRepository, RepositoryResult, CacheStrategy, TitanModuleBootstrap)
- Infrastructure abstractions (`titan_ai`, `titan_storage`, `titan_network`)

### Forbidden Dependencies
- **UI / Presentation Layer**: Flutter widgets, Flutter UI components, `package:flutter/material.dart` (except basic Flutter types if pure Dart), `ViewModels`, `Bloc`, `Provider`, `GetX`.
- **Concrete Third-Party Drivers**: Raw `Dio`, `Hive`, `Http`, Google Gemini REST SDKs inside domain logic (must go through `titan_network`, `titan_storage`, or `titan_ai`).
- **Circular Dependencies**: Modules MUST NOT form cyclic import loops with other domain modules.

### Layer Direction Rule
```
UI / Applications  ──>  Domain Modules (titan_<module>)  ──>  Domain Foundation (titan_domain)  ──>  Infrastructure Services (AI, Storage, Network)
```

---

## 5. Module Documentation README Template

Every domain module MUST include a `README.md` containing the following sections:

```markdown
# titan_<module>

## Overview
Brief summary of the domain module's business purpose.

## Architecture
Explanation of domain entities, repositories, and service coordination.

## Dependencies
List of required infrastructure packages (`titan_core`, `titan_domain`, `titan_ai`, etc.).

## Public API
List of exported contracts, repositories, entities, and bootstrap classes.

## Testing
Instructions for running unit tests (`flutter test`).

## Extension Points
How to extend or override default behaviors.

## Versioning
Semantic versioning history.
```

---

## 6. Testing & Validation Checklist

Before declaring a module complete:
1. All repositories implement `BaseRepository` and wrap calls with `executeGuarded`.
2. Bootstrap implements `TitanModuleBootstrap` and validates required dependencies.
3. Unit test coverage verifies initialization, repository CRUD operations, exception mapping, and DI resolution.
4. `dart analyze .` returns 0 errors and 0 warnings.
5. `flutter test` returns 100% passing.
