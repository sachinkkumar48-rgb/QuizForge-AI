# TITAN-KO-018.0 P18 — Learner Progress & Assessment Engine

## 1. Overview & Architectural Alignment

The **Learner Progress & Assessment Engine** (P18) provides the execution layer for learner interactions within the TITAN Learning Operating System. Built directly on top of P15 (`garuda_case_law` Question Knowledge Products) and P17 (`garuda_learning` Learning Objectives Framework), P18 enables learners to:

- Register profiles and open assessment sessions.
- Attempt evidence-backed legal questions.
- Evaluate submitted answers deterministically (Multiple Choice, True/False, Short Answer Keyword rules, Manual fallback for essays).
- Persist immutable attempts and score results.
- Track progress towards learning objectives against configurable achievement thresholds (`minimumAttempts = 5`, `minimumSuccessRate = 0.80`).

```
+-----------------------------------------------------------------------------------+
|                        P18 Learner Progress & Assessment Engine                   |
+-----------------------------------------------------------------------------------+
| Entities:  Learner | QuestionAttempt | AttemptResult | LearnerProgress | Session  |
| Services:  AssessmentService | ProgressTracker | SessionManager                   |
| Evaluators: MultipleChoice | TrueFalse | ShortAnswerKeyword | Manual              |
| Repos:     InMemoryLearnerRepository | InMemoryAttemptRepo | InMemoryProgressRepo |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| P17 Learning Objectives Framework   | P15 Question Knowledge Product Framework   |
| (LearningObjective, CurriculumFramework)| (LegalQuestion, StructuredAnswer)       |
+-----------------------------------------------------------------------------------+
```

---

## 2. Core Domain Entities

### `Learner`
- `id`: Immutable unique learner identifier.
- `name`: Display name.
- `email`: Optional contact email.
- `createdAt`: UTC registration timestamp.
- `metadata`: Immutable key-value properties.

### `QuestionAttempt`
- `attemptId`: Unique attempt event identifier.
- `learnerId`: Submitting learner ID.
- `questionId`: Canonical P15 question ID.
- `objectiveId`: Canonical P17 learning objective ID.
- `submittedAnswer`: String response submitted by learner.
- `attemptedAt`: UTC submission timestamp.
- `sessionId`: Optional session reference.

### `AttemptResult`
- `attemptId`: Unique reference to `QuestionAttempt`.
- `isCorrect`: Deterministic correctness boolean.
- `score`: Normalized double score in range `[0.0, 1.0]`.
- `feedback`: Optional rationale or keyword match summary.
- `evaluatedAt`: UTC evaluation timestamp.
- `evaluationMethod`: Enum (`multipleChoice`, `trueFalse`, `shortAnswerKeyword`, `manual`).

### `LearnerProgress`
- `learnerId`: Learner identifier.
- `objectiveId`: Target learning objective ID.
- `attemptCount`: Total submitted attempts.
- `correctCount`: Total correct attempts.
- `successRate`: `(correctCount / attemptCount).clamp(0.0, 1.0)`.
- `status`: `LearnerObjectiveStatus` (`notStarted`, `inProgress`, `achieved`).
- `achievedAt`: UTC timestamp when achievement threshold was first met.

### `AssessmentSession`
- `sessionId`: Unique session identifier.
- `learnerId`: Learner identifier.
- `objectiveIds`: Targeted objective IDs.
- `questionIds`: Targeted question IDs.
- `startedAt`: UTC start timestamp.
- `completedAt`: Optional UTC completion timestamp.
- `attemptIds`: Submitted attempt ID sequence.

### `AssessmentThresholdConfig`
- `minimumAttempts`: Configurable minimum required attempts (Default: `5`).
- `minimumSuccessRate`: Configurable minimum required success rate (Default: `0.80`).

---

## 3. Answer Evaluator Engine

| Evaluator | Method | Rules / Matching Mechanism | Score Output |
|---|---|---|---|
| `MultipleChoiceEvaluator` | `multipleChoice` | Exact string / normalized option key match | `1.0` (Match) / `0.0` (Mismatch) |
| `TrueFalseEvaluator` | `trueFalse` | Normalized boolean matching (`true/t/1/yes` vs `false/f/0/no`) | `1.0` (Match) / `0.0` (Mismatch) |
| `ShortAnswerEvaluator` | `shortAnswerKeyword` | Rule-based keyword extraction and hit-ratio calculation | `[0.0, 1.0]` based on keyword hit ratio |
| `ManualEvaluator` | `manual` | Non-automated placeholder for essay/case analysis questions | `0.0` (`isCorrect: false`, no AI fabrication) |

---

## 4. In-Memory Repositories

- `InMemoryLearnerRepository`: Stores and indexes `Learner` profiles by ID.
- `InMemoryAttemptRepository`: Stores `QuestionAttempt` and `AttemptResult` entities, enabling lookup by learner, objective, session, or attempt ID.
- `InMemoryProgressRepository`: Stores `LearnerProgress` records indexed by `(learnerId, objectiveId)`.

---

## 5. Application Services

### `AssessmentService`
Validates inputs against repository, curriculum, and question services; evaluates submitted answers; persists attempts and results; updates session and progress.

### `ProgressTracker`
Aggregates attempts and results, calculates success rates, applies threshold rules, and updates `LearnerObjectiveStatus`.

### `SessionManager`
Manages optional `AssessmentSession` creation, attempt linkage, and completion lifecycle.

---

## 6. Safety & Invariant Safeguards

1. **Non-Existent Identifier Rejection**: Submissions referencing non-existent learners, questions, or objectives are strictly rejected with an `ArgumentError`.
2. **Score Range Enforcement**: `AttemptResult.score` is strictly asserted to be within `[0.0, 1.0]`.
3. **Attempt Binding**: `AttemptResult` must be explicitly linked to a valid `QuestionAttempt`.
4. **Terminology Compliance**: Allowed status values are strictly `notStarted`, `inProgress`, and `achieved`. No unsupported claims of "mastery", "comprehension", or "understanding".
5. **Offline Execution**: Pure in-memory operations with zero external network or database dependencies.

---

## 7. Verification Summary

- **Total Package Tests**: `145` unit, integration, safety, determinism, and regression tests in `garuda_learning`.
- **Total Suite Tests**: `1,095` tests passing across `garuda_learning` and `garuda_case_law`.
- **Static Analysis**: `flutter analyze` clean (`0` issues).
- **Format**: `dart format` clean (`0` unformatted files).
