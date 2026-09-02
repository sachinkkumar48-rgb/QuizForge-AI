# P38 — Adaptive Learning State Reconciliation Engine

## 1. Executive Summary & Purpose

**P38** implements the deterministic **Adaptive Learning State Reconciliation Engine** within the QuizForge-AI / GARUDA Learning architecture.

Building directly upon the verified **P37 Adaptive Learning Evidence Feedback Loop + Learning-State Update Proposal** milestone (`c9bccddff83d0dd9ba162e6be83b9e3292abd645`), P38 reconciles the learner's existing authoritative state (`AuthoritativeLearnerState`) with evidence-derived proposals (`LearningStateUpdateProposal`), formulating an explainable, deterministic, non-persistent reconciled proposal (`ReconciledLearningStateProposal`).

### Core Architectural Principle: Non-Persistent Reconciliation Proposal
> **"P38 formulates the reconciled learning-state proposal; it never directly persists or mutates authoritative storage. Authoritative persistence remains strictly owned by P19."**

---

## 2. Pipeline Position & Subsystem Ownership

```
P35 Execution Engine
      │
      ▼
P36 Outcome Consolidation (Evidence Bridge)
      │
      ▼
P37 Learning-State Update Proposal (Feedback Loop)
      │
      ▼
┌─────────────────────────────────────────────────────────────┐
│ P38: ADAPTIVE LEARNING STATE RECONCILIATION ENGINE          │
│                                                             │
│ • Validates Base State & Proposal Fingerprints              │
│ • Enforces Strict Multi-Exam & Learner Isolation            │
│ • Detects Session Duplication & Guarantees Idempotency      │
│ • Detects Stale Transient Proposals                         │
│ • Reconciles Objective Progress Against Thresholds          │
│ • Generates Granular Question & Topic Decisions             │
│ • Logs Explainable Conflict Audit Entries                   │
│ • Produces Canonical SHA-256 Fingerprinted Proposal         │
└─────────────────────────────────────────────────────────────┘
      │
      ├───────────────────────┬───────────────────────┐
      ▼                       ▼                       ▼
P19 Persistence         P20 Scheduling          P23 Analytics
(Durable Attempts)      (SM-2 Spaced Repetition) (Longitudinal Decay)
      │                       │                       │
      └───────────────────────┴───────────────────────┘
                              │
                              ▼
                   Future P33/P34 Adaptive Cycle
```

### Strict Subsystem Ownership Matrix

| Subsystem | Responsibilities & Ownership | P38 Strict Boundary |
| :--- | :--- | :--- |
| **P19 Persistence** | Owns SQLite attempt tables, durable database writes, and historical persistence. | **P38 never writes to databases or persists records.** |
| **P20 Spaced Repetition** | Owns SM-2 algorithm, ease factors, review intervals, repetition counts, and next review dates. | **P38 never calculates ease factors or schedules reviews.** |
| **P23 Longitudinal Analytics** | Owns multi-session learning velocity, retention decay curves, and longitudinal weak-spot diagnosis. | **P38 never calculates decay curves or multi-session diagnoses.** |
| **P33 Question Selection** | Owns multi-factor candidate scoring, ranking, and diversity filtering. | **P38 never ranks or selects questions.** |
| **P34 Session Composition** | Owns session structure, difficulty distributions, and pedagogical modes. | **P38 never composes future sessions.** |
| **P35 Practice Execution** | Owns interactive runtime state, answer submissions, skips, and timer pauses. | **P38 never mutates execution state.** |
| **P36 Outcome Consolidation** | Owns consolidating execution events into descriptive performance evidence. | **P38 operates on P37 proposals derived from P36.** |
| **P37 Proposal Producer** | Owns translating observed execution evidence into update proposals. | **P38 consumes P37 proposals as read-only inputs.** |
| **P38 Reconciliation** | **Owns deterministic state reconciliation and decision explanation.** | **Produces proposals only; zero persistence.** |

---

## 3. Reconciliation Semantics & Decision Hierarchy

P38 implements categorical, explainable decisions for each reconciled state dimension:

### 3.1 Decision Taxonomy (`ReconciliationDecision`)
1. **`unchanged`**: Existing state and proposal are equivalent, or proposal has 0 attempts for that dimension.
2. **`accepted`**: Valid new evidence for an objective/question not previously tracked in existing state.
3. **`merged`**: Compatible progress update (e.g. existing 10 attempts + 5 proposed attempts = 15 reconciled attempts; recalculates success rate and achievement status).
4. **`conflict`**: Detected contradiction (e.g. attempt count decrease or ungrounded status regress). Resolved via authoritative state precedence: `authoritative persisted state > transient proposal`.
5. **`stale`**: Proposal was generated against an older base state or proposal timestamp is earlier than authoritative state's last update.
6. **`duplicate`**: Practice session was already incorporated into authoritative state (`hasProcessedSession`); idempotent no-op.
7. **`invalid`**: Malformed or unverified proposal rejected via typed structured error.
8. **`rejected`**: Proposal failed domain constraints.

### 3.2 Authoritative State Precedence Rules
* **Achievement Permanence**: Once an objective achieves `LearnerObjectiveStatus.achieved` in authoritative state, subsequent incorrect practice attempts **never regress** the status back to `inProgress`.
* **Monotonic Attempt Counts**: Reconciled attempt counts must always be $\ge$ prior authoritative attempt counts. Any attempt to decrement attempt counts is resolved by enforcing authoritative counts and logging a `ReconciliationConflict`.
* **Strict Provenance**: Every state mutation records its source proposal ID, session ID, and input fingerprints.

---

## 4. Idempotency & Duplicate Replay Safety

P38 guarantees semantic and mathematical idempotency:
$$\text{reconcile}(S, P) = R_1$$
$$\text{reconcile}(R_1.\text{proposedState}, P) = R_2$$
Where $R_2.\text{overallDecision} = \text{duplicate}$, and $R_2.\text{reconciledProgress} = R_1.\text{reconciledProgress}$.

Re-running the same practice session proposal twice produces zero state drift and zero double-counting of attempts.

---

## 5. Multi-Exam & Learner Isolation

Every reconciliation operation validates strict boundary constraints:
* **Exam Mismatch**: If `authoritativeState.examId != proposal.examId`, reconciliation halts immediately returning `ReconciliationErrorCode.examMismatch`.
* **Learner Mismatch**: If proposal specifies a `learnerId` differing from `authoritativeState.learnerId`, reconciliation halts immediately returning `ReconciliationErrorCode.learnerMismatch`.
* **Fingerprint Diversity**: Overlapping question IDs or topic names in different exams (e.g. UPSC vs BPSC) produce distinct, isolated fingerprints and state proposals.

---

## 6. Cryptographic Determinism & Canonical Hashing

### Deterministic SHA-256 Fingerprint Formula
```
reconciliationId|learnerId|examId|baseStateFingerprint|sourceProposalFingerprint|reconciledAtIso|overallDecision|sortedReconciledProgress|sortedProcessedSessions|sortedObjectiveDecisions|sortedTopicDecisions|questionDecisions
```

### Invariants:
1. **Zero DateTime.now()**: All timestamps are caller-supplied (defaults to `proposal.proposedAt`).
2. **Canonical Map & Set Ordering**: All map keys and set elements are deterministically sorted via `SplayTreeMap` and `SplayTreeSet`.
3. **Immutability**: All collections (`Map`, `List`, `Set`) are deeply unmodifiable.

---

## 7. High-Throughput Performance Benchmarks

Measured on single-core Dart VM in Windows environment:

| Benchmark Scenario | Measured Latency | Engineering Target | Status |
| :--- | :--- | :--- | :--- |
| **1,000 Objectives Reconciliation** | **2 ms** | < 50 ms | **PASS** |
| **1,000 Objectives Fingerprint Generation** | **1 ms** | < 20 ms | **PASS** |
| **10,000 Objectives Reconciliation** | **12 ms** | < 150 ms | **PASS** |
| **10,000 Objectives JSON Serialization** | **22 ms** | < 100 ms | **PASS** |
| **50,000 Objectives Reconciliation** | **68 ms** | < 500 ms | **PASS** |
| **100,000 Objectives Reconciliation** | **148 ms** | < 2,000 ms | **PASS** |
| **Single Reconciliation Average Latency** | **45 µs** | < 1,000 µs (1 ms) | **PASS** |
| **Complexity Scaling (10K to 50K)** | **5.6x** | Linear $O(N)$ | **PASS** |

---

## 8. Comprehensive Test Matrix

### Unit Tests (`packages/garuda_learning/test/p38_adaptive_learning_state_reconciliation_test.dart`)
* **158 Tests across 22 Groups** (100% Passed):
  1. Group 1: Construction & Serialization (8 tests)
  2. Group 2: No-op & Unchanged Scenarios (8 tests)
  3. Group 3: Additive Objective Evidence (8 tests)
  4. Group 4: Compatible Progress Merging (8 tests)
  5. Group 5: Conflicting Update & Authoritative Precedence (8 tests)
  6. Group 6: Stale Proposal Detection (8 tests)
  7. Group 7: Duplicate Evidence & Idempotency (8 tests)
  8. Group 8: Question Reconciliation Decisions (8 tests)
  9. Group 9: Topic Reconciliation Decisions (8 tests)
  10. Group 10: Objective Achievement Threshold Evaluation (8 tests)
  11. Group 11: Multi-Exam Isolation & Cross-Exam Rejection (8 tests)
  12. Group 12: Learner Identity Isolation (8 tests)
  13. Group 13: P19 Boundary Verification (Zero Direct DB Writes) (4 tests)
  14. Group 14: P20 Boundary Verification (Zero SM-2 / Scheduling) (4 tests)
  15. Group 15: P23 Boundary Verification (Descriptive Only) (4 tests)
  16. Group 16: P33/P34 Boundary Verification (Zero Selection / Composition) (4 tests)
  17. Group 17: Immutability & Mutation Safety (6 tests)
  18. Group 18: Determinism & Canonical Ordering (8 tests)
  19. Group 19: Fingerprint Sensitivity & Stability (6 tests)
  20. Group 20: Error Handling & Idempotency (8 tests)
  21. Group 21: High-Throughput Benchmarks (8 tests)
  22. Group 22: Property & Deterministic Replay Tests (10 tests)

### Integration Tests (`test/p38_learning_state_reconciliation_integration_test.dart`)
* **5 Tests** (100% Passed):
  1. Full E2E Pipeline (P30 -> P29 -> P31 -> P32 -> P23 -> P33 -> P34 -> P35 -> P36 -> P37 -> P38).
  2. Multi-Exam Isolation: UPSC and BPSC states and proposals reconcile independently.
  3. Sequential Idempotency: Reconciling twice produces duplicate no-op without state drift.
  4. Conflicting Historical Progress Reconciliation: Preserves achieved status.
  5. Deterministic Pipeline Replay: 10 consecutive full pipeline executions produce identical JSON and SHA-256.

### Full Regression Suite
* **P36–P38 Learning Unit Regression**: 460 / 460 Passed (100%).
* **P32–P35 Learning Unit Regression**: Passed (100%).
* **Root Integration Regression (P29–P38)**: 24 / 24 Passed (100%).
* **GARUDA PYQ Suite**: 144 / 144 Passed (100%).

---

## 9. Known Architectural Limitations & Boundaries

1. **Non-Persistent Proposal**: P38 produces a reconciled learning-state proposal object; durable commitment to SQLite or remote backend tables is strictly owned by P19.
2. **Zero Spaced Repetition Scheduling**: P38 reconciles objective attempt and achievement counts; it never computes SM-2 ease factors, repetition intervals, or next-review due dates (owned by P20).
3. **Session-Level Scope**: P38 reconciles changes originating from a single practice session proposal against current authoritative state; longitudinal forgetting curves and multi-session trend modeling remain owned by P23.
4. **Downstream Cycle Only**: P38 does not select or compose future practice sessions; future sessions consume reconciled state through P33/P34.
