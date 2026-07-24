# titan_quiz

Quiz Domain Module for **Project TITAN**.

## Overview
`titan_quiz` establishes the canonical domain entities, evaluation engine, scoring strategies, statistics generation, and repository persistence for all present and future AI-generated and manually authored quizzes.

## Architecture
This package adheres strictly to Clean Architecture and TITAN Domain Module Template guidelines:
- **Presentation Layer**: Interacts with `QuizRepository` via `TitanServiceLocator`.
- **Domain Entities & Models**: `Quiz`, `QuizQuestion`, `QuizOption`, `QuizMetadata`, `UserAnswer`, `QuizResult`.
- **Enums**: `QuizDifficulty`, `QuizLanguage`, `QuizCategory`.
- **Domain Services**: `QuizValidationService`, `QuizScoringService`, `QuizStatisticsService`.
- **Platform Coordination**: `QuizRepositoryImpl` extends `BaseRepository<Quiz>` and persists data using `StorageService` (`titan_storage`).

## Public API Exports
- `TitanQuizBootstrap`
- `QuizRepository` & `QuizRepositoryImpl`
- `Quiz`, `QuizQuestion`, `QuizOption`, `QuizMetadata`, `UserAnswer`, `QuizResult`
- `QuizDifficulty`, `QuizLanguage`, `QuizCategory`
- `QuizException` hierarchy (`QuizValidationException`, `QuizScoringException`, `QuizRepositoryException`)

## Testing
Run unit test suite:
```bash
flutter test
```

## Extension Points
- Custom scoring weighting rules per exam category (`UPSC`, `BPSC`, `SSC`, `Banking`).
- Time-series performance tracking integration with future analytics modules (`titan_analytics`).
