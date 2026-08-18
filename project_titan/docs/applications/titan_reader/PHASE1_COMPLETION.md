# TITAN Reader — Phase 1 Completion Checkpoint

**Date:** 2026-08-18
**Branch:** `sprint-1-polish` (local only — not pushed)
**Status:** ✅ **PHASE 1 COMPLETE** — all acceptance criteria verified at final checkpoint.

## Phase

Phase 1 — Foundation: application shell, document library, PDF rendering,
navigation, search, reading-position persistence.

## Implementation Status

| Area | Status |
| --- | --- |
| Application shell + routing (go_router) | Done |
| Library screen with validated PDF import | Done |
| Recent documents shelf + history service | Done |
| PDF viewer (render, page nav, slider) | Done |
| Zoom in/out, fit-width / fit-page | Done |
| Rotation (presentation-level, quarter turns) | Done |
| Debounced full-text search with match navigation | Done |
| Reading position persistence | Done |
| LOCAL_ONLY privacy default | Done |
| Phase 2: annotations / bookmarks / notes | Not started |

## Features Completed

- Import PDF via file picker with header validation reusing `titan_pdf`
  `PdfValidationService` rules.
- Library list + recents, document cards, empty states, missing-file handling.
- Reader screen: page navigation, bottom page slider, zoom controls,
  fit modes, rotation, view-options menu.
- Text search: query entry, match highlighting via page paint callback,
  next/previous match navigation, match counter.
- Reading position restored on reopen; page count written back after load.
- Reading history recorded on open and visit.

## Architecture

TITAN Reader is an independent application under `apps/titan_reader`:

```text
TITAN
 ├── QuizForge AI        (apps/quizforge_ai — untouched)
 ├── TITAN Reader        (apps/titan_reader — this app)
 └── Shared TITAN infra  (packages/titan_core, titan_domain,
                          titan_storage, titan_pdf)
```

Layers inside Reader: `domain/entities` → `data` repositories over
`titan_storage` → `services` → Riverpod `providers` → `screens`/`widgets`.
The PDF engine lives in `src/pdf/` behind app-local contracts; no Reader PDF
functionality leaks into QuizForge or shared packages.

## PDF Engine

- Concrete engine: **pdfrx 2.4.7**, confined to a single adapter file:
  `lib/src/pdf/pdfrx_pdf_engine.dart` (the only `package:pdfrx` import in the
  whole TITAN workspace).
- Abstractions in `lib/src/pdf/pdf_engine_contracts.dart`:
  `PdfDocumentEngine`, `PdfViewerHandle`, `PdfViewerSettings`,
  `PdfSearchMatch`, `PdfDocumentSummary`, `PdfFitMode`.
  Render/extract/search concerns are expressed through the handle API, not
  pdfrx types; tests run against `FakePdfEngine`.
- Selection rationale recorded in
  `docs/adr/ADR-0004-titan-reader-pdf-engine-selection.md`;
  operational details in `docs/applications/titan_reader/PDF_ENGINE.md`.

## Dependencies

Reader-scoped (`apps/titan_reader/pubspec.yaml`): `file_picker ^8.3.7`,
`flutter_riverpod ^2.5.1`, `go_router ^13.2.0`, `meta ^1.11.0`,
`pdfrx ^2.4.7`, plus shared path packages `titan_core`, `titan_domain`,
`titan_storage`, `titan_pdf`. `pdfrx` is NOT a dependency of QuizForge or any
shared package. QuizForge's own `file_picker` predates Reader and is used for
its PDF quiz-import flow.

Storage namespaces: `titan.reader.library`, `titan.reader.positions` —
Reader-specific, created through the shared `StorageService` abstraction.

## Tests

Checkpoint re-run on 2026-08-18 from commit `006e416`:

| Suite | Result |
| --- | --- |
| titan_reader (`flutter test --no-pub`) | **56/56 PASS** |
| titan_pdf | **5/5 PASS** |
| titan_quiz | **31/31 PASS** |
| titan_quiz_ai | **42/42 PASS** |
| quizforge_ai (QuizForge regression) | **56/56 PASS** |

Widget tests are IO-free (no `dart:io` inside FakeAsync zones) per
`docs/applications/titan_reader/TESTING.md`.

## Static Analysis

`dart analyze .` → **No issues found** for titan_reader, quizforge_ai,
titan_pdf, titan_quiz, titan_quiz_ai. Formatting clean.

## QuizForge Regression Status

✅ No QuizForge application source, UI, business logic, configuration or
tests were modified by Reader work (verified via
`git log 91ebef2..HEAD --name-status`). Shared-package repairs
(`93432ed`, `dbf2196`, `006e416`) fixed pre-existing bootstrap import
ambiguities and stale test mocks; all backward-compatible import-level
changes with the full §8 regression matrix green.

## Known Limitations

- Rotation is presentation-level (`RotatedBox`); pdfrx has no rotation
  parameter, so text-search match rects are not rotated with the view.
- Search is in-memory per session; matches are not persisted.
- No annotations, bookmarks or notes yet (Phase 2).
- No dictionary/grammar/AI assistant (Phase 3/4).

## Known Technical Debt

- pdfrx deprecations: `minScale`/`maxScale` used via
  `PdfViewerSizeDelegateProviderLegacy`; must migrate to the non-legacy
  size-delegate API when upgrading pdfrx.
- `PdfViewerController` has no `dispose()`; handle lifecycle relies on
  controller GC (documented in PDF_ENGINE.md).
- Single shared `TitanServiceLocator` instance across test files requires
  careful reset discipline in new Reader tests.

## Next Phase

**Phase 2 — Annotations, Bookmarks & Notes:** text selection with contextual
toolbar, highlights / underlines / strikethroughs (multi-color, removable,
persistent), application bookmarks (+ PDF outline where available), notes
with page/selection references, Reader-scoped undo/redo, persistence via
`titan_storage` reader namespaces, coordinate abstraction stable across
zoom/resize/orientation.

## Commits (Phase 1, local only)

| Commit | Summary |
| --- | --- |
| `93432ed` | fix(titan_pdf): resolve ambiguous port imports, export validation service |
| `38b0018` | feat(reader): implement TITAN Reader Phase 1 foundation |
| `3940fd2` | docs(reader): Phase 1 documentation and feature matrix |
| `dbf2196` | fix(titan_pdf): repair stale test mocks to titan_domain ports |
| `006e416` | fix(titan_quiz): resolve bootstrap service-name ambiguities |
