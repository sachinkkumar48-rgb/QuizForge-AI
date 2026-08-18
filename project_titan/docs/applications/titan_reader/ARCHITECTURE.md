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
    │   └── document_search_bar.dart # debounced search panel + match nav
    ├── domain/entities/
    │   ├── reader_document.dart     # library entry (LOCAL_ONLY by default)
    │   ├── reading_position.dart    # page + total pages + timestamp
    │   ├── reading_visit.dart       # history entry for the Recent shelf
    │   └── document_privacy_state.dart
    ├── data/
    │   ├── document_library_repository.dart  # StorageService-backed library
    │   └── reading_position_repository.dart  # StorageService-backed positions
    ├── services/
    │   ├── library_service.dart     # import validation + library mutations
    │   └── reading_history_service.dart      # Recent ordering/cap/dedup
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

## Key invariants

- `pdfrx` is imported nowhere outside `src/pdf/pdfrx_pdf_engine.dart`.
- Every imported document starts `DocumentPrivacyState.localOnly`.
- Invalid files never reach storage: validation happens in
  `LibraryService.importFile` before any write.
