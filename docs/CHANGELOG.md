# QuizForge AI Changelog

All notable changes to the **QuizForge AI** platform are documented in this file in accordance with [Semantic Versioning](https://semver.org/).

---

## [1.4.0] - 2026-07-19

### Added
- **AI Learning Coach Subsystem**: Decoupled LLM interface (`LearningCoach`) supporting multiple AI backends.
- **Provider Implementations**: Added `GeminiLearningCoach`, `OpenAiLearningCoach`, `ClaudeLearningCoach`, and `LocalLlmLearningCoach`.
- **Dynamic Provider Factory**: `LearningCoachFactory` for runtime AI provider selection.
- **6 Core AI Coach Features**:
  1. Weekly performance summary report.
  2. Identified weak topics & conceptual explainer.
  3. Recommended PYQs.
  4. Recommended AI quizzes.
  5. Suggested daily study hours allocation.
  6. Motivational mindset insights.
- **AI Learning Coach Dashboard**: `AiLearningCoachPage` for interactive coaching.
- **Long-term Engineering Documentation Suite**: Published comprehensive architecture, database, API, data specification, roadmap, AI guidelines, and contributing docs under `docs/`.

### Migration Notes
- No database breaking changes. Fully backward-compatible with Schema Version 3.

---

## [1.3.0] - 2026-07-19

### Added
- **Analytics Engine**: Complete learning insights engine tracking 17 metrics (Overall, Subject, Topic, Year, Difficulty accuracy, streaks, time/question, attempt frequency).
- **Analytics Exporter**: Multi-format exports (`JSON`, `CSV`, printable `Text`).
- **Intelligent Revision Engine**: Spaced repetition scheduler (`RevisionStrategy` & `AdaptiveRevisionStrategy`) incorporating 6 multi-attribute inputs (Difficulty, Last attempt date, Correctness, Response time, Bookmark status, Confidence level).
- **Interactive Revision UI**: `PyqSmartRevisionPage` featuring 4 revision queues (Today, Overdue, Bookmarked, Weak Topic), Revision Calendar, and Smart Recommendations.

### Migration Notes
- Automatically migrated database to **Schema Version 3** with structured question IDs and multi-source explanation support.

---

## [1.2.0] - 2026-07-18

### Added
- **Plugin Architecture**: Modular plugin framework (`BaseModule`, `ModuleRepository`, `ModuleImporter`, `ModuleAnalytics`, `ModuleUI`).
- **Module Explorer UI**: `ModuleExplorerPage` for viewing and managing active study modules.

---

## [1.1.0] - 2026-07-17

### Added
- **UPSC PYQ Architecture**: Standardized `PyqQuestionModel` with multi-source explanations (`PyqExplanation`).
- **Fast Full-Text Search Engine**: `PyqSearchEngine` with inverted indices for filtering by year, subject, topic, difficulty, bookmark, and unattempted status.

---

## [1.0.0] - 2026-07-15

### Added
- Initial public release of QuizForge AI.
- PDF Document Text Extraction via Syncfusion engine.
- Gemini REST API integration for UPSC question generation.
- Dynamic UPSC Prelims countdown timer and session controller.
- Local Hive storage for generated quizzes and attempt history.
