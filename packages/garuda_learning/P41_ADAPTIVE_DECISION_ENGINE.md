# P41 — Adaptive Learning Decision & Continuation Engine

## Architecture Specification (TITAN-KO-041.0 P41)

The **Adaptive Learning Decision & Continuation Engine** establishes a deterministic, fully explainable pedagogical decision system for Project TITAN and QuizForge AI. It evaluates authoritative learner state, checkpoint recovery metadata, and curriculum constraints to decide *what* the learner should study next, *why* that choice was made, and *how* to execute it downstream without duplicating learning evidence.

---

## 1. Architectural Boundaries & Ownership

* **Separation of Concerns**:
  - **P17**: Curriculum frameworks, units, and learning objectives (`LearningObjective`, `CurriculumFramework`).
  - **P20**: Spaced repetition schedules and intervals (`ReviewItem`, `ReviewSchedule`).
  - **P25**: Remedial lessons, misconceptions, and legal doctrine references (`RemedialLesson`, `RemedialLessonBinding`).
  - **P33 / P34**: Question selection config, pool filtering, and session orchestration (`AdaptiveQuestionSelectionConfig`, `AdaptivePracticeSessionSpec`).
  - **P35**: Runtime question execution, timers, feedback policies (`PracticeExecutionState`, `AdaptivePracticeExecutionEngine`).
  - **P36 / P38**: Outcome consolidation and state reconciliation (`PracticeOutcomeConsolidator`, `AdaptiveLearningStateReconciler`).
  - **P39**: Authoritative state persistence and monotonic revisions (`AuthoritativeLearnerState`, `AuthoritativeLearningStateRepository`).
  - **P40**: Checkpoint durability and session resumption (`SessionCheckpoint`, `LearningSessionRecoveryService`).
  - **P41**: Decision synthesis, prioritization, evidence attribution, continuation plan formulation, and execution handoff (`AdaptiveLearningDecisionEngine`, `AdaptiveLearningDecision`, `LearningContinuationPlan`).
  - **GARUDA Game is completely out of scope.**

* **Zero AI / LLM Dependency**: Pure deterministic rules, explicit threshold evaluations, and mathematical priority calculations. Fully offline-executable.
* **Non-Duplicative State**: Consumes `AuthoritativeLearnerState` (P39) and `SessionCheckpoint` (P40) without maintaining a competing state repository.

---

## 2. Decision Pipeline & Flow

```text
       Authoritative Learner State (P39 rev N)
                          +
            Session Checkpoint (P40 chkRev M)
                          +
              Curriculum Framework (P17)
                          |
                          v
         [ LearningDecisionEvidence Compilation ]
                          |
                          v
        [ Deterministic Decision Policy (P41) ]
                          |
       ┌──────────────────┴──────────────────┐
       │ Evaluated in Strict Priority Order: │
       │ 1. CONTINUATION (Unfinished Session)│
       │ 2. REMEDIATION (Material Weakness)  │
       │ 3. REVIEW (Spaced Repetition Due)   │
       │ 4. REINFORCEMENT (In-Progress)      │
       │ 5. ADVANCEMENT (New Objective)      │
       │ 6. COMPLETE (Curriculum Achieved)   │
       └──────────────────┬──────────────────┘
                          |
                          v
               AdaptiveLearningDecision
                          +
                    DecisionTrace
                          |
                          v
              LearningContinuationPlan
                          |
                          v
      Handoff to P33/P34 Selection & P35 Practice Session
```

---

## 3. Decision Types & Priority Order

| Priority | Decision Type | Trigger Condition | Pedagogical Action |
|---|---|---|---|
| **1 (Highest)** | `continuation` | An interrupted or paused session exists with uncompleted questions. | Resumes the active session at the exact checkpoint cursor without repeating answered questions. |
| **2** | `remediation` | An objective has $\ge 3$ attempts and $\text{successRate} < 0.50$, or explicit struggle signal. | Binds a P25 `RemedialLesson` and scopes practice to targeted foundational items. |
| **3** | `review` | An achieved objective is due for review per spaced repetition intervals ($\text{daysSinceReview} \ge \text{interval}$). | Schedules focused review practice to prevent memory decay. |
| **4** | `reinforcement` | An objective has attempts ($\ge 1$) but is not yet achieved ($0.50 \le \text{successRate} < 0.80$ or $\text{attempts} < 5$). | Generates targeted practice to stabilize mastery. |
| **5** | `advancement` | Current objectives achieved; next logical curriculum objective has satisfied prerequisites. | Advances learner to the next sequential learning objective in the curriculum tree. |
| **6 (Lowest)** | `complete` | All objectives in the curriculum framework are achieved with zero pending reviews. | Signals syllabus completion; no new practice required. |

---

## 4. Domain Models (`packages/garuda_learning/lib/domain/entities/`)

1. **`LearningDecisionType`**:
   Enum: `continuation`, `remediation`, `review`, `reinforcement`, `advancement`, `complete`.
2. **`LearningDecisionPriority`**:
   Enum: `urgent` (continuation/critical remediation), `high` (remediation/review), `medium` (reinforcement), `low` (advancement), `none` (complete).
3. **`LearningTargetType`**:
   Enum: `sessionCursor`, `remedialLesson`, `reviewObjective`, `practiceObjective`, `curriculumObjective`, `none`.
4. **`LearningTarget`**:
   Target coordinates: `targetId`, `targetType`, `objectiveId`, `topic`, `subject`, `remedialLessonId`, `cursorIndex`, `metadata`.
5. **`LearningDecisionEvidence`**:
   Machine-readable metrics backing the decision: `objectiveId`, `masteryScore`, `attemptCount`, `correctCount`, `successRate`, `confidence`, `lastPracticedAt`, `daysSinceReview`, `authoritativeStateRevision`, `checkpointRevision`, `activeSessionId`.
6. **`DecisionTraceStep` & `DecisionTrace`**:
   Auditable reasoning chain recording which policies were inspected, metrics considered, and why a specific rule was matched or skipped.
7. **`AdaptiveLearningDecision`**:
   Immutable decision aggregate containing `decisionId`, `learnerId`, `examId`, `type`, `priority`, `reason`, `target`, `evidence`, `authoritativeStateRevision`, `checkpointRevision`, `decidedAt`, `trace`.
8. **`LearningContinuationPlan`**:
   Actionable execution contract providing handoff configurations:
   - `toAdaptiveQuestionSelectionConfig()` (P33)
   - `toAdaptivePracticeSessionConfig()` (P34)
   - Handoff metadata for P35 execution engine.

---

## 5. Revision Safety & Stale-Decision Protection

Every `AdaptiveLearningDecision` captures the exact `authoritativeStateRevision` of the state from which it was evaluated:
* `isStale(AuthoritativeLearnerState currentState)`:
  Returns `true` if `currentState.revision > decision.authoritativeStateRevision`.
* Downstream execution coordinators reject stale decisions to prevent applying actions formulated on obsolete progress data.
* Revision monotonicity ($rev_{N+1} > rev_N$) is strictly preserved.

---

## 6. Multi-Tenant Isolation

All decision and continuation operations are strictly scoped to `learnerId` and `examId`. Cross-learner or cross-exam evaluations throw `ArgumentError` or produce typed isolation errors.

---

## 7. Crash Recovery & Resumption Compatibility

When an application crashes during an active session:
1. P40 restores the `SessionCheckpoint` (e.g. at question cursor 3 of 5).
2. P41 evaluates the recovered state and checkpoint.
3. Rule 1 (`continuation`) fires with highest priority.
4. P41 emits a `continuation` decision targeting session ID and cursor 3.
5. P35 execution continues from question 4 without replaying questions 1–3 or duplicating outcomes.
