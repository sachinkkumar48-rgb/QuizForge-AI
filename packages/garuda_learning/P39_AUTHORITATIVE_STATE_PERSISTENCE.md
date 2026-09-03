# P39 — Authoritative Learning State Persistence & Recovery

## Architecture Specification (TITAN-KO-039.0 P39)

The **Authoritative Learning State Persistence & Recovery Layer** establishes durable, deterministic, and verifiable storage for authoritative learner state (`AuthoritativeLearnerState`) across application restarts in Project TITAN.

---

## 1. State Ownership & Architectural Boundaries

* **Persistence Boundary**: `AuthoritativeLearningStateRepository` defines the contract for loading, saving, and deleting persisted learner state.
* **Deterministic Isolation**: State is keyed strictly by tenant context: `learnerId` and normalized `examId`. Cross-exam and cross-learner mutations are strictly rejected.
* **Zero Runtime Dependencies**: No direct reliance on SQLite, Hive, network sockets, or background daemons. Storage operates on isolated canonical JSON payloads.
* **Separation of Concerns**:
  - P18/P19: Progress tracking models & session execution.
  - P38: Deterministic reconciliation & proposal generation (`AdaptiveLearningStateReconciler`).
  - P39 Persistence & Recovery: Durability, atomicity, revision monotonicity, schema evolution, and restart recovery.
  - **GARUDA Game is completely out of scope.**

---

## 2. Persistence Contract (`PersistedAuthoritativeLearnerState`)

Persisted state contains complete information required to reconstruct `AuthoritativeLearnerState`:

| Field | Type | Description |
|---|---|---|
| `schemaVersion` | `int` | Current schema version (active: `1`). |
| `revision` | `int` | Strictly positive monotonic revision counter (`>= 1`). |
| `learnerId` | `String` | Normalized learner identifier. |
| `examId` | `String` | Normalized lowercase exam identifier. |
| `progressMap` | `Map<String, LearnerProgress>` | Canonical objective progress records, deterministically sorted. |
| `processedSessionIds` | `Set<String>` | Processed practice session IDs for duplicate detection. |
| `lastUpdatedAt` | `DateTime` | UTC timestamp of last authoritative update. |
| `stateFingerprint` | `String` | SHA-256 state fingerprint matching `AuthoritativeLearnerState`. |
| `checksum` | `String` | SHA-256 checksum over canonical serialization payload. |
| `metadata` | `Map<String, dynamic>` | Optional audit and migration metadata. |

---

## 3. Serialization & Strict Deserialization

* **Deterministic Serialization**:
  `toJson()` and `toCanonicalJson()` sort all map keys lexicographically at every level. Identical logical states produce byte-identical canonical JSON and matching SHA-256 checksums.
* **Strict Deserialization (`fromJson` / `fromRawJson`)**:
  Silent substitution or arbitrary default fallback for corrupt required data is **strictly forbidden**. Deserialization validates:
  - Required fields presence (`learnerId`, `examId`, `schemaVersion`, `revision`, `stateFingerprint`, `checksum`, `progressMap`, `processedSessionIds`).
  - Numeric integrity: `attemptCount >= 0`, `0 <= correctCount <= attemptCount`, `0.0 <= successRate <= 1.0`, `revision >= 1`.
  - Enum integrity: `status` must match valid `LearnerObjectiveStatus`.
  - Checksum validation: recomputed canonical checksum must match stored `checksum`.
  - Structural consistency: recomputed state fingerprint must match `stateFingerprint`.
  - Failures throw typed `AuthoritativePersistenceException`.

---

## 4. Revision Semantics & Stale-Write Protection

To prevent an older authoritative state from overwriting a newer one, the repository enforces monotonic revision checks:

```text
incoming.revision > existing.revision
    → ACCEPT: Atomically replaces existing state.

incoming.revision == existing.revision
    → IDEMPOTENT: If payload identical, succeeds as no-op.
    → REJECT: If payload differs, throws staleWrite.

incoming.revision < existing.revision
    → REJECT: Throws AuthoritativePersistenceException(code: staleWrite).
```

---

## 5. Atomicity & Replacement Semantics

* Save operations behave atomically:
  - Serialization, validation, and revision checks occur before mutation.
  - If any failure occurs during save, previous persistent state is preserved untouched (zero partial writes).
  - Successful save replaces previous complete state in its entirety.

---

## 6. Recovery Strategy (`AuthoritativeLearningStateRecoveryService`)

The recovery service categorizes application startup into five deterministic outcomes:

| Case | Scenario | Decision | Behavior |
|---|---|---|---|
| **CASE A** | No persisted state (first launch) | `initialized` | Returns clean initial `AuthoritativeLearnerState` (`revision: 1`). |
| **CASE B** | Valid persisted state | `restored` | Restores exact state matching persisted snapshot. |
| **CASE C** | Corrupted persisted state | `corrupted` | Returns explicit typed error (`corruptedChecksum`, `inconsistentState`, etc.). Never fakes valid state. |
| **CASE D** | Unsupported schema version | `incompatibleSchema` | Returns explicit incompatible schema result for versions > current. |
| **CASE E** | Supported older schema | `migrated` | Migrates legacy schema (e.g. v0 -> v1) via `AuthoritativeSchemaMigrator` and persists upgraded state. |

---

## 7. Relationship to P38 Reconciliation

The integrated flow via `AuthoritativeStatePersistenceCoordinator`:

```text
Persisted State
      ↓ (RecoveryService.recover)
AuthoritativeLearnerState (rev N)
      ↓
P38 AdaptiveLearningStateReconciler.reconcile
      ↓
ReconciledLearningStateProposal
      ↓ (Validation: reject invalid / rejected / duplicates)
AuthoritativeLearnerState (rev N + 1)
      ↓ (Repository.save)
Persisted State (rev N + 1)
```

* Transient proposals never bypass P38 validation.
* Duplicate session submissions produce `isDuplicate: true` with zero additional writes.

---

## 8. Limitations & Non-Goals

* **No Distributed Consensus**: P39 provides single-node / offline-first transactional semantics with optimistic revision checks; it is not a multi-master distributed Raft consensus engine.
* **No Database Driver Ownership**: Physical storage is abstracted via `AuthoritativeLearningStateRepository` (e.g. `InMemoryAuthoritativeLearningStateRepository` in testing and gateway adapters in production).
