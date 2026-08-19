# TITAN Reader — Architecture

TITAN Reader follows the TITAN Clean Architecture conventions with four
inward-facing layers. The UI depends only on providers/services, services on
repositories/domain, and the PDF engine only through contracts.

## Layer map

```
lib/
├── main.dart                        # bootstrap: storage init + ProviderScope
└── src/
    ├── app.dart                     # MaterialApp.router + ReaderTheme
    ├── navigation/
    │   ├── reader_routes.dart       # route path constants
    │   └── reader_router.dart       # GoRouter config (/ and /reader/:documentId)
    ├── screens/
    │   ├── library_screen.dart      # import, list, Recent shelf, favorites
    │   └── reader_screen.dart       # viewer, navigation bar, search toggle
    ├── widgets/
    │   ├── document_card.dart       # library list item
    │   ├── document_search_bar.dart # debounced search panel + match nav
    │   ├── annotations_panel.dart   # Phase 2: markup list/recolor/delete
    │   ├── bookmarks_panel.dart     # Phase 2: bookmarks + PDF outline
    │   ├── notes_panel.dart         # Phase 2: notes list/search/editor
    │   └── note_editor_dialog.dart  # Phase 2: note create/edit dialog
    ├── domain/entities/
    │   ├── reader_document.dart     # library entry (LOCAL_ONLY by default)
    │   ├── reading_position.dart    # page + total pages + timestamp
    │   ├── reading_visit.dart       # history entry for the Recent shelf
    │   ├── document_privacy_state.dart
    │   ├── normalized_page_rect.dart # Phase 2: canonical annotation geometry
    │   ├── reader_annotation.dart   # Phase 2: highlight/underline/strikethrough
    │   ├── reader_bookmark.dart     # Phase 2: app bookmarks + outline entry
    │   └── reader_note.dart         # Phase 2: free-form notes
    ├── data/
    │   ├── document_library_repository.dart  # StorageService-backed library
    │   ├── reading_position_repository.dart  # StorageService-backed positions
    │   ├── annotation_repository.dart        # Phase 2 (titan.reader.annotations)
    │   ├── bookmark_repository.dart          # Phase 2 (titan.reader.bookmarks)
    │   └── note_repository.dart              # Phase 2 (titan.reader.notes)
    ├── services/
    │   ├── library_service.dart     # import validation + library mutations
    │   ├── reading_history_service.dart      # Recent ordering/cap/dedup
    │   ├── annotation_service.dart  # Phase 2: markup CRUD + undo/redo
    │   ├── bookmark_service.dart    # Phase 2: bookmark CRUD + undo/redo
    │   ├── note_service.dart        # Phase 2: note CRUD/search + undo/redo
    │   └── reader_undo_stack.dart   # Phase 2: Reader-scoped undo/redo core
    ├── providers/reader_providers.dart       # Riverpod wiring
    ├── pdf/
    │   ├── pdf_engine_contracts.dart         # PdfDocumentEngine + handle
    │   └── pdfrx_pdf_engine.dart             # pdfrx adapter (only pdfrx import site)
    └── theme/reader_theme.dart      # light/dark Material 3 schemes
```

## Package reuse (no parallel implementations)

| Need | Reused package | Usage |
| ---- | -------------- | ----- |
| Persistence | `titan_storage` | `StorageService` port; in-memory impl for tests |
| Storage keys | `titan_domain` | `StorageKey` namespaces per repository |
| PDF import validation | `titan_pdf` | `PdfValidationService.validatePdf` rules |
| State management | `flutter_riverpod` | providers + overrides, titan_mobile convention |
| Navigation | `go_router` | module-level `readerRouter` config |
| PDF rendering | `pdfrx` | isolated behind `src/pdf/` adapters (ADR-0004) |

## Dependency flow

`ReaderScreen` / `LibraryScreen` → Riverpod providers (`reader_providers.dart`)
→ `LibraryService` / `ReadingHistoryService` → repositories →
`StorageService` (injected via `storageServiceProvider`, overridden in
`main()` after `TitanStorageBootstrap.initializeStorage()` and in tests with
`InMemoryStorageService`).

`storageServiceProvider` throws a descriptive `StateError` when not
overridden, making bootstrap mistakes fail fast.

## Reading-position lifecycle

1. Open document → `LibraryService.loadPosition` → viewer receives
   `PdfViewerSettings(initialPage:)`.
2. Engine page-change events → `_onPageChanged` → persists position and the
   engine-reported page count back to the library metadata.
3. Dispose → best-effort final position save, then handle disposal.

## Phase 2: annotations, bookmarks & notes

### Coordinate model

Persisted geometry is the `NormalizedPageRect`: 0..1 fractions of the page
size with a top-left origin. The engine (PDFium via pdfrx) reports text
bounds in PDF coordinates (**bottom-left origin, Y-up**); the adapter
converts each fragment at capture time
(`top = (pageHeight - pdfTop) / pageHeight`) and converts back at paint time
inside `pagePaintCallbacks`. Because only fractions are stored, annotations
stay correctly positioned across zoom (100%/150%/200%…), window resize,
page scrolling, orientation changes and application restarts. Raw screen or
viewport coordinates are never persisted.

### Annotation lifecycle

```
text selection (engine)
   ↓ captureTextSelection() → PdfTextSelectionSnapshot (text + fragments)
context action (copy / highlight / underline / strikethrough / note)
   ↓ Reader screen handler
AnnotationService / NoteService (undoable mutation + persist)
   ↓ provider listener + initial sync on open
PdfViewerHandle.setAnnotationOverlays() → engine repaint
```

The adapter never clears the selection before the application has consumed
it; the Reader screen clears it after the operation completes.

### Bookmarks vs PDF outline

Application bookmarks (`ReaderBookmark`) are persisted in
`titan.reader.bookmarks` and fully managed by `BookmarkService`. The PDF's
native outline is read at runtime through `loadOutline()`/
`goToOutlineEntry(path)` — surfaced in the same panel, never persisted,
never conflated with app bookmarks.

### Notes

Notes reference pages and (optionally) selected text or an annotation id.
The reference is loose: deleting the annotation never invalidates the note.

### Undo/redo

Each service owns a `ReaderUndoStack` (capacity 100). Every mutation is a
`ReaderOperation(label, scope, apply, revert)` executed through the stack
and persisted afterwards, so undo/redo is durable, not just in-memory.
Undo/redo is Reader-scoped and never affects other applications.

## Key invariants

- `pdfrx` is imported nowhere outside `src/pdf/pdfrx_pdf_engine.dart`.
- Every imported document starts `DocumentPrivacyState.localOnly`.
- Invalid files never reach storage: validation happens in
  `LibraryService.importFile` before any write.
- Annotations, bookmarks and notes are Reader-managed data; nothing is
  written into the PDF file itself.
