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
| `PdfViewerHandle` | imperative/observable surface: page navigation, zoom, fit, rotation, text search, listeners, `dispose()` |
| `PdfViewerSettings` | immutable viewer config (`initialPage`, `textSelectionEnabled`) |
| `PdfSearchMatch` | engine-agnostic match (index, 1-based page, snippet) |
| `PdfFitMode` | `fitPage` / `fitWidth` |

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

## Replacing the engine

1. Implement `PdfDocumentEngine` + `PdfViewerHandle` against the new SDK in
   a new adapter file under `src/pdf/`.
2. Switch the default of `pdfEngineProvider` (or override it in `main()`).
3. No changes required outside `src/pdf/` — screens, services and tests are
   engine-agnostic.
