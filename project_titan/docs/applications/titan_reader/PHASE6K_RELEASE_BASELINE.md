# TITAN Reader — Phase 6K Release Baseline

**Document ID**: `TITAN-READER-6K-BASE-001`
**Release Identifier**: `TITAN-READER-1.0.0-RC1`
**Phase**: `Phase 6K — Release Freeze, Baseline & Handoff`
**Status**: `RELEASE FROZEN / PRODUCTION CANDIDATE`
**Release Verdict**: `PRODUCTION READY / RC PASSED`
**Baseline Git Commit**: `dda636d`
**Branch**: `sprint-1-polish`

---

## 1. Executive Summary & Environment Baseline

TITAN Reader is the core document reading, learning, language analysis, and non-destructive PDF manipulation engine of **Project TITAN**. This document formally records the exact frozen release baseline for TITAN Reader following successful completion of all Phase 6 sprints (6A through 6J).

### 1.1 SDK & Tooling Environment
* **Flutter SDK**: `3.44.4` (Channel `stable`, revision `ad70ec4617`)
* **Dart SDK**: `3.12.2` (Tools DevTools `2.57.0`)
* **Operating System**: `Windows 11 / x64`
* **Architecture**: Clean Architecture, Modular Monorepo, Dependency Injection, Offline-First

### 1.2 Dependency Baseline
```yaml
dependencies:
  flutter: sdk flutter
  file_picker: ^8.3.7
  flutter_riverpod: ^2.5.1
  go_router: ^13.2.0
  meta: ^1.11.0
  path: ^1.9.0
  pdfrx: ^2.4.7
  titan_core: path ../../packages/titan_core
  titan_domain: path ../../packages/titan_domain
  titan_storage: path ../../packages/titan_storage
  titan_pdf: path ../../packages/titan_pdf

dev_dependencies:
  flutter_test: sdk flutter
  flutter_lints: ^3.0.0
```

---

## 2. Feature Inventory & Capability Classification

Every capability is strictly classified based on verified production code and test evidence:
* **`IMPLEMENTED & VERIFIED`**: Full production implementation with 100% passing tests.
* **`IMPLEMENTED WITH LIMITATIONS`**: Functional in production with defined operational boundaries.
* **`DEFERRED`**: Architecturally planned for subsequent TITAN milestones.
* **`UNSUPPORTED`**: Intentionally out of scope for the current engine.

| Subsystem | Feature / Capability | Classification | Verification Notes |
|---|---|---|---|
| **Document** | PDF File Import & Open | `IMPLEMENTED & VERIFIED` | Opens local files, detects invalid/corrupted PDFs safely. |
| **Document** | High-Performance PDF Rendering | `IMPLEMENTED & VERIFIED` | Powered by `pdfrx` rendering layer with memory management. |
| **Document** | Thumbnail Sidebar & Virtualized Grid | `IMPLEMENTED & VERIFIED` | Lazy thumbnail generation, responsive drawer. |
| **Document** | Outline & Bookmark Navigation | `IMPLEMENTED & VERIFIED` | ISO 32000-1 `/Outlines` tree parsing and hierarchy jumping. |
| **Document** | Reading Position Persistence | `IMPLEMENTED & VERIFIED` | Auto-saves and restores exact page and scroll state. |
| **Text Layer** | Native PDF Text Selection | `IMPLEMENTED & VERIFIED` | Sub-pixel character quad extraction and multi-line selection. |
| **Text Layer** | OCR Fallback for Scanned Pages | `IMPLEMENTED & VERIFIED` | Detects `imageOnly` and recommends OCR pipeline. |
| **Text Layer** | Visual OCR Highlight & Text Overlay | `IMPLEMENTED & VERIFIED` | Renders word/line bounding boxes directly on canvas. |
| **Text Layer** | OCR Search & Coexistence | `IMPLEMENTED & VERIFIED` | Merges native and OCR search matches with deduplication. |
| **Text Layer** | OCR Selection & Clipboard Copy | `IMPLEMENTED & VERIFIED` | Native clipboard integration with provenance headers. |
| **Bridge** | `UnifiedTextContext` Domain Abstraction | `IMPLEMENTED & VERIFIED` | Unifies native and OCR selections for all downstream tools. |
| **Language** | Bundled Offline WordNet Dictionary | `IMPLEMENTED & VERIFIED` | 100% offline lookup across 26 shards, definitions, synonyms. |
| **Language** | Local Rule-Based Grammar Engine | `IMPLEMENTED & VERIFIED` | Offline rule checking (repeated words, capitalization, spacing). |
| **Language** | Storage Vocabulary Repository | `IMPLEMENTED & VERIFIED` | Saves words with page numbers, document IDs, and user notes. |
| **AI Assistant** | Explain / Summarize / Simplify / Key Points | `IMPLEMENTED & VERIFIED` | Converts text context into typed `AIReadingRequest` models. |
| **AI Assistant** | Grounded Document Q&A (Local RAG) | `IMPLEMENTED & VERIFIED` | Token-budget chunk retrieval with page number citations. |
| **Manipulation** | Page Organization (Reorder, Rotate, Delete, Insert) | `IMPLEMENTED & VERIFIED` | ISO 32000-1 AST tree manipulation via atomic writes. |
| **Manipulation** | PDF Merging & Splitting | `IMPLEMENTED & VERIFIED` | Non-destructive multi-file merging and multi-part splitting. |
| **Manipulation** | Native PDF Annotations (Highlight, Underline, FreeText, Ink) | `IMPLEMENTED & VERIFIED` | Full undo/redo stack, non-destructive derivative export. |
| **Manipulation** | Visual Signature Stamping | `IMPLEMENTED & VERIFIED` | Drawn, typed, and image signature stamps onto AST pages. |
| **Manipulation** | Password Protection (AES-128 Encryption) | `IMPLEMENTED & VERIFIED` | User & owner passwords with permission flags. |
| **Manipulation** | AcroForm Interactive Fields (Text, Checkbox, Radio, Dropdown) | `IMPLEMENTED & VERIFIED` | Form parsing, widget overlay, and FDF data serialization. |
| **Manipulation** | Embedded File Attachments | `IMPLEMENTED & VERIFIED` | `/EmbeddedFiles` listing and safe extraction to disk. |
| **Manipulation** | Searchable PDF Export | `IMPLEMENTED & VERIFIED` | Injects invisible text layer (`3 Tr` mode) with rotation matrices. |
| **Manipulation** | Native Platform Printing | `IMPLEMENTED & VERIFIED` | OS print spooling integration (PowerShell `PrintTo`, `lpr`, `lp`). |
| **Security** | Source Document Non-Mutation | `IMPLEMENTED & VERIFIED` | $\text{SHA-256}(\text{source}_{\text{before}}) == \text{SHA-256}(\text{source}_{\text{after}})$. |
| **Security** | Attachment Path Traversal Sanitization | `IMPLEMENTED & VERIFIED` | Strips `..`, validates absolute destination boundaries. |
| **Security** | Zero Attachment Execution | `IMPLEMENTED & VERIFIED` | Strict data extraction only; execution strictly prevented. |
| **OCR Models** | Latin / English OCR Pipeline | `IMPLEMENTED & VERIFIED` | ONNX runtime engine adapter & mock engine for testing. |
| **OCR Models** | Indic Scripts (Devanagari, Tamil, Telugu, Kannada, Bengali) | `DEFERRED` | Model weights deferred to Phase 7 model pack expansion. |
| **Platform** | WebAssembly (Wasm) Engine Support | `DEFERRED` | Flutter Web/Wasm engine packaging scheduled for Sprint 2. |

---

## 3. Architecture & Subsystem Boundaries

```
+-------------------------------------------------------------------------------+
|                              PRESENTATION LAYER                               |
|   ReaderScreen | LibraryScreen | VocabularyScreen | OutlineSidebar | Toolbar  |
|   OcrOverlayLayer | FormOverlayLayer | AIAssistantPanel | DictionaryPanel     |
+-------------------------------------------------------------------------------+
                                      │
                                      ▼
+-------------------------------------------------------------------------------+
|                              APPLICATION SERVICES                             |
|   LanguageServicesBridge | AIReadingService | DictionaryService               |
|   GrammarService | VocabularyService | PdfSearchableExportService             |
|   PdfNativeAnnotationService | PdfAttachmentService | PdfEncryptionService    |
+-------------------------------------------------------------------------------+
                                      │
                                      ▼
+-------------------------------------------------------------------------------+
|                                 DOMAIN LAYER                                  |
|   UnifiedTextContext | OcrResult | OcrTextSelection | PageTextClassification  |
|   DictionaryEntry | VocabularyItem | GrammarCheckResult | PdfDocumentAst      |
+-------------------------------------------------------------------------------+
                                      │
                                      ▼
+-------------------------------------------------------------------------------+
|                            INFRASTRUCTURE / DATA                              |
|   DefaultPdfManipulationEngine | BundledDictionaryDataSource | WordNetIndex   |
|   StorageVocabularyRepository | LocalRuleGrammarEngine | PdfWriter/PdfParser  |
+-------------------------------------------------------------------------------+
```

### 3.1 Local vs. Network Security Boundary
* **100% Local Operations**: PDF parsing, AST transformation, native text selection, OCR preprocessing, OCR inference, OCR search, visual text overlay, dictionary lookups, grammar rule checking, vocabulary persistence, annotation editing, signature stamping, attachment extraction, and searchable PDF export.
* **Configurable AI Boundary**: The AI Reading Assistant operates via configured providers (local Ollama instance, mock provider for offline tests, or configured cloud endpoints). Cloud connections only occur upon explicit user trigger.
* **Zero Telemetry / Zero Logging**: The application contains 0 analytics packages, 0 background telemetry trackers, and 0 print/debug statements that log user content.

---

## 4. Test Baseline & Quality Metrics

* **Dart Analyzer**: `0 issues` (0 errors, 0 warnings, 0 lints)
* **Dart Formatter**: `clean` (254 files verified)
* **Git Diff Check**: `clean` (0 whitespace errors)
* **Total Automated Tests**: **707 / 707 Passing (100% Pass Rate)**

### 4.1 Test Suite Breakdown
1. **Domain Entities & Adapters (`test/domain`)**: 144 tests
2. **Application Services (`test/services`)**: 117 tests
3. **Widgets & Overlays (`test/widgets`)**: 84 tests
4. **Screens & Views (`test/screens`)**: 78 tests
5. **OCR Pipeline & Hardening Corpus (`test/ocr`)**: 49 tests
6. **Data Repositories & Parsers (`test/data`)**: 88 tests
7. **AST Manipulation & PDF Compatibility (`test/manipulation`)**: 120 tests
8. **Navigation & Shell (`test/navigation`)**: 6 tests
9. **End-to-End Integration & RC Acceptance (`test/integration`)**: 21 tests

---

## 5. Known Limitations & Deferred Roadmap

### 5.1 Known Operational Limitations
1. **Encrypted PDF Searchable Export**: Exporting a searchable PDF from a password-protected source is intentionally rejected with `PdfSearchableExportStatus.encrypted` until the user provides decryption credentials.
2. **Rotated Text Flow in Export**: OCR text coordinate transformations support $0^\circ, 90^\circ, 180^\circ, 270^\circ$ page rotations. Non-orthogonal angular skews (e.g. $15^\circ$ hand-held camera tilts) require pre-deskewing prior to AST text layer injection.
3. **OS Printing Spooling**: Native printing delegates to system spoolers (`Start-Process -Verb PrintTo` on Windows, `lpr` on macOS/Linux); printer queue management is deferred to the OS.

### 5.2 Deferred Roadmap (Phase 7+)
* **Phase 7A**: Indic Script ONNX Model Packs (Hindi, Tamil, Telugu, Bengali).
* **Phase 7B**: PDF 2.0 (ISO 32000-2) Advanced Encryption (AES-256 with UTF-8 passwords).
* **Phase 7C**: WebAssembly (WASM) multi-threading web worker support.

---

## 6. Release Sign-Off & Verification Verdict

* **Release Gate**: **PASSED**
* **Production Status**: **RELEASE CANDIDATE FROZEN**
* **Rollback Commit**: `dda636d`

*Prepared by Senior Implementation Engineer: Antigravity*
*Project TITAN — TITAN Reader Architecture Team*
