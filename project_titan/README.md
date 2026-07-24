# Project TITAN Monorepo

Project TITAN is an enterprise Dart/Flutter monorepo architecture designed for scalable, modular application development. Powered by [Melos](https://melos.invertase.dev), it enforces strict separation of concerns, reusable packages, unified static analysis, and multi-package testing.

---

## Version 1.0 Foundation Release (TDL-010)

* **Baseline Version**: `v1.0.0-foundation`
* **Architecture Report**: [`FOUNDATION_REPORT.md`](file:///c:/Users/acer/StudioProjects/quizforge_upsc/project_titan/FOUNDATION_REPORT.md)
* **Release Changelog**: [`CHANGELOG.md`](file:///c:/Users/acer/StudioProjects/quizforge_upsc/project_titan/CHANGELOG.md)
* **Technical Debt Register**: [`docs/architecture/TECHNICAL_DEBT.md`](file:///c:/Users/acer/StudioProjects/quizforge_upsc/project_titan/docs/architecture/TECHNICAL_DEBT.md)

---

## 1. Repository Architecture

The monorepo structure separates target applications from shared platform packages:

```
project_titan/
├── apps/
│   └── quizforge_ai/         # Primary mobile/web application wrapper
├── packages/
│   ├── titan_core/            # Core primitives, result types, foundation utilities
│   ├── titan_domain/          # Core business entities, specifications, value objects
│   ├── titan_events/          # Event definitions, bus abstractions, event handlers
│   ├── titan_ai/              # AI services, LLM engines, prompt management
│   ├── titan_analytics/       # Telemetry, analytics tracking, metric reports
│   ├── titan_assessment/      # Quiz generation, examination simulation, scoring
│   ├── titan_content/         # Question bank ingestion, syllabus mapping
│   ├── titan_learning/        # Spaced repetition, adaptive learning paths
│   └── titan_storage/         # Persistence layer, local cache, database contracts
├── .github/
│   └── workflows/
│       └── ci.yml             # GitHub Actions CI workflow
├── melos.yaml                 # Melos monorepo configuration
├── pubspec.yaml               # Root workspace management pubspec
├── analysis_options.yaml      # Shared static analysis rules
└── README.md                  # Monorepo architecture & workflow guide
```

---

## 2. Package Dependency Philosophy

Project TITAN strictly follows a layered dependency architecture:

```
                  ┌────────────────────┐
                  │ apps/quizforge_ai  │
                  └─────────┬──────────┘
                            │
       ┌────────────────────┼────────────────────┐
       ▼                    ▼                    ▼
┌──────────────┐   ┌────────────────┐   ┌─────────────────┐
│  titan_ai    │   │ titan_learning │   │titan_assessment │
└──────┬───────┘   └───────┬────────┘   └────────┬────────┘
       │                   │                     │
       └───────────┬───────┴───────────┬─────────┘
                   ▼                   ▼
          ┌────────────────┐   ┌───────────────┐
          │  titan_domain  │   │ titan_storage │
          └────────┬───────┘   └───────┬───────┘
                   │                   │
                   └─────────┬─────────┘
                             ▼
                     ┌───────────────┐
                     │  titan_core   │
                     └───────────────┘
```

### Hierarchy Rules
1. **Foundation (`titan_core`)**: Zero internal package dependencies. Defines primitive abstractions, `Result<T, E>`, type definitions, and generic utilities.
2. **Domain (`titan_domain`)**: Depends strictly on `titan_core`. Contains enterprise entities, value objects, and business specifications.
3. **Infrastructure (`titan_storage`, `titan_events`)**: Depend on `titan_core`. Provide persistence, caching, and event handling abstractions.
4. **Features & Intelligence (`titan_ai`, `titan_assessment`, `titan_content`, `titan_learning`, `titan_analytics`)**: Depend on `titan_core` and `titan_domain`. Encapsulate discrete domain logic.
5. **Applications (`apps/*`)**: Compose feature and infrastructure packages. Local package dependencies are declared via relative path (e.g. `path: ../../packages/titan_core`).

---

## 3. Development Workflow

### Prerequisites
- Flutter SDK (stable channel, >=3.19.0)
- Dart SDK (>=3.3.0 <4.0.0)
- Melos CLI (`dart pub global activate melos`)

### Initializing Workspace
Clone the repository and run bootstrap to link local dependencies across all packages:

```bash
# Activate Melos globally (if not already activated)
dart pub global activate melos

# Bootstrap the monorepo
melos bootstrap
```

---

## 4. How to Create New Packages

To add a new package under `packages/`:

1. Create a directory: `packages/titan_newpackage`
2. Add a `pubspec.yaml`:
   ```yaml
   name: titan_newpackage
   description: Brief description of titan_newpackage.
   version: 0.1.0
   publish_to: none

   environment:
     sdk: "^3.3.0"

   dependencies:
     titan_core:
       path: ../titan_core

   devDependencies:
     lints: ^3.0.0
     test: ^1.24.0
   ```
3. Add `README.md`, `lib/titan_newpackage.dart`, and `test/titan_newpackage_test.dart`.
4. Run `melos bootstrap` to register and link the new package across the workspace.

---

## 5. How to Analyze Entire Repository

Run static analysis across every package in the monorepo simultaneously:

```bash
# Using Melos script
melos run analyze

# Or directly with Dart SDK in the root
dart analyze .
```

---

## 6. How to Run All Tests

Execute test suites across all packages:

```bash
# Using Melos script
melos run test

# Or run tests in a specific package
cd packages/titan_core
dart test
```
