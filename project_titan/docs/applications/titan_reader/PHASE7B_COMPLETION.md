# Phase 7B — Indic OCR Language Pack UI & Download Management

**Document ID**: `TITAN-READER-7B-CMP-001`
**Phase**: `Phase 7B — Indic OCR Language Pack UI & Download Management`
**Baseline Checkpoint**: `aec5a36` (Phase 7A-2 Bilingual Routing)
**Status**: `COMPLETE`
**Language Pack UI**: `READY`
**Download Management Architecture**: `READY`
**Production Hindi Model Status**: `NOT YET INSTALLED (DISTRIBUTION DEFERRED)`

---

## 1. Executive Summary & Objective

Phase 7B implements the complete user-facing management foundation for modular **Indic OCR Language Packs** within **TITAN Reader**, focusing on **Hindi (Devanagari)** as the initial target while establishing a scalable architecture for future Indic languages.

### Core Achievements:
1. **Indic OCR Settings UI (`IndicOcrSettingsDialog`)**: Built a polished Material 3 settings dialog displaying language metadata (Hindi, Bengali, Tamil, Telugu, Kannada, Malayalam, Gujarati, Punjabi, Odia, Urdu), scripts, versions, license badges (e.g. Apache-2.0), download/installed disk sizes, and dynamic state-driven action buttons.
2. **Download & Installation Coordinator (`IndicLanguagePackDownloader`)**: Engine-independent downloader contract orchestrating storage verification, isolated sandbox downloading, cryptographic validation, and atomic promotion into active storage.
3. **Atomic Installation & Rollback**: All package transfers take place inside `.tmp_<packId>_<timestamp>` isolation directories. Failed checksums, cancelled transfers, or corrupt manifests trigger immediate cleanup without ever leaving partial models or corrupting active packs.
4. **Cancellation & Retry Support**: Fully idempotent cancellation stops streams and purges temporary files; retry requests initiate cleanly from zero-state.
5. **Safe Deletion & Session Coordination**: Uninstallation coordinates directly with `IndicOcrSessionManager` to safely dispose any loaded in-memory neural sessions before deleting files from disk.
6. **100% Offline Runtime Guarantee**: Local document recognition continues completely offline without network dependencies. Downloads require explicit user initiation.

---

## 2. Baseline Verification Context

* **Phase 7A-2 Baseline**: `aec5a36` (`feat(reader): add bilingual indic ocr session routing`)
* **Pre-existing Tests**: `745 / 745 PASS (100%)`
* **Analyzer Baseline**: `0 issues`
* **Formatter Baseline**: `clean`

---

## 3. UI Architecture & Language Pack Catalog

```
                    Reader Settings
                           │
                           ▼
                 IndicOcrSettingsDialog
                           │
         ┌─────────────────┴─────────────────┐
         ▼                                   ▼
Storage Usage Banner                Language Pack Catalog
(Installed count & MB)              (10 Indic Languages)
                                             │
                          ┌──────────────────┼──────────────────┐
                          ▼                  ▼                  ▼
                        Hindi             Bengali             Tamil
                     (Devanagari)        (Bengali)           (Tamil)
                     [Available]       [Coming Soon]       [Coming Soon]
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
      [Download]      [Cancel]        [Remove]
```

### 3.1 Indic Catalog Specification
| Language | Script | Code | Version | Size (est.) | License | Initial Status |
|---|---|---|---|---|---|---|
| **Hindi** | Devanagari | `hi` / `Deva` | 1.0.0 | ~9.4 MB | Apache-2.0 | Available / Not Installed |
| **Bengali** | Bengali | `bn` / `Beng` | 1.0.0 | ~9.5 MB | Apache-2.0 | Coming Soon |
| **Tamil** | Tamil | `ta` / `Taml` | 1.0.0 | ~9.3 MB | Apache-2.0 | Coming Soon |
| **Telugu** | Telugu | `te` / `Telu` | 1.0.0 | ~9.3 MB | Apache-2.0 | Coming Soon |
| **Kannada** | Kannada | `kn` / `Knda` | 1.0.0 | ~9.2 MB | Apache-2.0 | Coming Soon |
| **Malayalam** | Malayalam | `ml` / `Mlym` | 1.0.0 | ~9.4 MB | Apache-2.0 | Coming Soon |
| **Gujarati** | Gujarati | `gu` / `Gujr` | 1.0.0 | ~9.1 MB | Apache-2.0 | Coming Soon |
| **Punjabi** | Gurmukhi | `pa` / `Guru` | 1.0.0 | ~9.2 MB | Apache-2.0 | Coming Soon |
| **Odia** | Odia | `or` / `Orya` | 1.0.0 | ~9.2 MB | Apache-2.0 | Coming Soon |
| **Urdu** | Arabic | `ur` / `Arab` | 1.0.0 | ~9.4 MB | Apache-2.0 | Coming Soon |

---

## 4. Download & Installation Security Pipeline

```
[User Taps Download]
        │
        ▼
1. CHECKING
   • Storage quota evaluation (rejects if insufficient space)
        │
        ▼
2. DOWNLOADING
   • Stream bytes into sandboxed temporary directory: `.tmp_<packId>_<timestamp>`
   • Stream cancellation token check on every chunk
        │
        ▼
3. VERIFYING
   • Manifest schema & version verification
   • Pure-Dart FIPS 180-4 SHA-256 validation (`model.onnx`, `dict.txt`)
   • Path traversal defense (blocks `../`, `..\`, absolute/UNC paths)
   • Prohibited extension defense (blocks `.exe`, `.dll`, `.bat`, etc.)
   • On validation failure: Delete temporary sandbox & emit Corrupted
        │
        ▼
4. INSTALLING
   • Atomic rename/move: `.tmp_<packId>_<timestamp>` ➔ `<destinationDirectory>/<packId>`
   • Register verified pack into `IndicLanguagePackManager`
        │
        ▼
5. READY
   • Emit Ready state and update total disk usage
```

---

## 5. Deletion & Active Session Coordination

When a user triggers "Remove Pack":
1. `DefaultIndicLanguagePackDownloader` requests `IndicOcrSessionManager` to locate and dispose any active in-memory session matching `<languageCode>`.
2. Native session runners release tensor memory buffers.
3. Destination directory `<destinationDirectory>/<packId>` is purged from the filesystem.
4. `IndicLanguagePackManager` updates pack status to `notInstalled`.

---

## 6. Security Guarantees & Privacy Boundaries

* **No Automated Network Activity**: Network operations never trigger on app launch or document open; all downloads require explicit user action.
* **No Cloud Telemetry or OCR Uploads**: OCR inference runs strictly on-device. No document images, text, or tokens are sent across the network.
* **Integrity Guard**: Unsigned or modified model files are rejected before installation or session activation.

---

## 7. Automated Test Suite & Coverage

14 automated tests in `test/ocr/indic_pack_ui_download_test.dart`:
1. Catalog contains all 10 planned Indic languages with Hindi first.
2. Hindi pack metadata exposes correct version and Apache-2.0 license.
3. Initial download state is `notInstalled`.
4. Successful download, SHA-256 verification, and atomic installation.
5. Cancellation stops download, cleans temp directory, and emits `cancelled` state.
6. SHA-256 checksum mismatch rejects corrupted download and cleans temp files.
7. Insufficient storage emits `insufficientStorage` state before download begins.
8. Deletion removes pack files and disposes active session.
9. Retry starts from clean temporary state.
10. `IndicOcrSettingsDialog` renders header, storage summary, and catalog items.
11. Security: Path traversal in payload filename is rejected during installation.
12. Security: Dangerous executable extension is rejected during installation.
13. `IndicPackDownloadNotifier` manages state transitions and deletion.
14. `IndicOcrSettingsDialog` reacts dynamically to download state changes.

---

## 8. Limitations & Production Model Status

### 8.1 Status
* **Hindi Pack UI**: `READY`
* **Download Management**: `READY`
* **Production Hindi Model Weights**: `NOT INSTALLED` (External distribution packaging deferred)

---

## 9. Next Engineering Phase

**Phase 7C: Production Indic Model Packaging & Quality Hardening**  
* Scope: Build distribution-ready `.titanpack` artifact bundle for Hindi/Devanagari, perform real-device memory and latency verification, and complete acceptance testing.

---

*Report prepared by Senior Implementation Engineer: Antigravity*  
*Project TITAN — TITAN Reader Engineering Team*  
