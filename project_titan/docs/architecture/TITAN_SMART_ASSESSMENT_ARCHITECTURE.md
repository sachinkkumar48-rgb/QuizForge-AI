# TITAN Smart Assessment Generation Architecture

**Phase**: 8B — Smart Assessment Generation Pipeline  
**Specification Code**: `TITAN-8B-001`  
**Monorepo Packages**: `packages/titan_pdf`, `packages/titan_quiz_ai`, `packages/titan_quiz`, `apps/quizforge_ai`  
**Status**: Production Verified  

---

## 1. Overview & Architectural Goals

The **TITAN Smart Assessment Generation Pipeline** establishes an end-to-end, privacy-preserving, and psychometrically grounded assessment engine. It transforms ingested document context (`LearningDocument` and `LearningDocumentChunk[]`) into rigorously verified, source-attributed `Quiz` models consumable by QuizForge AI.

```
PDF / Document Source (Digital / Scanned / Mixed / Bilingual)
         ↓
Document Intelligence (packages/titan_pdf)
         ↓
LearningDocument & LearningDocumentChunk[]
         ↓
AssessmentSourceBridge
         ↓
AssessmentSource[] & AssessmentBlueprint
         ↓
AssessmentChunkSelector (Deterministic Token Batching & Order Preservation)
         ↓
AssessmentPromptBuilder (Grounded System & User Prompts)
         ↓
AIService (packages/titan_ai)
         ↓
AssessmentJsonParser (Structured Schema Extraction)
         ↓
QuestionDeduplicator (Jaccard Token Similarity Filter)
         ↓
AssessmentValidator (Strict Grounding & Integrity Verification)
         ↓
GeneratedQuestion[] → QuizModel Adapter
         ↓
QuizSession & QuizSessionRepository
         ↓
QuizForge UI & State Workflow
```

---

## 2. Assessment Domain Entities

The core domain resides in `packages/titan_quiz_ai`:

### 2.1 `AssessmentQuestionType`
Enumerates supported question schemas:
- `mcq`: Standard 4-option single-choice item.
- `trueFalse`: 2-option binary choice item.
- `multipleSelect`: Multi-select question with 1 to 4 correct options.
- Designed for extension: `assertionReason`, `statementBased`, `matchTheFollowing`, `fillInBlank`.

### 2.2 `AssessmentBlueprint`
Defines **WHAT** assessment is requested without coupling to AI providers:
- `documentId`: String identifier of source document.
- `targetQuestions`: Total requested count (e.g. 5, 10, 20).
- `difficulty`: `QuizDifficulty` (easy, medium, hard, mixed).
- `language`: `QuizLanguage` (english, hindi, bilingual).
- `category`: `QuizCategory` (upsc, bpsc, ssc, banking, railway, custom).
- `allowedQuestionTypes`: List of enabled `AssessmentQuestionType`s.
- `explanationRequired`: Boolean enforcement for detailed rationales.
- `maxTokensPerBatch`: Token context safety boundary.

### 2.3 `AssessmentSource`
Preserves document provenance and physical page citations:
- `documentId`: Document identifier.
- `chunkId`: Unique deterministic chunk ID.
- `pageNumber` & `endPageNumber`: Page range boundaries.
- `text`: Clean normalized text snippet.
- `provenance`: `TextProvenance` (`nativePdf`, `ocr`, `mixed`).
- `script`: Unicode script identifier (`latin`, `devanagari`, `bilingual`).
- `tokenEstimate`: Heuristic token count.

### 2.4 `GeneratedQuestion` & `QuestionGenerationMetadata`
- Holds raw options, correct answer indices array, and explanation.
- `QuestionGenerationMetadata` records `sourceChunkId`, `pageNumber`, `confidenceScore`, and `isGroundingVerified`.
- `toQuizQuestion()` adapts directly to canonical `QuizQuestion` models with custom marks and negative marking.

---

## 3. Grounding & Anti-Hallucination Pipeline

1. **Source Citation Requirement**: Every generated question is explicitly tied to a `sourceChunkId` and `pageNumber` found in the prompt header.
2. **Deterministic Pre- & Post-Validation (`AssessmentValidator`)**:
   - Rejects missing or blank question text.
   - Rejects duplicate options within any question.
   - Asserts correct answer indices are strictly in bounds.
   - Enforces explanation presence when required by blueprint.
   - **Grounding Verification**: If `question.metadata.sourceChunkId` does not match an actual chunk in the input batch, the question is rejected with typed failure.

---

## 4. Multi-Batching & Deduplication

1. **`AssessmentChunkSelector`**:
   - Preserves deterministic reading order and page numbering.
   - Divides large multi-page documents into token-bounded generation batches.
2. **`QuestionDeduplicator`**:
   - Performs text normalization (case normalization, punctuation removal, whitespace collapsing).
   - Computes Jaccard token overlap across candidate questions.
   - Drops duplicate questions generated across adjacent chunk boundaries before final quiz assembly.

---

## 5. Cancellation & Error Safety

- **`AssessmentCancellationToken`**: Enables non-blocking, user-initiated cancellation. In-flight operations discard incomplete generations without corrupting repositories or creating stale sessions.
- **Typed Exceptions**: User-safe exceptions (`PromptException`, `JsonValidationException`, `JsonParsingException`, `AssessmentCancellationException`, `SourceGroundingException`) wrapped by `ApplicationException`. Zero credentials or raw AI provider error stacks are exposed to the UI.

---

## 6. Offline-First & Security Boundary

- **Local Execution**: Document ingestion, OCR fallback, text cleaning, chunking, and validation execute 100% locally.
- **Explicit Triggering**: AI generation is only invoked on explicit user request.
- **Zero Telemetry / Zero Content Logging**: Source passages, prompts, and credentials are never logged or transmitted to unapproved endpoints.
