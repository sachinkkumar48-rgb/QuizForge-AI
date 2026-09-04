# P43: Adaptive Learning Activity Completion & Outcome Feedback Specification

## 1. Architectural Purpose
Milestone **P43 (Adaptive Learning Activity Completion & Outcome Feedback)** closes the operational loop between activity execution (**P42**) and state reconciliation/persistence (**P36/P38/P39**), feeding the resulting updated state forward into future pedagogical decision cycles (**P41**).

While P42 handles the dispatch and orchestration of learning activities (resuming sessions, binding remedial lessons, starting practice activities), P43 governs the deterministic finalization boundary:
1. Validates the integrity of activity attempts and results.
2. Normalizes performance metrics into an activity-independent domain contract (`LearningActivityOutcome`).
3. Forms structured evidence (`ActivityOutcomeEvidence`) preserving question, attempt, objective, and session traceability.
4. Invokes P36 outcome consolidation and P38/P39 state reconciliation to atomically increment authoritative learner state revisions.
5. Enforces dual-layer idempotency to prevent duplicate scoring or progress double-counting.
6. Preserves monotonic revision safety by rejecting stale or premature plan revisions.

---

## 2. The Complete Closed-Loop Topology

```
+-------------------------------------------------------------------------------------------------------+
|                                    CLOSED-LOOP ADAPTIVE LIFECYCLE                                    |
|                                                                                                       |
|  [Authoritative Learner State (P39)] ---> [Adaptive Decision Engine (P41)]                           |
|                                                      |                                                |
|                                                      v                                                |
|                                          [LearningContinuationPlan]                                   |
|                                                      |                                                |
|                                                      v                                                |
|                                      [AdaptiveLearningPlanExecutor (P42)]                             |
|                                                      |                                                |
|                                                      v                                                |
|                                  [Learning Activity / Practice Session]                               |
|                                                      |                                                |
|                                                      v                                                |
|                                [LearningActivityCompletionRequest (P43)]                              |
|                                                      |                                                |
|                                                      v                                                |
|                                [LearningActivityCompletionService (P43)]                              |
|                                      /                       \                                        |
|                                     /                         \                                       |
|                                    v                           v                                      |
|                       [LearningActivityOutcome]     [ActivityOutcomeEvidence]                         |
|                                                                |                                      |
|                                                                v                                      |
|                                                  [PracticeOutcomeConsolidator (P36)]                  |
|                                                                |                                      |
|                                                                v                                      |
|                                             [AdaptiveLearningStateReconciler (P38)]                   |
|                                                                |                                      |
|                                                                v                                      |
|                                             [Authoritative State Pipeline (P39)]                      |
|                                                                |                                      |
|                                                                +---> Monotonic Revision Advanced      |
|                                                                +---> Previous Plan Invalidated        |
|                                                                +---> Feeds Next P41 Decision Loop     |
+-------------------------------------------------------------------------------------------------------+
```

---

## 3. Core Domain Contracts

### 3.1 `LearningActivityCompletionStatus` & Error Taxonomy
Operational states:
* `success`: Activity completed and authoritative state reconciled.
* `alreadyCompleted`: Idempotent replay detected; cached outcome returned without double-counting.
* `invalidRequest`: Request failed validation (empty identifiers, negative numbers, missing data).
* `stalePlan`: Plan revision is strictly less than authoritative learner state revision.
* `futurePlanRevision`: Plan revision is ahead of authoritative learner state revision.
* `missingSession`: Required session execution state not found.
* `invalidAttempts`: Attempt validation failed (duplicate questions, unknown question IDs, contradictory states).
* `consolidationFailed`: Downstream P36 outcome consolidation failed.
* `reconciliationFailed`: Downstream P38/P39 reconciliation or persistence failed.
* `executionFailed`: General operational failure.

Error codes (`ActivityCompletionErrorCode`):
* `tenantMismatch`
* `stalePlan`
* `futurePlanRevision`
* `preconditionFailed`
* `missingSession`
* `duplicateAttempt`
* `unknownQuestion`
* `invalidAttempts`
* `consolidationFailed`
* `reconciliationFailed`
* `alreadyCompleted`

### 3.2 `LearningActivityOutcome`
A normalized, activity-independent learning outcome entity:
* Quantitative metrics: `questionsPresented`, `questionsAttempted`, `correctAnswers`, `incorrectAnswers`, `skippedAnswers`, `unansweredCount`.
* Safe mathematical metrics:
  * `score`: Ratio in $[0.0, 1.0]$.
  * `accuracy`: Nullable double in $[0.0, 1.0]$, explicitly `null` when `questionsAttempted == 0` for safe zero-denominator behavior.
  * `accuracyPercentage`: Nullable double in $[0.0, 100.0]$.
  * `completionRate`: Ratio in $[0.0, 1.0]$.
* Dimensional evidence maps:
  * `topicEvidence`: Performance breakdown by topic.
  * `objectiveEvidence`: Performance breakdown by objective.
  * `remedialEvidence`: Structured record if remediation was completed.
* Mathematical safety rules:
  * 0 questions: score = 0.0, accuracy = null, completionRate = 1.0.
  * 0 attempts with questions: score = 0.0, accuracy = null.
  * All skipped: score = 0.0, accuracy = null, completionRate = 1.0.
  * 100% correct: score = 1.0, accuracy = 1.0, accuracyPercentage = 100.0.
  * 0% correct: score = 0.0, accuracy = 0.0, accuracyPercentage = 0.0.
  * Guaranteed no `NaN` or `Infinity`.
* Cryptographic provenance: Deterministic SHA-256 fingerprinting.

### 3.3 `ActivityOutcomeEvidence`
Preserves provenance and traceability:
$$\text{Activity} \to \text{Session} \to \text{Question} \to \text{Attempt} \to \text{Objective} \to \text{Result}$$
Carries typed collections of `PracticeQuestionEvidence`, `QuestionAttempt`, and `AttemptResult`.

### 3.4 `LearningActivityCompletionRequest` & `LearningActivityCompletionResult`
Immutable input and output transport bundles providing complete context, metadata, and diagnostic audit steps (`ActivityCompletionAuditTrail`).

---

## 4. Dual-Layer Idempotency Strategy

1. **Activity-Level Idempotency (`LearningActivityCompletionRepository`)**:
   * Uses deterministic idempotency key:
     `comp_${learnerId}_${examId}_${activityId}_${sessionId ?? 'nosess'}`
   * Before executing consolidation or reconciliation, the repository is queried.
   * If a record exists with the same idempotency key, the completion service immediately returns `LearningActivityCompletionStatus.alreadyCompleted` with the cached `LearningActivityOutcome`.
   * Downstream consolidation and state updates are completely bypassed, preventing duplicate scoring.

2. **Session-Level Idempotency (`AuthoritativeLearnerState.processedSessions`)**:
   * P38 and P39 inspect whether the session was already applied to learner state.
   * Replays are marked idempotent and state revisions remain untouched.

---

## 5. Monotonic Stale-Plan Protection

P43 enforces strict revision invariants against `AuthoritativeLearnerState`:
* If `request.planRevision < authoritativeState.revision`:
  Rejects with `ActivityCompletionErrorCode.stalePlan`. The plan was formulated against an older state revision and cannot update newer state.
* If `request.planRevision > authoritativeState.revision`:
  Rejects with `ActivityCompletionErrorCode.futurePlanRevision`. The plan claims a state revision that does not yet exist.
* If `request.planRevision == authoritativeState.revision`:
  Plan revision matches authoritative state; proceeding with completion.

---

## 6. Attempt Validation Rules

Every attempt submitted in a completion request is rigorously validated:
1. **Duplicate Questions**: No two attempts in the same request may reference the same `questionId`.
2. **Session Scope**: Every attempt must belong to a question presented in the session specification (`orderedQuestionIds`).
3. **Contradictory States**: An attempt cannot be simultaneously marked correct with a zero score unless explicitly unweighted.
4. **Empty Submissions**: An answer string cannot be whitespace-only for an answered question.

---

## 7. Explicit GARUDA Game Scope Boundary

**GARUDA GAME IS COMPLETELY OUT OF SCOPE.**
* Zero Unreal Engine code inspected, modified, imported, or referenced.
* Zero game assets or game packages touched.
* All work is strictly bounded to `packages/garuda_learning`.
