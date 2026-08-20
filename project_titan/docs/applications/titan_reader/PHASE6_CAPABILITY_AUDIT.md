# TITAN Reader — Phase 6 Advanced PDF Capability Audit

## Executive Summary

Phase 5 of TITAN Reader successfully established a multi-provider AI reading assistant on top of the Phase 1–4 foundation (checkpoint `a907593`). The application currently features high-performance PDF rendering, text selection, Reader-managed annotations (highlights, underlines, strikeouts, notes, bookmarks), bundled offline WordNet dictionary, local-first grammar and spelling checks, and contextual AI study tools (summaries, explanations, Q&A, flashcards).

This audit investigates the path toward achieving a **professional personal PDF reader with the broad feature set of Adobe Acrobat Reader** on **Android and Windows**.

### Golden Rule of Phase 6 Architecture
**Do not assume `pdfrx` can implement everything.**
`pdfrx` 2.4.7 is an exceptional display and view engine backed by Google PDFium, but it is strictly read-only. It cannot write binary PDF files, modify page trees, serialize native annotations, fill AcroForms, or execute cryptographic signatures. Therefore, TITAN Reader must adopt a **Multi-Engine Modular Architecture (Option D)** that preserves `pdfrx` for interactive viewing while layering specialized, open-source/permissive modules for document manipulation, form processing, signatures, and on-device OCR.

---

## 1. Current PDF Architecture & Baseline Inspection

### A. Current Stack
* **Viewing Engine**: `pdfrx` ^2.4.7 (MIT, PDFium C++ via Dart FFI).
* **Engine Adapter**: `PdfrxPdfEngine` in `lib/src/pdf/pdfrx_pdf_engine.dart` implements `PdfDocumentEngine` and `PdfViewerHandle` from `lib/src/pdf/pdf_engine_contracts.dart`.
* **Coordinate Model**: Canonical `NormalizedPageRect` (0.0 to 1.0 fraction of page dimensions, top-left origin). The adapter converts between PDFium coordinates (bottom-left origin, Y-up) and canonical space at selection capture and overlay paint time.
* **Storage & Persistence**: `StorageService` (`titan_storage`) with namespaced storage keys (`titan.reader.*`).
* **Document Model**: `ReaderDocument` entity with metadata (size, page count, added timestamp, favorites, reading position).

### B. Current Architectural Boundaries
* **Engine Isolation**: `pdfrx` is imported exclusively inside `lib/src/pdf/pdfrx_pdf_engine.dart`. All screens, services, and widgets interact only with abstract contracts.
* **Reader-Managed vs PDF-Native**: Annotations, bookmarks, notes, dictionary lookups, grammar corrections, and AI conversations are stored in TITAN local storage and painted via `pagePaintCallbacks`. The source PDF byte stream is never altered.

---

## 2. Feature Master Matrix: Adobe Acrobat Parity Audit

### Legend
* **Status**: ✅ COMPLETE · 🟡 PARTIAL · ⏳ PLANNED (Phase 6) · ❌ NOT FEASIBLE / OUT OF SCOPE
* **Priority**: **P0** (Essential) · **P1** (High Value) · **P2** (Advanced) · **P3** (Optional / Future)

---

### A. Core PDF Viewing

| Feature | Status | Engine Support | Implementation Strategy | Android | Windows | Priority | Recommendation |
| ------- | ------ | -------------- | ----------------------- | ------- | ------- | -------- | -------------- |
| Open / Close PDF | ✅ COMPLETE | `pdfrx` (PDFium) | `PdfViewer.file` | ✅ Native | ✅ Native | Core | Retain |
| Recent Documents | ✅ COMPLETE | TITAN Storage | `ReadingHistoryService` | ✅ Native | ✅ Native | Core | Retain |
| Document Library | ✅ COMPLETE | TITAN Storage | `DocumentLibraryRepository` | ✅ Native | ✅ Native | Core | Retain |
| Single Page View | 🟡 PARTIAL | `pdfrx` | Custom layout parameters | ✅ Supported | ✅ Supported | P1 | Add discrete page view mode |
| Continuous Scroll | ✅ COMPLETE | `pdfrx` | Default vertical scroll | ✅ Native | ✅ Native | Core | Retain |
| Facing Pages (Two-Up) | ⏳ PLANNED | `pdfrx` / Canvas | Layout delegate for dual page rendering | ✅ Feasible | ✅ Feasible | P2 | Add desktop two-up mode |
| Cover Page Mode | ⏳ PLANNED | `pdfrx` | Two-up with single first page offset | ✅ Feasible | ✅ Feasible | P2 | Pair with Facing Pages |
| Fit Page / Fit Width | ✅ COMPLETE | `pdfrx` | `calcMatrixForFit` / `calcMatrixFitWidthForPage` | ✅ Native | ✅ Native | Core | Retain |
| Fit Height | ⏳ PLANNED | `pdfrx` | Calculate viewport aspect ratio matrix | ✅ Feasible | ✅ Feasible | P1 | Implement in viewer handle |
| Custom Zoom | ✅ COMPLETE | `pdfrx` | Multi-touch pinch & Ctrl+Wheel | ✅ Native | ✅ Native | Core | Retain |
| Presentation Rotation | ✅ COMPLETE | Flutter Box | `RotatedBox` presentation layer | ✅ Native | ✅ Native | Core | Retain |
| Full Screen Mode | ⏳ PLANNED | Flutter / Win32 | Hide system appbars and titlebars | ✅ Supported | ✅ Supported | P1 | Add toggle in top toolbar |
| Dark / Night Mode | ✅ COMPLETE | `ReaderTheme` | Inverted background & PDF canvas shader | ✅ Native | ✅ Native | Core | Retain |
| Page Navigation | ✅ COMPLETE | `pdfrx` | Slider + `goToPage` API | ✅ Native | ✅ Native | Core | Retain |
| Page Thumbnails | ⏳ PLANNED | `pdfrx` page render | Grid of rendered page thumbnail images | ✅ Feasible | ✅ Feasible | P0 | Implement Thumbnail Drawer |
| Text Search & Highlight | ✅ COMPLETE | `pdfrx` | `PdfTextSearcher` + debounce | ✅ Native | ✅ Native | Core | Retain |
| Document Outline | ✅ COMPLETE | `pdfrx` | `loadOutline` + `goToDest` | ✅ Native | ✅ Native | Core | Retain |

---

### B. Text & Selection

| Feature | Status | Engine Support | Implementation Strategy | Android | Windows | Priority | Recommendation |
| ------- | ------ | -------------- | ----------------------- | ------- | ------- | -------- | -------------- |
| Text Selection | ✅ COMPLETE | `pdfrx` | `textSelectionDelegate` | ✅ Native | ✅ Native | Core | Retain |
| Copy to Clipboard | ✅ COMPLETE | Flutter Services | `Clipboard.setData` | ✅ Native | ✅ Native | Core | Retain |
| Select All | ⏳ PLANNED | `pdfrx` | Select all page character spans | ✅ Feasible | ✅ Feasible | P1 | Add Ctrl+A / Select All action |
| Dictionary & Vocabulary | ✅ COMPLETE | TITAN WordNet | Local WordNet 3.0 sharded bundle | ✅ Offline | ✅ Offline | Core | Retain |
| Grammar & Spelling | ✅ COMPLETE | TITAN Engine | 10 rules + Damerau-Levenshtein | ✅ Offline | ✅ Offline | Core | Retain |
| AI Explain / Summarize | ✅ COMPLETE | TITAN AI (P5) | Multi-provider RAG assistant | ✅ Offline/Opt-in | ✅ Offline/Opt-in | Core | Retain |
| Search Selected Text | ⏳ PLANNED | `pdfrx` / Web | Send selection directly to SearchBar / Web | ✅ Feasible | ✅ Feasible | P1 | Add to Context Menu |
| Text-to-Speech (TTS) | ⏳ PLANNED | `flutter_tts` | Stream extracted page text to OS TTS | ✅ Supported | ✅ Supported | P2 | Add read-aloud playback bar |

---

### C. Reader-Managed Annotations vs D. PDF-Native Annotations

| Annotation Type | Reader-Managed (In-App) | PDF-Native Read | PDF-Native Write / Export | PDF-Native Flatten | Priority |
| --------------- | ----------------------- | --------------- | ------------------------- | ------------------ | -------- |
| **Highlight** (`/Highlight`) | ✅ COMPLETE | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | **P0** |
| **Underline** (`/Underline`) | ✅ COMPLETE | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | **P0** |
| **Strikethrough** (`/StrikeOut`) | ✅ COMPLETE | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | **P0** |
| **Freehand Ink Drawing** (`/Ink`) | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | **P0** |
| **Pen / Pencil / Eraser** | ⏳ Phase 6B | N/A (UI Tool) | ⏳ Phase 6B (As Ink) | ⏳ Phase 6B | **P0** |
| **Shapes: Rectangle / Circle / Line / Arrow** | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B (`/Square`, `/Circle`, `/Line`) | ⏳ Phase 6B | **P1** |
| **Free Text Box** (`/FreeText`) | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | **P0** |
| **Sticky Note / Popup** (`/Text`) | ✅ COMPLETE (Notes Panel) | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | **P1** |
| **Standard & Custom Stamps** (`/Stamp`) | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | **P1** |
| **Color & Opacity Selector** | ✅ COMPLETE | ⏳ Phase 6B | ⏳ Phase 6B | ⏳ Phase 6B | **P0** |
| **Undo / Redo Markup** | ✅ COMPLETE | N/A (UI Stack) | ⏳ Phase 6B | N/A | **P0** |

---

### E. Document Organization & Page Operations

| Feature | Status | Engine Required | Implementation Details | Android | Windows | Priority | Recommendation |
| ------- | ------ | --------------- | ---------------------- | ------- | ------- | -------- | -------------- |
| **Merge PDFs** | ⏳ PLANNED | Pure Dart / PDFium | Combine page trees into single document | ✅ Fast | ✅ Fast | **P0** | Implement in Phase 6A |
| **Split PDFs** | ⏳ PLANNED | Pure Dart / PDFium | Extract page ranges into new files | ✅ Fast | ✅ Fast | **P0** | Implement in Phase 6A |
| **Extract Pages** | ⏳ PLANNED | Pure Dart / PDFium | Save selected page subset | ✅ Fast | ✅ Fast | **P0** | Implement in Phase 6A |
| **Delete Pages** | ⏳ PLANNED | Pure Dart / PDFium | Prune `/Pages` kids array and references | ✅ Fast | ✅ Fast | **P0** | Implement in Phase 6A |
| **Reorder Pages** | ⏳ PLANNED | Pure Dart / PDFium | Re-index `/Pages` kids array via drag-drop | ✅ Fast | ✅ Fast | **P0** | Implement in Phase 6A |
| **Rotate Pages (Permanent)** | ⏳ PLANNED | Pure Dart / PDFium | Update `/Rotate` (0/90/180/270) attribute | ✅ Instant | ✅ Instant | **P0** | Implement in Phase 6A |
| **Insert Blank Page** | ⏳ PLANNED | Pure Dart / PDFium | Synthesize empty page dictionary | ✅ Instant | ✅ Instant | **P0** | Implement in Phase 6A |
| **Insert Pages from PDF** | ⏳ PLANNED | Pure Dart / PDFium | Import object cross-references & insert | ✅ Fast | ✅ Fast | **P0** | Implement in Phase 6A |
| **Duplicate Pages** | ⏳ PLANNED | Pure Dart / PDFium | Clone page dictionary and references | ✅ Fast | ✅ Fast | **P1** | Implement in Phase 6A |
| **Page Labels** | ⏳ PLANNED | Pure Dart / PDFium | Read/Write `/PageLabels` dictionary | ✅ Supported | ✅ Supported | **P2** | Implement in Phase 6A |

---

### F. PDF Creation & Export

| Feature | Status | Engine Required | Implementation Details | Android | Windows | Priority | Recommendation |
| ------- | ------ | --------------- | ---------------------- | ------- | ------- | -------- | -------------- |
| **Export Annotated PDF** | ⏳ PLANNED | Pure Dart / PDFium | Save with native `/Annots` dictionaries | ✅ Supported | ✅ Supported | **P0** | Implement in Phase 6B |
| **Flatten Annotations** | ⏳ PLANNED | Pure Dart / PDFium | Render annotations into `/Contents` stream | ✅ Supported | ✅ Supported | **P0** | Implement in Phase 6B |
| **Save As New PDF** | ⏳ PLANNED | Pure Dart / PDFium | Atomic file save to user-chosen path | ✅ Supported | ✅ Supported | **P0** | Implement in Phase 6A |
| **Images to PDF** | ⏳ PLANNED | `pdf` (Dart) | Convert JPG/PNG images into multi-page PDF | ✅ Fast | ✅ Fast | **P1** | Implement in Phase 6A |
| **Text to PDF** | ⏳ PLANNED | `pdf` (Dart) | Simple layout pagination for TXT/MD | ✅ Fast | ✅ Fast | **P2** | Implement in Phase 6A |
| **PDF/A Archival Export** | ⏳ PLANNED | Specialized Serializer | Embed sRGB color profile, XMP metadata | ✅ Feasible | ✅ Feasible | **P3** | Defer to later sprint |

---

### G. Interactive Forms (AcroForms)

| Feature | Status | Engine Required | Implementation Details | Android | Windows | Priority | Recommendation |
| ------- | ------ | --------------- | ---------------------- | ------- | ------- | -------- | -------------- |
| **Detect Form Fields** | ⏳ PLANNED | Form Parser | Parse `/Root` -> `/AcroForm` -> `/Fields` | ✅ Supported | ✅ Supported | **P1** | Implement in Phase 6C |
| **Text Fields (`/Tx`)** | ⏳ PLANNED | Flutter Overlay | Render editable TextField matching field bounds | ✅ Supported | ✅ Supported | **P1** | Implement in Phase 6C |
| **Checkboxes (`/Btn`)** | ⏳ PLANNED | Flutter Overlay | Render interactive Checkbox widget | ✅ Supported | ✅ Supported | **P1** | Implement in Phase 6C |
| **Radio Buttons (`/Btn`)**| ⏳ PLANNED | Flutter Overlay | Render RadioGroup linked by `/Parent` | ✅ Supported | ✅ Supported | **P1** | Implement in Phase 6C |
| **Dropdowns (`/Ch`)** | ⏳ PLANNED | Flutter Overlay | Render DropdownMenu using `/Opt` array | ✅ Supported | ✅ Supported | **P1** | Implement in Phase 6C |
| **Save Form Values** | ⏳ PLANNED | Form Serializer | Update `/V` (Value) and `/AP` (Appearance) | ✅ Supported | ✅ Supported | **P1** | Implement in Phase 6C |
| **Form Reset** | ⏳ PLANNED | Form Serializer | Revert field values to `/DV` (Default Value) | ✅ Supported | ✅ Supported | **P1** | Implement in Phase 6C |
| **Form Flattening** | ⏳ PLANNED | Form Serializer | Burn form appearances into page `/Contents` | ✅ Supported | ✅ Supported | **P1** | Implement in Phase 6C |
| **JavaScript in Forms** | ❌ REJECTED | JS Engine | Security and sandboxing complexity | ❌ Unsafe | ❌ Unsafe | N/A | **Do Not Implement** |

---

### H. Signatures: Visual vs Cryptographic

| Feature | Category | Implementation Strategy | Legal / Technical Standard | Android | Windows | Priority |
| ------- | -------- | ----------------------- | -------------------------- | ------- | ------- | -------- |
| **Draw Signature** | Visual | Flutter Canvas Bézier curve capture | Electronic signature stamp | ✅ Native | ✅ Native | **P0** |
| **Type Signature** | Visual | Script font rendering to image/vector | Electronic signature stamp | ✅ Native | ✅ Native | **P0** |
| **Image Signature** | Visual | PNG import with alpha channel | Electronic signature stamp | ✅ Native | ✅ Native | **P0** |
| **Save Signature Stamp** | Visual | Local secure storage (`titan.reader.signatures`) | Local convenience | ✅ Secure | ✅ Secure | **P0** |
| **Place & Resize Signature**| Visual | Interactive draggable overlay box | Standard visual placement | ✅ Native | ✅ Native | **P0** |
| **Digital Signing** | Cryptographic | X.509 PAdES-B-B / PKCS#7 detached signature | ISO 32000 / Adobe PAdES standard | ✅ Feasible | ✅ Feasible | **P2** |
| **Signature Verification** | Cryptographic | Validate `/ByteRange` SHA-256 and X.509 chain | PKI certificate validation | ✅ Feasible | ✅ Feasible | **P2** |

---

### I. Optical Character Recognition (OCR)

| Capability | Engine Strategy (Android) | Engine Strategy (Windows) | Language Support | Priority |
| ---------- | ------------------------- | ------------------------- | ---------------- | -------- |
| **Detect Scanned Pages** | Image dimension / text-density heuristic | Image dimension / text-density heuristic | Language-independent | **P1** |
| **Single Page OCR** | Google ML Kit (On-device, offline) | Offline Tesseract 5 / ONNX PP-OCRv4 | English + Hindi (Devanagari) | **P1** |
| **Full Document Batch OCR**| Background worker isolate | Background worker isolate | English + Hindi (Devanagari) | **P1** |
| **Searchable PDF Generation**| Inject invisible text layer behind image | Inject invisible text layer behind image | UTF-8 / Standard Type 3 font | **P1** |
| **OCR Text Selection & Copy**| Handled automatically by injected text layer | Handled automatically by injected text layer | Text glyphs with exact bounding rects | **P1** |

---

### J. Document Security & K. True Redaction

| Feature | Category | Mechanism | Critical Quality Rule | Priority |
| ------- | -------- | --------- | --------------------- | -------- |
| **Password Open (User)** | Security | Standard PDF encryption (AES-128 / AES-256) | Decrypt stream on load | **P1** |
| **Permissions (Owner)** | Security | Set permission flags (`/P` bitmask) | Restrict print/copy/edit | **P2** |
| **Visual Redaction (Marking)** | Redaction | Redaction annotation overlay (`/Redact`) | Stage marked areas for review | **P2** |
| **Permanent Content Redaction**| Redaction | **PHYSICAL OBJECT STRIPPING** | **UNDERLYING TEXT GLYPHS, VECTOR PATHS, AND RASTER PIXELS ARE PERMANENTLY REMOVED FROM THE STREAM. NEVER A FAKE BLACK RECTANGLE.** | **P2** |
| **Metadata Sanitization** | Redaction | Purge Info and XMP metadata dictionaries | Eliminate author/title leaks | **P2** |

---

### L. Metadata & M. Accessibility

| Feature | Status | Implementation Strategy | Priority |
| ------- | ------ | ----------------------- | -------- |
| **Metadata View & Edit** | ⏳ PLANNED | Read/write `/Info` dictionary (Title, Author, Subject, Keywords, Creator) | **P1** |
| **XMP Metadata** | ⏳ PLANNED | Parse and serialize XML packet in `/Metadata` stream | **P2** |
| **Reading Order Extraction** | ⏳ PLANNED | Sort text fragments by column-aware top-left geometry | **P1** |
| **Screen Reader Semantics** | ⏳ PLANNED | Expose extracted text spans to Flutter `Semantics` tree | **P1** |
| **Keyboard Shortcuts** | ⏳ PLANNED | Standard desktop bindings (Ctrl+F, Ctrl+P, PageUp, PageDown, Home, End, +, -) | **P0** |

---

### N. Printing & O. Attachments & P. Links & Q. Media

| Feature | Status | Implementation Strategy | Priority |
| ------- | ------ | ----------------------- | -------- |
| **Android Printing** | ⏳ PLANNED | Native Android `PrintManager` via `PrintDocumentAdapter` | **P1** |
| **Windows Printing** | ⏳ PLANNED | Windows native print dialog / Win32 GDI print spooler | **P1** |
| **Embedded Attachments View** | ⏳ PLANNED | Traverse `/Root` -> `/Names` -> `/EmbeddedFiles` name tree | **P2** |
| **Extract / Add Attachments** | ⏳ PLANNED | Extract file stream or attach binary files | **P2** |
| **Internal Page Links** | ✅ COMPLETE | `pdfrx` `goToDest` handler | Core |
| **External URL Links** | ⏳ PLANNED | Intercept `/URI` link annotations -> `url_launcher` | **P0** |
| **Rich Media (Audio/Video/3D)** | ❌ REJECTED | Non-standard, bloated, legacy Flash/U3D format | **Do Not Implement** |

---

### R. AI Integration (Phase 6 Opportunities)

| Feature | Baseline (Phase 5) | Phase 6 Upgrade |
| ------- | ------------------ | --------------- |
| **Scanned PDF Understanding** | Failed on image-only PDFs | **OCR + RAG**: Scanned documents automatically become searchable, explainable, and summarizable. |
| **Form Assistance** | None | **AI Form Filling**: AI analyzes context and suggests field values for complex government/legal forms. |
| **Smart Redaction** | None | **AI Sensitive Entity Detection**: Auto-detects Aadhaar, PAN, SSN, phone numbers, and addresses for batch redaction review. |

---

## 3. Recommended Multi-Engine Architecture (Option D)

```
                       ┌────────────────────────────────────────────────┐
                       │                  TITAN READER                  │
                       │           (UI / Presentation Layer)            │
                       └───────────────────────┬────────────────────────┘
                                               │
               ┌───────────────────────────────┴───────────────────────────────┐
               ▼                                                               ▼
┌───────────────────────────────┐                             ┌───────────────────────────────┐
│     PdfDocumentEngine (MIT)   │                             │  PdfManipulationEngine (Dart) │
│       (Display & Viewing)     │                             │  (Document & Page Mutations)  │
├───────────────────────────────┤                             ├───────────────────────────────┤
│ • Hardware-accelerated view   │                             │ • Page Merge / Split / Reorder│
│ • Smooth continuous scroll    │                             │ • Page Rotation & Deletion    │
│ • Glyph text selection bounds │                             │ • PDF-Native Annotations (/Ann│
│ • Real-time text search       │                             │ • AcroForm Field Serializer   │
│ • Fast Outline navigation     │                             │ • True Redaction Stream Stripp│
└──────────────┬────────────────┘                             └───────────────┬───────────────┘
               │                                                              │
               ▼                                                              ▼
┌───────────────────────────────┐                             ┌───────────────────────────────┐
│         pdfrx 2.4.7           │                             │ Pure Dart / Permissive C-FFI  │
│        (Google PDFium)        │                             │    PDF Structural Engine      │
└───────────────────────────────┘                             └───────────────────────────────┘
                                               ▲
                                               │
                        ┌──────────────────────┴──────────────────────┐
                        ▼                                             ▼
         ┌─────────────────────────────┐               ┌─────────────────────────────┐
         │     OcrEngine (Modular)     │               │   PdfSignatureEngine        │
         ├─────────────────────────────┤               ├─────────────────────────────┤
         │ • Android: Google ML Kit    │               │ • Visual Signature Canvas   │
         │ • Windows: Tesseract / ONNX │               │ • Cryptographic PAdES / X509│
         └─────────────────────────────┘               └─────────────────────────────┘
```

---

## 4. Phase 6 Implementation Sub-Phases & Prioritization

### Phase 6A: PDF Document Manipulation & Page Operations (**P0 — Immediate Next Sprint**)
* **Scope**: Merge, Split, Extract, Delete, Rotate (permanent), Reorder (drag-and-drop), Insert blank/PDF pages.
* **UI**: Interactive Page Thumbnail Grid Manager.
* **Risk**: Low. Pure structural operations on document page trees.

### Phase 6B: PDF-Native Annotations & Interoperability (**P0**)
* **Scope**: Bi-directional bridge between Reader-managed overlays and ISO 32000 PDF annotations (`/Highlight`, `/Underline`, `/StrikeOut`, `/Ink`, `/FreeText`). Flattening engine.
* **Risk**: Low-Medium. Coordinate space mapping verified in Phase 2.

### Phase 6C: Interactive Forms (AcroForms) (**P1**)
* **Scope**: Detect, fill, save, and flatten `/AcroForm` text boxes, checkboxes, radio buttons, and dropdowns.
* **Risk**: Medium. Dynamic widget layout alignment over zoom levels.

### Phase 6D: On-Device OCR & Searchable Text Layers (**P1**)
* **Scope**: ML Kit (Android) and Tesseract/ONNX (Windows) OCR. Searchable invisible text layer injection for scanned documents.
* **Risk**: Medium. Binary asset management and background isolate processing.

### Phase 6E: Visual & Cryptographic Signatures (**P1 / P2**)
* **Scope**: Visual signature pad (draw/type/image) + X.509 PAdES digital signing and certificate verification.
* **Risk**: Medium. PKI and cryptographic byte range integrity.

### Phase 6F: True Content Redaction & Security (**P2**)
* **Scope**: Physical content stream stripping for sensitive data + standard AES-128/256 password protection.
* **Risk**: High. Must strictly verify zero underlying data leakage.

### Phase 6G: Native Printing, Attachments & Accessibility (**P2**)
* **Scope**: Platform print dialogs, embedded file attachment viewer, reading-order screen reader accessibility.
* **Risk**: Low. Standard OS integrations.

---

## 5. Features to Defer & Features to Reject

### Features to Defer (Phase 7+)
1. **PDF/A ISO Archival Certification**: Niche legal compliance requirement; defer until requested.
2. **Dense Vector Embeddings Index (Offline HNSW)**: Enhances AI semantic search; defer to dedicated AI search sprint.
3. **Advanced Prepress Color Separation (CMYK)**: Professional print shop requirement; out of scope for a personal reader.

### Features NOT Worth Implementing (Strictly Rejected)
1. **Flash / Rich Media (Audio/Video/3D)**: Legacy, deprecated by Adobe, security risk.
2. **Embedded JavaScript Execution in Forms**: Major security vulnerability vector; PDF forms can be validated purely via Flutter UI logic.
3. **Full Desktop Word-Processor WYSIWYG Layout Reflow**: PDFs are fixed-layout documents by design; attempting to turn a PDF reader into Microsoft Word causes layout destruction.
4. **Proprietary Closed-Source SDKs (PSPDFKit/Nutrient)**: Unacceptable ongoing licensing fees (\$10k+/yr); destroys free-first open-source viability.
5. **AGPL-3.0 Engines (MuPDF)**: Viral license infects the entire TITAN codebase.

---

## 6. Architectural Impact & QuizForge Protection

* **`quizforge_upsc` Application Source**: **100% ISOLATED & UNTOUCHED**.
* **`titan_pdf`**: Reusable document validation contracts remain preserved.
* **`titan_storage`**: Storage namespaces expanded strictly under `titan.reader.*`.
* **`titan_domain`**: Zero breaking changes.

---

## 7. Final Recommendations

1. **Recommended PDF Engine Strategy**: Adopt **Option D (Multi-Engine Modular Architecture)** retaining `pdfrx` 2.4.7 for rendering and layering modular manipulation, OCR, and signature services.
2. **Recommended First Implementation Sprint**: **Phase 6A — PDF Document Manipulation & Page Operations**.
3. **Approval Status**: Investigation complete. Phase 6 implementation remains **NOT STARTED** awaiting Product Owner approval.
