# Phase 7A-2 — Line-Level Script Router & Multi-Session ONNX Runner

**Document ID**: `TITAN-READER-7A2-CMP-001`
**Phase**: `Phase 7A-2 — Line-Level Script Router & Multi-Session ONNX Runner`
**Baseline Checkpoint**: `8501f24` (Phase 7A-1 Foundation)
**Status**: `COMPLETE`
**Bilingual Indic Script Routing**: `READY`
**Multi-Session Architecture**: `READY`
**Production Hindi Model Status**: `NOT YET INTEGRATED (EXTERNAL ACQUISITION DEFERRED)`

---

## 1. Executive Summary & Objective

Phase 7A-2 delivers the complete execution and orchestration architecture for bilingual **Hindi (Devanagari) + English (Latin)** optical character recognition within **TITAN Reader**.

### Core Achievements:
1. **Line-Level Script Classification**: Built `LineScriptClassifier` and `UnicodeLineScriptClassifier` utilizing deterministic Unicode property code-point ranges to classify lines into `latin`, `devanagari`, `mixed`, or `unknown` scripts with high confidence without neural overhead or network requests.
2. **Deterministic Mixed-Line Policy**: Handled bilingual lines through dominant ratio thresholds (85% dominance threshold for single-script dominance, balanced mixed routing for bilingual lines).
3. **Multi-Session Orchestrator (`IndicOcrSessionManager`)**: Implemented deterministic session key generation (`<lang>-<version>-<format>`), lazy initialization, session reuse, and busy session inference protection.
4. **Monotonic LRU Memory Eviction**: Strict enforcement of maximum 2 active recognition sessions in memory ($\le 65$ MB RAM target envelope) using clock-independent monotonic sequence counters.
5. **Bilingual OCR Routing & Spatial Aggregation (`BilingualOcrRouter`)**: Dispatches Latin lines to English baseline models and Devanagari lines to Hindi model sessions, assembling output into cohesive `OcrBlock`s with deterministic vertical (top-to-bottom) and horizontal (left-to-right) reading order.
6. **Cancellation & Stale Result Protection**: Full preservation of document and page identity tokens to guarantee cancelled or out-of-date document results are discarded safely.
7. **100% Offline Execution & Clean Architecture**: Complete integration with frozen `OcrEngine`, `OcrService`, `UnifiedTextContext`, and `PdfSearchableExportService` abstractions with zero external network calls.

---

## 2. Baseline Verification Context

* **Phase 7A Audit Baseline**: `8195bf0` (`docs(reader): audit indic ocr model expansion`)
* **Phase 7A-1 Foundation Baseline**: `8501f24` (`feat(reader): add indic language pack foundation`)
* **Pre-existing Tests**: `723 / 723 PASS (100%)`
* **Analyzer Baseline**: `0 issues`
* **Formatter Baseline**: `clean`

---

## 3. Script Classification Contract & Implementation

### 3.1 Domain Model (`LineScriptClassification`)
* `LineScript`: Enum with `latin`, `devanagari`, `mixed`, and `unknown`.
* `ScriptClassificationResult`: Immutable result containing `script`, `confidence`, `characterCount`, `scriptCharacterCount`, `dominantRatio`, `dominantScript`, and diagnostic `reason`.

### 3.2 Unicode Script Boundaries
```
Latin Ranges:
  Basic Latin letters:       U+0041..U+005A, U+0061..U+007A
  Latin-1 Supplement:        U+00C0..U+00D6, U+00D8..U+00F6, U+00F8..U+00FF
  Latin Extended-A & B:      U+0100..U+024F

Devanagari Ranges:
  Main Devanagari Block:     U+0900..U+097F (excl. digits U+0966..U+096F and dandas U+0964..U+0965)
  Devanagari Extended:       U+A8E0..U+A8FF
  Vedic Extensions:          U+1CD0..U+1CFF
```

---

## 4. Hindi / Latin Routing Architecture

```
                    Page / Image Input
                            │
                            ▼
                    Line Segmentation
                            │
                            ▼
                 UnicodeLineScriptClassifier
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
          [LATIN]                   [DEVANAGARI]
              │                           │
              ▼                           ▼
        Latin Session               Hindi Session
       (English Default)       (IndicOcrSessionManager)
              │                           │
              └─────────────┬─────────────┘
                            ▼
                   BilingualOcrRouter
              (Reading Order Sort & Blocks)
                            │
                            ▼
                        OcrResult
```

---

## 5. Multi-Session Management & LRU Eviction

### 5.1 Deterministic Session Key
Sessions are keyed as:
`"${pack.languageCode}-${pack.version}-${pack.manifest.modelFormat}"` (e.g. `hi-1.0.0-onnx`).

### 5.2 Concurrency & Eviction Safety
* **Max Active Sessions**: 2 concurrent sessions in RAM.
* **LRU Eviction**: When a 3rd language model is requested, `IndicOcrSessionManager` selects the idle session with the lowest monotonic `accessSequence`.
* **Busy Protection**: Active sessions running inference (`isBusy == true`) are strictly protected from eviction. If all active sessions are currently busy, requests fail gracefully with `OcrErrorCode.engineUnavailable`.
* **Disposal**: Safely invokes `runner.closeSession()` to release native tensor buffers.

---

## 6. Model Verification Pipeline

Every OCR session initialized by `IndicOcrSessionManager` is verified through the Phase 7A-1 pipeline:
1. `IndicLanguagePackManager.validatePackDirectory()`
2. Schema & Version Validation (`IndicPackManifest`)
3. Cryptographic SHA-256 Checksum Validation (`model.onnx` & `dict.txt`)
4. Sandboxed Path Traversal Defense
5. Session instantiation only from verified `IndicLanguagePackStatus.ready` packs.

---

## 7. Bilingual Document Processing & Spatial Aggregation

### 7.1 Reading Order Preservation
Lines recognized across multiple sessions are re-assembled deterministically:
1. Primary sort key: `line.boundingBox.top` (vertical ascending)
2. Secondary sort key: `line.boundingBox.left` (horizontal ascending)

### 7.2 Geometry & Token Provenance
* Word and Line bounding boxes are normalized to standard PDF/Image canvas ratios (`NormalizedPageRect`).
* Confidence scores are assigned per token and aggregated to calculate page-level `averageConfidence`.

---

## 8. Cancellation & Stale Result Protection

* `BilingualOcrRouter.processPageLines()` evaluates `isCancelled` before dispatching lines and between line batches.
* When cancelled, it immediately returns `OcrResult.cancelled(pageNumber: pageNumber)`.
* Operations preserve `documentId` and `pageNumber` context tokens to prevent out-of-date responses from polluting the active document state.

---

## 9. Security & Offline Guarantees

* **Zero Network Traffic**: 100% on-device local execution; zero telemetry or external HTTP API calls.
* **Cryptographic Integrity**: Unsigned/unverified files cannot initialize an `IndicOcrSession`.
* **Sandboxed Path Validation**: Directory traversal (`../`), root paths, and executable payloads are blocked.
* **Privacy Boundary**: OCR content and token strings are kept strictly in memory and are never persisted to unauthorized log sinks.

---

## 10. Automated Test Suite & Coverage

22 comprehensive automated tests in `test/ocr/indic_bilingual_routing_test.dart`:
1. Latin script classification
2. Devanagari script classification
3. Unknown classification (digits, symbols, punctuation, empty text)
4. Mixed-script classification (balanced and dominant lines)
5. Confidence calculation
6. Hindi pack resolution and session initialization
7. Missing Hindi pack structured exception handling
8. Corrupted pack rejection
9. Session reuse and duplicate initialization prevention
10. Monotonic LRU eviction enforcing max 2 sessions
11. Busy session eviction protection
12. Session disposal and cleanup
13. Bilingual OCR routing (Latin $\to$ English, Devanagari $\to$ Hindi)
14. Deterministic reading order sorting
15. Cancellation handling and immediate termination
16. Offline-first execution verification
17. Stale result document/page identity protection
18. Arbitrary unverified model path rejection
19. Disposed session cache purging
20. All-sessions-busy failure handling
21. Empty line candidates handling
22. Missing pack structured `OcrResult.failure`

---

## 11. Production Model Status & Limitations

### 11.1 Status
* **Script Routing**: `READY`
* **Multi-Session Architecture**: `READY`
* **Production Hindi Model Weights**: `NOT INSTALLED` (Deferred to external distribution packaging)

### 11.2 Memory Envelope
* Target incremental RAM: $\le 65$ MB (Enforced via max 2 active sessions limit).

---

## 12. Next Engineering Phase

**Phase 7B: Indic OCR UI Controls & Download Management**
* Scope: Build the user-facing language pack download and status UI in Reader Settings, download progress tracking, and on-demand model unpacker.

---

*Report prepared by Senior Implementation Engineer: Antigravity*
*Project TITAN — TITAN Reader Engineering Team*
