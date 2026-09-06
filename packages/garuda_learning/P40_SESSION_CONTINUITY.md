# P40 — Adaptive Learning Session Continuity & Resumption Specification

## Architecture Specification (TITAN-KO-040.0 P40)

The **Adaptive Learning Session Continuity & Resumption Layer** provides deterministic, crash-safe persistence and recovery for interrupted adaptive learning sessions across application restarts, network drops, and device failures in Project TITAN / QuizForge AI.

---

## 1. Architectural Boundaries & Component Ownership

```
                        Session Orchestration
                                 │
                                 ▼
                     Session Recovery Service
                                 │
                                 ▼
                    Authoritative Learner State
                                 │
                                 ▼
                     Persistence Repositories
                                 │
                ┌────────────────┴────────────────┐
                ▼                                 ▼
   SessionCheckpointRepository     AuthoritativeStateRepository
```

* **Separation of Concerns**:
  - **P34 / P35 (Adaptive Practice Specification & Execution)**: Session specifications (`AdaptivePracticeSessionSpec`) and runtime state machine (`PracticeExecutionState`, `AdaptivePracticeExecutionEngine`).
  - **P36 (Outcome Consolidation)**: Aggregates question attempts into verified evidence (`PracticeOutcomeConsolidator`).
  - **P38 (State Reconciliation)**: Reconciles proposals against authoritative progress (`AdaptiveLearningStateReconciler`).
  - **P39 (Authoritative Persistence & Recovery)**: Authoritative single source of truth for learner mastery (`AuthoritativeLearningStateRepository`, `AuthoritativeLearningStateRecoveryService`).
  - **P40 (Session Continuity & Resumption)**: Coordinates crash-resilient checkpoints, validates integrity, restores the exact cursor position, and reconstructs execution state without duplicating progress (`LearningSessionRecoveryService`, `ResumableAdaptivePracticeCoordinator`).
  - **GARUDA Game is completely out of scope.**
* **Zero Learner-State Duplication**: Checkpoints do **NOT** duplicate the `AuthoritativeLearnerState` progress map. The authoritative state managed by P39 remains the sole source of truth for learner competency. Checkpoints track minimal cursor coordinates (`questionIndex`, `completedQuestionIds`, `checkpointRevision`, `authoritativeStateRevision`).
* **Offline-First & Deterministic**: 100% pure Dart, offline-executable, with zero network sockets or third-party database dependencies.

---

## 2. The Complete End-to-End Session Lifecycle

```text
Learner Starts Session (P35 Engine / P40 Coordinator)
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

### Transition Matrix Rules:
* `created` $\to$ `active`, `abandoned`, `failed`
* `active` $\to$ `paused`, `interrupted`, `completed`, `abandoned`, `failed`
* `paused` $\to$ `active`, `resumed`, `interrupted`, `abandoned`, `failed`
* `interrupted` $\to$ `recoverable`, `resumed`, `abandoned`, `failed`
* `recoverable` $\to$ `resumed`, `abandoned`, `failed`
* `resumed` $\to$ `active`, `paused`, `interrupted`, `completed`, `abandoned`, `failed`
* `completed`, `abandoned`, `failed` $\to$ $\emptyset$ (Strictly terminal; no outbound transitions permitted).

---

## 4. Checkpoint Model & Cryptographic Integrity

Each checkpoint is an immutable `SessionCheckpoint` containing:

| Field | Type | Description |
|---|---|---|
| `sessionId` | `String` | Unique session identifier. |
| `learnerId` | `String` | Scoped learner identity. |
| `examId` | `String` | Examination context code (lowercase). |
| `questionIndex` | `int` | 0-based cursor for the next question to be presented. |
| `completedQuestionIds` | `List<String>` | Sequence of question IDs answered and consolidated. |
| `activeObjectiveId` | `String` | The current learning objective frontier. |
| `checkpointRevision` | `int` | Monotonic revision number ($\ge 1$). |
| `authoritativeStateRevision` | `int` | Linked P39 learner state revision ($\ge 1$). |
| `isCompleted` | `bool` | Whether all questions in the session spec are completed. |
| `checksum` | `String` | Hex-encoded SHA-256 hash computed over canonical payload. |
| `schemaVersion` | `int` | Version identifier (currently `1`). |
| `timestamp` | `DateTime` | UTC timestamp of checkpoint generation. |

### Canonical Checksum Calculation
The checksum is generated deterministically over canonical JSON fields:
```dart
final canonical = {
  'authoritativeStateRevision': authoritativeStateRevision,
  'checkpointRevision': checkpointRevision,
  'completedQuestionIds': completedQuestionIds,
  'examId': examId,
  'isCompleted': isCompleted,
  'learnerId': learnerId,
  'questionIndex': questionIndex,
  'schemaVersion': schemaVersion,
  'sessionId': sessionId,
};
final payloadBytes = utf8.encode(json.encode(canonical));
final calculatedChecksum = sha256.convert(payloadBytes).toString();
```

---

## 5. Recovery Algorithm

```text
                                [recoverSession]
                                       │
                    ┌──────────────────┴──────────────────┐
                    ▼                                     ▼
        Check Checkpoint Exists?              Check Authoritative State?
                    │                                     │
           NO ──────┴──────► return coldStart             │
                    │ YES                                 │
                    ▼                                     │
         Validate Checksum & Schema                       │
                    │                                     │
         FAIL ──────┴──────► return corrupt / incompatible│
                    │ PASS                                │
                    ▼                                     ▼
         Match Tenant & Learner Identities? ──────────────┘
                    │
           NO ──────┴──────► return identityMismatch
                    │ YES
                    ▼
         Check Stale Revision:
         authRev < checkpoint.authRev ?
                    │
          YES ──────┴──────► return stale
                    │ NO
                    ▼
         Is Session Already Completed?
                    │
          YES ──────┴──────► return alreadyCompleted
                    │ NO
                    ▼
         Reconstruct PracticeExecutionState:
         • Completed items (index < cursor) marked answered & skipped=false
         • Current item (index == cursor) presented at resume timestamp
         • Subsequent items (index > cursor) unattempted
                    │
                    ▼
         Produce SessionRecoveryResult.success
```

---

## 6. Idempotency Strategy

1. **Dual-Layer Idempotency**:
   - **Persistence Layer**: Re-saving the exact same checkpoint payload with identical `checkpointRevision` and `checksum` succeeds as an idempotent no-op without creating duplicate entries or throwing errors.
   - **Recovery Layer**: Calling `recoverSession` multiple times sequentially on the same persisted checkpoint returns an identical `SessionRecoveryResult` with the same session state and cursor coordinates.
2. **Duplicate Outcome Prevention**:
   - Answered question IDs are recorded in `completedQuestionIds`.
   - Reconstructed execution state positions the cursor at `questionIndex`, skipping already answered questions.
   - The P38/P39 pipeline uses `processedSessionIds` and monotonic revision checks to ensure duplicate consolidation proposals are rejected.

---

## 7. Failure Handling & Edge Cases

| Failure Mode | Detection Point | Handling / Result |
|---|---|---|
| **Cold Start (No Session)** | Repository lookup returns null | `SessionRecoveryResult.coldStart` |
| **Payload Bitrot / Tampering** | Computed SHA-256 $\neq$ stored checksum | `SessionRecoveryResult.corrupt` (`checksumMismatch`) |
| **Unsupported Schema Version** | Checkpoint `schemaVersion > current` | `SessionRecoveryResult.incompatibleVersion` |
| **Cross-Learner Attack** | Requested `learnerId` $\neq$ checkpoint `learnerId` | `SessionRecoveryResult.identityMismatch` |
| **Cross-Exam Mismatch** | Requested `examId` $\neq$ checkpoint `examId` | `SessionRecoveryResult.identityMismatch` |
| **Stale Write / Out-of-Order Save** | $R_{checkpoint} \le R_{stored}$ | Stale write rejected with `SessionRecoveryErrorCode.staleRevision` |
| **Stale Checkpoint (State Ahead)** | State rev $>$ checkpoint rev | `SessionRecoveryResult.stale` |
| **Completed Session Resumption** | Checkpoint `isCompleted == true` | `SessionRecoveryResult.alreadyCompleted` |
| **Illegal State Machine Transition** | Transition not in legal matrix | Throws typed `SessionRecoveryException` |
| **Underlying Repository IO Fault** | Checkpoint repository throws error | `SessionRecoveryResult.failure` |

---

## 8. Schema Versioning & Forward/Backward Compatibility

* **Current Schema**: Version `1`.
* **Forward Compatibility**: Checkpoints with future schema versions (`schemaVersion > 1`) are safely rejected with `SessionRecoveryResultStatus.incompatibleVersion`.
* **P39 Persistence Compatibility**: P40 integrates seamlessly with P39 `AuthoritativeLearningStateRepository` and `PersistedAuthoritativeLearnerState` v1 schemas.

---

## 9. Multi-Tenant Isolation

Multi-tenant isolation is enforced at all levels:
* **Composite Repository Keys**: Storage indexing uses the composite key:
  $$\text{Key} = \text{tenantId} : \text{learnerId} : \text{examId} : \text{sessionId}$$
* **Isolation Guarantee**: Learner $A$ cannot access, inspect, or resume sessions belonging to Learner $B$, even within the same examination.
* **Exam Guarantee**: A session created for Exam $X$ cannot be resumed under Exam $Y$.

---

## 10. Testing Strategy

The test suite provides complete, end-to-end verification across:
* **P40 Unit Test Suite** (`p40_learning_session_recovery_test.dart`): 25 focused contract tests for lifecycle transitions, domain invariants, checksum verification, monotonic writes, and service orchestration.
* **P40 32-Item Verification Suite** (`p40_session_continuity_test.dart`): Direct 1-to-1 mapping verifying all 32 minimum requirements specified in the project roadmap.
* **P40 Integration Suite** (`p40_learning_session_recovery_integration_test.dart`): End-to-end multi-step practice, crash simulation, recovery, resumption, and completion across tenants.
* **Regression Suites**: Zero regressions across P35, P36, P38, P39, P41, P42, P43, and P44.

---

## 11. Operational Guarantees

1. **Deterministic Reconstruction**: Given the same checkpoint and session specification, `reconstructExecutionState` produces bit-for-bit identical `PracticeExecutionState`.
2. **Zero Historical Evidence Loss**: Every answered question prior to an interruption remains recorded and cannot be overwritten.
3. **Crash Safety**: In the event of process termination, unpersisted transient memory is discarded, and the system cleanly resumes from the last atomic checkpoint.
