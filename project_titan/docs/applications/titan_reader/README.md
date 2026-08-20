# TITAN Reader

TITAN Reader is the professional document application of Project TITAN: a PDF
reader with document management, reading-position persistence, in-document
text search, Phase 2 markup (annotations, bookmarks, notes), Phase 3
fully offline dictionary with personal vocabulary, Phase 4 local-first grammar
and spelling, and Phase 5 multi-provider AI reading assistant with RAG context
retrieval and prompt-injection defense.

- Location: `apps/titan_reader`
- Targets: **Android** and **Windows** first (Web future-compatible)
- Privacy default: every imported document is **LOCAL_ONLY** — nothing leaves
  the device (see [PRIVACY.md](PRIVACY.md))

## Phase 1 capabilities

- Library screen with PDF import (`file_picker`), validation (reuses
  `titan_pdf` rules), favorites and removal
- Recent shelf driven by the reading-history service
- Full reader: pdfrx-backed rendering, page navigation (slider + engine
  events), page number display, zoom in/out, fit width / fit page, rotation
- Last reading position restored on open and persisted on navigation/close
- Debounced in-document text search with match navigation and results list
- Light/dark theme via `ReaderTheme`

See [FEATURE_MATRIX.md](FEATURE_MATRIX.md) for the feature-by-feature status.

## Running the app

Platform scaffolding is **not committed** (monorepo convention shared with
`titan_mobile` and `quizforge_ai`). Generate it once locally:

```powershell
cd apps/titan_reader
flutter create --platforms=android,windows .
flutter pub get
flutter run
```

Windows note: pdfrx packages PDFium native assets via symlinks, so Windows
builds require **Developer Mode** enabled (Settings > System > For developers).

## Verification gates

```powershell
cd apps/titan_reader
flutter analyze                                  # 0 issues
dart format --set-exit-if-changed lib test       # 0 changed
flutter test                                     # all tests pass
```

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) — layer map and package reuse
- [DICTIONARY.md](DICTIONARY.md) — Phase 3 dictionary/vocabulary, WordNet
  license and attribution, offline strategy
- [PDF_ENGINE.md](PDF_ENGINE.md) — engine abstraction and pdfrx adapter
- [PRIVACY.md](PRIVACY.md) — LOCAL_ONLY policy
- [TESTING.md](TESTING.md) — test strategy and the fake engine
- Engine selection rationale:
  [`docs/adr/ADR-0004-titan-reader-pdf-engine-selection.md`](../../adr/ADR-0004-titan-reader-pdf-engine-selection.md)
