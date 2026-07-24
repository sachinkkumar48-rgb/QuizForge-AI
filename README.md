# QuizForge AI: UPSC Quiz Generator

QuizForge AI is a production-ready, local-first Flutter application that leverages Gemini AI to parse UPSC (Union Public Service Commission) preparation study materials in PDF format and generate high-fidelity, exam-conforming practice quizzes.

---

## Technical Architecture

The codebase adheres strictly to **Clean Architecture** and **MVC-like separation patterns**:

1. **Domain Models (`lib/models/`)**: Pure Dart models with zero Flutter imports. Handles data modeling, immutability contracts, and JSON serialization.
2. **Controller Layer (`lib/controllers/`)**: Encapsulates state mutation and business logic rules. Decoupled from the database and UI layers.
3. **Repository Layer (`lib/repositories/`)**: Abstract interfaces with concrete implementations (Hive CE) managing offline persistence, metadata updates, and cache structures.
4. **Service Layer (`lib/services/`)**: Interfaces with external modules, local PDF extraction utilities, Knowledge Intelligence Engine, and the Google Gemini API.
5. **UI Layer (`lib/pages/` & `lib/widgets/`)**: Responsive, Material 3 layouts presenting loading, empty, and success states dynamically depending on form factors.

---

## Directory Structure

```text
lib/
├── core/
│   └── utils/
│       └── text_chunk_service.dart          # Text preprocessing and cleanup
├── models/
│   ├── quiz_analytics.dart                  # Analytics snapshot model
│   ├── quiz_attempt.dart                    # Complete historical attempt
│   ├── quiz_model.dart                      # Questions and state models
│   ├── quiz_session.dart                    # Active session snapshot
│   └── quiz_source.dart                     # PDF Library entry metadata
├── repositories/
│   ├── impl/
│   │   ├── hive_quiz_history_repository.dart# Persistent quiz history
│   │   ├── hive_quiz_session_repository.dart# Persistent active sessions
│   │   └── hive_quiz_source_repository.dart # Persistent PDF source metadata
│   ├── quiz_history_repository.dart
│   ├── quiz_session_repository.dart
│   └── quiz_source_repository.dart
├── services/
│   ├── ai_service.dart                      # Gemini 2.5 API connector & retry handler
│   ├── cache_service.dart                   # Local quiz caching service
│   ├── knowledge_integration_service.dart   # KIE PDF ingestion bridge
│   ├── pdf_reader_service.dart              # Syncfusion PDF text extractor
│   ├── pdf_service.dart                     # File picker service
│   └── quiz_generation_adapter.dart         # KnowledgeObject to prompt text adapter
├── themes/
│   ├── app_colors.dart                      # Color constants
│   ├── app_text_styles.dart
│   └── app_theme.dart                       # Global Material 3 configurations
├── widgets/
│   ├── analytics_dashboard.dart
│   ├── loading_dialog.dart
│   └── question_card.dart
└── pages/
    ├── home_page.dart                       # Landing screen & session recovery
    ├── library_page.dart                    # PDF Library (Search, Sort, CRUD)
    ├── history_page.dart                    # Historical attempts list
    ├── attempt_summary_page.dart            # Read-only attempt results
    ├── quiz_page.dart                       # Interactive quiz runner
    └── result_page.dart                     # Quiz results & dashboard
```

---

## Project TITAN - Version 1.0 Foundation Baseline (TDL-010)

Project TITAN is an enterprise Dart/Flutter architecture providing a modular foundation for QuizForge AI.

* **Release Version**: `v1.0.0-foundation`
* **Architecture Report**: [`FOUNDATION_REPORT.md`](file:///c:/Users/acer/StudioProjects/quizforge_upsc/FOUNDATION_REPORT.md)
* **Release Notes**: [`CHANGELOG.md`](file:///c:/Users/acer/StudioProjects/quizforge_upsc/CHANGELOG.md)
* **Technical Debt Register**: [`docs/architecture/TECHNICAL_DEBT.md`](file:///c:/Users/acer/StudioProjects/quizforge_upsc/docs/architecture/TECHNICAL_DEBT.md)

### Decision Record Summary
* **TDL-009**: Knowledge Intelligence Engine (KIE) integration for QuizForge AI.
* **TDL-010**: Freeze Version 1.0 Foundation Baseline before Sprint 2 (Knowledge Graph Services) to eliminate architectural ambiguity, enforce clean boundaries, and register technical debt.

---

## Knowledge Engine Integration (TDL-009)

As per Decision Record **TDL-009**, QuizForge AI consumes knowledge through the **Knowledge Intelligence Engine (KIE)** (`packages/knowledge_engine`) instead of directly passing raw extracted PDF text to Gemini:

* **KnowledgeIngestionPipeline**: PDF text is normalized, chunked, and transformed into canonical `KnowledgeObject` domain entities.
* **RepositoryCoordinator**: `KnowledgeObject` instances are stored in the multi-tier knowledge repository.
* **QuizGenerationAdapter**: Formats canonical knowledge chunks into clean prompt payloads consumed by Gemini without altering existing prompt templates.

---

## AI Integration & Preprocessing

* **Gemini 2.5 Flash**: Connects directly to Google's generative models with strict prompt rules specifying question formats, difficulty levels, and domain-appropriate subject tagging.
* **Pre-processing**: Extracted PDF texts are sanitized, normalized via KIE, truncated to 15,000 characters to manage LLM attention and token usage, and hashed to generate content fingerprints.
* **Response validation**: Responses are parsed, and formatting anomalies (such as markdown code blocks) are stripped and cleaned to prevent decoding crashes.

---

## Local Storage & Cache Policies

* **Hive CE**: Lightweight, fast key-value storage box engines.
* **Caching**: Quizzes generated via Gemini are cached under their SHA-256 fingerprint ID. Selecting the same PDF loads cached questions instantly, ensuring offline operability and avoiding API call overheads.
* **Session Recovery**: Progress is auto-saved on every interaction (answering questions, bookmarking, navigation, and 30s timers). Unfinished sessions can be resumed or discarded from the Home Page.

---

## Setup & Running

### Prerequisites
* Flutter SDK (>=3.0.0 <4.0.0)
* Gemini API Key

### Configuration
Create a `.env` file in the root directory:
```env
GEMINI_API_KEY=your_actual_gemini_api_key_here
```

### Running the Application
```bash
# Fetch dependencies
flutter pub get

# Run in debug mode
flutter run
```

### Running Analysis & Tests
```bash
# Run static analysis
flutter analyze

# Run unit, integration, and UI smoke tests
flutter test
```

### Building Release Bundle
```bash
# Build Android APK
flutter build apk --release
```

---

## Known Limitations

1. **Free Tier Quota**: The application relies on free-tier Gemini API keys. Heavy usage will trigger a `429 (Too Many Requests)` warning, which is intercepted and displayed gracefully in the UI.
2. **Text Extraction boundaries**: Scanned images (non-searchable PDFs) will return empty extracted text. The app displays a clear warning prompting the user for text-based PDFs.

