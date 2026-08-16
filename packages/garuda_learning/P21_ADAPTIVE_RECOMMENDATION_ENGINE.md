# P21: Adaptive Recommendation & Learning Path Engine

**TITAN Knowledge Package:** `garuda_learning` (TITAN-KO-021.0)  
**Status:** Implemented & Verified  
**Date:** 2026-08-16  
**Clean Architecture Alignment:** Domain / Repository / Service Layers  

---

## 1. Executive Summary & Architectural Role in TITAN

Project TITAN is an enterprise-grade Learning Operating System. **P21 (Adaptive Recommendation & Learning Path Engine)** serves as the high-level intelligence and steering layer of the pedagogical loop, bridging learner progress, spaced review schedules, and structured curriculum graphs to guide aspirants through targeted next-learning actions.

Within the GARUDA pedagogical continuum:
- **P17 (Curriculum & DAG):** Provides the topological structure of learning objectives and strict prerequisite dependency graphs.
- **P18 (Progress Assessment Engine):** Assesses question attempts, verifies objective thresholds, and tracks mastery-neutral progress states (`notStarted`, `inProgress`, `achieved`).
- **P19 (Learning Session Orchestration):** Executes learning sessions using configurable selection and sequencing policies.
- **P20 (Spaced Repetition Review Scheduling):** Implements modified SM-2 scheduling to compute optimal recall intervals and track review urgency.
- **P21 (Adaptive Recommendation Engine):** Synthesizes multi-factor signals ($U_{\text{review}}, S_{\text{prereq}}, G_{\text{weak}}, P_{\text{curric}}, H_{\text{density}}$) into deterministic priority scores ($W(LO_i) \in [0.0, 1.0]$), selects dominant recommendation strategies, and generates turn-key `SessionConfiguration` payloads for direct P19 orchestration.

P21 is strictly **offline-first**, **deterministic**, and contains **zero AI/LLM hallucinations**, **zero non-deterministic sorting**, and **zero external network dependencies**.

---

## 2. Clean Architecture Layer Alignment

```
packages/garuda_learning/
├── lib/
│   ├── domain/
│   │   └── entities/
│   │       ├── recommendation_type.dart           # Canonical recommendation strategy enum
│   │       ├── learning_recommendation.dart       # Immutable recommendation value object
│   │       ├── recommendation_policy.dart         # Tunable weights & safety thresholds
│   │       └── recommendation_queue.dart          # Deterministically ordered queue root
│   ├── repository/
│   │   ├── recommendation_repository.dart         # Abstract persistence interface
│   │   └── in_memory_recommendation_repository.dart # In-memory offline repository
│   ├── service/
│   │   ├── recommendation_engine.dart             # Application service contract
│   │   └── adaptive_recommendation_service.dart   # Deterministic multi-factor scoring engine
│   └── garuda_learning.dart                       # Barrel export
└── test/
    ├── domain/                                    # Entity & policy unit tests
    ├── repository/                                # Repository persistence tests
    ├── service/                                   # Scoring & cold-start unit tests
    ├── safety/                                    # Clamping, determinism & safety tests
    └── integration/                               # End-to-end P17–P21 lifecycle tests
```

### Domain Layer
- **`RecommendationType`**: 5 canonical recommendation strategies:
  1. `spacedReview`: Due/overdue SM-2 review recall.
  2. `prerequisiteGap`: Unachieved objective blocking downstream curriculum nodes.
  3. `weakDomainRemediation`: Remediation for domains with historical accuracy below threshold.
  4. `curriculumAdvance`: Next sequential objective whose prerequisites are fully satisfied.
  5. `practiceDensity`: Active retrieval practice on objectives with high question density.
- **`LearningRecommendation`**: Immutable entity capturing `recommendationId`, `learnerId`, `objectiveId`, `type`, `priorityScore`, `rationale`, `suggestedConfig` (P19 `SessionConfiguration`), `generatedAt`, and granular factor `metadata`.
- **`RecommendationPolicy`**: Value object encapsulating scoring weights ($w_1..w_5$), cold-start sample minimums (`minDomainAttempts = 3`), accuracy threshold (`weakDomainThreshold = 0.60`), target domain/unit filters, and `maxRecommendations = 10`.
- **`RecommendationQueue`**: Aggregate root maintaining a deterministic list of recommendations ordered by `priorityScore` descending with `objectiveId` lexicographical tie-breaking.

### Repository Layer
- **`RecommendationRepository`**: Abstract repository interface providing `saveQueue`, `getQueue`, `getRecommendationsForLearner`, `clearQueue`, and `clearAll`.
- **`InMemoryRecommendationRepository`**: Deterministic, offline-first in-memory implementation with full deep copying.

### Service Layer
- **`RecommendationEngine`**: Abstract service interface specifying `generateRecommendations` and `evaluateObjective`.
- **`AdaptiveRecommendationService`**: Core orchestrator calculating individual normalized factors, applying cold-start safety guards, synthesizing turn-key P19 configurations, and composing evidence-based rationales.

---

## 3. Multi-Factor Priority Scoring Formulation

For any learning objective $LO_i \in \mathcal{O}$, the composite priority score $W(LO_i) \in [0.0, 1.0]$ is defined as:

$$W(LO_i) = \text{clamp}\left( w_1 \cdot U_{\text{review}}(LO_i) + w_2 \cdot S_{\text{prereq}}(LO_i) + w_3 \cdot G_{\text{weak}}(LO_i) + w_4 \cdot P_{\text{curric}}(LO_i) + w_5 \cdot H_{\text{density}}(LO_i), 0.0, 1.0 \right)$$

### Default Weight Configuration
$$\sum_{j=1}^5 w_j = 1.00$$
- $w_1 = 0.35$ (Spaced Review Urgency)
- $w_2 = 0.25$ (Prerequisite Blocker Severity)
- $w_3 = 0.20$ (Weak Domain Accuracy Gap)
- $w_4 = 0.10$ (Curriculum Advancement)
- $w_5 = 0.10$ (Practice Question Density)

---

## 4. Mathematical Factor Formulations & Safety Guards

### Factor 1: Spaced Repetition Review Urgency ($U_{\text{review}}$)
Evaluates urgency based on the learner's P20 SM-2 review schedule:
$$U_{\text{review}}(LO_i) = \begin{cases} 0.0 & \text{if not scheduled or } T_{\text{asOf}} < T_{\text{due}} \\ \text{clamp}\left(\frac{T_{\text{asOf}} - T_{\text{due}}}{7\text{ days}}, 0.0, 1.0\right) & \text{if overdue} \\ 0.10 & \text{if due today } (T_{\text{asOf}} \ge T_{\text{due}} \text{ but overdue } < 1\text{ day}) \end{cases}$$

### Factor 2: Prerequisite Blocker Severity ($S_{\text{prereq}}$)
Measures the number of unachieved downstream learning objectives blocked by $LO_i$:
$$S_{\text{prereq}}(LO_i) = \begin{cases} 0.0 & \text{if } LO_i \text{ is already achieved or } B_{\text{downstream}}(LO_i) = 0 \\ \text{clamp}\left(\frac{B_{\text{downstream}}(LO_i)}{5.0}, 0.0, 1.0\right) & \text{otherwise} \end{cases}$$

### Factor 3: Weak Domain Accuracy Gap ($G_{\text{weak}}$) with Cold-Start Guard
Measures historical weakness across the parent curriculum domain $\mathcal{D}(LO_i)$:
$$G_{\text{weak}}(LO_i) = \begin{cases} 0.0 & \text{if } N_{\text{attempts}}(\mathcal{D}) < \text{minDomainAttempts } (3) \quad \text{[Cold-Start Guard]} \\ 0.0 & \text{if } \text{Acc}(\mathcal{D}) \ge \theta_{\text{weak}} \ (0.60) \\ \text{clamp}\left(\frac{0.60 - \text{Acc}(\mathcal{D})}{0.60}, 0.0, 1.0\right) & \text{if } N_{\text{attempts}}(\mathcal{D}) \ge 3 \text{ and } \text{Acc}(\mathcal{D}) < 0.60 \end{cases}$$

> [!IMPORTANT]
> **Precondition 2 Enforced:** The cold-start guard ensures $G_{\text{weak}} = 0.0$ whenever `domainAttemptCount < 3`, preventing premature penalization on zero/sparse history.

### Factor 4: Curriculum Advancement Factor ($P_{\text{curric}}$)
Incentivizes sequential progression along the P17 curriculum DAG for ready objectives:
$$P_{\text{curric}}(LO_i) = \begin{cases} 0.0 & \text{if } LO_i \text{ is achieved or any prerequisite is unachieved} \\ \text{clamp}\left(1.0 - (0.05 \times \text{topologicalLevel}(LO_i)), 0.0, 1.0\right) & \text{if all prerequisites are achieved} \end{cases}$$

### Factor 5: Practice Question Density ($H_{\text{density}}$)
Evaluates deterministic density of validated P15 practice questions in `garuda_case_law`:
$$H_{\text{density}}(LO_i) = \text{clamp}\left(\frac{N_{\text{P15Questions}}(LO_i)}{10.0}, 0.0, 1.0\right)$$

> [!IMPORTANT]
> **Precondition 1 Enforced:** Evaluated strictly from P15 Question Knowledge Products mapped to $LO_i$ without coupling to `garuda_pyq`.

---

## 5. Turn-Key P19 SessionConfiguration Synthesis

Every `LearningRecommendation` contains a ready-to-run P19 `SessionConfiguration` configured to match the dominant pedagogical strategy:

| Recommendation Strategy | P19 Selection Policy (`QuestionSelectionPolicy`) | P19 Sequencer Policy (`QuestionSequencerPolicy`) | Question Limit | Allow Repeat Attempts |
| :--- | :--- | :--- | :---: | :---: |
| `spacedReview` | `balanced` | `difficultyAscending` | 10 | `true` |
| `prerequisiteGap` | `allObjectiveQuestions` | `curriculumOrder` | 10 | `true` |
| `weakDomainRemediation` | `incorrectFocus` | `difficultyAscending` | 10 | `true` |
| `curriculumAdvance` | `unattemptedOnly` | `curriculumOrder` | 10 | `true` |
| `practiceDensity` | `allObjectiveQuestions` | `sequential` | 10 | `true` |

---

## 6. Empirically-Grounded Rationale Formats

P21 rationales are generated deterministically from verified numerical evidence without LLM synthesis:

- **`spacedReview`**: `"Scheduled review is overdue by {X.X} hours based on SM-2 recall history."`
- **`prerequisiteGap`**: `"Unachieved prerequisite objective blocking {N} downstream learning objective(s) in curriculum."`
- **`weakDomainRemediation`**: `"Domain accuracy is {XX.X}% across {N} attempts (below 60.0% target threshold)."`
- **`curriculumAdvance`**: `"Next sequential curriculum objective with all prerequisite requirements satisfied."`
- **`practiceDensity`**: `"Objective has {N} validated practice question(s) available for active retrieval practice."`

---

## 7. Architectural Safety Invariants

1. **Strict Clamping $[0.0, 1.0]$:** All factor scores ($U_{\text{review}}, S_{\text{prereq}}, G_{\text{weak}}, P_{\text{curric}}, H_{\text{density}}$) and composite score $W(LO_i)$ are strictly clamped.
2. **Deterministic Queue Ordering:** Recommendations are sorted strictly by `priorityScore` descending, with `objectiveId` ascending as a deterministic tie-breaker.
3. **Cold-Start Resilience:** Sparse learner histories default cleanly to curriculum advance or practice density without crashes or divide-by-zero errors.
4. **No Direct Learner State Mutation:** P21 generates recommendation recommendations; it never mutates learner progress or SM-2 schedules directly.
5. **Offline-First & Zero AI Hallucinations:** No cloud or LLM dependencies. All calculations execute locally on device.
