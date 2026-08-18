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
  zoom/rotate counters, match lists; test hooks `firePageChanged` and
  `fireSearchChanged` simulate engine events.

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

## Running

```powershell
cd apps/titan_reader
flutter test                                     # full suite (56 tests)
flutter analyze                                  # 0 issues
dart format --set-exit-if-changed lib test       # 0 changed
```
