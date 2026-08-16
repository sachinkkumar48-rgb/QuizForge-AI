# TITAN-KO-021.0 P21 — Adaptive Recommendation & Learning Path Engine
## Architecture Design & Research Report

**Document Identifier:** TITAN-DESIGN-P21-V1.1  
**Phase:** P21 — Adaptive Recommendation & Learning Path Engine  
**Package:** `garuda_learning`  
**Status:** Approved Architecture Design & Research Report (Precision Updated)  
**Author:** Senior Implementation Engineer / Chief Software Architect  

---

## Executive Summary

This report establishes the complete, authoritative architecture, domain model, mathematical scoring formulation, data flows, integration contracts, safety invariants, and verification strategy for **P21: Adaptive Recommendation & Learning Path Engine** within the `garuda_learning` package of Project TITAN.

P21 operates at the apex of the `garuda_learning` intelligence subsystem, synthesizing learner context from **P17 (Curriculum Framework)**, **P18 (Assessment & Learner Progress Engine)**, **P19 (Learning Session Orchestration)**, and **P20 (Spaced Repetition & Review Scheduling)**. It computes prioritized, evidence-backed, multi-criteria learning recommendations (`LearningRecommendation`) that dynamically optimize a learner's study path without fabricating claims of mastery, without inventing unverified PYQ frequency data, and without relying on non-deterministic AI/LLM execution.

---

## A. Context & Memory Retrieval Summary

Prior to finalizing P21 research and architecture design, context retrieval was executed across existing AgentMemory stores and authoritative project repositories:

1. **AgentMemory Protocol**: MCP tool queries (`memory_smart_search`, `memory_recall`) confirmed zero stale or unverified memories. As mandated by Project TITAN guidelines, repository source code, approved research/design documents, Product Owner rules, and verified tests served as the primary source of truth.
2. **TITAN Architecture & Principles**:
   - Clean Architecture: Domain, Repository, Service, and Data layer isolation.
   - SOLID & Dependency Injection: Explicit contract interfaces and in-memory testable repositories.
   - Modular Design: `garuda_learning` remains 100% offline, self-contained, and decoupled from external cloud databases or non-deterministic LLM services.
   - File Change Limit: Maximum 3 source files modified per implementation task.
3. **P17–P20 Historical Progression**:
   - **P17**: Directed Acyclic Graph (DAG) of Learning Objectives (`LearningObjective`) with explicit prerequisite links (`PrerequisiteRelationship`) and mapped P11–P16 Knowledge Products.
   - **P18**: Evaluation of answer attempts (`QuestionAttempt`, `AttemptResult`), learner profile management (`Learner`), and progress tracking (`LearnerProgress`) with explicit status transitions (`notStarted`, `inProgress`, `achieved`).
   - **P19**: Practice session lifecycle orchestration (`LearningSession`), question selection (`QuestionSelector`), and deterministic sequencing (`QuestionSequencer`).
   - **P20**: SuperMemo 2 (SM-2) spaced repetition review scheduler (`SpacedRepetitionService`), calculating decay intervals ($[1, 180]$ days) and ease factor adjustments ($[1.3, 2.5]$).
4. **Known Lessons & Previous Repair Insights**:
   - **Determinism**: All sorting, scoring, and tie-breaking must be strictly deterministic (tie-breaking by canonical ID `objectiveId`).
   - **Educational Safety**: Avoid unsupported claims of "legal mastery", "exam readiness", or "doctrinal expertise". All recommendation rationales must cite empirical metrics (e.g. "Review overdue by 36 hours", "Blocks 4 downstream objectives", "Domain accuracy is 45.0% across 8 attempts").
   - **Score Clamping**: All individual probability or normalized score factors as well as composite scores must be strictly clamped to $[0.0, 1.0]$.
   - **Cold-Start Protection**: Sparse or unattempted domains must not trigger remediation recommendations due to absence of attempt data.

---

## B. P21 Purpose and Problem Statement

### Problem Statement
While P17 through P20 establish individual components of the learning pipeline—curriculum structure (P17), assessment scoring (P18), session execution (P19), and memory decay scheduling (P20)—a learner currently lacks a unified, intelligent, multi-criteria recommendation engine that tells them **"What should I study next?"**.

- **Without P21**, a learner must manually navigate between reviewing overdue items (P20), fixing weak domains (P18), unblocking prerequisite gaps in the curriculum (P17), or progressing sequentially.
- **Manual selection leads to sub-optimal learning paths**, where critical prerequisite gaps are ignored, memory decay is unaddressed, or high-density practice opportunities are missed.

### Architectural Purpose of P21
P21 introduces an evidence-backed, multi-criteria recommendation engine (`RecommendationEngine` / `AdaptiveRecommendationService`) that:
1. Synthesizes P17 DAG structure, P18 progress metrics, P19 session configurations, and P20 SM-2 review queues.
2. Formulates a multi-factor mathematical scoring model to evaluate every candidate objective $LO_i$.
3. Categorizes recommendations into 5 distinct strategies (`RecommendationType`): `spacedReview`, `prerequisiteGap`, `weakDomainRemediation`, `curriculumAdvance`, and `practiceDensity`.
4. Synthesizes turn-key `SessionConfiguration` objects for direct consumption by P19's `LearningSessionOrchestrator`.
5. Operates 100% offline with zero network latency, zero API costs, and 100% deterministic reproducibility.

---

## C. Existing Architecture Dependencies

P21 sits at the highest abstraction layer within `garuda_learning`, depending directly on P15, P17, P18, P19, and P20:

```
+-----------------------------------------------------------------------------------+
|               P21 Adaptive Recommendation & Learning Path Engine                  |
+-----------------------------------------------------------------------------------+
| Entities:   LearningRecommendation | RecommendationQueue | RecommendationPolicy   |
| Engine:     RecommendationEngine / AdaptiveLearningRecommendationService          |
| Repository: RecommendationRepository | InMemoryRecommendationRepository           |
+-----------------------------------------------------------------------------------+
                                         |
                                         v
+-----------------------------------------------------------------------------------+
| P20 Spaced Repetition Engine (ReviewSchedule, ReviewItem, SpacedRepetitionService)|
| P19 Session Orchestration (SessionConfiguration, LearningSessionOrchestrator)    |
| P18 Learner Progress Engine (LearnerProgress, LearnerObjectiveStatus)             |
| P17 Learning Objectives Framework (LearningObjective, PrerequisiteRelationship)  |
| P15 Question Knowledge Products (LegalQuestion, KnowledgeProductType.question)   |
+-----------------------------------------------------------------------------------+
```

---

## D. Functional Requirements

1. **Multi-Factor Priority Scoring**: Compute a composite priority score $W(LO_i) \in [0.0, 1.0]$ for candidate learning objectives by combining spaced repetition urgency, prerequisite blocker severity, weak domain accuracy gaps (with cold-start guard), curriculum advancement order (clamped), and practice question density.
2. **Recommendation Categorization**: Classify each generated recommendation into one of the 5 canonical types defined in `RecommendationType`:
   - `spacedReview`: Overdue review items from P20 SM-2 queue.
   - `prerequisiteGap`: Unachieved objective blocking downstream active objectives in the P17 DAG.
   - `weakDomainRemediation`: Objective in a domain with average accuracy below threshold ($< 0.60$) and sufficient attempt evidence ($\ge 3$ attempts).
   - `curriculumAdvance`: Next unachieved objective in topological curriculum sequence whose prerequisites are satisfied.
   - `practiceDensity`: Objective mapped to high availability/density of validated P15 practice questions.
3. **Turn-key P19 Integration**: Produce ready-to-run `SessionConfiguration` objects attached to each `LearningRecommendation`, specifying appropriate `QuestionSelectionPolicy` and `QuestionSequencerPolicy`.
4. **Configurable Weighting & Filtering**: Allow callers to pass a `RecommendationPolicy` that customizes priority weights ($w_1, w_2, w_3, w_4, w_5$), maximum recommendation limit $K$, minimum domain attempts threshold, and target domain/unit filters.
5. **Deterministic Ordering**: Sort recommendation queues strictly by `priorityScore` descending, using `objectiveId` string comparison as a stable tie-breaker.
6. **In-Memory Storage & Querying**: Persist recommendations in `InMemoryRecommendationRepository` for fast lookup by learner ID, recommendation type, or objective ID.

---

## E. Domain Model Specification

### 1. `RecommendationType` (Domain Enum)
```dart
/// Categorization of recommendations generated by GARUDA Recommendation Engine (P21).
enum RecommendationType {
  /// Overdue item from P20 Spaced Repetition queue requiring immediate review.
  spacedReview,

  /// Prerequisite gap preventing advancement in higher-level learning objectives.
  prerequisiteGap,

  /// Weak domain performance requiring target practice (accuracy below threshold with >= minDomainAttempts).
  weakDomainRemediation,

  /// Next logical objective in sequence for curriculum progression.
  curriculumAdvance,

  /// High practice question density recommendation based on mapped P15 questions.
  practiceDensity,
}
```

### 2. `LearningRecommendation` (Domain Entity)
Immutable representation of a generated recommendation:
- `recommendationId`: Unique string identifier (e.g., `'rec_lo_fr_art21_1723725000'`).
- `learnerId`: Target learner ID.
- `objectiveId`: P17 target learning objective ID (`LO_i`).
- `type`: `RecommendationType` enum.
- `priorityScore`: Clamped double value $W(LO_i) \in [0.0, 1.0]$.
- `rationale`: Human-readable evidence-backed explanation string.
- `suggestedConfig`: Suggested P19 `SessionConfiguration` for immediate execution.
- `generatedAt`: UTC creation timestamp.
- `metadata`: Immutable key-value metadata map (e.g. `{ 'overdueHours': 36, 'blockedCount': 3, 'domainAttempts': 8, 'domainAccuracy': 0.45 }`).

### 3. `RecommendationPolicy` (Domain Value Object)
Configuration descriptor governing recommendation generation:
- `weightSpacedReview`: Weight $w_1$ (Default: `0.35`).
- `weightPrerequisiteGap`: Weight $w_2$ (Default: `0.25`).
- `weightWeakDomain`: Weight $w_3$ (Default: `0.20`).
- `weightCurriculumAdvance`: Weight $w_4$ (Default: `0.10`).
- `weightPracticeDensity`: Weight $w_5$ (Default: `0.10`).
- `maxRecommendations`: Maximum items to return $K$ (Default: `10`).
- `weakDomainThreshold`: Accuracy threshold below which a domain is flagged weak (Default: `0.60`).
- `minDomainAttempts`: Minimum attempts required in a domain before evaluating accuracy (Default: `3`).
- `targetDomainId`: Optional domain filter string.
- `targetUnitId`: Optional unit filter string.

### 4. `RecommendationQueue` (Aggregate Root)
Sequence of generated recommendations for a learner:
- `learnerId`: Learner ID.
- `items`: Immutable list of `LearningRecommendation` items sorted by `priorityScore` descending.
- `generatedAt`: UTC timestamp.
- `policyUsed`: Copy of `RecommendationPolicy` used for generation.

---

## F. Mathematical Scoring & Multi-Criteria Prioritization Model

For any candidate learning objective $LO_i$, the composite recommendation score $W(LO_i)$ is formulated as:

$$W(LO_i) = \text{clamp}\left( w_1 \cdot U_{\text{review}}(LO_i) + w_2 \cdot S_{\text{prereq}}(LO_i) + w_3 \cdot G_{\text{weak}}(LO_i) + w_4 \cdot P_{\text{curric}}(LO_i) + w_5 \cdot H_{\text{density}}(LO_i), 0.0, 1.0 \right)$$

Where all individual factors are strictly normalized and bounded in $[0.0, 1.0]$:

### 1. Spaced Repetition Urgency Factor $U_{\text{review}}(LO_i)$
Derived from P20 `ReviewItem` overdue duration:
$$U_{\text{review}}(LO_i) = \begin{cases} 
0.0 & \text{if item is not due or not in review schedule} \\
\min\left(1.0, \frac{T_{\text{now}} - T_{\text{due}}}{7 \text{ days}}\right) & \text{if item is due (caps at 7 days overdue)}
\end{cases}$$

### 2. Prerequisite Blocker Severity Factor $S_{\text{prereq}}(LO_i)$
Measures how many unachieved downstream objectives in P17 DAG are blocked by $LO_i$:
$$S_{\text{prereq}}(LO_i) = \begin{cases}
0.0 & \text{if } LO_i \text{ is achieved or blocks 0 objectives} \\
\min\left(1.0, \frac{\text{Count of blocked downstream objectives}}{5}\right) & \text{otherwise}
\end{cases}$$

### 3. Weak Domain Accuracy Gap Factor $G_{\text{weak}}(LO_i)$ (With Cold-Start Guard)
Derived from P18 `LearnerProgress` and domain performance with an explicit guard against sparse or unattempted domains:
$$G_{\text{weak}}(LO_i) = \begin{cases}
0.0 & \text{if } \text{domainAttemptCount} < \text{minDomainAttempts} \ (\text{default: } 3) \\
0.0 & \text{if } \text{domainAccuracy} \ge \text{weakDomainThreshold} \ (\text{default: } 0.60) \\
\text{clamp}\left(\frac{\text{weakDomainThreshold} - \text{domainAccuracy}}{\text{weakDomainThreshold}}, 0.0, 1.0\right) & \text{if } \text{domainAccuracy} < \text{weakDomainThreshold} \text{ and } \text{domainAttemptCount} \ge \text{minDomainAttempts}
\end{cases}$$

> **Cold-Start Rationale**: Unattempted domains have zero attempts ($0 / 0$), which would otherwise evaluate to 0.0 accuracy without a minimum attempt threshold. Requiring $\ge \text{minDomainAttempts}$ ensures that a domain is only classified as weak when empirical assessment evidence warrants targeted remediation.

### 4. Curriculum Advancement Factor $P_{\text{curric}}(LO_i)$ (Strictly Clamped)
Prioritizes the next eligible objective in topological order whose prerequisites are 100% satisfied:
$$P_{\text{curric}}(LO_i) = \begin{cases}
\text{clamp}\left(1.0 - (0.05 \times \text{topologicalLevel}), 0.0, 1.0\right) & \text{if } LO_i \text{ is unachieved and prerequisites are satisfied} \\
0.0 & \text{otherwise}
\end{cases}$$

### 5. Practice Question Density Factor $H_{\text{density}}(LO_i)$
Reflects the density/availability of validated P15 practice questions mapped to the objective in P17:
$$H_{\text{density}}(LO_i) = \text{clamp}\left(\frac{\text{Count of mapped P15 questions}}{10}, 0.0, 1.0\right)$$

> **Scope Clarification**: $H_{\text{density}}$ evaluates mapped P15 Question Knowledge Products from `garuda_case_law`. Actual UPSC Previous Year Question (PYQ) frequency data from `garuda_pyq` is outside the current P21 scope.

---

## G. Application Service Architecture

### `RecommendationEngine` (or `AdaptiveLearningRecommendationService`)

The central service coordinating recommendation computation:

```dart
abstract class RecommendationEngine {
  /// Generates a prioritized recommendation queue for a learner.
  Future<RecommendationQueue> generateRecommendations({
    required String learnerId,
    RecommendationPolicy policy = const RecommendationPolicy(),
    DateTime? asOfDate,
  });

  /// Evaluates a single objective and returns its recommendation score breakdown.
  Future<LearningRecommendation?> evaluateObjective({
    required String learnerId,
    required String objectiveId,
    RecommendationPolicy policy = const RecommendationPolicy(),
    DateTime? asOfDate,
  });
}
```

---

## H. Turn-key Session Configuration Synthesis

For each generated `LearningRecommendation`, P21 synthesizes a P19 `SessionConfiguration` tailored to the recommendation type:

| Recommendation Type | P19 Question Selection Policy | P19 Question Sequencer Policy | Primary Purpose |
|---|---|---|---|
| `spacedReview` | `balanced` | `difficultyAscending` | Reinforce decaying memory traces via SM-2 |
| `prerequisiteGap` | `allObjectiveQuestions` | `curriculumOrder` | Build foundational prerequisite competency |
| `weakDomainRemediation` | `incorrectFocus` | `difficultyAscending` | Remediate low-accuracy topics (< 60% with >= 3 attempts) |
| `curriculumAdvance` | `unattemptedOnly` | `curriculumOrder` | Progress to next unachieved objective |
| `practiceDensity` | `allObjectiveQuestions` | `sequential` | Practice high-density objective question sets |

---

## I. Offline-First & Determinism Invariants

1. **100% Offline Execution**: All calculations are executed in memory using pure Dart data structures. Zero network requests, local DB locks, or cloud dependencies.
2. **Strict Determinism**: For identical inputs (P17 curriculum, P18 progress, P20 schedule, `asOfDate`, and `RecommendationPolicy`), `RecommendationEngine` produces identical output queues.
3. **Deterministic Tie-Breaking**: When two recommendations produce identical `priorityScore` values, tie-breaking is strictly resolved via lexicographical ordering of `objectiveId`.
4. **All Factors Bounded**: Every individual scoring factor ($U_{\text{review}}, S_{\text{prereq}}, G_{\text{weak}}, P_{\text{curric}}, H_{\text{density}}$) and the composite score $W(LO_i)$ are strictly asserted and clamped within $[0.0, 1.0]$.

---

## J. Security, Safety & Educational Invariants

1. **No Fake Mastery Claims**: Recommendations and rationales report empirical metrics (e.g. attempt counts, accuracy percentages, overdue hours). Words like "mastered", "expert", or "exam ready" are strictly prohibited.
2. **Provenance Preservation**: All recommendations preserve mapped P11–P16 Knowledge Product IDs and P17 objective sources.
3. **Zero Secrets in Code/Memory**: Compliance with `AGENTS.md` rules—no API keys, tokens, or private credentials stored or logged.

---

## K. Explicit Exclusions & Non-Goals

The following items are strictly OUT OF SCOPE for P21:
1. **No `garuda_pyq` Dependency**: `garuda_learning` does not add `garuda_pyq` as a package dependency.
2. **No UPSC PYQ Frequency Engine**: P21 does not ingest, calculate, or claim UPSC PYQ appearance frequency.
3. **No New PYQ Mapping Registry**: P21 reuses P17's existing `supportedProducts` mappings to P15 `LegalQuestion` products.
4. **No Modification to P17–P20**: P17, P18, P19, and P20 packages/files remain immutable and unedited during P21.
5. **No UI / Flutter Widgets**: P21 is strictly a headless domain and application service layer.
6. **No Non-Deterministic AI / LLM / Cloud Dependencies**: No OpenAI, Claude, Gemini API, embeddings, or network databases.
7. **No P22 Scope**: P22 work is strictly prohibited until P21 is authorized, implemented, verified, and closed.

---

## L. Package Directory Structure & File Map

Implementation will strictly add files to `packages/garuda_learning/`:

```
packages/garuda_learning/
├── P21_ADAPTIVE_RECOMMENDATION_ENGINE_RESEARCH_AND_DESIGN.md [THIS REPORT]
├── lib/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── recommendation_type.dart           [EXISTING]
│   │   │   ├── learning_recommendation.dart       [NEW]
│   │   │   ├── recommendation_policy.dart         [NEW]
│   │   │   └── recommendation_queue.dart          [NEW]
│   ├── repository/
│   │   ├── recommendation_repository.dart         [NEW]
│   │   └── in_memory_recommendation_repository.dart [NEW]
│   ├── service/
│   │   ├── recommendation_engine.dart             [NEW]
│   │   └── adaptive_recommendation_service.dart   [NEW]
│   └── garuda_learning.dart                       [BARREL UPDATE]
└── test/
    ├── domain/
    │   └── learning_recommendation_test.dart       [NEW]
    ├── service/
    │   └── adaptive_recommendation_service_test.dart [NEW]
    └── integration/
        └── p21_recommendation_integration_test.dart [NEW]
```

---

## M. Static Analysis & Code Quality Rules

1. **Static Analysis**: `flutter analyze` must yield `0` errors and `0` warnings.
2. **Formatting**: `dart format` must be clean across all package files.
3. **Lint Rules**: Strict compliance with `analysis_options.yaml` (strong mode, pedantic checks).

---

## N. Clean Architecture & SOLID Compliance Matrix

| SOLID Principle | P21 Implementation Pattern |
|---|---|
| **Single Responsibility (SRP)** | `LearningRecommendation` handles domain representation; `RecommendationEngine` handles scoring calculation; `RecommendationRepository` handles persistence. |
| **Open/Closed (OCP)** | `RecommendationPolicy` allows extending prioritization behavior without modifying scoring core code. |
| **Liskov Substitution (LSP)** | `InMemoryRecommendationRepository` fully satisfies `RecommendationRepository` interface. |
| **Interface Segregation (ISP)** | Clean, focused service interface `RecommendationEngine`. |
| **Dependency Inversion (DIP)** | Services depend on abstract repositories (`RecommendationRepository`) and frameworks (`CurriculumService`, `SpacedRepetitionService`). |

---

## O. Verification & Test Plan

1. **Unit Tests (`test/domain/`, `test/service/`)**:
   - Priority score calculation correctness across all 5 component factors ($U_{\text{review}}, S_{\text{prereq}}, G_{\text{weak}}, P_{\text{curric}}, H_{\text{density}}$).
   - Cold-start safety: $G_{\text{weak}} = 0.0$ when domain attempts $< 3$.
   - Factor and composite score clamping ($[0.0, 1.0]$).
   - Deterministic tie-breaking by `objectiveId`.
   - Turn-key `SessionConfiguration` generation for all 5 `RecommendationType`s.
2. **Integration Tests (`test/integration/`)**:
   - End-to-end integration across P17 (Curriculum), P18 (Progress), P19 (Session), P20 (SM-2 Review), and P21 (Recommendation).
3. **Full Suite Regression**:
   - Run existing test suites (`garuda_learning`, `garuda_case_law`) to ensure 100% green passing status (1,200+ tests).

---

## P. Acceptance Criteria

1. **P15 Practice Density Factor**: $H_{\text{density}}$ computed strictly from mapped P15 questions without unsupported PYQ frequency claims.
2. **Weak-Domain Cold-Start Guard**: Requires minimum 3 attempts in a domain before $G_{\text{weak}} > 0.0$.
3. **Curriculum Clamping**: $P_{\text{curric}}$ strictly clamped to $[0.0, 1.0]$.
4. **Final Composite Score Clamping**: $W(LO_i)$ clamped to $[0.0, 1.0]$.
5. **Deterministic Ordering & Tie-Breaking**: Stable sorting by priority descending with `objectiveId` tie-breaker.
6. **Missing-Data Safety**: Empty histories, missing schedules, or unattempted objectives do not throw or fabricate metrics.
7. **Clean Architecture Separation**: Strict adherence to Domain, Repository, and Service boundaries.
8. **Zero Regression**: Zero broken tests across the repository.
9. **Static Analysis & Format**: `flutter analyze` and `dart format` clean.

---

## Q. STOP CONDITIONS

> [!IMPORTANT]  
> 1. **Phase Boundary Stop**: STOP immediately after producing and saving this architecture design report (`P21_ADAPTIVE_RECOMMENDATION_ENGINE_RESEARCH_AND_DESIGN.md`).  
> 2. **No Implementation**: Do NOT write production code or execute implementation tasks in this phase turn.  
> 3. **User Approval Gate**: Await explicit user review and approval before proceeding to any future P21 implementation turn.

---

## R. Implementation Sequencing (For Future Implementation Phase)

When authorized by the Product Owner to proceed with P21 implementation in a subsequent turn, tasks will be executed in the following strict order:

1. **Step 1 — Domain Entities**:
   - `LearningRecommendation` entity (`lib/domain/entities/learning_recommendation.dart`).
   - `RecommendationPolicy` value object (`lib/domain/entities/recommendation_policy.dart`).
   - `RecommendationQueue` aggregate root (`lib/domain/entities/recommendation_queue.dart`).
2. **Step 2 — Repository Layer**:
   - `RecommendationRepository` interface (`lib/repository/recommendation_repository.dart`).
   - `InMemoryRecommendationRepository` implementation (`lib/repository/in_memory_recommendation_repository.dart`).
3. **Step 3 — Service Engine**:
   - `RecommendationEngine` interface & `AdaptiveRecommendationService` implementation (`lib/service/adaptive_recommendation_service.dart`).
4. **Step 4 — Package Barrel Export**:
   - Update `lib/garuda_learning.dart` to export P21 domain entities, repositories, and services.
5. **Step 5 — Comprehensive Test Suite**:
   - Unit tests for priority scoring, clamping, tie-breaking, and policy filtering.
   - Integration tests with P17/P18/P19/P20.
6. **Step 6 — Static Analysis & Format Verification**:
   - Execute `flutter analyze` and `dart format`.
   - Run full workspace test suite.

---
*End of P21 Architecture Design & Research Report.*
