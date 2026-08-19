# TITAN Reader — Phase 3 Completion Report

Phase 3: **Dictionary + Thesaurus + Vocabulary** — completed on top of the
Phase 2 selection pipeline (checkpoint `7b8b0a3`) without touching QuizForge
AI or introducing a second architecture.

## Scope

All changes are confined to:

- `project_titan/apps/titan_reader/**` (implementation + tests + assets)
- `project_titan/docs/applications/titan_reader/**` (documentation)
- `project_titan/tools/build_wordnet_dictionary.py` (dataset build pipeline)

No shared TITAN package was modified during Phase 3; no QuizForge file was
modified.

## Dictionary source investigation (§2–3)

Candidates reviewed before implementation:

| Source | License | Verdict |
| ------ | ------- | ------- |
| **WordNet Release 3.0** (Princeton) | Permissive: free to use, copy, modify and distribute for any purpose without fee, provided the copyright notice appears on all copies | ✅ Selected |
| Wiktionary dumps | CC BY-SA (share-alike, large/irregular dumps) | Rejected |
| dictionaryapi.dev | Free remote API, no redistribution rights | Optional **off-by-default** online fallback only |
| GCIDE / Webster 1913 | Public domain but stale language, inconsistent markup | Rejected |

License attribution ships in `assets/dictionary/manifest.json` and is
rendered inside every bundled entry. Full detail: `DICTIONARY.md`.

## Features implemented

### Offline-first dictionary lookup

- Select word → Dictionary panel → definitions, part of speech, usage
  examples, synonym/antonym chips, WordNet attribution.
- Lookup pipeline: bundled local source → dictionary cache → remote source
  (only if `remoteLookupEnabled == true`) → record recent lookup.
- Word normalization (`"Ephemeral,"` → `ephemeral`); multi-word selections
  rejected before lookup (§14).
- Explicit UI states: loading / success / not-found / offline-unavailable /
  typed failure. Raw HTTP errors never reach the user (§16–18).

### Bundled dataset (never the whole dictionary in memory — §39)

- 147,306 words across 553 gzipped JSON shards + `headwords.json.gz` +
  `manifest.json` (~9 MB compressed total).
- Shard key = first two letters (alphabetic) else `_` + first character;
  shards load lazily behind an LRU cache (max 12 decoded shards).
- Build pipeline: `project_titan/tools/build_wordnet_dictionary.py`.

### Recent lookups

- Recorded on every completed lookup (word + timestamp, deduplicated,
  most recent first, capped); tap to reopen; clear-history action.
- Persisted to `titan.reader.dictionary.recent`.

### My Vocabulary

- Save from the panel or directly from the selection toolbar; duplicate
  saves are a no-op returning the existing entry.
- Source context recorded (document id/name, page, selected text) with
  "jump back to source" navigation to `/reader/:documentId?page=N`.
- Mastery statuses `New / Learning / Known / Mastered` — manual only, no
  spaced repetition (§27).
- Personal meaning/note are user-owned and never overwrite source-backed
  definitions.
- Persisted to `titan.reader.vocabulary`; survives restarts and document
  deletion.

### Privacy (LOCAL_ONLY default — §34)

- Remote lookup disabled by default; enabling it transmits only the
  normalized word to `api.dictionaryapi.dev` — never document, page,
  selection or identity. Cached remote entries store provenance.
- Dictionary/vocabulary are fully separate from QuizForge AI and from any
  AI feature. Grammar remains a placeholder (§35).

## Storage model

| Namespace | Content |
| --------- | ------- |
| `titan.reader.dictionary.cache` | remote lookup cache with provenance (`dictionary:<word>`, `index`) |
| `titan.reader.dictionary.recent` | recent lookups (word + timestamp) |
| `titan.reader.vocabulary` | My Vocabulary words |

All persisted through the shared `titan_storage` `StorageService` port
(`InMemoryStorageService` in tests).

## Tests

Suite: `flutter test` in `apps/titan_reader` — **191/191 PASS**.

| File | Coverage |
| ---- | -------- |
| `phase3_entities_test.dart` | word normalization, JSON round-trips, status fallback, typed errors |
| `phase3_repositories_test.dart` | shard decode/corruption, shard keys, prefix search, cache/recent/vocabulary repos |
| `phase3_services_test.dart` | local-first pipeline, remote fill + cache short-circuit, typed failures, CRUD, restart persistence, dictionaryapi.dev parsing |
| `dictionary_panel_test.dart` | entry rendering, save/duplicate-save, offline state, synonym push/back, recent lookups, suggestions |
| `vocabulary_screen_test.dart` | list/search/status filter/delete, personal-meaning edit, open-source navigation, tile → entry |
| `dictionary_integration_test.dart` | the three §36–38 workflows + §50 acceptance (ephemeral, offline restart, source jump-back) |

## Regression results

| Gate | Result |
| ---- | ------ |
| `dart analyze` (titan_reader) | 0 issues |
| titan_pdf | 5/5 PASS |
| titan_quiz | 31/31 PASS |
| titan_quiz_ai | 42/42 PASS |
| QuizForge AI (workspace root) | 234/234 PASS |
| TITAN Reader | 191/191 PASS |

## Known limitations

- **No pronunciation/phonetics**: WordNet ships no phonetics; IPA/audio
  only if a future source provides them — never faked (§8).
- **No word origin**: shown only if the source provides it.
- Grammar stays a placeholder by design (§35).
- Remote fallback is best-effort; offline behavior is the primary contract.
- Snackbars raised from the modal dictionary panel render below the sheet
  route (carried over from Phase 2).

## Phase 4 readiness

The dictionary panel and vocabulary service expose stable provider seams
(`dictionaryServiceProvider`, `vocabularyServiceProvider`,
`remoteLookupEnabledProvider`) that later phases (flashcards, spaced
repetition, grammar) can build on without touching the lookup pipeline.
Phase 3 is complete.
