# Changelog

## 0.1.0

- Initial release of the TITAN Quiz Domain Module (`titan_quiz`).
- Implemented canonical `Quiz`, `QuizQuestion`, `QuizOption`, `QuizMetadata`, `UserAnswer`, and `QuizResult` domain models.
- Implemented `QuizDifficulty`, `QuizLanguage`, and `QuizCategory` enums.
- Implemented `QuizException` domain exception hierarchy.
- Implemented `QuizValidationService`, `QuizScoringService`, and `QuizStatisticsService`.
- Implemented `QuizRepository` contract and `QuizRepositoryImpl` extending `BaseRepository<Quiz>`.
- Implemented `TitanQuizBootstrap` integrating service registration into `TitanServiceLocator`.
