# QuizForge AI Engineering Contribution Guidelines

Welcome to the **QuizForge AI** engineering repository. This document details the coding standards, folder structures, review checklists, and testing standards for all contributors.

---

## 1. Codebase Directory Conventions

The project codebase follows a modular structure under `lib/` and `test/`:

```text
lib/
├── controllers/       # State controllers bridging UI and Services/Repositories
├── models/            # Pure domain data models & JSON serialization
├── pages/             # Main application screens (Material 3 UI)
│   └── pyq/           # Specialized PYQ screens
├── plugins/           # Modular plugin system contracts and implementations
├── repositories/      # Data repository contracts
│   └── impl/          # Concrete Hive & memory implementations
├── services/          # Domain engines & logic (Analytics, Revision, Importer, Search)
│   ├── ai/            # AI provider contracts, factories, & implementations
│   │   ├── coach/     # AI Learning Coach providers (Gemini, OpenAI, Claude, Local)
│   │   └── providers/ # Raw AI Provider integrations
│   └── search/        # Full-text search engine
└── widgets/           # Reusable UI widgets and dialog components
```

---

## 2. Naming Conventions

| Entity Type | Convention | Example |
| :--- | :--- | :--- |
| **Dart Files** | `snake_case.dart` | `pyq_question_model.dart` |
| **Classes / Enums** | `PascalCase` | `PyqSmartRevisionPage` |
| **Methods / Variables** | `camelCase` | `calculatePriorityScore()` |
| **Constant Values** | `camelCase` or `UPPER_SNAKE_CASE` | `defaultEaseFactor` |
| **Private Fields** | `_leadingUnderscore` | `_scheduleMap` |
| **Test Files** | `<subject>_test.dart` | `revision_strategy_test.dart` |

---

## 3. Coding Standards & Architectural Rules

1. **Format Execution**: Always run `dart format .` before pushing or requesting pull request reviews.
2. **Zero Analyzer Warnings**: Code MUST pass `flutter analyze` cleanly with **0 errors and 0 warnings**.
3. **Immutability**: Prefer `final` fields in data model classes and widgets.
4. **State Management**: Use standard `ChangeNotifier`, `ValueNotifier`, `AnimatedBuilder`, or `ListenableBuilder`. **Do NOT introduce Riverpod, Bloc, GetX, or Provider packages.**
5. **UI Layer Isolation**: Widgets MUST NOT execute database queries or API network requests directly; delegate all data operations to Controllers.

---

## 4. Testing Requirements

Every new feature or bugfix must be accompanied by comprehensive tests under `test/`:

### Test Coverage Mandates
- **Domain Logic & Engines**: 100% coverage for unit logic (e.g. `AnalyticsEngine`, `SpacedRepetitionScheduler`, `PyqSearchEngine`, `DatasetValidator`).
- **Repositories**: Mock or in-memory tests for all CRUD operations.
- **AI Providers**: Implement non-networked unit tests for provider fallback and response parsing.
- **Widget Integration**: Widget tests for all primary screens verifying UI rendering and button interactions.

---

## 5. Pull Request Review Checklist

Before submitting a Pull Request, ensure every item on this checklist is completed:

- [ ] Ran `dart format .` (All files formatted cleanly).
- [ ] Ran `flutter analyze` (Zero errors, zero warnings).
- [ ] Ran `flutter test` (100% test pass rate).
- [ ] Preserved existing comments and docstrings.
- [ ] Added unit or widget tests covering new functionality.
- [ ] Followed layer hierarchy rules (`UI -> Controller -> Repository -> Service`).
