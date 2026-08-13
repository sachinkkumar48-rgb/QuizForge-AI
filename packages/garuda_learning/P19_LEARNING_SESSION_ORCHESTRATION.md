# TITAN-KO-019.0 P19 — Learning Session Orchestration

## 1. Overview & Architectural Purpose

The **Learning Session Orchestration** engine (P19) closes the operational gap between **P15 Question Knowledge Products**, **P17 Learning Objectives Framework**, and **P18 Assessment & Learner Progress Engine**. 

P19 provides a deterministic, offline-first orchestration layer that:
- Coordinates the selection and presentation of P15 questions mapped to target P17 learning objectives.
- Sequences questions deterministically (by curriculum order, Bloom difficulty level, or seed-shuffled order).
- Manages the lifecycle of practice sessions (`created`, `active`, `paused`, `completed`, `cancelled`).
- Integrates directly with P18's `AssessmentService`, `SessionManager`, and `ProgressTracker` to score submitted answers and update aggregate learner progress.
- Strictly operates 100% offline with zero AI/LLM, network API, or spaced-repetition dependencies.

```
+-----------------------------------------------------------------------------------+
|                     P19 Learning Session Orchestration Engine                     |
+-----------------------------------------------------------------------------------+
| Entities:   LearningSession | SessionConfiguration | SessionProgressSummary       |
| Enums:      LearningSessionState | SelectionPolicy | SequencerPolicy              |
| Engine:     QuestionSelector | QuestionSequencer | LearningSessionOrchestrator    |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| P18 Learner Progress & Assessment Engine (Learner, QuestionAttempt, AttemptResult)|
| P17 Learning Objectives Framework (LearningObjective, CurriculumFramework)        |
| P15 Question Knowledge Product Framework (LegalQuestion, StructuredAnswer)        |
+-----------------------------------------------------------------------------------+
```

---

## 2. Core Domain Entities & Policies

### `LearningSession`
- `sessionId`: Unique identifier for the learning session.
- `learnerId`: Identifier of the practicing learner.
- `configuration`: Session configuration rules (`SessionConfiguration`).
- `orderedQuestionIds`: Immutable list of deterministically selected and sequenced P15 question IDs.
- `currentQuestionIndex`: 0-based index of the presented question.
- `submittedAttemptIds`: Sequence of submitted P18 `QuestionAttempt` IDs.
- `state`: Current lifecycle state (`LearningSessionState`).
- `startedAt`, `pausedAt`, `completedAt`: UTC timestamps.
- `assessmentSessionId`: Optional reference to linked P18 `AssessmentSession`.

### `LearningSessionState`
- `created`: Initial state after configuration.
- `active`: Session actively in progress.
- `paused`: Session temporarily paused by learner.
- `completed`: Session finished after answering scheduled questions or manual completion.
- `cancelled`: Session aborted prior to completion.

### `QuestionSelectionPolicy`
- `allObjectiveQuestions`: Selects all questions mapped to target objective(s).
- `unattemptedOnly`: Filters out questions previously attempted by the learner.
- `incorrectFocus`: Prioritizes questions previously answered incorrectly by the learner.
- `balanced`: Balanced mix of unattempted and review questions.

### `QuestionSequencerPolicy`
- `curriculumOrder`: Orders questions by unit/objective sequence index and canonical `questionId`.
- `difficultyAscending`: Orders questions by Bloom taxonomy cognitive level ascending.
- `deterministicShuffle`: Reproducibly shuffles questions using a deterministic seed (`learnerId_sessionId`).
- `sequential`: Orders questions by canonical source `questionId`.

### `SessionProgressSummary`
- Aggregates `totalQuestions`, `answeredCount`, `correctCount`, `currentScore` (`[0.0, 1.0]`), `state`, and `isCompleted`.

---

## 3. Question Selection & Sequencing Engine

1. **Selection (`QuestionSelector`)**:
   - Queries `QuestionKnowledgeProductService` (P15) for candidate questions.
   - Cross-references mapped product IDs from `CurriculumService` (P17).
   - Filters candidates against `AttemptRepository` (P18) when `unattemptedOnly` or `incorrectFocus` policy is requested.
   - Enforces `questionLimit` deterministically.

2. **Sequencing (`QuestionSequencer`)**:
   - Orders selected questions according to `QuestionSequencerPolicy`.
   - Uses canonical `questionId` as a stable tie-breaker.
   - Uses seed-based pseudo-random shuffling for `deterministicShuffle` so identical seeds produce identical question sequences.

---

## 4. Session Lifecycle & P18 Integration Flow

1. `createSession(config)`:
   - Verifies learner exists in `LearnerRepository`.
   - Verifies objective IDs exist in `CurriculumService`.
   - Runs `QuestionSelector` & `QuestionSequencer`.
   - Starts linked P18 `AssessmentSession` via `SessionManager`.
   - Instantiates `LearningSession` in `created` state.

2. `startSession(sessionId)`:
   - Transitions state to `active`.

3. `getCurrentQuestion(sessionId)`:
   - Resolves and returns current `LegalQuestion` object.

4. `submitAnswer(sessionId, answerText)`:
   - Delegates evaluation and attempt creation to `AssessmentService` (P18).
   - Saves `QuestionAttempt` and `AttemptResult` in `AttemptRepository`.
   - Updates `LearnerProgress` via `ProgressTracker`.
   - Records attempt ID in `LearningSession` and advances index.
   - Automatically completes session when final question is attempted.

---

## 5. Safety & Explicit Scope Boundaries

1. **Legal Safety**:
   - Preserves all P15 question provenance, statutory citations, and case evidence intact.
   - Does NOT invent legal doctrines, statutory interpretations, or case precedents.

2. **Educational Safety**:
   - Reports deterministic metrics (`score`, `answeredCount`, `correctCount`).
   - Does NOT make unsupported claims of "legal mastery", "doctrinal understanding", or "exam readiness".

3. **Offline & Non-AI Guarantee**:
   - 100% offline execution with zero network APIs.
   - Zero LLM, Gemini, Claude, or embedding dependencies.

4. **Explicit Exclusions**:
   - P19 does NOT implement UI components, spaced repetition, SM-2, Leitner systems, persistent database schemas, or cloud sync.

---

## 6. Verification Summary

- **P19 Unit & Integration Tests**: 80+ comprehensive tests covering selection, sequencing, lifecycle, P15/P17/P18 integrations, determinism, and safety invariants.
- **Full Suite Regression**: 1,175+ tests passing across `garuda_learning` and `garuda_case_law`.
- **Static Analysis**: `flutter analyze` clean (`0` issues).
- **Format**: `dart format` clean (`0` unformatted files).
