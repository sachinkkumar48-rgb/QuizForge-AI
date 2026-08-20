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

## Phase 3 coverage

- `phase3_entities_test.dart` — word normalization rules, entity JSON
  round-trips, mastery-status fallback, typed dictionary errors.
- `phase3_repositories_test.dart` — gzipped shard decoding against fake
  in-memory assets (including corrupt-shard handling), shard key rules,
  prefix binary search, cache/recent/vocabulary storage repositories and
  malformed-payload tolerance.
- `phase3_services_test.dart` — local-first pipeline (local hit, offline
  miss, phrase rejection, remote fill + cache short-circuit, transport
  failure → typed failure), recent-lookup dedup/cap, vocabulary CRUD,
  restart persistence, sort/search, dictionaryapi.dev parsing.
- `dictionary_panel_test.dart` — entry rendering (definitions, examples,
  synonyms/attribution), save + duplicate-save, offline-unavailable state,
  synonym push/back stack, recent lookups + clear, suggestions.
- `vocabulary_screen_test.dart` — list/source subtitle, search, status
  change + filter, delete, personal-meaning edit, open-source navigation,
  empty state, tile → dictionary entry.
- `dictionary_integration_test.dart` — the three mandated workflows plus
  §50 acceptance:
  1. select `"Ephemeral,"` → dictionary → save → vocabulary → reopen entry;
  2. save records source page → open source → reader at the right
     PDF/page;
  3. fully offline lookup/save/restart persistence with no remote source;
  4. acceptance against the **real bundled WordNet assets** (ephemeral
     resolves, definitions non-empty, attribution present, restart-safe).

## Phase 4 coverage

- `phase4_entities_test.dart` — `GrammarIssue`, `GrammarSuggestion`, `GrammarCheckResult`,
  and `GrammarCorrection` JSON serialization/deserialization, defensive clamping,
  `spanIn` bounds safety, right-to-left `GrammarTextCorrection.apply` offset preservation,
  and overlapping span resolution.
- `phase4_engine_test.dart` — deterministic grammar rules (`repeated-word`,
  `sentence-capitalization`, `standalone-i`, `double-space`, `doubled-punctuation`,
  `punctuation-space-after/before`, `modal-of`, `alot`, `article-agreement`), WordNet
  headword spell checking (edit distance 1 & 2, contraction handling, acronym skipping),
  and `LocalGrammarEngine` issue merging and suppression.
- `phase4_repositories_test.dart` — `GrammarCacheRepository` versioned keys and cache
  lifecycle, `GrammarCorrectionRepository` storage persistence, `LanguageToolApiSource`
  request formatting, HTTP error mapping, and malformed response tolerance.
- `phase4_services_test.dart` — `GrammarService` local-first orchestration, cache hits,
  engine update invalidation, opt-in remote merging, graceful remote failure fallback,
  and Reader-managed correction persistence.
- `grammar_panel_test.dart` — `GrammarPanel` widget states (loading, error, no issues,
  issue rendering), suggestion copy/apply, dismiss, Dictionary open, and Save Word actions.
- `reader_phase4_test.dart` — PDF text selection context toolbar → Grammar action integration,
  panel presentation, and selection clearing.
- `grammar_workflow_integration_test.dart` — end-to-end integration workflows:
  1. Selected text → grammar analysis → issue rendering → apply correction →
     Reader-managed correction persistence.
  2. Single-word spelling error → direct Dictionary definition lookup & Vocabulary save.
  3. Fully offline checking resilience with remote features disabled.

## Widget-test conventions (learned the hard way)

- **No real `dart:io` inside `testWidgets`.** The test body runs in a
  FakeAsync zone where real file-system operations never complete, hanging
  the suite indefinitely. Import fixtures by passing `headerBytes` directly
  to `LibraryService.importFile`, use fictional paths, and inject
  `ReaderScreen(fileExists:)` instead of touching disk.
  *Exception:* router-driven integration tests cannot inject `fileExists`,
  so they create a tiny real temp PDF in `setUp` (async IO in `setUp` is
  safe) and delete it in `tearDown`.
- Prefer bounded `tester.pump()` sequences; avoid `pumpAndSettle` near
  anything that can schedule frames continuously.
- Tooltip finders must be scoped (`find.descendant`) when the same tooltip
  text appears on the AppBar toggle and the search bar.
- Snackbars raised while a modal bottom sheet is open render **below** the
  sheet route; dismiss the sheet in tests before tapping snackbar actions.
- Snackbars are **queued** by `ScaffoldMessenger`: a second snackbar only
  appears after the first expires. Dismiss the first (or split into
  separate `testWidgets`) before asserting the next message.
- The module-level `readerRouter` keeps navigation state between tests;
  router-based tests build isolated routers via `buildReaderRouter()`.
- Multi-line `Text` subtitles need `find.textContaining`, not `find.text`.
- Asset directories are not recursive in `pubspec.yaml`: `shards/` is
  listed separately so `flutter test` bundles it.

## Phase 6A coverage

- `ast_parser_writer_test.dart` — low-level PDF tokenizer, AST nodes, dictionary/array manipulation, xref offset calculation, and parser/writer roundtrips.
- `phase6a_manipulation_engine_test.dart` — `DefaultPdfManipulationEngine` operational tests for all 9 operations (merge, split, extract, delete, reorder, rotate, insert blank, insert from PDF, page labels) using synthetically generated valid test PDFs.
- `phase6a_entities_test.dart` — `PdfPageRange` parsing, formatting, validation, `PdfPageLabelRange` styling/numbering rules, and typed PDF manipulation exceptions.
- `phase6a_manipulation_service_test.dart` — non-destructive file safety, collision-free filename generator, preflight validation against bad files, and postflight atomic write verification.
- `phase6a_workflows_integration_test.dart` — end-to-end safe workflows: multi-document merge, range split, extract/delete/reorder pipelines, and disk validation.
- `merge_pdfs_dialog_test.dart` — `MergePdfsDialog` UI states, empty state, file selection list, reordering, item removal, and merge execution.
- `organize_pages_dialog_test.dart` — `OrganizePagesDialog` UI grid, single/multi page selection, rotate clockwise/counter-clockwise, delete selected, move left/right, and atomic save.

## Running

```powershell
cd apps/titan_reader
flutter test                                     # full suite (382 tests)
dart analyze project_titan/apps/titan_reader     # 0 issues
dart format --set-exit-if-changed lib test       # 0 changed
```
