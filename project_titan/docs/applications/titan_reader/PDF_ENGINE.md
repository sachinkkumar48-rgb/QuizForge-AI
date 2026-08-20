# TITAN Reader — PDF Engine

Engine selection is documented in
[ADR-0004](../../adr/ADR-0004-titan-reader-pdf-engine-selection.md):
`pdfrx` ^2.4.7 (MIT, PDFium-backed) behind an application-owned abstraction.

## Abstraction

All engine-facing contracts live in `lib/src/pdf/pdf_engine_contracts.dart`
and contain no pdfrx types:

| Contract | Role |
| -------- | ---- |
| `PdfDocumentEngine` | factory: `createHandle()` and `buildViewer(filePath, settings, handle)` |
| `PdfViewerHandle` | imperative/observable surface: page navigation, zoom, fit, rotation, text search, text selection, outline, annotation overlays, listeners, `dispose()` |
| `PdfViewerSettings` | immutable viewer config (`initialPage`, `textSelectionEnabled`, `selectionActions`, `onSelectionAction`) |
| `PdfSearchMatch` | engine-agnostic match (index, 1-based page, snippet) |
| `PdfFitMode` | `fitPage` / `fitWidth` |
| `PdfTextSelectionSnapshot` / `PdfSelectionFragment` | selected text plus per-fragment normalized geometry |
| `PdfAnnotationOverlay` / `PdfOverlayStyle` | Reader-managed markup to paint on pages |
| `ReaderOutlineEntry` | engine-agnostic PDF outline node (path-keyed) |

Business code depends only on these contracts. The engine is injected via
`pdfEngineProvider`, so tests substitute `FakePdfEngine` without platform
channels.

## pdfrx adapter

`lib/src/pdf/pdfrx_pdf_engine.dart` is the **only file that imports pdfrx**:

- `PdfrxPdfEngine` delegates viewer construction to the handle's
  `buildViewer`, which wraps `PdfViewer.file` in a `RotatedBox` (pdfrx
  exposes no viewer rotation parameter, so rotation is presentation-level).
- `PdfrxViewerHandle` wraps `PdfViewerController` + `PdfTextSearcher`,
  translating pdfrx page/search events into the contract listeners.
- Page count is read from the controller only after `isReady`, keeping the
  contract's nullable `pageCount` honest.

### pdfrx 2.x API notes (verified against pdfrx 2.4.7)

- `PdfViewerController` has no `dispose()`; the handle disposes the
  searcher only.
- Deprecated `minScale`/`maxScale` viewer parameters are replaced with
  `PdfViewerSizeDelegateProviderLegacy`.
- Text selection: `controller.textSelectionDelegate` exposes
  `getSelectedText()` / `getSelectedTextRanges()`; each range yields
  fragment bounding rects via `enumerateFragmentBoundingRects()`.
- Selection bounds are `PdfRect` values in **bottom-left origin, Y-up**
  page coordinates; the adapter flips Y into the Reader's canonical
  top-left normalized space at capture time and back at paint time.
- Outline: `controller.document.loadOutline()` → `PdfOutlineNode` tree;
  navigation via `controller.goToDest(dest)`.
- Overlays: painted through `PdfViewerParams.pagePaintCallbacks`, using
  `PdfRect.toRect(page:, scaledPageSize:)` and forcing repaints with
  `controller.invalidate()`.
- Context toolbar: `PdfViewerParams.customizeContextMenuItems`
  (`PdfViewerContextMenuUpdateMenuItemsFunction`) appends the Reader's
  selection actions to pdfrx's native menu.

## PDF-native vs Reader-managed annotations

TITAN Reader supports two distinct, complementary annotation architectures:

| Feature / Dimension | Reader-Managed Annotations (Phase 2) | PDF-Native Annotations (Phase 6B) |
| ------------------- | ------------------------------------ | --------------------------------- |
| **Storage Location** | Application database / Hive / SQLite | `/Annots` array inside PDF binary |
| **Target Use Case** | User study notes, AI summaries, high-speed overlays | Interoperable document sharing & standard PDF viewers |
| **Portability** | Within TITAN Reader application ecosystem | Universal across Acrobat, Preview, Chrome, PDFium, Foxit |
| **Mutation Style** | Non-destructive database writes | In-place or new PDF AST object serialization |
| **Rendering** | Presentation overlays on `pdfrx` viewer | Direct PDF Appearance Streams (`/AP` Form XObjects) |
| **Supported Types** | Highlights, Notes, Bookmarks | Highlight, Underline, StrikeOut, Ink, FreeText, Sticky Note, Raw |
| **Undo / Redo** | Memory & DB state reversal | `ReaderUndoStack` with atomic synchronous disk persistence |

## PDF Manipulation Engine (Phase 6A)

While `pdfrx` handles high-performance native rendering and text selection, PDF page mutations and structural operations are handled by a dedicated, pure Dart AST manipulation engine (`DefaultPdfManipulationEngine`) behind the `PdfManipulationEngine` contract (`src/manipulation/engine/pdf_manipulation_engine.dart`).

### Engine Separation Rule

```
pdfrx (PDFium) ───► Viewing / Rendering / Interactive Selection
DefaultPdfManipulationEngine ───► Structural Mutation / Merge / Split / AST Manipulation
DefaultPdfNativeAnnotationEngine ───► PDF-Native /Annots CRUD / /AP Generation / Flattening
```

### AST Architecture
- `PdfTokenizer`: Lexical analysis of PDF syntax into tokens (Names, Strings, Numbers, Booleans, References, Dict/Array delimiters).
- `PdfParser`: Reconstructs the complete cross-reference (`xref`) table, object generations, trailer dictionary, and catalog.
- `PdfDocumentAst`: In-memory mutable representation of the document object graph and page hierarchy.
- `PdfWriter`: Serializes AST objects back to byte streams with reconstructed `/XRef` tables, object numbers, and atomic output writing (`writeBytes`, `writeAtomic`, `writeAtomicSync`).

## PDF-Native Annotation Engine (Phase 6B)

The PDF-Native Annotation Engine (`DefaultPdfNativeAnnotationEngine` behind `PdfNativeAnnotationEngine`) enables full ISO 32000-1 annotation lifecycle management directly within the AST:

### Core Capabilities
1. **Parser & Builder**:
   - `PdfAnnotationParser`: Scans `/Annots` arrays, resolving direct and indirect object dictionaries into strongly-typed `PdfNativeAnnotation` entities.
   - `PdfAnnotationBuilder`: Translates domain annotations into standard PDF dictionaries, computing `/Rect`, `/QuadPoints`, `/InkList`, `/DA`, `/C` (RGB), `/CA` (opacity), `/BM` (blend mode), and `/AP` (Form XObject Appearance Streams).
2. **Raw Annotation Preservation**:
   - Unknown or complex annotation types (e.g. `/Link`, `/Widget`, stamps) are preserved as `PdfNativeRawAnnotation` and written back unmodified.
3. **Page Flattening**:
   - Flattens native annotations into the page's `/Contents` stream using PDF operator sequences (q/Q matrix transformations, Do for XObjects), locking visual appearance permanently.
4. **Coordinate Transformation**:
   - `PdfCoordinateTransformer`: Converts bidirectionally between screen coordinates (top-left normalized `[0, 1]`) and PDF User Space points (bottom-left origin, 72 DPI).
5. **Undo / Redo System**:
   - Integrated with `ReaderUndoStack`, providing synchronous reversible state transitions and atomic file disk synchronization.

## Hardening & Compatibility (Phase 6A.1 & 6B)

The AST engine was hardened across 20 corpus categories (A–T), differential roundtrips, and malformed fuzzing suites:
- **Inheritance Resolution**: Automatically flattens and inherits `/MediaBox`, `/CropBox`, `/Resources`, and `/Rotate` from nested `/Pages` ancestors down to leaf `/Page` nodes.
- **Unicode Strings**: Full UTF-16BE decoding and hex serialization for international metadata and annotations.
- **Safety**: Rejection of encrypted PDFs (`/Encrypt`) with typed `PdfUnsupportedDocumentException` to protect files from cryptographic corruption.
- **Zero-Page Protection**: Rejection of empty/corrupt document graphs with typed `PdfInvalidDocumentException`.
- **Atomic Reliability**: All mutations stage writes to `.tmp_titan_*` before atomic renaming to prevent corrupted outputs on interrupt.

