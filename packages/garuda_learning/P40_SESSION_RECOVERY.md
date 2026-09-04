# P40 — Recovery-Aware Adaptive Learning Continuation & Session Resumption

## Architecture Specification (TITAN-KO-040.0 P40)

The **Session Recovery & Adaptive Learning Continuation Layer** provides deterministic, crash-safe persistence and recovery for interrupted adaptive learning sessions across application restarts in Project TITAN.

---

## 1. Architectural Boundaries & Ownership

* **Separation of Concerns**:
  - **P34 / P35**: Session specification (`AdaptivePracticeSessionSpec`) and runtime execution (`PracticeExecutionState`, `AdaptivePracticeExecutionEngine`).
  - **P36**: Practice outcome evidence consolidation (`PracticeOutcomeConsolidator`).
  - **P38**: Conceptual state reconciliation (`AdaptiveLearningStateReconciler`).
  - **P39**: Authoritative learner state persistence and cold-start recovery (`AuthoritativeLearningStateRepository`, `AuthoritativeLearningStateRecoveryService`).
  - **P40**: Resumable session coordinates, checkpoint durability, crash recovery, and adaptive execution continuation (`LearningSessionRecoveryService`, `ResumableAdaptivePracticeCoordinator`).
  - **GARUDA Game is completely out of scope.**
* **Zero Learner-State Duplication**: Checkpoints and resumable session objects do **NOT** duplicate the `AuthoritativeLearnerState` progress map. The authoritative state managed by P39 remains the single source of truth for learner mastery. Checkpoints capture minimal cursor coordinates (`questionIndex`, `completedQuestionIds`, `checkpointRevision`, `authoritativeStateRevision`).
* **Offline-First & Zero External Dependencies**: 100% pure Dart, offline-executable, with zero network sockets or third-party database drivers.

---

## 2. The Complete End-to-End Lifecycle

```text
Learner Starts Session (P35 / P40 Coordinator)
       ↓
Initial Checkpoint Saved (chkRev: 1, cursor: 0)
       ↓
Question Attempt Submitted (P35 Engine)
       ↓
Practice Outcome Consolidated (P36 Consolidator)
       ↓
Learning State Update Proposed (P37 Proposer)
       ↓
State Reconciled with Authoritative State (P38 Reconciler)
       ↓
Authoritative State Atomically Persisted (P39 Repository, rev N + 1)
       ↓
Session Checkpoint Atomically Persisted (P40 Repository, chkRev M + 1, cursor + 1)
       ↓
[APPLICATION CRASH / RESTART OCCURS]
       ↓
Session Recovery Service Loads Checkpoint & Authoritative State (P40 / P39)
       ↓
Execution State Reconstructed at First Uncompleted Question Cursor
       ↓
Adaptive Practice Continues Without Repeating Answered Questions
       ↓
Final Question Answered → Session Finalized (isCompleted: true)
```

---

## 3. Session Lifecycle State Machine (`ResumableSessionStatus`)

```text
       ┌───────────┐
       │  created  │
       └─────┬─────┘
             │ (start)
             ▼
       ┌───────────┐
  ┌───►│  active   │◄─────────┐
  │    └─────┬─────┘          │
  │ (resume) │ (pause/crash)  │ (resume)
  │          ▼                │
  │    ┌───────────┐          │
  │    │  paused   ├──────────┤
  │    └─────┬─────┘          │
  │          │ (crash)        │
  │          ▼                │
  │    ┌──────────────┐       │
  │    │ interrupted  │       │
  │    └─────┬────────┘       │
  │          │ (verify)       │
  │          ▼                │
  │    ┌──────────────┐       │
  │    │  recoverable ├───────┘
  │    └─────┬────────┘
  │          │ (recover)
  │          ▼
  │    ┌───────────┐
  └────┤  resumed  ├──────────┐
       └─────┬─────┘          │
             │                │
             ▼                ▼
       ┌─────────────────────────┐
       │   TERMINAL STATES       │
       │ completed / abandoned / │
       │         failed          │
       └─────────────────────────┘
```

### Transition Validation Rules:
* `created` $\to$ `active`, `abandoned`, `failed`
* `active` $\to$ `paused`, `interrupted`, `completed`, `abandoned`, `failed`
* `paused` $\to$ `active`, `resumed`, `interrupted`, `abandoned`, `failed`
* `interrupted` $\to$ `recoverable`, `resumed`, `abandoned`, `failed`
* `recoverable` $\to$ `resumed`, `abandoned`, `failed`
* `resumed` $\to$ `active`, `paused`, `interrupted`, `completed`, `abandoned`, `failed`
* Terminal states (`completed`, `abandoned`, `failed`) forbid all outgoing transitions.

---

## 4. Checkpoint Contract (`SessionCheckpoint`)

Persisted checkpoints contain minimal required coordinates:

| Field | Type | Description |
|---|---|---|
| `schemaVersion` | `int` | Checkpoint schema version (active: `1`). |
| `checkpointRevision` | `int` | Monotonic sequence number ($\ge 1$). |
| `authoritativeStateRevision` | `int` | Associated `AuthoritativeLearnerState` revision ($\ge 1$). |
| `sessionId` | `String` | Unique session identifier. |
| `learnerId` | `String` | Normalized learner identifier. |
| `examId` | `String` | Normalized lowercase exam identifier. |
| `questionIndex` | `int` | 0-based cursor of next question to present ($\ge 0$). |
| `completedQuestionIds` | `List<String>` | Deterministically ordered completed question IDs. |
| `activeObjectiveId` | `String` | Primary active learning objective. |
| `timestamp` | `DateTime` | UTC timestamp of checkpoint. |
| `isCompleted` | `bool` | Whether session reached completion. |
| `checksum` | `String` | SHA-256 over canonical JSON representation. |
| `metadata` | `Map<String, dynamic>` | Optional extensible diagnostic metadata. |

---

## 5. Monotonic Revisions & Stale Checkpoint Rejection

The repository (`SessionCheckpointRepository`) enforces strict revision monotonicity:

```text
incoming.checkpointRevision > existing.checkpointRevision
    → ACCEPT: Atomically writes incoming checkpoint.

incoming.checkpointRevision == existing.checkpointRevision
    → IDEMPOTENT: If payload identical, succeeds as no-op.
    → REJECT: If payload differs, throws SessionRecoveryException(staleCheckpoint).

incoming.checkpointRevision < existing.checkpointRevision
    → REJECT: Throws SessionRecoveryException(staleCheckpoint).
```

---

## 6. Recovery Outcomes (`SessionRecoveryResultStatus`)

The `LearningSessionRecoveryService` categorizes recovery into deterministic results:

1. **`coldStart`**: No checkpoint exists for the requested `(learnerId, examId, sessionId)`. Allows fresh session start without corruption errors.
2. **`success`**: Valid checkpoint and matching authoritative learner state recovered. Reconstructs `ResumableLearningSession` at `checkpoint.questionIndex`.
3. **`alreadyCompleted`**: Session was previously completed. Prevents duplicate attempts on finalized sessions.
4. **`corrupt`**: Checkpoint fails cryptographic SHA-256 checksum, or underlying authoritative state is corrupt.
5. **`stale`**: Checkpoint references an authoritative revision higher than currently persisted authoritative state.
6. **`identityMismatch`**: Checkpoint contents do not match requested `learnerId`, `examId`, or `sessionId`.
7. **`incompatibleVersion`**: Schema version $> 1$.
8. **`notRecoverable`**: Session is in abandoned or failed state.

---

## 7. Crash Recovery Verification (Interrupted Session)

When a crash occurs after questions 0, 1, and 2 are answered:
* Memory is completely cleared.
* Persistent repositories retain `authRepo` (rev 4) and `checkpointRepo` (chkRev 4, `questionIndex`: 3).
* On recovery, `reconstructExecutionState` marks questions 0..2 as answered and positions cursor at question index 3.
* Questions 0..2 are **never presented again**.
* Learner answers question 3 and 4, cleanly finalizing session at question index 5, checkpoint revision 6, and authoritative revision 6.

---

## 8. Test Coverage

* **`test/p40_learning_session_recovery_test.dart`**:
  - 25 unit tests covering lifecycle transition matrices, invariant enforcement, deterministic serialization, bitrot detection, repository monotonicity, fault injection, and recovery error scenarios.
* **`test/integration/p40_learning_session_recovery_integration_test.dart`**:
  - Full end-to-end crash simulation and recovery lifecycle.
  - Multi-tenant tenant isolation across learners and examination codes.
* **Regression Safety**:
  - 100% pass rate on all P39 authoritative persistence and reconciliation suites.
