# TITAN Reader — Feature Matrix

Status: ✅ shipped · 🚧 in progress · ⏳ planned

## Phase 1 — Reader foundation

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| App shell + bootstrap (storage, ProviderScope) | ✅ | `main.dart`, `app.dart` | `app_shell_test.dart` |
| Navigation (go_router, error handling) | ✅ | `navigation/reader_router.dart` | `app_shell_test.dart` |
| Light/dark theme | ✅ | `theme/reader_theme.dart` | analyze + app boot |
| Library list with metadata | ✅ | `screens/library_screen.dart`, `widgets/document_card.dart` | `library_screen_test.dart` |
| PDF import with validation (titan_pdf rules) | ✅ | `services/library_service.dart` | `library_service_test.dart` |
| Open + render PDF (pdfrx behind abstraction) | ✅ | `pdf/pdfrx_pdf_engine.dart` | `reader_screen_test.dart` (fake engine) |
| Continuous scrolling | ✅ | pdfrx default viewer mode | manual/device |
| Page navigation | ✅ | `reader_screen.dart` slider + engine events | `reader_screen_test.dart` |
| Page number display | ✅ | reader bottom bar | `reader_screen_test.dart` |
| Page slider | ✅ | reader bottom bar | `reader_screen_test.dart` |
| Zoom in/out | ✅ | handle `zoomIn`/`zoomOut` | `reader_screen_test.dart` |
| Fit width / fit page | ✅ | view-options menu → `applyFitMode` | `reader_screen_test.dart` |
| Rotation (presentation-level) | ✅ | view-options menu → `rotateClockwise` | `reader_screen_test.dart` |
| Recent documents shelf | ✅ | `_RecentShelf` in library screen | `library_screen_test.dart` |
| Reading history (ordering, dedup, cap) | ✅ | `services/reading_history_service.dart` | `reading_history_service_test.dart` |
| Last reading position (restore + persist) | ✅ | `reader_screen.dart` + position repo | `reader_screen_test.dart` |
| Document metadata (size, added, page count) | ✅ | `ReaderDocument` entity | `entities_test.dart`, `repositories_test.dart` |
| Basic text search | ✅ | `widgets/document_search_bar.dart` | `document_search_bar_test.dart` |
| Search result navigation (prev/next/list) | ✅ | search bar + handle match APIs | `document_search_bar_test.dart` |
| Favorites + removal (cascade) | ✅ | library screen + service | `library_screen_test.dart`, `library_service_test.dart` |

## Phase 2 — Annotations, bookmarks & notes

All Phase 2 data is **Reader-managed**: persisted in TITAN storage
(`titan.reader.*` namespaces), rendered as engine overlays. It is NOT
embedded into the PDF file (pdfrx 2.4.7 cannot create PDF-native
annotations) — see PDF_ENGINE.md.

| Feature | Status | Where | Verified by |
| ------- | ------ | ----- | ----------- |
| Text selection capture (text + geometry) | ✅ | `PdfViewerHandle.captureTextSelection` | `reader_phase2_test.dart` |
| Highlight (5 colors, add/remove/recolor) | ✅ | `annotation_service.dart`, overlays | `phase2_services_test.dart`, `reader_phase2_test.dart` |
| Underline (add/remove) | ✅ | same pipeline, `PdfOverlayStyle.underline` | `reader_phase2_test.dart` |
| Strikethrough (add/remove) | ✅ | same pipeline, `PdfOverlayStyle.strikethrough` | `reader_phase2_test.dart` |
| Annotation persistence + restore after restart | ✅ | `titan.reader.annotations` namespace | `reader_phase2_test.dart` (restart test) |
| Overlay rendering stable across zoom/resize | ✅ | normalized rects → `pagePaintCallbacks` | `phase2_entities_test.dart`, restart test |
| Selection context toolbar (Copy/Highlight/Underline/Strikethrough/Note) | ✅ | `customizeContextMenuItems` adapter hook | `reader_phase2_test.dart` |
| Dictionary / Grammar placeholders | ✅ | placeholder snackbars (later phases) | `reader_phase2_test.dart` |
| Bookmarks (add/remove/edit/list/navigate) | ✅ | `bookmark_service.dart`, `bookmarks_panel.dart` | `phase2_services_test.dart`, `reader_phase2_test.dart` |
| Bookmark persistence + restore after restart | ✅ | `titan.reader.bookmarks` namespace | `reader_phase2_test.dart` (restart test) |
| PDF-native outline reading + navigation | ✅ | `loadOutline`/`goToOutlineEntry` (never persisted) | `reader_phase2_test.dart` |
| Notes (add/edit/delete/search/navigate) | ✅ | `note_service.dart`, `notes_panel.dart` | `phase2_services_test.dart`, `reader_phase2_test.dart` |
| Notes survive annotation deletion | ✅ | loose `annotationId` reference | `phase2_entities_test.dart` |
| Note persistence + restore after restart | ✅ | `titan.reader.notes` namespace | `reader_phase2_test.dart` (restart test) |
| Reader-scoped undo/redo | ✅ | `reader_undo_stack.dart` + service stacks | `phase2_services_test.dart`, `reader_phase2_test.dart` |
| PDF-native annotation export/import | ⏳ | not supported by pdfrx 2.4.7; model designed for future mapping | — |

## Later phases (planned)

| Feature | Status | Notes |
| ------- | ------ | ----- |
| Thumbnails | ⏳ | pdfrx supports page images; UI not built yet |
| Dictionary lookup | ⏳ | Phase 3; selection toolbar slot already reserved |
| Grammar + vocabulary tools | ⏳ | Phase 3+ |
| AI reading assistant (opt-in) | ⏳ | requires privacy-state transitions, see PRIVACY.md |
| PDF-native annotation export/import | ⏳ | blocked on engine capability |

## Quality gates (current)

- `flutter test`: 111 tests passing
- `dart analyze`: 0 issues
- `dart format --set-exit-if-changed lib test`: clean
