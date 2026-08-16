# P22 Implementation Plan

**TITAN Knowledge Package:** `garuda_learning` (TITAN-KO-022.0)  
**Package Scope:** Learning Recommendation Lifecycle & Feedback System  
**Clean Architecture Alignment:** Domain / Repository / Service Layers  
**Author:** Senior Implementation Engineer (Antigravity)  
**Reviewer:** Chief Software Architect (ChatGPT) & Product Owner  
**Date:** 2026-08-16  
**Status:** Approved for Architecture Refinement & Implementation Planning  

---

## 1. Approved Scope

P22 establishes the **Recommendation Lifecycle, Provenance, and Closed-Loop Feedback Architecture** within Project TITAN.

### System Boundary Division
- **P21 (Adaptive Recommendation Engine):** Generates recommendation candidates, computes multi-factor priority scores ($W(LO_i)$), selects recommendation strategies (`RecommendationType`), and outputs turn-key `SessionConfiguration` payloads.
- **P22 (Recommendation Lifecycle & Feedback):** 
  - Manages the lifecycle of persisted recommendation instances (`RecommendationInstance`).
  - Records learner interactions (`RecommendationInteraction`) such as view, acceptance, dismissal, and deferral.
  - Links recommendations to execution sessions (`RecommendationSessionLink`) without modifying P19.
  - Measures observed recommendation outcomes (`RecommendationOutcome`) and post-recommendation performance metrics (`RecommendationEffectiveness`).
  - Closes the pedagogical feedback loop between P21 recommendations, P19 session executions, and P18 assessment outcomes.

---

## 2. Architecture Decision

### Pedagogical Closed-Loop Overview
```
┌─────────────────────────────────────────────────────────────────────────┐
│                          PROJECT TITAN LEARNING LOOP                    │
└─────────────────────────────────────────────────────────────────────────┘
        │
        ▼
   [P17 / P18 / P20 Signals]
        │
        ▼
   [P21 Adaptive Recommendation Engine] ──(Generates LearningRecommendation)
        │
        ▼
   [P22 Recommendation Lifecycle Service]
        │ ── Creates RecommendationInstance (State: issued)
        │ ── Records RecommendationInteraction (accepted / dismissed / deferred)
        ▼
   [RecommendationSessionLink] ──(Points to P19 Session ID)
        │
        ▼
   [P19 Learning Session Orchestrator] ──(Executes Session & Records Question Attempts)
        │
        ▼
   [P18 Progress Assessment Engine] ──(Produces AttemptResults & Updates LearnerProgress)
        │
        ▼
   [P22 Effectiveness Evaluator] ──(Computes Observed Delta & Session Completion Rate)
        │
        ▼
   [P22 RecommendationOutcome / RecommendationEffectiveness] (Immutable Feedback Record)
```

### Architectural Guarantees
1. **Offline-First & Self-Contained:** Zero network calls, zero external APIs, zero LLM dependencies.
2. **Strict Clean Architecture:** Unidirectional dependencies. P19 and P21 have zero knowledge of P22.
3. **Immutability & Safety:** All domain models are `@immutable` with defensive copying and strict validation.
4. **Pedagogical Safety:** Strictly differentiates observed performance differences from causal mastery claims.

---

## 3. Provenance Decision

### Comparative Analysis: Option A vs Option B

| Evaluation Dimension | Option A: `recommendationId` on `LearningSession` (P19) | Option B: Separate `RecommendationSessionLink` (P22) |
| :--- | :--- | :--- |
| **Coupling** | High. Couples session execution directly to recommendation concepts. | Low. Clean Architecture decoupling; P19 remains agnostic of P22. |
| **P19 Backward Compatibility** | Breaking change. Requires modifying `LearningSession`, constructors, JSON schema, and existing tests. | **100% Preserved**. Zero changes required in P19 source code or schemas. |
| **User-Initiated Sessions** | Awkward. Requires nullable `recommendationId` on all sessions. | Clean. Non-recommended sessions simply have no P22 link record. |
| **Multi-Session Support** | Inflexible. One session can only point to one recommendation. | Highly Flexible. 1 recommendation can map to multiple sessions (e.g., retries/resumptions). |
| **3-File Constraint** | High risk. Modifying P19 spills edits across multiple stages. | **100% Compliant**. All P22 changes are isolated to P22 files. |

### Architectural Verdict
**Option B (Separate P22 Linking Entity: `RecommendationSessionLink`) is chosen.**
- P19 source code remains completely untouched (`P19 COMPATIBILITY CHANGE NOT REQUIRED`).
- Provenance is explicitly tracked in P22 via `RecommendationSessionLink(linkId, instanceId, sessionId, linkedAt)`.

---

## 4. Lifecycle State Machine

### Deterministic State Diagram
```
              ┌───────────────┐
              │    issued     │
              └───────┬───────┘
                      │
        ┌─────────────┼──────────────┐
        │             │              │
        ▼             ▼              ▼
  ┌───────────┐ ┌───────────┐  ┌───────────┐
  │  viewed   │ │ dismissed │  │  expired  │ [Terminal]
  └─────┬─────┘ └───────────┘  └───────────┘
        │         [Terminal]
   ┌────┴────┬─────────────┐
   │         │             │
   ▼         ▼             ▼
┌────────┐ ┌───────────┐ ┌───────────┐
│accepted│ │ dismissed │ │ deferred  │
└───┬────┘ └───────────┘ └─────┬─────┘
    │        [Terminal]        │ (Re-activated or Superseded)
    ▼                          ▼
┌────────┐               ┌───────────┐
│started │               │superseded │ [Terminal]
└───┬────┘               └───────────┘
    │
    ├────────────────────────┐
    ▼                        ▼
┌───────────┐          ┌───────────┐
│ completed │          │ abandoned │
└───────────┘          └───────────┘
 [Terminal]             [Terminal]
```

### State Transition Specification

| From State | Allowed Target State | Triggering Event / Action | Evidence / Validation Rule |
| :--- | :--- | :--- | :--- |
| `issued` | `viewed` | Recommendation rendered in learner feed | Non-empty timestamp; valid learner ID. |
| `issued` / `viewed` | `accepted` | Learner explicitly selects recommendation | Valid user interaction event. |
| `issued` / `viewed` | `dismissed` | Learner dismisses recommendation | Requires valid `DismissalReason`. |
| `issued` / `viewed` | `deferred` | Learner defers recommendation | Stored deferral timestamp; retains instance. |
| `issued` / `viewed` | `expired` | Time window exceeds validity TTL | `asOf - issuedAt > validityWindow`. |
| `accepted` | `started` | Practice session initialized via P19 | Valid `sessionId` linked via `RecommendationSessionLink`. |
| `started` | `completed` | Linked P19 session completes | P19 `LearningSessionState.completed` confirmed. |
| `started` | `abandoned` | Linked session cancelled or timed out | P19 `LearningSessionState.cancelled` or abort recorded. |
| `deferred` | `accepted` / `superseded` | Re-engaged or superseded by new queue | Re-engagement or queue refresh. |

---

## 5. Domain Models

### 1. `RecommendationLifecycleState` (Enum)
```dart
enum RecommendationLifecycleState {
  issued,
  viewed,
  accepted,
  dismissed,
  deferred,
  started,
  completed,
  abandoned,
  expired,
  superseded;

  bool get isTerminal =>
      this == dismissed ||
      this == completed ||
      this == abandoned ||
      this == expired ||
      this == superseded;
}
```

### 2. `DismissalReason` (Enum)
```dart
enum DismissalReason {
  notInterested,
  tooDifficult,
  tooEasy,
  alreadyMastered,
  deferredForLater,
  other;
}
```

### 3. `RecommendationEvidenceSnapshot` (Value Object)
Captures an immutable, compact audit snapshot at the time of issuance:
- `double reviewUrgencyFactor`
- `double prerequisiteBlockerFactor`
- `double weakDomainFactor`
- `double curriculumAdvancementFactor`
- `double practiceDensityFactor`
- `double? baselineAccuracy`
- `int baselineAttemptsCount`
- `LearnerObjectiveStatus baselineStatus`

### 4. `RecommendationInstance` (Aggregate Root Entity)
- `String instanceId`
- `String recommendationId` (P21 reference)
- `String learnerId`
- `String objectiveId`
- `RecommendationType recommendationType`
- `double priorityScore`
- `String rationale`
- `SessionConfiguration suggestedConfig`
- `RecommendationLifecycleState state`
- `RecommendationEvidenceSnapshot evidenceSnapshot`
- `DateTime issuedAt`
- `DateTime updatedAt`

### 5. `RecommendationInteraction` (Domain Entity)
- `String interactionId`
- `String instanceId`
- `RecommendationLifecycleState targetState`
- `DismissalReason? dismissalReason`
- `DateTime timestamp`
- `Map<String, dynamic> metadata`

### 6. `RecommendationSessionLink` (Domain Entity)
- `String linkId`
- `String instanceId`
- `String sessionId` (P19 reference)
- `DateTime linkedAt`

### 7. `RecommendationOutcome` (Domain Entity)
- `String outcomeId`
- `String instanceId`
- `String sessionId`
- `int totalQuestionsScheduled`
- `int totalQuestionsAttempted`
- `double completionRate`
- `double? sessionAccuracy`
- `bool isCompleted`
- `DateTime evaluatedAt`

### 8. `RecommendationEffectiveness` (Value Object)
- `String instanceId`
- `String objectiveId`
- `double? baselineAccuracy`
- `int baselineAttemptsCount`
- `double? postAccuracy`
- `int postAttemptsCount`
- `double? observedPerformanceDelta`
- `bool insufficientEvidence`
- `Duration measurementWindow`
- `DateTime evaluatedAt`

---

## 6. Repository Architecture

P22 adheres to Clean Architecture by establishing abstract repository interfaces in `lib/repository/`:

### Interface: `RecommendationLifecycleRepository`
```dart
abstract interface class RecommendationLifecycleRepository {
  Future<void> saveInstance(RecommendationInstance instance);
  Future<RecommendationInstance?> getInstanceById(String instanceId);
  Future<RecommendationInstance?> getInstanceByRecommendationId(String recommendationId);
  Future<List<RecommendationInstance>> getInstancesForLearner(
    String learnerId, {
    RecommendationLifecycleState? state,
    String? objectiveId,
  });

  Future<void> recordInteraction(RecommendationInteraction interaction);
  Future<List<RecommendationInteraction>> getInteractionsForInstance(String instanceId);

  Future<void> saveSessionLink(RecommendationSessionLink link);
  Future<RecommendationSessionLink?> getLinkForSession(String sessionId);
  Future<List<RecommendationSessionLink>> getLinksForInstance(String instanceId);

  Future<void> saveOutcome(RecommendationOutcome outcome);
  Future<RecommendationOutcome?> getOutcomeForInstance(String instanceId);

  Future<void> clear();
}
```

---

## 7. Persistence Architecture

### Offline-First In-Memory Implementation
- `InMemoryRecommendationLifecycleRepository` implements `RecommendationLifecycleRepository` with:
  - Deep immutable defensive copying on reads and writes.
  - Deterministic sort order (timestamp ascending, ID lexicographical tie-breaking).
  - Clean isolation for unit, safety, and integration testing.
  - Zero external database lock-in.

### Future SQLite / Hive Adapter Compatibility
- All entities implement canonical `toJson()` and `fromJson()` serialization formats.
- Schema versioning is explicit via JSON payload structures without mutating core interfaces.

---

## 8. P17 Integration

- **Read-Only:** P22 references canonical P17 `objectiveId` and curriculum domain metadata stored in `RecommendationInstance` and `RecommendationEffectiveness`.
- P22 does not modify P17 curriculum graphs or DAG topologies.

---

## 9. P18 Integration

- **Read-Only Evaluation Signal:**
  - P22 queries P18 `AttemptRepository` to determine baseline performance prior to `issuedAt`.
  - P22 queries P18 `AttemptRepository` to evaluate post-recommendation attempts within the measurement window.
  - P22 inspects P18 `LearnerProgress` to determine status shifts (e.g. `notStarted` $\rightarrow$ `inProgress` $\rightarrow$ `achieved`).
- P22 does not alter assessment scoring or threshold evaluation logic.

---

## 10. P19 Integration

- **Zero-Modification Decoupled Integration:**
  - When a learner starts a practice session from a recommendation, P19 `LearningSessionOrchestrator` creates the `LearningSession` using `suggestedConfig`.
  - P22 creates a `RecommendationSessionLink(instanceId, sessionId)` record.
  - When the session concludes, P22 observes session completion status and answered counts to generate `RecommendationOutcome`.
- P19 code remains 100% unchanged.

---

## 11. P20 Integration

- **Read-Only Consumption:**
  - P22 inspects P20 SM-2 review items (due dates and stability) when recording the initial `RecommendationEvidenceSnapshot`.
- **Strict Constraint:** P22 does **NOT** write to P20 and does **NOT** introduce a second review scheduler. Review scheduling remains exclusively owned by P20.

---

## 12. P21 Integration

- **Downstream Consumer:**
  - P21 `AdaptiveRecommendationService` produces `LearningRecommendation`s in a `RecommendationQueue`.
  - P22 `RecommendationLifecycleService` ingests these recommendations, persists them as `RecommendationInstance`s with state `issued`, and captures the baseline snapshot.
- P22 does not modify P21 factor formulas, scoring weights, or strategy selection.

---

## 13. Effectiveness Model

### Mathematical Formulation
For a target learning objective $LO_i$ associated with `RecommendationInstance` $R$:

1. **Baseline Accuracy ($Acc_{\text{baseline}}$):**
   $$Acc_{\text{baseline}} = \frac{\sum_{a \in \mathcal{A}_{\text{baseline}}} \mathbb{I}(a.\text{isCorrect})}{|\mathcal{A}_{\text{baseline}}|}$$
   where $\mathcal{A}_{\text{baseline}}$ is the set of attempts on $LO_i$ recorded strictly prior to $R.\text{issuedAt}$.

2. **Post-Recommendation Accuracy ($Acc_{\text{post}}$):**
   $$Acc_{\text{post}} = \frac{\sum_{a \in \mathcal{A}_{\text{post}}} \mathbb{I}(a.\text{isCorrect})}{|\mathcal{A}_{\text{post}}|}$$
   where $\mathcal{A}_{\text{post}}$ is the set of attempts on $LO_i$ recorded during the measurement window $[R.\text{issuedAt}, R.\text{issuedAt} + \Delta T_{\text{window}}]$.

3. **Observed Performance Difference ($\Delta_{\text{perf}}$):**
   $$\Delta_{\text{perf}} = Acc_{\text{post}} - Acc_{\text{baseline}}$$

4. **Session Completion Rate ($C_{\text{rate}}$):**
   $$C_{\text{rate}} = \frac{N_{\text{attempted}}}{N_{\text{scheduled}}}$$

### Effectiveness Measurement Window
- Default window: **7 days** (aligned with standard SM-2 review cycles).
- Configurable window range: $[1\text{ day}, 30\text{ days}]$.
- Injected `DateTime asOf` parameter to ensure strict determinism.

---

## 14. Determinism

1. **Injected Time Abstraction:** All service methods and state transitions accept an explicit `DateTime asOf` parameter. No business logic invokes raw `DateTime.now()` internally.
2. **Deterministic State Replay:** Given an initial state and a sorted sequence of `RecommendationInteraction`s, the resulting state is 100% deterministic.
3. **Stable Metric Evaluation:** Effectiveness calculations on identical datasets yield bit-for-bit identical results with standard floating-point precision.
4. **Stable Ordering:** All repository queries return lists with deterministic tie-breaking (sorted by `timestamp` ascending, then `instanceId` lexicographically).

---

## 15. Educational Safety Boundaries

The following pedagogical safety principles are enforced in code and documentation:
1. **Dismissal Is Not Failure:** A dismissed recommendation reflects learner agency or scheduling preference; it is never penalized or treated as a cognitive weakness.
2. **Low Completion Is Not Poor Performance:** Session abandonment or low completion rate is tracked purely as execution telemetry, not learner incompetence.
3. **Correlation Is Not Causation:** Metric is strictly labeled `observedPerformanceDelta`, never "causal mastery improvement".
4. **Acceptance Is Not Mastery:** Accepting a recommendation does not advance learner progress status. Only P18 verified assessment attempts alter progress.
5. **No Metric Fabrication:** When attempts are zero or sample size is insufficient, metrics are returned as `null` with `insufficientEvidence: true`. Zero denominator is guarded against.

---

## 16. Missing Data & Edge Case Handling

| Scenario | System Behavior | Metric Output |
| :--- | :--- | :--- |
| **Missing Recommendation Instance** | Returns `null` or throws `InstanceNotFoundException`. | None. |
| **Zero Baseline Attempts** | Evaluates post-recommendation accuracy only. | `baselineAccuracy: null`, `observedPerformanceDelta: null`, `insufficientEvidence: true`. |
| **Zero Post-Recommendation Attempts** | Records session as incomplete/unattempted. | `postAccuracy: null`, `observedPerformanceDelta: null`, `insufficientEvidence: true`. |
| **Cancelled / Aborted Session** | Linked session marked `abandoned`; outcome records partial attempts. | `completionRate: answeredCount / totalQuestions`, `isCompleted: false`. |
| **Superseded Recommendation Queue** | Unacted `issued` recommendations transition to `superseded`. | Terminal state recorded; no outcome evaluated. |
| **Zero Scheduled Questions** | Guarded by assertion / validation. | Throws `ArgumentError`. |

---

## 17. Multi-Objective & Multi-Session Behavior

1. **One Recommendation $\rightarrow$ One Primary Objective:** Each `RecommendationInstance` targets exactly one primary `objectiveId`.
2. **One Recommendation $\rightarrow$ Multiple Sessions:** A learner may pause, cancel, and later start a new session targeting the same recommendation. `RecommendationSessionLink` supports multiple sessions per instance.
3. **One Session $\rightarrow$ Primary Recommendation:** A practice session launched from a recommendation links to that primary `RecommendationInstance`.
4. **User-Initiated Sessions:** Sessions launched outside the recommendation engine function independently without a `RecommendationSessionLink`.

---

## 18. Implementation Stages

To strictly comply with the TITAN rule of **maximum 3 files modified per task**, the implementation is structured across 6 granular, sequential stages:

```
┌────────────────────────────────────────────────────────────┐
│                  P22 IMPLEMENTATION ROADMAP                │
├────────────────────────────────────────────────────────────┤
│ Stage 1: Core Domain Entities & States                     │
│ Stage 2: Interaction, Link & Outcome Entities              │
│ Stage 3: Repository Interfaces & In-Memory Implementation  │
│ Stage 4: Lifecycle Service & Effectiveness Evaluator       │
│ Stage 5: Barrel Export & Unit Test Coverage                │
│ Stage 6: Integration, Safety & Regression Test Suite       │
└────────────────────────────────────────────────────────────┘
```

### Detailed Stage Breakdown

#### Stage 1: Core Domain Entities & States
- **Purpose:** Define lifecycle state enum, dismissal enum, and immutable `RecommendationInstance` domain aggregate.
- **Files (3 New):**
  1. `lib/domain/entities/recommendation_lifecycle_state.dart`
  2. `lib/domain/entities/dismissal_reason.dart`
  3. `lib/domain/entities/recommendation_instance.dart`
- **Dependencies:** `garuda_learning/lib/domain/entities/recommendation_type.dart`, `session_configuration.dart`.
- **Verification:** Unit tests for entity construction, validations, state immutability, and JSON serialization.
- **Commit Boundary:** `feat(garuda_learning): add P22 recommendation lifecycle states and instance entity`

#### Stage 2: Interaction, Link & Outcome Entities
- **Purpose:** Define entities for capturing learner interactions, session linking, evidence snapshots, and outcome evaluation.
- **Files (3 New):**
  1. `lib/domain/entities/recommendation_interaction.dart`
  2. `lib/domain/entities/recommendation_session_link.dart`
  3. `lib/domain/entities/recommendation_outcome.dart`
- **Dependencies:** Stage 1 entities.
- **Verification:** Unit tests for interaction logging, session link immutability, and outcome calculation value objects.
- **Commit Boundary:** `feat(garuda_learning): add P22 interaction, session link, and outcome domain models`

#### Stage 3: Repository Interfaces & In-Memory Implementation
- **Purpose:** Define Clean Architecture repository contracts and the deterministic offline in-memory store.
- **Files (3 New):**
  1. `lib/domain/entities/recommendation_evidence_snapshot.dart`
  2. `lib/repository/recommendation_lifecycle_repository.dart`
  3. `lib/repository/in_memory_recommendation_lifecycle_repository.dart`
- **Dependencies:** Stage 1 & Stage 2 entities.
- **Verification:** Repository persistence tests, query filtering by state/learner, defensive copy validation.
- **Commit Boundary:** `feat(garuda_learning): add P22 lifecycle repository interface and in-memory store`

#### Stage 4: Lifecycle Service & Effectiveness Evaluator
- **Purpose:** Implement business service managing lifecycle transitions, event logging, and observed effectiveness scoring.
- **Files (3 New):**
  1. `lib/domain/entities/recommendation_effectiveness.dart`
  2. `lib/service/recommendation_lifecycle_service.dart`
  3. `lib/service/recommendation_effectiveness_evaluator.dart`
- **Dependencies:** Stages 1–3, P18 `AttemptRepository`, P20 `ReviewScheduleRepository`.
- **Verification:** Unit tests for deterministic state transitions, observed delta math, missing data safety guards.
- **Commit Boundary:** `feat(garuda_learning): implement P22 lifecycle service and effectiveness evaluator`

#### Stage 5: Barrel Export & Unit Test Coverage
- **Purpose:** Export all P22 domain models and services via package barrel file, and establish core domain unit test suites.
- **Files (1 Modified, 2 New):**
  1. `[MODIFY] lib/garuda_learning.dart`
  2. `[NEW] test/domain/recommendation_instance_test.dart`
  3. `[NEW] test/service/recommendation_lifecycle_service_test.dart`
- **Dependencies:** Stages 1–4.
- **Verification:** `flutter test test/domain/recommendation_instance_test.dart test/service/recommendation_lifecycle_service_test.dart`.
- **Commit Boundary:** `feat(garuda_learning): export P22 API and add core unit test suites`

#### Stage 6: Integration, Safety & Regression Test Suite
- **Purpose:** Validate complete closed-loop workflow across P17 $\rightarrow$ P21 $\rightarrow$ P22 $\rightarrow$ P19 $\rightarrow$ P18 $\rightarrow$ P22, and ensure zero regressions across P17–P21.
- **Files (3 New):**
  1. `[NEW] test/integration/p22_closed_loop_feedback_test.dart`
  2. `[NEW] test/safety/p22_educational_safety_test.dart`
  3. `[NEW] test/regression/p17_p22_regression_test.dart`
- **Dependencies:** Complete P17–P22 implementations.
- **Verification:** Full package test run (`flutter test`).
- **Commit Boundary:** `test(garuda_learning): add P22 end-to-end integration, safety, and regression tests`

---

## 19. File-Level Change Plan

### Summary Table

| Stage | Action | File Path | Description |
| :--- | :--- | :--- | :--- |
| **Stage 1** | `NEW` | `packages/garuda_learning/lib/domain/entities/recommendation_lifecycle_state.dart` | State machine enum and terminal state helper. |
| **Stage 1** | `NEW` | `packages/garuda_learning/lib/domain/entities/dismissal_reason.dart` | Structured dismissal reason enum. |
| **Stage 1** | `NEW` | `packages/garuda_learning/lib/domain/entities/recommendation_instance.dart` | Core persisted recommendation entity. |
| **Stage 2** | `NEW` | `packages/garuda_learning/lib/domain/entities/recommendation_interaction.dart` | Learner interaction telemetry event model. |
| **Stage 2** | `NEW` | `packages/garuda_learning/lib/domain/entities/recommendation_session_link.dart` | Decoupled link between recommendation and P19 session. |
| **Stage 2** | `NEW` | `packages/garuda_learning/lib/domain/entities/recommendation_outcome.dart` | Practice session execution outcome model. |
| **Stage 3** | `NEW` | `packages/garuda_learning/lib/domain/entities/recommendation_evidence_snapshot.dart` | Immutable issuance-time audit snapshot. |
| **Stage 3** | `NEW` | `packages/garuda_learning/lib/repository/recommendation_lifecycle_repository.dart` | Abstract Clean Architecture repository contract. |
| **Stage 3** | `NEW` | `packages/garuda_learning/lib/repository/in_memory_recommendation_lifecycle_repository.dart` | Offline-first in-memory repository implementation. |
| **Stage 4** | `NEW` | `packages/garuda_learning/lib/domain/entities/recommendation_effectiveness.dart` | Observed performance metrics value object. |
| **Stage 4** | `NEW` | `packages/garuda_learning/lib/service/recommendation_lifecycle_service.dart` | Lifecycle transition orchestrator and manager. |
| **Stage 4** | `NEW` | `packages/garuda_learning/lib/service/recommendation_effectiveness_evaluator.dart` | Post-recommendation effectiveness evaluator. |
| **Stage 5** | `MODIFY`| `packages/garuda_learning/lib/garuda_learning.dart` | Barrel export of P22 public classes and enums. |
| **Stage 5** | `NEW` | `packages/garuda_learning/test/domain/recommendation_instance_test.dart` | Unit tests for domain entities and validations. |
| **Stage 5** | `NEW` | `packages/garuda_learning/test/service/recommendation_lifecycle_service_test.dart` | Unit tests for lifecycle transitions and event logging. |
| **Stage 6** | `NEW` | `packages/garuda_learning/test/integration/p22_closed_loop_feedback_test.dart` | E2E P21 $\rightarrow$ P22 $\rightarrow$ P19 $\rightarrow$ P18 integration test. |
| **Stage 6** | `NEW` | `packages/garuda_learning/test/safety/p22_educational_safety_test.dart` | Clamping, missing data, and educational safety tests. |
| **Stage 6** | `NEW` | `packages/garuda_learning/test/regression/p17_p22_regression_test.dart` | Full regression test across P17–P21. |

---

## 20. Test Strategy

1. **Unit Testing:**
   - Entity validation constraints (non-empty IDs, score ranges $[0.0, 1.0]$).
   - Deterministic state machine transitions and invalid transition rejections (`StateError`).
   - JSON round-trip serialization and deserialization.
2. **Service & Evaluator Testing:**
   - Accurate calculation of $\Delta_{\text{perf}}$ under varying attempt counts.
   - Deterministic behavior with injected `asOf` timestamps.
   - Zero denominator safety (0 baseline attempts, 0 post attempts).
3. **Educational Safety Testing:**
   - Verification that dismissed recommendations do not degrade learner progress.
   - Verification that metric labeling is non-causal.
4. **Integration & Regression Testing:**
   - End-to-end execution: P21 recommendation generation $\rightarrow$ P22 instance issuance $\rightarrow$ learner acceptance $\rightarrow$ P19 session run $\rightarrow$ P18 attempt recording $\rightarrow$ P22 outcome & effectiveness evaluation.
   - Verification of 100% test pass rate across all existing P17, P18, P19, P20, and P21 test suites.

---

## 21. Acceptance Criteria

- [ ] **AC-1 (Lifecycle State Machine):** `RecommendationInstance` transitions deterministically through valid states (`issued` $\rightarrow$ `viewed` $\rightarrow$ `accepted` $\rightarrow$ `started` $\rightarrow$ `completed`), and throws `StateError` on invalid transitions.
- [ ] **AC-2 (Zero-Coupling Provenance):** `RecommendationSessionLink` establishes bidirectional traceability between `RecommendationInstance` and P19 `LearningSession` with zero edits to P19 files.
- [ ] **AC-3 (Deterministic Ingestion):** Ingesting a P21 `RecommendationQueue` creates corresponding `RecommendationInstance` records with state `issued` and an immutable `RecommendationEvidenceSnapshot`.
- [ ] **AC-4 (Interaction Logging):** All learner interactions (`viewed`, `accepted`, `dismissed`, `deferred`) are recorded with timestamps and structured reasons.
- [ ] **AC-5 (Observed Effectiveness):** `RecommendationEffectivenessEvaluator` calculates $\Delta_{\text{perf}}$ and completion rate without fabricating metrics or crashing on zero attempts.
- [ ] **AC-6 (Time Determinism):** All calculations accept an explicit `DateTime asOf` parameter; zero direct `DateTime.now()` calls in domain logic.
- [ ] **AC-7 (Offline-First Storage):** `InMemoryRecommendationLifecycleRepository` supports full querying, isolation, and defensive copying.
- [ ] **AC-8 (Educational Safety):** Dismissed recommendations never alter learner mastery or progress scores.
- [ ] **AC-9 (Clean Architecture):** Package dependencies remain strictly internal; zero network or LLM dependencies.
- [ ] **AC-10 (Full Regression):** All existing tests in P17 (`curriculum`), P18 (`progress/assessment`), P19 (`session`), P20 (`spaced repetition`), and P21 (`recommendation`) continue passing with 100% success.

---

## 22. Explicit Exclusions

The following capabilities are explicitly out of scope for P22:
- ❌ **No Background Expiration Daemon:** Expiration is evaluated synchronously during query time based on validity windows.
- ❌ **No Recommendation Generation:** P22 does not generate recommendations or recalculate P21 scoring weights.
- ❌ **No Spaced Review Scheduling:** P22 does not schedule SM-2 reviews or write to P20 schedules.
- ❌ **No LLM / Network Dependencies:** P22 is 100% deterministic and offline-first.
- ❌ **No Modification of P19 / P21:** Existing P19 and P21 code remains completely unaltered.

---

## 23. STOP Conditions

Implementation must **STOP immediately** and request Product Owner clarification if:
1. An implementation task requires modifying more than 3 files simultaneously.
2. A change is discovered that would require modifying existing P17, P18, P19, P20, or P21 source code.
3. Any requirement arises to add network calls, cloud services, or non-deterministic ML/LLM models.
4. Existing test suites in P17–P21 fail during verification.

---

## 24. Known Technical Debt

- **In-Memory Store as Default:** While `InMemoryRecommendationLifecycleRepository` satisfies all current offline requirements, future app-level persistence will require a persistent SQLite/Hive adapter implementing `RecommendationLifecycleRepository`.
- **Sync TTL Expiration:** Recommendations remain in state `issued` until explicitly updated or evaluated during a query; no real-time cron operates in the background.

---

## 25. Open Decisions

All 6 research decisions have been resolved:
1. **Provenance:** Resolved $\rightarrow$ Option B (Separate P22 `RecommendationSessionLink`).
2. **Effectiveness Window:** Resolved $\rightarrow$ Default 7 days, configurable range $[1, 30]$ days.
3. **Recommendation Expiration:** Resolved $\rightarrow$ Query-time evaluation against TTL; no background daemon.
4. **Dismissal Reasons:** Resolved $\rightarrow$ Small structured `DismissalReason` enum.
5. **Multi-Objective / Multi-Session:** Resolved $\rightarrow$ 1 primary objective per recommendation; multiple sessions supported per instance.
6. **Recommendation Refresh:** Resolved $\rightarrow$ P21 generates queues; P22 transitions unacted `issued` instances to `superseded`.

---

## 26. Final Recommendation

The P22 architecture is fully aligned with Project TITAN principles, Clean Architecture, and pedagogical safety standards. It closes the feedback loop between recommendation, practice, and assessment while preserving 100% backward compatibility and adhering strictly to the 3-file modification limit.

**Final Verdict:** `P22 IMPLEMENTATION PLAN READY`
