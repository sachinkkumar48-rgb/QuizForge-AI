# TITAN Reader — Phase 2 Completion Report

Phase 2: **Annotations, Bookmarks & Notes** — completed on top of the
Phase 1 foundation (checkpoint `6ee845f`) without touching QuizForge AI or
introducing a second architecture.

## Scope

All changes are confined to:

- `project_titan/apps/titan_reader/**` (implementation + tests)
- `project_titan/docs/applications/titan_reader/**` (documentation)

No shared TITAN package was modified during Phase 2; no QuizForge file was
modified.

## Features implemented

### Annotations (Reader-managed overlays)

- Highlight, underline and strikethrough from the text-selection toolbar.
- 5-color palette (yellow/green/blue/pink/purple), per-annotation recolor.
- Remove via annotations panel, with undoable snackbar.
- Persisted to `titan.reader.annotations`; restored after restart and
  repainted as engine overlays on open (initial synchronization).

### Bookmarks

- Add/remove toggle for the current page; rename/edit; list with page
  references; tap to navigate.
- Persisted to `titan.reader.bookmarks`; restored after restart.
- PDF-native outline is read through the engine abstraction and shown in
  the same panel (runtime only, never persisted, never conflated with app
  bookmarks).

### Notes

- Add/edit/delete with title, content, page reference and optional
  selected-text/annotation references.
- Full-text search across title/content/selected text; tap to navigate to
  the source page.
- Persisted to `titan.reader.notes`; restored after restart.
- Loose coupling: deleting a referenced annotation never invalidates a
  note.

### Undo/redo

- Reader-scoped `ReaderUndoStack` (capacity 100) per service; every
  add/edit/delete of annotations, bookmarks and notes is undoable and
  redoable, and the post-operation state is persisted (durable undo).

### Selection toolbar

- Copy, Dictionary, Grammar, Highlight, Underline, Strikethrough, Note.
- Dictionary/Grammar are explicit placeholders for later phases.
- The adapter never clears the selection before the application consumes
  it; the Reader clears it after the operation.

## Coordinate strategy

Persisted geometry is `NormalizedPageRect` — 0..1 fractions of the page
size, top-left origin. Capture converts pdfrx/PDFium bounds (bottom-left
origin, Y-up) with `top = (pageHeight - pdfTop) / pageHeight`; paint
converts back inside `pagePaintCallbacks`. Because only fractions are
stored, annotation positions remain correct across zoom (100%/150%/200%…),
window resize, page scrolling, orientation changes and restarts. Raw
screen/viewport coordinates are never persisted.

## PDF-native vs Reader-managed annotations

pdfrx 2.4.7 cannot create, render or persist PDF-native annotations
(`PdfAnnotation` is metadata-only). All Phase 2 markup is therefore
Reader-managed: stored in TITAN storage and painted as overlays. It is NOT
embedded into the PDF file; other PDF tools will not see it. The data model
(normalized rects per fragment) maps directly onto PDF highlight-family
annotation rects, leaving room for future export/import.

## Storage model

One JSON entry per document per namespace in the shared `StorageService`:

| Namespace | Content |
| --------- | ------- |
| `titan.reader.annotations` | markup annotations (id, page, type, color, text, rects, timestamps) |
| `titan.reader.bookmarks` | application bookmarks (id, page, title, timestamps) |
| `titan.reader.notes` | notes (id, page, title, content, refs, timestamps) |

Namespaces are isolated from each other and from the Phase 1 namespaces
(`titan.reader.library`, `titan.reader.positions`); per-document keys keep
documents isolated; deletion of one document never touches another.

## Tests

Suite: `flutter test` in `apps/titan_reader` — **111/111 PASS**.

| File | Coverage |
| ---- | -------- |
| `phase2_entities_test.dart` | entity CRUD/JSON round-trips, wire fallbacks, note matching, rect clamping + zoom-invariant scaling |
| `phase2_repositories_test.dart` | persistence, per-document isolation, namespace isolation, malformed payloads |
| `phase2_services_test.dart` | CRUD, recolor, search, durable undo/redo across add/edit/delete |
| `reader_phase2_test.dart` | toolbar actions; highlight/bookmark/note persistence across a simulated restart (fresh engine, same storage); outline navigation; panel delete+undo; restored overlay geometry |

User-flow validation (open → select → mark → close → reopen → present at
correct position) is covered by the restart tests for highlight, bookmark
and note; coordinate stability is covered by the normalized-rect domain
tests plus restored-overlay geometry equality.

## Regression results

| Gate | Result |
| ---- | ------ |
| `dart analyze` (titan_reader) | 0 issues |
| titan_pdf | 5/5 PASS |
| titan_quiz | 31/31 PASS |
| titan_quiz_ai | 42/42 PASS |
| QuizForge AI (workspace root) | 234/234 PASS |
| TITAN Reader | 111/111 PASS |

(Pre-existing info-level lints in `titan_pdf` remain untouched; they
pre-date Phase 2 and no titan_pdf file changed.)

## Known limitations

- Annotations are not embedded into the PDF file (engine limitation); no
  PDF-native export/import yet.
- Snackbars raised from a modal panel render below the sheet route; the
  undo action is reachable after dismissing the panel.
- Rotation remains presentation-level (Phase 1 limitation); annotation
  rects are defined in unrotated page space.
- Dictionary/Grammar toolbar entries are placeholders.
- pdfrx `PdfViewerController` has no `dispose()` (tech debt carried from
  Phase 1).

## Phase 3 readiness

The selection pipeline (`captureTextSelection` → action dispatch) is the
exact integration point for Dictionary and Vocabulary: add action ids,
route them to new services, reuse the normalized-rect/selection model.
Phase 3 can begin.
