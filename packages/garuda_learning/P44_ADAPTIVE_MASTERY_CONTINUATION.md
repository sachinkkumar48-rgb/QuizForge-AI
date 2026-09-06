# P44 — Adaptive Mastery Continuation & Closed-Loop Mastery Engine Specification

## Architecture Specification (TITAN-KO-044.0 P44)

The **Adaptive Mastery Continuation & Closed-Loop Mastery Engine** closes the operational and pedagogical loop between learning activity finalization (**P43**), authoritative learner state reconciliation & persistence (**P36/P38/P39**), objective-level progression interpretation, and future pedagogical decision formulation (**P41/P42**).

---

## 1. Problem Statement

Prior milestones established a robust execution, finalization, and persistence pipeline:
- **P41**: Evaluates authoritative learner state and checkpoint recovery to formulate an actionable `LearningContinuationPlan`.
- **P42**: Dispatches and orchestrates practice activities via `AdaptiveLearningPlanExecutor`.
- **P43**: Normalizes outcome metrics into `LearningActivityOutcome`, forms `ActivityOutcomeEvidence`, executes `PracticeOutcomeConsolidator` (P36), reconciles authoritative progress via `AdaptiveLearningStateReconciler` (P38), and persists monotonic revisions via `AuthoritativeLearningStateRepository` (P39).

However, upon P43 completion, the learning lifecycle halts at raw state persistence:
1. **Lack of Objective-Level Progression Interpretation**: Raw attempt counters and success rates are updated in `AuthoritativeLearnerState`, but the system does not evaluate what state transitions occurred (e.g., progression from `inProgress` to `mastered`, regression from `mastered` back to `regressed`, or emergence of struggle).
2. **Missing Pedagogical Feedback Contract**: The client and learner receive activity scores and question counts, but no typed, auditable feedback answering:
   - *What did the learner demonstrate?*
   - *What remains weak?*
   - *What should happen next?*
   - *Why?*
3. **Discontinuous Closed-Loop Orchestration**: Moving from a completed activity to the next adaptive decision requires ad-hoc orchestration rather than an idempotent, revision-anchored mastery continuation pipeline.

---

## 2. Architectural Gap

The architectural gap lies between:
```text
P43 Completed Activity
        ↓
Updated Authoritative Learner State (P39)
        ↓
[GAP: Objective Mastery Evaluation, Weakness Detection, & Adaptive Feedback]
        ↓
Next Adaptive Learning Decision (P41) & Execution Plan (P42)
```

P44 bridges this gap with a deterministic, explainable subsystem that:
1. Evaluates objective-level progress transitions against rigorous educational thresholds.
2. Identifies demonstrated competencies and diagnoses persistent or emerging weak areas.
3. Computes deterministic confidence and overall exam readiness metrics.
4. Derives the optimal next learning action (`NextLearningAction`) with an auditable pedagogical rationale.
5. Packages these insights into an immutable, cryptographically fingerprinted `AdaptiveContinuationFeedback` contract.
6. Coordinates seamless progression into the next `LearningContinuationPlan` without human intervention.

---

## 3. Existing Contracts Reused

P44 strictly extends existing Project TITAN / QuizForge AI contracts:
- **P17**: `CurriculumFramework`, `CurriculumUnit`, `LearningObjective`.
- **P18**: `LearnerProgress`, `LearnerObjectiveStatus`, `AttemptResult`, `QuestionAttempt`.
- **P20**: `ReviewItem`, `ReviewSchedule`.
- **P23**: `DomainMasteryProfile`, `WeakSpotProfile`, `WeakObjectiveDiagnostic`.
- **P25**: `RemedialLesson`, `RemedialBinding`.
- **P36**: `ConsolidatedPracticeOutcome`, `PracticeOutcomeConsolidator`.
- **P38**: `AuthoritativeLearnerState`, `AdaptiveLearningStateReconciler`.
- **P39**: `AuthoritativeLearningStateRepository`, `AuthoritativeLearningStateRecoveryService`, `AuthoritativeStatePersistenceCoordinator`.
- **P40**: `SessionCheckpoint`, `ResumableLearningSession`.
- **P41**: `AdaptiveLearningDecisionEngine`, `AdaptiveLearningDecision`, `LearningContinuationPlan`, `LearningDecisionType`, `LearningDecisionPriority`, `AdaptiveDecisionPolicy`.
- **P42**: `AdaptiveLearningPlanExecutor`, `LearningActivityExecutionResult`.
- **P43**: `LearningActivityCompletionResult`, `LearningActivityOutcome`, `ActivityOutcomeEvidence`, `LearningActivityCompletionService`.

---

## 4. New Domain & Service Contracts

### 4.1 Domain Enums & Entities (`lib/domain/entities/`)
1. **`ObjectiveMasteryStatus`**:
   - `notAttempted`: 0 attempts recorded.
   - `insufficientEvidence`: 1 to $N-1$ attempts ($N$ is evidence threshold).
   - `inProgress`: Sufficient attempts with moderate performance ($0.50 \le \text{rate} < 0.80$).
   - `mastered`: Met achievement criteria ($\text{attempts} \ge 3$ and $\text{rate} \ge 0.80$).
   - `remediationRequired`: Material weakness ($\ge 3$ attempts and $\text{rate} < 0.50$).
   - `regressed`: Previously achieved/mastered objective falling below retention threshold.
2. **`ObjectiveTransitionType`**:
   - `initialAssessment`: Objective first evaluated.
   - `progressed`: Demonstrated positive progression towards mastery.
   - `mastered`: Crossed achievement threshold into mastery.
   - `maintainedMastery`: Maintained mastery with continued strong performance.
   - `regressed`: Dropped below retention threshold after prior achievement.
   - `remediationTriggered`: Identified persistent struggle triggering remediation.
   - `remediationResolved`: Successfully recovered from struggle through remediation.
   - `unchanged`: Evidence insufficient to warrant status change.
3. **`ObjectiveProgressionSummary`**:
   - Immutable progression aggregate for an objective: prior/new status, transition type, attempt deltas, success rate deltas, confidence score ($[0.0, 1.0]$), and auditable transition rationale.
4. **`ObjectiveWeaknessDetail`**:
   - Diagnostic detail for a struggling or regressed objective: deficiency score ($[0.0, 1.0]$), attempt count, correct count, consecutive incorrect count, and recommended remedial lesson link.
5. **`NextLearningAction`**:
   - Structured recommendation: `actionType` (`LearningDecisionType`), `priority` (`LearningDecisionPriority`), `targetObjectiveId`, `targetTopic`, `rationale`, and execution parameters.
6. **`MasteryContinuationAuditTrail` & `MasteryContinuationAuditStep`**:
   - Step-by-step diagnostic audit trail capturing every stage of progression analysis, weakness detection, readiness evaluation, and action determination.
7. **`AdaptiveContinuationFeedback`**:
   - Immutable domain contract: `feedbackId`, `learnerId`, `examId`, `authoritativeRevision`, `evaluatedAt`, `overallReadinessScore`, `overallConfidence`, `objectiveProgressions`, `demonstratedCompetencies`, `detectedWeaknesses`, `recommendedAction`, `auditTrail`, `fingerprint` (SHA-256), `idempotencyKey`.
8. **`AdaptiveMasteryContinuationRequest` & `AdaptiveMasteryContinuationResult`**:
   - Request and result transport envelopes.

### 4.2 Repository Contracts (`lib/repository/`)
- **`AdaptiveMasteryContinuationRepository`**:
  Abstract interface for storing and retrieving continuation feedback by idempotency key and query filters.
- **`InMemoryAdaptiveMasteryContinuationRepository`**:
  Production-grade in-memory implementation supporting tenant isolation, deterministic lookup, and query indexing.

### 4.3 Service Engine (`lib/service/`)
- **`AdaptiveMasteryContinuationService`**:
  Core deterministic engine orchestrating:
  - `evaluateFromCompletion(...)`: Evaluates directly from a P43 `LearningActivityCompletionResult`.
  - `evaluateMasteryContinuation(...)`: Evaluates against an authoritative learner state and optional curriculum context.
  - Generates typed `AdaptiveContinuationFeedback` and pre-formulates the next `LearningContinuationPlan`.

---

## 5. Data Flow Topology

```text
+-------------------------------------------------------------------------------------------------------+
|                                    CLOSED-LOOP ADAPTIVE LIFECYCLE (P44)                              |
|                                                                                                       |
|  [P41 Decision Engine] ---> [LearningContinuationPlan] ---> [P42 Plan Executor]                       |
|                                                                    |                                  |
|                                                                    v                                  |
|                                                          [Activity Execution]                         |
|                                                                    |                                  |
|                                                                    v                                  |
|                                                      [P43 Activity Completion]                        |
|                                                                    |                                  |
|                                                                    v                                  |
|                                               [P36 Consolidation & P38/P39 State]                    |
|                                                                    |                                  |
|                                                                    v                                  |
|                                                   AuthoritativeLearnerState (rev N)                  |
|                                                                    |                                  |
|                                                                    v                                  |
|                                              +--------------------------------------------+          |
|                                              | P44 AdaptiveMasteryContinuationService      |          |
|                                              +--------------------------------------------+          |
|                                              | 1. Tenant & Revision Safety Check          |          |
|                                              | 2. Objective-Level Progression Evaluation  |          |
|                                              | 3. Weakness & Regression Detection         |          |
|                                              | 4. Deterministic Confidence & Readiness    |          |
|                                              | 5. Next Learning Action Determination      |          |
|                                              | 6. Typed AdaptiveContinuationFeedback      |          |
|                                              | 7. Pre-formulate Next Continuation Plan    |          |
|                                              +--------------------------------------------+          |
|                                                                    |                                  |
|                                           +------------------------+------------------------+         |
|                                           v                                                 v         |
|                             [AdaptiveContinuationFeedback]                     [LearningContinuationPlan]
|                             - What did learner demonstrate?                    - Actionable next plan |
|                             - What remains weak?                               - Ready for P42 exec   |
|                             - What should happen next & why?                                          |
+-------------------------------------------------------------------------------------------------------+
```

---

## 6. State Transitions & Progression Rules

For each objective $O_i$ in the authoritative learner state:
1. **Initial Assessment**: If prior attempts $= 0$ and new attempts $> 0$:
   - If attempts $\ge 3$ and success rate $\ge 0.80 \implies \text{mastered}$
   - If attempts $\ge 3$ and success rate $< 0.50 \implies \text{remediationRequired}$
   - Else $\implies \text{inProgress}$ (or $\text{insufficientEvidence}$ if attempts $< 3$)
2. **Mastery Achievement**:
   - Prior status $\in \{\text{notStarted}, \text{inProgress}, \text{insufficientEvidence}\}$
   - Total attempts $\ge 3$ and total success rate $\ge 0.80$
   - Transition: `mastered` (status: `mastered`)
3. **Mastery Maintenance**:
   - Prior status $== \text{mastered}$
   - Recent attempts maintain success rate $\ge 0.70$
   - Transition: `maintainedMastery` (status: `mastered`)
4. **Regression**:
   - Prior status $== \text{mastered}$
   - Recent activity has multiple incorrect attempts dropping overall or recent success rate $< 0.60$
   - Transition: `regressed` (status: `regressed`)
5. **Remediation Triggered**:
   - Prior status $\ne \text{remediationRequired}$
   - Total attempts $\ge 3$ and total success rate $< 0.50$
   - Transition: `remediationTriggered` (status: `remediationRequired`)
6. **Remediation Resolved**:
   - Prior status $== \text{remediationRequired}$
   - Remedial lesson completed and recent practice success rate $\ge 0.70$
   - Transition: `remediationResolved` (status: `inProgress` or `mastered` if rate $\ge 0.80$)

---

## 7. Mathematical Rules & Calculations

### 7.1 Zero-Denominator Safety
All divisions check denominator $> 0$. If $0$, accuracy is $0.0$ or explicitly $null$ where representing unknown probability. Guaranteed zero `NaN` or `Infinity`.

### 7.2 Evidence Sufficiency & Confidence Adjustment
$$\text{sufficiency} = \min\left(1.0, \frac{\text{attemptCount}}{\text{minEvidenceThreshold}}\right)$$
$$\text{confidence} = \left(0.7 \times \text{sufficiency}\right) + \left(0.3 \times \text{successRate}\right)$$
Confidence is strictly bounded to $[0.0, 1.0]$.

### 7.3 Deficiency Score
$$\text{deficiencyScore} = \left(1.0 - \text{successRate}\right) \times \min\left(1.0, \frac{\text{attemptCount}}{\text{minEvidenceThreshold}}\right)$$

### 7.4 Overall Curriculum Readiness
$$\text{Readiness} = \frac{\sum_{i=1}^{M} \text{ObjectiveScore}(O_i)}{M}$$
Where $\text{ObjectiveScore}(O_i) = \text{successRate}_i \times \text{confidence}_i$.
If $M == 0$, Readiness $= 0.0$.

---

## 8. Deterministic Behavior

1. **Purely Deterministic**: Given identical `AuthoritativeLearnerState`, completion result, and policies, the output `AdaptiveContinuationFeedback` is bit-for-bit identical.
2. **Zero Drift**: Zero `DateTime.now()` inside domain calculation logic; all timestamps are explicitly caller-supplied or anchored to authoritative state.
3. **Deterministic Sorting**: Collections and maps are sorted by objective ID, deficiency score, or explicit priority to avoid non-deterministic iteration order.
4. **Cryptographic Fingerprint**: SHA-256 canonical fingerprint computed over all key fields.

---

## 9. Failure Semantics

1. **Tenant Mismatch**: Rejects when learner ID or exam ID does not match the authoritative state (`tenantMismatch`).
2. **Stale Revision**: Rejects when input state or plan revision is strictly older than the latest persisted revision (`staleRevision`).
3. **Empty Identifiers**: Empty `learnerId`, `examId`, or `requestId` immediately throws `ArgumentError` or produces `invalidRequest`.
4. **Corrupted State**: Inconsistent attempt counts ($\text{correct} > \text{attempts}$ or $\text{attempts} < 0$) throw `ArgumentError` or return `invalidState`.

---

## 10. Idempotency Strategy

- Deterministic idempotency key:
  `mcont_${learnerId}_${examId}_rev${stateRevision}_${activityId ?? 'direct'}`
- Querying `AdaptiveMasteryContinuationRepository` with this key returns cached `AdaptiveContinuationFeedback` without recomputing or double-evaluating.

---

## 11. Persistence & Recovery Interaction

- P44 reads from `AuthoritativeLearningStateRepository` and `AuthoritativeLearningStateRecoveryService` (P39).
- After application restart or crash recovery:
  1. Authoritative state is recovered via P39 recovery service.
  2. P44 evaluates the recovered state.
  3. The resulting feedback and continuation plan match the exact state before shutdown.
- Does NOT introduce a second competing learner state repository.

---

## 12. Backward Compatibility

- Existing P39, P40, P41, P42, P43 APIs remain 100% untouched.
- `garuda_learning.dart` exports the new P44 public API.
- All existing tests pass without regressions.

---

## 13. Test Strategy

1. **Unit Tests (`test/p44_adaptive_mastery_continuation_test.dart`)**:
   - Model invariants, enum properties, JSON serialization round-trips.
   - Objective status transitions: normal progression, mastery threshold, below-threshold, insufficient evidence, all-correct, all-incorrect, skipped, repeated attempts, improvement, regression, boundary values.
   - Deterministic fingerprinting and idempotency keys.
   - Service safety: tenant isolation, stale revision rejection, empty inputs.
2. **Integration Tests (`test/integration/p44_adaptive_mastery_continuation_integration_test.dart`)**:
   - Complete end-to-end chain across P41 -> P42 -> activity execution -> P43 -> P36 -> P38 -> P39 -> P44 -> next P41/P42 loop.
   - Scenarios 1 to 10 covering strong performance, weak performance, mixed performance, repeated completion requests, restart/recovery, stale state rejection, tenant mismatch, insufficient evidence, improvement after remediation, and regression after mastery.

---

## 14. Scope Boundaries

- **GARUDA Game is completely out of scope.** Zero Unreal Engine files, blueprints, or game assets are touched, inspected, or imported.
- All changes are strictly contained within `packages/garuda_learning`.
