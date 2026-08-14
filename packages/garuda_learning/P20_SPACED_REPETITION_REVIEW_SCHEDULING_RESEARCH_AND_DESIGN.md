# TITAN-KO-020.0 P20 — Spaced Repetition & Review Scheduling Engine
## Architecture Design & Research Report

**Document Identifier:** TITAN-DESIGN-P20-V1.0  
**Phase:** P20 — Spaced Repetition & Review Scheduling  
**Package:** `garuda_learning`  
**Status:** Approved Architecture Design & Research Report  
**Author:** Senior Implementation Engineer / Chief Software Architect  

---

## Executive Summary

This report establishes the complete, authoritative architecture, domain model, mathematical foundation, data flows, integration points, and safety invariants for **P20: Spaced Repetition & Review Scheduling Engine** within `garuda_learning`.

P20 completes the core learning loop of Project TITAN by introducing evidence-backed, deterministic review interval calculations based on the SuperMemo 2 (SM-2) algorithm. It bridges **P18 Learner Progress & Assessment Engine** and **P19 Learning Session Orchestration** by automatically calculating decay-adjusted review schedules for learned objectives without fabricating mastery claims or relying on non-deterministic AI/LLM processing.

---

## A. P20 Purpose and Problem Statement

### Problem Statement
In educational progress tracking, learners suffer from cognitive decay (the Ebbinghaus Forgetting Curve) after initially completing a learning objective.
- **P17 (Curriculum Framework)** defines static learning objectives and prerequisite graphs.
- **P18 (Learner Progress Engine)** measures performance and records objective achievement (`notStarted`, `inProgress`, `achieved`). However, P18 does not calculate future recall decay or schedule review interventions.
- **P19 (Learning Session Orchestration)** sequences questions for active practice sessions, but requires a prioritized queue of overdue review objectives to construct effective revision sessions.

Without P20, learning objective achievement remains static, leading to either premature over-testing or memory loss due to unmanaged review intervals.

### Architectural Purpose of P20
P20 introduces an evidence-backed, deterministic spaced repetition engine that:
1. Translates empirical assessment scores ($[0.0, 1.0]$) into SM-2 performance ratings (`again`, `hard`, `good`, `easy`).
2. Calculates next review intervals ($[1, 180]$ days) and ease factor adjustments ($[1.3, 2.5]$) deterministically.
3. Maintains a per-learner `ReviewSchedule` aggregate root.
4. Generates prioritized review queues sorted by overdue duration for consumption by P19 session orchestration.
5. Operates 100% offline with zero network APIs, external databases, or AI/LLM dependencies.

---

## B. Existing Architecture Dependencies

P20 directly builds upon and integrates with the following established packages and phase capabilities:

```
+-----------------------------------------------------------------------------------+
|               P20 Spaced Repetition & Review Scheduling Engine                    |
+-----------------------------------------------------------------------------------+
| Domain Entities:  ReviewItem | ReviewSchedule | ReviewResult | PerformanceRating |
| Service Engine:   SpacedRepetitionService                                         |
| Repository:       ReviewScheduleRepository | InMemoryReviewScheduleRepository    |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| P19 Learning Session Orchestration (SessionConfiguration, LearningSession)       |
| P18 Learner Progress & Assessment Engine (Learner, AttemptResult, ProgressTracker)|
| P17 Learning Objectives Framework (LearningObjective, CurriculumFramework)        |
| P15 Question Knowledge Product Framework (LegalQuestion, StructuredAnswer)        |
+-----------------------------------------------------------------------------------+
```

1. **P17 Learning Objectives Framework (`garuda_learning`)**:
   - Primary identifier anchor: `LearningObjective.id` (`objectiveId`).
   - Prerequisites and Bloom cognitive taxonomy levels.

2. **P18 Assessment & Learner Progress Engine (`garuda_learning`)**:
   - `Learner` profiles (`learnerId`).
   - `AttemptResult` scores (`score` in $[0.0, 1.0]$) evaluated by P18 evaluators.
   - `LearnerProgress` status transitions (`achieved`).

3. **P19 Learning Session Orchestration (`garuda_learning`)**:
   - `RecommendationType.spacedRepetitionReview`.
   - `QuestionSelectionPolicy` prioritizing review and overdue items.

4. **P15 Question Knowledge Product Framework (`garuda_case_law`)**:
   - Canonical legal questions mapped to P17 learning objectives.

---

## C. Functional Requirements

1. **Deterministic Performance Grade Mapping**: Map normalized assessment scores ($[0.0, 1.0]$) into SM-2 rating grades:
   - Score $< 0.40 \implies \text{again } (q=2)$
   - Score $[0.40, 0.60) \implies \text{hard } (q=3)$
   - Score $[0.60, 0.80) \implies \text{good } (q=4)$
   - Score $\ge 0.80 \implies \text{easy } (q=5)$

2. **SM-2 Ease Factor Adjustment**: Calculate new Ease Factor ($\text{EF}'$) using the standard SM-2 equation:
   $$\text{EF}' = \text{clamp}\left(\text{EF} + \left(0.1 - (5 - q) \times (0.08 + (5 - q) \times 0.02)\right), 1.3, 2.5\right)$$

3. **SM-2 Interval Calculation**: Compute next review interval ($I'$) based on recall rating $q$:
   - For $q < 3$ (`again`): Reset interval to 1 day ($I' = 1$).
   - For $q \ge 3$ on initial review ($I_{\text{prev}} \le 1$ or `reviewCount` = 0):
     - $q=3 \implies I'=1$
     - $q=4 \implies I'=3$
     - $q=5 \implies I'=4$
   - For $q \ge 3$ on subsequent reviews ($I_{\text{prev}} > 1$):
     - Hard ($q=3$): $I' = \text{round}(I_{\text{prev}} \times 1.2)$
     - Good ($q=4$): $I' = \text{round}(I_{\text{prev}} \times \text{EF}')$
     - Easy ($q=5$): $I' = \text{round}(I_{\text{prev}} \times \text{EF}' \times 1.3)$
   - Interval clamping: $I' = \text{clamp}(I', 1, 180)$ days.

4. **Schedule Schedule Persistence & In-Memory Retrieval**:
   - Store and retrieve `ReviewSchedule` aggregates keyed by `learnerId`.
   - Update individual `ReviewItem` entries atomically.

5. **Overdue Item Prioritization**:
   - Retrieve all items where `nextReviewDate <= asOfDate`.
   - Sort by `priorityScore` (overdue hours) descending, using `objectiveId` string order as deterministic tie-breaker.

---

## D. Domain Model Specification

### 1. `PerformanceRating` (Enum)
```dart
enum PerformanceRating {
  again(2, 'Again'),
  hard(3, 'Hard'),
  good(4, 'Good'),
  easy(5, 'Easy');

  final int grade;
  final String label;

  factory PerformanceRating.fromScore(double score);
}
```

### 2. `ReviewItem` (Domain Entity)
- `objectiveId`: Canonical P17 objective string ID.
- `intervalDays`: Scheduled review interval (integer, $[1, 180]$).
- `easeFactor`: SM-2 ease factor (double, $[1.3, 2.5]$).
- `nextReviewDate`: UTC timestamp when review is due.
- `lastReviewed`: Optional UTC timestamp of previous attempt.
- `reviewCount`: Integer count of completed reviews.
- `createdAt`: UTC creation timestamp.

Key Methods:
- `ReviewItem.initial(String objectiveId, {DateTime? now})`
- `bool isDue({DateTime? asOfDate})`
- `double priorityScore({DateTime? asOfDate})`
- `ReviewItem copyWith(...)`
- `Map<String, dynamic> toJson()` / `factory ReviewItem.fromJson(...)`

### 3. `ReviewResult` (Domain Entity)
- `objectiveId`: P17 target objective ID.
- `rating`: `PerformanceRating` enum.
- `assessmentScore`: Double score in range $[0.0, 1.0]$.
- `timestamp`: UTC evaluation timestamp.

### 4. `ReviewSchedule` (Aggregate Root)
- `learnerId`: Submitting learner identifier.
- `_items`: `Map<String, ReviewItem>` mapping objective IDs to review items.
- `createdAt`: UTC creation timestamp.
- `updatedAt`: UTC last modification timestamp.

Key Methods:
- `ReviewItem? getItem(String objectiveId)`
- `ReviewSchedule addItem(ReviewItem item)`
- `ReviewSchedule updateItem(ReviewItem item)`
- `ReviewSchedule removeItem(String objectiveId)`
- `List<ReviewItem> getDueItems({DateTime? asOfDate})`
- `Map<String, dynamic> toJson()` / `factory ReviewSchedule.fromJson(...)`

---

## E. New Abstractions Required

1. **`ReviewScheduleRepository` (Interface)**:
   - Contract for persisting and retrieving `ReviewSchedule` and `ReviewItem` entities.

2. **`InMemoryReviewScheduleRepository` (Implementation)**:
   - Pure in-memory thread-safe repository implementation for 100% offline execution.

3. **`SpacedRepetitionService` (Application Service)**:
   - High-level application service executing SM-2 math, updating schedule repositories, and serving prioritized review queues.

---

## F. Existing Abstractions & Services Reused

- `Learner` and `AttemptResult` from P18 (`garuda_learning`).
- `LearningObjective` from P17 (`garuda_learning`).
- `RecommendationType` enum from `garuda_learning`.
- Standard Dart `DateTime` and JSON serialization patterns.

---

## G. Data Flow Architecture

```
[P18 Assessment Complete] 
           │
           ▼
[P18 AttemptResult (score: 0.85)]
           │
           ▼
[P20 SpacedRepetitionService.updateAfterReview()]
           │
           ├─► PerformanceRating.fromScore(0.85) => PerformanceRating.easy (q=5)
           ├─► SM-2 Math: EF' = clamp(2.5 + 0.1 - 0 = 2.6 => 2.5)
           ├─► SM-2 Math: I' = round(1 * 2.5 * 1.3) = 3 -> clamped [1, 180] = 3 days
           ├─► nextReviewDate = timestamp + 3 days
           └─► Save updated ReviewItem to ReviewScheduleRepository
           │
           ▼
[P19 Learning Session Orchestrator]
           │
           ├─► Queries SpacedRepetitionService.getDueItems(learnerId)
           └─► Injects overdue objective IDs into practice session queue
```

---

## H. Integration Points with P17, P18, and P19

1. **P17 Integration**:
   - `objectiveId` strictly references valid P17 `LearningObjective` instances.
   - Initial scheduling occurs when a learner completes an objective in P17 curriculum order.

2. **P18 Integration**:
   - Assessment scores generated by P18 evaluators (`MultipleChoice`, `TrueFalse`, `ShortAnswerKeyword`) feed directly into `SpacedRepetitionService.updateAfterReview()`.
   - Score boundaries map deterministically to rating grades.

3. **P19 Integration**:
   - P19 `QuestionSelector` calls `SpacedRepetitionService.getDueItems()` when assembling revision sessions.
   - Recommended due items populate `RecommendationType.spacedRepetitionReview`.

---

## I. Persistence & Storage Requirements

- **Abstraction**: `ReviewScheduleRepository` interface isolating domain logic from storage implementation.
- **In-Memory Default**: `InMemoryReviewScheduleRepository` utilizing in-memory Dart `Map<String, ReviewSchedule>`.
- **Serialization Guarantee**: All P20 entities (`ReviewItem`, `ReviewSchedule`) implement `toJson()` and `fromJson()` to support future Hive/SQL persistence without domain model refactoring.

---

## J. Determinism Requirements

1. **Mathematical Determinism**:
   - SM-2 ease factor formula is purely algebraic and deterministic.
   - Score-to-rating mapping (`PerformanceRating.fromScore`) produces identical ratings for identical floating-point scores.
   - Clamping boundaries ($[1.3, 2.5]$ for EF, $[1, 180]$ for interval) are strictly enforced.

2. **Ordering Determinism**:
   - `ReviewSchedule.getDueItems()` sorts by `priorityScore` descending.
   - Equal priority scores break ties deterministically using lexical comparison on `objectiveId`.

3. **Timestamp Determinism**:
   - All `DateTime` instances are coerced to UTC (`toUtc()`).

---

## K. Offline-First Requirements

- 100% in-memory execution.
- Zero network API requests, zero cloud database connections, zero HTTP clients.
- Zero dependency on remote LLM endpoints or external AI services.

---

## L. Safety, Integrity, and Invariant Requirements

1. **Range Clamping Invariants**:
   - `intervalDays` $\in [1, 180]$
   - `easeFactor` $\in [1.3, 2.5]$
   - `score` $\in [0.0, 1.0]$

2. **Collection Invariants**:
   - `ReviewSchedule.addItem()` throws `ArgumentError` if `objectiveId` already exists.
   - `ReviewSchedule.items` returns an unmodifiable map view (`Map.unmodifiable`).

3. **Legal & Educational Claim Invariants**:
   - P20 schedules review intervals based strictly on empirical recall scores.
   - P20 does NOT make unsupported claims of "legal expertise", "doctrinal mastery", or "exam readiness".

---

## M. Missing-Data Behavior

1. **Unscheduled Objective**:
   - If `updateAfterReview()` is invoked for an objective not yet present in the learner's schedule, P20 automatically initializes it using `ReviewItem.initial(objectiveId)` before applying the review update.

2. **Non-Existent Learner Schedule**:
   - If `getDueItems(learnerId)` is called for a learner with no saved schedule, it returns an empty list (`[]`) rather than throwing an exception.

---

## N. Provenance and Evidence Requirements

- P20 handles scheduling metadata (`objectiveId`, `nextReviewDate`, `intervalDays`, `easeFactor`).
- P20 preserves all legal provenance, statutory citations, case references, and official answer keys established in P3–P15 intact without modification or synthetic extrapolation.

---

## O. Explicit Exclusions / Non-Goals

1. **No Production Implementation Code**: This document is strictly an Architecture Design & Research Report.
2. **No Modifications to P3–P19**: Existing implementations in P3 through P19 remain untouched.
3. **No Phase 21 Work**: P21 (and subsequent phases) are explicitly out of scope.
4. **No UI / Flutter Widgets**: Presentation layer widgets (e.g. Flutter cards, progress bars) are excluded from the core P20 domain engine.
5. **No Network / Cloud Sync**: Remote database sync and cloud API endpoints are excluded.

---

## P. API & Interface Design

### 1. `SpacedRepetitionService` Interface
```dart
class SpacedRepetitionService {
  SpacedRepetitionService({ReviewScheduleRepository? repository});

  Future<ReviewItem> addToSchedule(
    String learnerId,
    String objectiveId, {
    DateTime? now,
  });

  Future<ReviewItem> updateAfterReview({
    required String learnerId,
    required String objectiveId,
    required double assessmentScore,
    PerformanceRating? explicitRating,
    DateTime? timestamp,
  });

  ReviewItem calculateNextState({
    required ReviewItem item,
    required ReviewResult result,
    DateTime? now,
  });

  Future<List<ReviewItem>> getDueItems(
    String learnerId, {
    DateTime? asOf,
  });

  Future<ReviewSchedule?> getSchedule(String learnerId);
}
```

---

## Q. Test Strategy

1. **Unit Tests (SM-2 Math)**:
   - Verify ease factor adjustments for all grades ($q=2, 3, 4, 5$).
   - Verify interval progression for initial vs. subsequent attempts.
   - Verify clamping boundaries for interval ($1$ min, $180$ max) and ease factor ($1.3$ min, $2.5$ max).

2. **Unit Tests (Rating Mapping)**:
   - Test score boundaries ($0.0, 0.39, 0.40, 0.59, 0.60, 0.79, 0.80, 1.00$).

3. **Domain Entity Tests**:
   - Test immutability, `copyWith`, `toJson`, `fromJson`, `operator ==`, and `hashCode`.

4. **Integration & Regression Tests**:
   - Test end-to-end flow from P18 attempt result evaluation to P20 schedule update to P19 due queue extraction.
   - Run full regression suite across `garuda_learning` to ensure 100% green status.

---

## R. Acceptance Criteria

1. **Clean Architecture Separation**: Pure domain entities in `lib/domain/entities`, repository interfaces in `lib/repository`, application services in `lib/service`.
2. **Mathematical Correctness**: 100% adherence to SuperMemo 2 (SM-2) algorithm specifications.
3. **Deterministic Execution**: Zero non-deterministic behavior; identical inputs yield identical schedules.
4. **Static Analysis Compliance**: `flutter analyze` passes with zero issues (`0 warnings`, `0 errors`).
5. **Formatting Compliance**: `dart format` clean across all package files.
6. **Zero Regression**: All existing P17, P18, and P19 test suites continue passing without failure.

---

## S. STOP CONDITIONS

1. **Phase Boundary Stop**: STOP immediately after writing this architecture design report (`P20_SPACED_REPETITION_REVIEW_SCHEDULING_RESEARCH_AND_DESIGN.md`).
2. **No Implementation**: Do NOT write production code or execute implementation tasks in this phase.
3. **No P21 Execution**: Do NOT begin Phase 21 or subsequent phases.
4. **User Review Gate**: Await explicit user approval and next prompt before proceeding to any implementation phase.

---

## T. Implementation Sequencing (For Later Implementation Phase)

When authorized to proceed with P20 implementation in a subsequent turn, work will be executed in the following strict order:

1. **Step 1 — Domain Entities**:
   - `PerformanceRating` enum (`lib/domain/entities/performance_rating.dart`).
   - `ReviewItem` entity (`lib/domain/entities/review_item.dart`).
   - `ReviewResult` entity (`lib/domain/entities/review_result.dart`).
   - `ReviewSchedule` aggregate root (`lib/domain/entities/review_schedule.dart`).

2. **Step 2 — Repository Layer**:
   - `ReviewScheduleRepository` interface (`lib/repository/review_schedule_repository.dart`).
   - `InMemoryReviewScheduleRepository` implementation.

3. **Step 3 — Application Service**:
   - `SpacedRepetitionService` (`lib/service/spaced_repetition_service.dart`).

4. **Step 4 — Barrel Exports & Wiring**:
   - Update `lib/garuda_learning.dart` barrel file to export P20 entities, repositories, and services.

5. **Step 5 — Unit & Integration Tests**:
   - Domain unit tests (`test/domain/review_item_test.dart`).
   - Service unit tests (`test/service/spaced_repetition_service_test.dart`).
   - Regression and integration tests.

6. **Step 6 — Static Analysis & Verification**:
   - Run `flutter analyze` and `dart format`.
   - Run full test suite across workspace.

---
*End of P20 Architecture Design & Research Report.*
