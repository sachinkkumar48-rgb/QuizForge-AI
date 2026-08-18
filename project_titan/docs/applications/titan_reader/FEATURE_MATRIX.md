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
| Thumbnails | ⏳ | pdfrx supports page images; UI not built yet | — |
| Recent documents shelf | ✅ | `_RecentShelf` in library screen | `library_screen_test.dart` |
| Reading history (ordering, dedup, cap) | ✅ | `services/reading_history_service.dart` | `reading_history_service_test.dart` |
| Last reading position (restore + persist) | ✅ | `reader_screen.dart` + position repo | `reader_screen_test.dart` |
| Document metadata (size, added, page count) | ✅ | `ReaderDocument` entity | `entities_test.dart`, `repositories_test.dart` |
| Basic text search | ✅ | `widgets/document_search_bar.dart` | `document_search_bar_test.dart` |
| Search result navigation (prev/next/list) | ✅ | search bar + handle match APIs | `document_search_bar_test.dart` |
| Favorites + removal (cascade) | ✅ | library screen + service | `library_screen_test.dart`, `library_service_test.dart` |

## Later phases (planned)

| Feature | Status | Notes |
| ------- | ------ | ----- |
| Text selection foundation for dictionary | ⏳ | `textSelectionEnabled` already in `PdfViewerSettings` |
| Dictionary lookup | ⏳ | Phase 2 |
| Grammar + vocabulary tools | ⏳ | Phase 3+ |
| AI reading assistant (opt-in) | ⏳ | requires privacy-state transitions, see PRIVACY.md |

## Quality gates (current)

- `flutter test`: 56 tests passing
- `flutter analyze`: 0 issues
- `dart format --set-exit-if-changed lib test`: clean
