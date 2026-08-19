# TITAN Reader — Testing

## Strategy

- **Domain/data/services**: plain `test()` against `InMemoryStorageService`
  from `titan_storage` — JSON round-trips, clamping, ordering, dedup, caps,
  malformed-payload tolerance, import validation (extension, size, `%PDF-`
  magic, encryption marker), re-import dedupe and cascade removal.
- **Widgets/screens**: `testWidgets` with `ProviderScope` overrides —
  `storageServiceProvider` → in-memory storage, `pdfEngineProvider` →
  `FakePdfEngine`. No platform channels, no native PDFium.
- **Navigation**: `app_shell_test.dart` boots the real `TitanReaderApp`
  router and checks the initial route plus the error builder.

## Fake engine

`test/support/fake_pdf_engine.dart` provides:

- `FakePdfEngine` — records `lastHandle`; `buildViewer` records
  `lastFilePath`/`lastSettings` and returns a plain `SizedBox`.
- `FakeViewerHandle` — scriptable page/search listeners, visited pages,
  zoom/rotate counters, match lists; scriptable text selection
  (`scriptedSelection`), outline (`scriptedOutline`) and recorded
  annotation overlays (`lastOverlays`); test hooks `firePageChanged`,
  `fireSearchChanged` and `fireSelectionChanged` simulate engine events.

## Phase 2 coverage

- `phase2_entities_test.dart` — entity JSON round-trips, wire fallbacks,
  note matching, normalized-rect clamping/reordering and zoom-invariant
  scaling.
- `phase2_repositories_test.dart` — per-document persistence, namespace
  isolation between annotations/bookmarks/notes and the library, malformed
  payload handling.
- `phase2_services_test.dart` — CRUD, color changes, search, durable
  undo/redo across add/edit/delete, cascade-safe `clearDocument`.
- `reader_phase2_test.dart` — user flows end to end: selection toolbar
  actions, highlight/bookmark/note **persistence across a simulated
  restart** (fresh engine, same storage), outline navigation, panel
  delete+undo, coordinate stability of restored overlays.

## Widget-test conventions (learned the hard way)

- **No real `dart:io` inside `testWidgets`.** The test body runs in a
  FakeAsync zone where real file-system operations never complete, hanging
  the suite indefinitely. Import fixtures by passing `headerBytes` directly
  to `LibraryService.importFile`, use fictional paths, and inject
  `ReaderScreen(fileExists:)` instead of touching disk.
- Prefer bounded `tester.pump()` sequences; avoid `pumpAndSettle` near
  anything that can schedule frames continuously.
- Tooltip finders must be scoped (`find.descendant`) when the same tooltip
  text appears on the AppBar toggle and the search bar.
- Snackbars raised while a modal bottom sheet is open render **below** the
  sheet route; dismiss the sheet in tests before tapping snackbar actions.

## Running

```powershell
cd apps/titan_reader
flutter test                                     # full suite (111 tests)
dart analyze .                                   # 0 issues
dart format --set-exit-if-changed lib test       # 0 changed
```
