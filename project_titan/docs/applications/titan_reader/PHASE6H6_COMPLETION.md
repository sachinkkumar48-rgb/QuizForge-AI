# Phase 6H-6 Completion: Searchable PDF Export from OCR

## 1. Overview
Phase 6H-6 implements on-device Searchable PDF Export for TITAN Reader. Scanned and raster PDF documents processed through on-device OCR inference can be exported as standard ISO 32000-1 searchable PDF derivatives containing an invisible, selectable text layer that maps faithfully to recognized glyph bounds without mutating the original source file.

---

## 2. Key Architecture & Pipeline Design

### 2.1 Searchable PDF Synthesis Architecture
```
                      Original Source PDF (Read-Only)
                                     │
                                     ▼
                        Rendered Page Image & OCR
                                     │
                                     ▼
                            OcrResult (Tokens)
                                     │
                                     ▼
                        PdfSearchableExportService
                                     │
               ┌─────────────────────┴─────────────────────┐
               ▼                                           ▼
   Coordinate Transformation                   Reading Order Sort
   (NormalizedPageRect -> PDF Points)          (Top-to-Bottom / L-to-R)
               │                                           │
               └─────────────────────┬─────────────────────┘
                                     │
                                     ▼
                     Invisible Text Layer (/Contents)
                     BT 3 Tr /F_OCR <size> Tf ... ET
                                     │
                                     ▼
                         Newly Generated PDF Output
                 - Original visual appearance preserved
                 - Invisible text layer for search/selection
                 - Standard Type 1 Helvetica font (/F_OCR)
                 - Source PDF SHA-256 strictly unchanged
```

### 2.2 Key Invariants & Non-Destructive Principles
- **Zero PDF Mutation**: Source PDF files are opened in read-only mode. Before-and-after cryptographic SHA-256 byte comparison validates 100% source invariance.
- **Coordinate Transformation**: Normalized coordinates ($0.0 \dots 1.0$, top-down) are mapped deterministically to native bottom-up PDF point coordinate space with strict bounding box preservation.
- **Invisible Text Layering (ISO 32000-1 §9.3.5)**: Text is injected using rendering mode `3 Tr` ("Neither fill nor stroke text") referencing standard embedded Type 1 `/F_OCR` resources, allowing universal search and selection in any standard PDF reader.
- **Security & Privacy**: 100% offline-first execution in pure Dart; zero cloud uploads, zero background telemetry, and zero logging of sensitive document bytes or recognized text.

---

## 3. Verification & Quality Metrics

- **Total Test Suite**: 688 / 688 tests passing (100% pass rate).
- **Phase 6H-6 Dedicated Tests**: 20 / 20 passing
  - `test/domain/pdf_searchable_export_result_test.dart` (8 tests PASS)
  - `test/services/pdf_searchable_coordinate_transformer_test.dart` (7 tests PASS)
  - `test/services/pdf_searchable_export_service_test.dart` (5 tests PASS)
- **Dart Analyzer**: 0 issues found.
- **Dart Formatter**: Clean across 252 files.
- **Git Diff Check**: Clean.
