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

pdfrx 2.4.7's `PdfAnnotation` surface is metadata-only (title/content
strings); it **cannot create, render or persist PDF-native annotations**.
Therefore TITAN Reader stores annotations in TITAN storage and paints them
as overlays. Consequences:

- Annotations survive restarts and sync with the Reader, but are **not
  embedded into the PDF file** and are invisible to other PDF tools.
- The normalized-rect model maps cleanly onto PDF highlight/underline/
  strike-out annotation rects, leaving room for future export/import once
  an engine supports it.
- The PDF's native outline is still *read* and surfaced (read-only).

## Replacing the engine

1. Implement `PdfDocumentEngine` + `PdfViewerHandle` against the new SDK in
   a new adapter file under `src/pdf/`.
2. Switch the default of `pdfEngineProvider` (or override it in `main()`).
3. No changes required outside `src/pdf/` — screens, services and tests are
   engine-agnostic.

## PDF Manipulation Engine (Phase 6A)

While `pdfrx` handles high-performance native rendering and text selection, PDF page mutations and structural operations are handled by a dedicated, pure Dart AST manipulation engine (`DefaultPdfManipulationEngine`) behind the `PdfManipulationEngine` contract (`src/manipulation/engine/pdf_manipulation_engine.dart`).

### Engine Separation Rule

```
pdfrx (PDFium) ───► Viewing / Rendering / Interactive Selection
DefaultPdfManipulationEngine ───► Structural Mutation / Merge / Split / AST Manipulation
```

### AST Architecture
- `PdfTokenizer`: Lexical analysis of PDF syntax into tokens (Names, Strings, Numbers, Booleans, References, Dict/Array delimiters).
- `PdfParser`: Reconstructs the complete cross-reference (`xref`) table, object generations, trailer dictionary, and catalog.
- `PdfDocumentAst`: In-memory mutable representation of the document object graph and page hierarchy.
- `PdfWriter`: Serializes AST objects back to byte streams with reconstructed `/XRef` tables, object numbers, and atomic output writing.

## Hardening & Compatibility (Phase 6A.1)

The AST engine was hardened across 20 corpus categories (A–T), differential roundtrips, and malformed fuzzing suites:
- **Inheritance Resolution**: Automatically flattens and inherits `/MediaBox`, `/CropBox`, `/Resources`, and `/Rotate` from nested `/Pages` ancestors down to leaf `/Page` nodes.
- **Unicode Strings**: Full UTF-16BE decoding and hex serialization for international metadata and annotations.
- **Safety**: Rejection of encrypted PDFs (`/Encrypt`) with typed `PdfUnsupportedDocumentException` to protect files from cryptographic corruption.
- **Zero-Page Protection**: Rejection of empty/corrupt document graphs with typed `PdfInvalidDocumentException`.
- **Atomic Reliability**: All mutations stage writes to `.tmp_titan_*` before atomic renaming to prevent corrupted outputs on interrupt.
