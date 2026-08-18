# ADR-0004: TITAN Reader PDF Engine Selection and Application Placement

- Status: Accepted
- Date: 2026-08-18
- Decision Owner: Senior Implementation Engineer (TITAN-KO Reader Phase 0)

## Context

Project TITAN requires a professional document/PDF application, **TITAN Reader**,
targeting Android and Windows first, with Web future-compatible. Phase 1 needs a
PDF engine capable of:

- rendering local PDF files with lazy page rendering,
- page navigation, zoom, fit-width/fit-page, rotation,
- text search with match navigation,
- text selection (foundation for dictionary/annotation phases),
- thumbnails,
- offline-first operation.

Section 12 of the TITAN Reader mandate requires an **engine abstraction** so the
application is never directly coupled to a single PDF library.

Existing repository state (Phase 0 audit):

- `project_titan/` is a Melos monorepo (`melos.yaml`: `apps/**`, `packages/**`).
- Existing apps: `apps/titan_mobile` (riverpod + go_router shell),
  `apps/quizforge_ai` (integration layer). Neither commits platform scaffolding
  (`android/`, `windows/`); platform folders are generated locally.
- `packages/titan_pdf` exists but is an **ingestion/domain module** (import,
  validation, chunking, metadata) with no rendering capability. It is reused for
  document import/validation semantics, not rendering.
- Core infrastructure to reuse: `titan_core` (DI `TitanServiceLocator`,
  `TitanLogger`, error model), `titan_domain` (`StorageKey`), `titan_storage`
  (`StorageService` with Hive and in-memory implementations).

## Candidates Evaluated

| Option | License | Android | Windows | Search | Selection | Thumbnails | Notes |
| ------ | ------- | ------- | ------- | ------ | --------- | ---------- | ----- |
| `pdfrx` 2.x | MIT | yes | yes | built-in | built-in | via `PdfPageView` | PDFium-based, actively maintained, manipulation APIs for later phases |
| `pdfx` | MIT | yes | yes | no (render only) | partial | partial | No integrated text search/selection; weaker fit for dictionary phases |
| `flutter_pdfview` | MIT | yes | no | no | no | no | Android-only; dead end for Windows target |
| `syncfusion_flutter_pdfviewer` | commercial (community license) | yes | yes | yes | yes | yes | License incompatible with "prefer free/open-source" and future commercial use |

## Decision

1. **PDF engine: `pdfrx` ^2.4.7** (MIT, PDFium-backed, supports Android,
   iOS, Windows, macOS, Linux, Web). It uniquely satisfies all Phase 1
   requirements under a permissive license, including built-in text search and
   selection required by later dictionary/annotation phases.

2. **Abstraction first.** The app never imports `pdfrx` outside
   `src/pdf/` adapters. Domain-facing contracts are defined in
   `pdf_engine_contracts.dart` (`PdfDocumentEngine`, `PdfPageRenderer`,
   `PdfTextExtractor`, `PdfSearchEngine`, `PdfAnnotationEngine`, `PdfEditor`
   placeholders for later phases). All business logic and tests depend only on
   the contracts.

3. **Application placement: `apps/titan_reader`**, following the established
   Melos monorepo convention (`apps/**`). The app reuses `titan_core` (DI,
   logging, errors), `titan_storage` (persistence via `StorageService`),
   `titan_domain` (`StorageKey`), and `titan_pdf` (import validation models).

4. **State management/navigation:** `flutter_riverpod` + `go_router`, matching
   `titan_mobile` conventions.

5. **Platform scaffolding:** not committed (matches `titan_mobile` /
   `quizforge_ai`); generated locally via
   `flutter create --platforms=android,windows .` inside the app directory.

6. **Privacy default:** every imported document is `LOCAL_ONLY`; nothing is
   transmitted externally without explicit later user configuration.

## Consequences

- Positive: single permissively licensed engine across both target platforms;
  clean seam for engine replacement; tests run against a fake engine with no
  platform channels.
- Positive: PDFium rendering gives fast lazy page rendering for large PDFs.
- Negative: Windows builds require Developer Mode (symlinks in PDFium native
  asset packaging); documented in app README.
- Negative: pdfrx API churn between majors; contained entirely inside the
  adapter layer by this ADR.
- Rejected alternatives: `pdfx` (no search/selection), `flutter_pdfview`
  (Android-only), Syncfusion (licensing).
