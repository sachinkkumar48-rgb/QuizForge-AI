# P37 — Adaptive Learning Evidence Feedback Loop + Learning-State Update Proposal

## 1. Executive Summary & Purpose

**P37** implements the deterministic **Adaptive Learning Evidence Feedback Loop and Learning-State Update Proposal** layer within the QuizForge-AI / GARUDA Learning architecture.

Building directly upon the verified **P36 Practice Outcome Consolidation** milestone (`526e24bb4711aa0d983e8d8b1660899888947eae`), P37 completes the feedback bridge connecting transient practice execution evidence (`ConsolidatedPracticeOutcome`) to downstream learning systems (P19 Persistence, P20 Spaced Repetition, P23 Longitudinal Analytics, and future P38+ adaptive scheduling).

### Core Philosophy: Evidence Interpretation Without Diagnostic Overreach
> **"P37 interprets observed practice evidence into bounded learning signals and recommendation proposals, but it never claims more than the empirical evidence supports."**

P37 produces a **proposal / evidence transformation** (`LearningStateUpdateProposal`), not an authoritative mutation.

---

## 2. Pipeline Position & Architecture

```
P29 / P30
Question Corpus & Normalization
      │
      ▼
P31
Multi-Exam Historical Intelligence
      │
      ▼
P32
Adaptive Learning Priority Profile
      │
      ▼
P33
Adaptive Question Selection
      │
      ▼
P34
Adaptive Practice Session Composition
      │
      ▼
P35
Adaptive Practice Execution Engine (Runtime State)
      │
      ▼
P36
Practice Outcome Consolidation (Evidence Bridge)
      │
      ▼
┌─────────────────────────────────────────────────────────────┐
│ P37: LEARNING-STATE UPDATE PROPOSAL (Feedback Loop)         │
│                                                             │
│ • Question-Level Evidence Signals                           │
│ • Topic-Level Aggregated Evidence                           │
│ • Objective-Level Aggregated Evidence                       │
│ • Section-Level Aggregated Evidence                         │
│ • Difficulty-Level Aggregated Evidence                      │
│ • Calibrated Evidence Strength Assessment                   │
│ • Within-Session Trajectory Analysis (Improvement/Decline)  │
│ • Recommended Downstream Learning Action Proposals          │
│ • Canonical SHA-256 Cryptographic Fingerprint               │
└─────────────────────────────────────────────────────────────┘
      │
      ├───────────────────────┬───────────────────────┐
      ▼                       ▼                       ▼
P19 Persistence         P20 Scheduling          P23 Analytics
(Durable Attempts)      (SM-2 Spaced Repetition) (Longitudinal Decay)
```

---

## 3. Strict Subsystem Ownership Boundaries

| System | Role & Ownership | P37 Strict Boundary |
| :--- | :--- | :--- |
| **P19 Persistence** | Owns SQLite attempt tables, durable database writes, and historical persistence. | **P37 never writes to databases or persists records.** |
| **P20 Spaced Repetition** | Owns SM-2 algorithm, ease factors, review intervals, repetition counts, and next review dates. | **P37 never calculates ease factors or schedules reviews.** |
| **P23 Longitudinal Analytics** | Owns multi-session learning velocity, retention decay curves, and longitudinal weak-spot diagnosis. | **P37 never calculates decay curves or multi-session diagnoses.** |
| **P33 Question Selection** | Owns multi-factor candidate scoring, ranking, and diversity filtering. | **P37 never ranks or selects questions.** |
| **P34 Session Composition** | Owns session structure, difficulty distributions, and pedagogical modes. | **P37 never composes future sessions.** |
| **P35 Practice Execution** | Owns interactive runtime state, answer submissions, skips, and timer pauses. | **P37 never mutates execution state.** |
| **P36 Outcome Consolidation** | Owns consolidating execution events into descriptive performance evidence. | **P37 consumes P36 output as pure read-only input.** |
| **P37 Feedback Proposal** | **Owns deriving bounded evidence signals, trajectory patterns, and action proposals.** | Produces proposals only; does not perform mutations. |

---

## 4. Evidence Semantics vs Cognitive/Trait Claims

P37 enforces a strict linguistic and semantic boundary:

| Observed Evidence (Allowed) | Cognitive / Trait Interpretation (Forbidden) |
| :--- | :--- |
| `observedCorrect` (submitted answer matched official key) | `studentHasHighAbility`, `geniusLearner` |
| `observedIncorrect` (submitted answer did not match key) | `studentIsWeak`, `studentHasLowAbility`, `studentWillFail` |
| `observedSkipped` (learner skipped question) | `learnerIsLazy`, `learnerLacksConfidence` |
| `recentExposure` (question presented in session) | `permanentMemoryImprint` |
| `OutcomePattern.improving` (later accuracy > earlier accuracy) | `learnerHasOvercomeCognitiveDeficit` |
| `OutcomePattern.declining` (earlier accuracy > later accuracy) | `learnerSuffersFromMentalFatigue` |
| `EvidenceStrength.none` (0 attempts recorded) | `learnerHasZeroMastery`, `poorPerformance` |
| `ProposedLearningAction.reviewRemediation` (evidence suggests review) | `forceImmediateTestFailure` |

### Mandatory Zero-Evidence & Single-Error Rules
1. **0 Attempts**: Yields `EvidenceStrength.none`, `OutcomePattern.insufficientEvidence`, and `ProposedLearningAction.noAction`. Never interpreted as weakness or failure.
2. **1 Wrong Answer**: Yields `EvidenceStrength.insufficient` and `OutcomePattern.insufficientEvidence`. Never interpreted as systemic learner inability.

---

## 5. Domain Models & Calibrations

### 5.1 Evidence Strength (`EvidenceStrength`)
Evidence strength is strictly calibrated against the volume of observed attempts within the session:
* `none`: 0 attempts (zero observations).
* `insufficient`: Exactly 1 attempt (insufficient for pattern derivation).
* `limited`: Exactly 2 attempts (preliminary trend).
* `moderate`: 3 to 4 attempts (usable empirical evidence).
* `strong`: 5 or more attempts (strong within-session empirical evidence).

### 5.2 Trajectory Pattern Analysis (`OutcomePattern`)
For 3 or more attempts within an entity, chronological trajectory is analyzed across the first half ($A_1$) and second half ($A_2$) of attempted questions:
* `consistentlyCorrect`: 2+ attempts, 100% accuracy.
* `consistentlyIncorrect`: 2+ attempts, 0% accuracy.
* `improving`: $\text{acc}(A_2) \ge \text{acc}(A_1) + 0.35$ and $\text{acc}(A_2) \ge 0.50$.
* `declining`: $\text{acc}(A_1) \ge \text{acc}(A_2) + 0.35$ and $\text{acc}(A_2) < 0.50$.
* `mixed`: 2+ attempts with mixed accuracy without strong directional trend.
* `skippedOnly`: All scheduled questions were skipped.
* `unansweredOnly`: All scheduled questions were unattempted (e.g. abandoned session).

### 5.3 Downstream Action Proposals (`ProposedLearningAction`)
* `noAction`: Zero attempts or baseline unattempted session.
* `retainMastery`: Consistent correctness ($100\%$) or high overall accuracy ($\ge 75\%$).
* `reviewRemediation`: Repeated errors ($0\%$), declining trajectory, or low accuracy ($< 50\%$).
* `reinforceConcept`: Mixed performance ($50\% - 74\%$) or single incorrect answers.
* `continueExposure`: Skipped or introductory syllabus questions.

---

## 6. Multi-Exam Isolation & Provenance

Every `LearningStateUpdateProposal` and child evidence signal preserves:
* Normalized `examId` (e.g. `upsc`, `bpsc`, `ssc`).
* Unique `sessionId` matching P34/P35/P36.
* Full question provenance (`subject`, `topic`, `objectiveIds`, `difficulty`).

Any cross-exam mismatch (e.g. UPSC session containing BPSC question evidence) is rejected deterministically with `LearningProposalErrorCode.examMismatch`.

---

## 7. Cryptographic Determinism & Replay

### Deterministic SHA-256 Fingerprint
P37 computes a 64-character hex SHA-256 fingerprint from a canonical string representation:
```
proposalId|sessionId|examId|learnerId|sessionMode|sessionStatus|sourceFingerprint|proposedAtIso|overallStrength|overallPattern|recommendedAction|total|attempted|correct|incorrect|skipped|unanswered|compRate|acc|scoreRatio|sortedTopicKeys|sortedObjKeys|sortedSecKeys|sortedDiffKeys|questionFingerprints
```

### Invariants:
1. **Zero DateTime.now()**: All timestamps are caller-supplied; defaults to `outcome.completedAt`.
2. **Deterministic Map Sorting**: All signal map keys are strictly ordered alphabetically via `SplayTreeMap`.
3. **Immutability**: All collections (`List`, `Map`) are deeply unmodifiable (`List.unmodifiable`, `Map.unmodifiable`).

---

## 8. High-Throughput Performance Benchmarks

Benchmarked on single-core Dart VM in Windows environment:

| Benchmark Scenario | Measured Latency | Engineering Target | Status |
| :--- | :--- | :--- | :--- |
| **1,000 Outcomes Proposal Generation** | **6 ms** | < 50 ms | **PASS** |
| **1,000 Outcomes Fingerprinting** | **2 ms** | < 20 ms | **PASS** |
| **10,000 Outcomes Proposal Generation** | **28 ms** | < 150 ms | **PASS** |
| **10,000 Outcomes Signals JSON Serialization** | **18 ms** | < 50 ms | **PASS** |
| **50,000 Outcomes Proposal Generation** | **148 ms** | < 500 ms | **PASS** |
| **100,000 Outcomes Proposal Generation** | **312 ms** | < 2,000 ms | **PASS** |
| **Single Proposal Lookup / Derivation Latency** | **122 µs** | < 1,000 µs (1 ms) | **PASS** |
| **Complexity Scaling (10K to 50K)** | **5.28x** | Linear $O(N)$ | **PASS** |

---

## 9. Comprehensive Test Matrix

### Unit Tests (`packages/garuda_learning/test/p37_learning_state_update_proposal_test.dart`)
* **158 Tests across 22 Groups** (100% Passed):
  1. Group 1: Construction & Serialization (8 tests)
  2. Group 2: Session Status Proposals (8 tests)
  3. Group 3: Question-Level Signals (10 tests)
  4. Group 4: Evidence Strength Calibration (6 tests)
  5. Group 5: Repeated Evidence & Consistency (6 tests)
  6. Group 6: Chronological Direction (Improvement & Decline) (8 tests)
  7. Group 7: Topic Signals & Zero-Denominator Safety (8 tests)
  8. Group 8: Objective Signals (8 tests)
  9. Group 9: Section Signals (8 tests)
  10. Group 10: Difficulty Band Signals (8 tests)
  11. Group 11: Multi-Exam Isolation & Cross-Exam Rejection (8 tests)
  12. Group 12: Feedback Action Proposals (8 tests)
  13. Group 13: P20 Boundary Verification (Zero SM-2 / Scheduling) (4 tests)
  14. Group 14: P23 Boundary Verification (Descriptive Only) (4 tests)
  15. Group 15: P33/P34 Boundary Verification (Zero Selection / Composition) (4 tests)
  16. Group 16: Immutability & Mutation Safety (6 tests)
  17. Group 17: Determinism & Canonical Ordering (8 tests)
  18. Group 18: Fingerprint Sensitivity & Stability (6 tests)
  19. Group 19: Error Handling & Idempotency (8 tests)
  20. Group 20: High-Throughput Benchmarks (8 tests)
  21. Group 21: Safety & Non-Fabrication Invariants (6 tests)
  22. Group 22: Property & Deterministic Replay Tests (10 tests)

### Integration Tests (`test/p37_learning_state_update_proposal_integration_test.dart`)
* **5 Tests** (100% Passed):
  1. Full E2E Pipeline (P30 -> P29 -> P31 -> P32 -> P23 -> P33 -> P34 -> P35 -> P36 -> P37).
  2. Multi-Exam Isolation: UPSC and BPSC generate independent proposals and distinct fingerprints.
  3. Directional Trajectory Analysis: Improving vs Declining sessions produce justified distinct proposals.
  4. Abandoned Session Partial Proposal: Compiles partial evidence without penalizing unanswered questions.
  5. Deterministic Pipeline Replay: 10 consecutive full pipeline executions produce identical JSON and SHA-256 fingerprints.

### Full Regression Test Suite
* **P32–P37 Learning Unit Tests**: 641 / 641 Passed (100%).
* **Root Integration Tests (P29–P37)**: 19 / 19 Passed (100%).
* **GARUDA PYQ Tests**: 144 / 144 Passed (100%).

---

## 10. Known Architectural Limitations & Boundaries

1. **Transient Proposal Only**: P37 formulates justified update proposals; it does not commit durable updates to SQLite or remote stores (owned by P19).
2. **Zero Spaced Repetition Scheduling**: P37 exposes `ProposedLearningAction.reviewRemediation` and `retainMastery`; it never modifies SM-2 ease factors or interval schedules (owned by P20).
3. **Session-Bounded Evidence**: P37 analyzes trajectory within an individual practice session; multi-session longitudinal decay and forgetting curves are strictly owned by P23.
4. **Zero Question Ranking**: P37 evaluates completed practice outcomes; it does not select or rank candidates for future sessions (owned by P33/P34).
