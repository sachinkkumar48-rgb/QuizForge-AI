# P42 — Adaptive Learning Plan Execution & Orchestration Specification

## 1. Architectural Role & Boundary
In the QuizForge AI / Project TITAN architecture, **Milestone P41** acts as the pedagogical reasoning layer that deterministically decides *what* the learner should do next (`AdaptiveLearningDecision` and `LearningContinuationPlan`).

**Milestone P42** implements the **Plan Execution & Orchestration Layer** (`AdaptiveLearningPlanExecutor`). It translates high-level pedagogical decisions into real, running learning activities by coordinating downstream services:
- **P33**: Adaptive Question Selection (`AdaptiveQuestionSelectionService`)
- **P34**: Practice Session Orchestration (`AdaptivePracticeSessionOrchestrator`)
- **P35**: Practice Execution Engine (`AdaptivePracticeExecutionEngine`)
- **P40**: Session Recovery & Resumption (`ResumableAdaptivePracticeCoordinator`)

```text
       Authoritative Learner State (P39 rev N)
                          +
            Session Checkpoint (P40 chkRev M)
                          │
                          ▼
            [ P41 Decision Engine ]
                          │
                          ▼
              LearningContinuationPlan
                          │
                          ▼
        [ P42 AdaptiveLearningPlanExecutor ]
       ┌──────────────────┴──────────────────┐
       │ 1. Validate Tenant & Freshness      │
       │ 2. Check Session Conflicts          │
       │ 3. Deterministic Activity Routing:  │
       │    - CONTINUATION: Resume session   │
       │    - REMEDIATION:  Bind lesson/prac │
       │    - REVIEW:       Spaced review    │
       │    - REINFORCE:    Weakness practice│
       │    - ADVANCE:      Next objective   │
       │    - COMPLETE:     Terminal result  │
       └──────────────────┬──────────────────┘
                          │
                          ▼
           LearningActivityExecutionResult
          (SessionSpec / ExecutionState /
           AuditTrail / Checkpoint / Error)
```

### Critical Boundaries
- **GARUDA Game is completely out of scope.** Zero Unreal Engine, blueprint, or game dependencies.
- **Pure Deterministic Execution**: 100% offline-compatible; zero LLM or cloud API requirements.
- **Non-Duplicative State**: Never mutates authoritative learner state directly; state updates flow exclusively through P36 consolidation, P38 reconciliation, and P39 persistence.

---

## 2. Supported Activity Lifecycle & Routing

| Activity Type | Pedagogical Intent | Downstream Action | Expected Output Status |
|---|---|---|---|
| `continuation` | Resume interrupted or paused practice session at exact cursor | Recovers checkpoint and reconstructs execution state via `ResumableAdaptivePracticeCoordinator` | `resumed` |
| `remediation` | Targeted concept remediation on material learner weakness | Binds P25 `RemedialLesson`, selects weak-spot questions, orchestrates `remedialPractice` session, initializes execution | `success` |
| `review` | Spaced repetition to preserve long-term retention | Selects due review items, orchestrates `mixedRevision` session, initializes execution | `success` |
| `reinforcement` | Additional practice to achieve objective mastery | Selects in-progress objective questions, orchestrates `weaknessFocused` session, initializes execution | `success` |
| `advancement` | Progression to next sequential curriculum objective | Selects questions for eligible unattempted objective, orchestrates `standard` session, initializes execution | `success` |
| `complete` | Curriculum fully achieved, no pending reviews | Emits terminal completion result without allocating or starting any practice session | `completed` |

---

## 3. Freshness, Conflict & Safety Guarantees

1. **Stale Plan Rejection**:
   If `currentState.revision > plan.decision.authoritativeStateRevision`, the executor immediately aborts execution and emits `LearningActivityExecutionStatus.stalePlan` with error code `stalePlan`.
2. **Tenant Isolation**:
   `request.learnerId == plan.decision.learnerId == currentState.learnerId` and `request.examId == plan.decision.examId == currentState.examId`. Any mismatch results in immediate rejection with `tenantMismatch`.
3. **Active Session Conflict Protection**:
   If an activity requiring a new session (`remediation`, `review`, `reinforcement`, `advancement`) is dispatched while an unfinished session is already active (`activeCheckpoint != null && !activeCheckpoint.isCompleted`), the executor refuses to overwrite the session and emits `sessionAlreadyActive`.
4. **Resumption Integrity**:
   When resuming an interrupted session, answered questions are preserved as completed without re-presentation or duplicated outcome recording.

---

## 4. Domain & Service Model Inventory

1. **`LearningActivityExecutionStatus`**:
   Enum representing operational result: `success`, `resumed`, `completed`, `stalePlan`, `invalidPlan`, `invalidTarget`, `unsupportedActivity`, `sessionAlreadyActive`, `recoveryRequired`, `executionFailed`.
2. **`PlanExecutionErrorCode` & `PlanExecutionError` & `PlanExecutionException`**:
   Strongly typed machine-readable error definitions.
3. **`ExecutionAuditStep` & `ExecutionAuditTrail`**:
   Step-by-step diagnostic reasoning chain recording:
   - `PLAN_RECEIVED`
   - `TENANT_VALIDATED`
   - `REVISION_VALIDATED`
   - `ACTIVITY_ROUTED`
   - `TARGET_VALIDATED`
   - `DOWNSTREAM_EXECUTION_STARTED`
   - `DOWNSTREAM_EXECUTION_COMPLETED`
   - `EXECUTION_RESULT_EMITTED`
4. **`LearningActivityExecutionRequest`**:
   Request payload encapsulating `plan`, `currentState`, `corpus`, `existingSessionSpec`, `activeCheckpoint`, and execution options.
5. **`LearningActivityExecutionResult`**:
   Comprehensive result aggregate containing status, target, session spec, execution state, checkpoint, remedial lesson, audit trail, and failure details.
6. **`AdaptiveLearningPlanExecutor`**:
   Deterministic orchestrator service executing the plan against downstream components.

---

## 5. Verification Matrix

- **Unit Tests (`p42_adaptive_plan_executor_test.dart`)**:
  - Request/Result models, status checks, error codes, serialization.
  - Tenant mismatch rejection, stale plan rejection, session conflict protection.
  - Deterministic routing for all 6 activities: continuation, remediation, review, reinforcement, advancement, complete.
  - Complete audit trail step sequence verification.
- **Integration Tests (`p42_adaptive_plan_execution_integration_test.dart`)**:
  - Full flow across P39 persisted state, P40 session checkpointing, P41 decision formulation, and P42 execution.
  - Continuation recovery after simulated crash.
  - Remediation lesson binding and practice execution.
  - Spaced review and curriculum completion without session start.
