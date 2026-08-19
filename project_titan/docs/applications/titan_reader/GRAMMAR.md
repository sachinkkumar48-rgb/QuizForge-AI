# TITAN Reader — Grammar & Spelling

Phase 4 introduces deterministic, offline-first grammar and spelling
assistance for selected text in TITAN Reader.

## Architecture

The grammar system follows TITAN Clean Architecture principles, ensuring that
the UI and domain layers never depend directly on WordNet, HTTP, JSON, or any
concrete remote API.

```
Reader Screen / Selection Toolbar
       ↓
Grammar Panel (`widgets/grammar_panel.dart`)
       ↓
Grammar Service (`services/grammar_service.dart`)
       ↓
GrammarEngine Abstraction (`data/grammar_engine.dart`)
       ├── LocalGrammarEngine (default, 100% offline)
       │     ├── RuleGrammarChecker (`data/local_rule_engine.dart`)
       │     └── WordNetSpellChecker (`data/spell_checker.dart`)
       └── RemoteGrammarSource (optional, opt-in)
             └── LanguageToolApiSource (`data/remote_grammar_source.dart`)
```

## Local Spelling Engine

- **Dataset reuse**: The spelling engine directly reuses the sorted headword
  index from the bundled WordNet 3.0 dictionary (147,306 words) via
  `DictionaryHeadwordIndex`. No second dictionary or duplicate asset is shipped.
- **Candidate generation**: Generates suggestions using Damerau-Levenshtein
  distance 1 (single deletion, transposition, substitution, or insertion). Only
  when distance 1 yields no results does it evaluate distance 2.
- **Sorting and limits**: Suggestions are sorted alphabetically and capped to
  `maxSuggestions` (default 5). No arbitrary confidence scores are fabricated.
- **Token handling**:
  - Contractions (`don't`, `they'll`, `we've`, `i'm`) are split and validated
    against known word bases and valid contraction suffixes.
  - Acronyms (all-caps words of length >= 2) and capitalized mid-sentence tokens
    (probable proper nouns) are skipped to prevent false positives.
  - Valid single-letter words (`a`, `I`) are recognized.

## Implemented Grammar Rules

The local rule engine (`RuleGrammarChecker`) is intentionally lightweight,
deterministic, and explainable. No fuzzy heuristics or unverified AI outputs
are reported as facts.

| Rule ID | Category | Severity | Description | Correction Behavior |
| ------- | -------- | -------- | ----------- | ------------------- |
| `rule.repeated-word` | Typographical | Error | Detects duplicate consecutive words (`the the`) | Deletes separator and second word |
| `rule.sentence-capitalization` | Style | Warning | Detects uncapitalized sentence starters after `[.!?]` | Capitalizes first letter |
| `rule.standalone-i` | Style | Error | Flags lowercase `i` pronoun | Replaces with uppercase `I` |
| `rule.double-space` | Typographical | Warning | Flags consecutive spaces between words | Replaces with single space |
| `rule.doubled-punctuation` | Typographical | Warning | Flags doubled punctuation marks (`,,`, `;;`, `!!`, `??`) | Reduces to single mark |
| `rule.punctuation-space-after` | Punctuation | Warning | Flags missing space following `,`, `;`, or `:` | Inserts trailing space |
| `rule.punctuation-space-before` | Punctuation | Warning | Flags whitespace preceding `,`, `;`, or `:` | Removes preceding space |
| `rule.modal-of` | Grammar | Error | Flags modal verbs paired with `of` (`would of`, `could of`, `should of`, `might of`, `must of`) | Replaces with modal + `have` |
| `rule.alot` | Spelling | Error | Flags single-word `alot` / `Alot` | Replaces with `a lot` / `A lot` |
| `rule.article-agreement` | Grammar | Warning | Detects indefinite article mismatch (`a apple`, `an car`) with vowel/consonant sound heuristics | Replaces `a` ↔ `an` |
| `spelling.unknown-word` | Spelling | Error | Flags words absent from WordNet index | Suggests Damerau-Levenshtein candidates |

*Note on Rule / Spelling interaction*: If a spelling issue falls inside a span
already flagged by a grammar rule (e.g. `alot`), `LocalGrammarEngine` suppresses
the redundant spelling error so each problem is reported cleanly once.

## Offset Safety & Correction Applier

- Offsets (`startOffset`, `endOffset`) are character indices into the checked
  selection string, never raw PDF coordinates.
- Multi-word and multi-paragraph selections maintain exact character offsets.
- `GrammarTextCorrection.apply` applies replacements from right to left,
  ensuring that earlier spans do not get shifted or corrupted by length
  differences.
- Overlapping spans are handled safely (the earlier span is retained).

## PDF Editing Boundary

> [!IMPORTANT]
> **Grammar Analysis ≠ PDF Text Editing**
> The current PDF rendering engine (`pdfrx`) does not support rewriting text in
> compiled PDF documents. Applying a suggestion **never** alters the original PDF
> file. Instead, accepted corrections are stored as **Reader-managed records** in
> `titan.reader.grammar.corrections`. Users can review, copy corrected text to
> clipboard, and track changes safely. Native PDF text modifications belong to
> Phase 6.

## Offline Capability & Privacy

- **Default Mode**: `LOCAL_ONLY`. Local grammar checking and spell checking
  operate with 100% offline functionality.
- **Privacy Assurance**: No document content, annotations, or metadata are ever
  transmitted automatically.
- **Optional Remote Fallback**: Users may explicitly opt in to online checks
  via `LanguageToolApiSource`. When enabled:
  - Only the selected text snippet and language code are transmitted.
  - The entire PDF is never uploaded.
  - Remote failures fail gracefully, reporting the network status while preserving
    local results.

## Caching Strategy

Checked text results are cached in `titan.reader.grammar.cache` under a
versioned key format:
```
grammar:<engineId>:<engineVersion>:<language>:<sha256(text)>
```
- Exact matches hit the cache instantly without re-running tokenization or edit distance checks.
- Engine version changes automatically invalidate previous cache entries.

## Phase 3 Integration (Dictionary & Vocabulary)

- When a single-word spelling mistake is detected, the Grammar Panel exposes
  direct actions:
  - **Dictionary**: Opens the Phase 3 `DictionaryPanel` for definition and synonym lookup.
  - **Save Word**: Directly saves the word to **My Vocabulary** with full source context (document ID, document name, page number).
- Zero duplication: reuses `DictionaryService` and `VocabularyService` without parallel implementations.
