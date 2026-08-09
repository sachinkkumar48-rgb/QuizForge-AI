# P6 — Case Law Search Engine

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 6 of GARUDA Landmark Case Law)
**Base:** P5 `Precedent & Doctrine Graph` at commit `efa0926`
**Status:** ✅ P6 implemented & verified (0 analyzer issues, all tests green)

---

## 1. What P6 adds

An **offline-first, deterministic, in-memory search engine** over the existing
49-case landmark corpus. It makes the P3 records **and** the P4 Judgment
Intelligence layers searchable, and queries the P5 graph for relationship- and
doctrine-aware discovery. It introduces **no** search infrastructure:
no Elasticsearch, Meilisearch, SQLite FTS, embeddings, vector databases or
LLM semantic search — only the Dart standard library plus `meta`.

```
search/
  domain/   case_search_enums.dart     CaseSearchUpscDimension, SearchEvidenceStatus,
                                        relevanceRank
            case_search_result.dart     CaseSearchResult (ranked hit, serializable)
            case_search_suggestion.dart CaseSearchSuggestion + kind enum
            case_search_query.dart      CaseSearchQuery (term + filters + limit)
            case_search_filters.dart    CaseSearchFilters (composable, evidence-aware)
  data/     case_search_normalizer.dart deterministic normalization (pure string ops)
            case_search_index.dart      inverted indexes over the real corpus
  service/  case_search_engine.dart     CaseSearchEngine (public API, P5 integration)
```

## 2. Architecture

`CaseSearchEngine` is the single public entry point. At construction it:

1. resolves (or builds once) the shared `LegalGraph`,
2. wires the P5 services (`PrecedentGraphService`, `DoctrineRelationshipService`,
   `LegalGraphTraversalService`) onto that same graph,
3. builds a `CaseSearchIndex` over `CaseSeedData.cases` (or an injected subset),
   feeding it the doctrine node names and doctrine→case sets from the P5
   `DoctrineRelationshipService`.

Search and graph remain **separate responsibilities**. The engine *reads* the
P5 graph through its public services; it never rebuilds, mutates or bypasses the
graph, and it never reimplements traversal. Free-text scoring lives entirely in
the engine; relationship/doctrine discovery delegates to P5.

## 3. Indexes

All indexes are deterministic `Map`/`Set` structures built from the corpus at
construction time. There are no hard-coded results.

| Index | Key (normalized) | Value |
|---|---|---|
| `_byCaseId` | case ID | `CaseKnowledgeObject` |
| `_caseNameToId` | case name | case ID |
| `_byAlias` | alias | `Set<caseId>` |
| `_byArticle` | article key (`21`, `191a`) | `Set<caseId>` |
| `_byAct` | act | `Set<caseId>` |
| `_byDoctrine` | doctrine ID | `Set<caseId>` |
| `_byJudge` | judge | `Set<caseId>` |
| `_byYear` | year | `Set<caseId>` |
| `_byCourt` | court | `Set<caseId>` |
| `_keywordIndex` | word token | `Set<caseId>` |
| `_keywordFrequency` | word token | corpus occurrence count |
| `_vocabulary` | suggestions | `CaseSearchSuggestion` list |

The keyword index is built by tokenising every searchable field value of every
case (see `searchableFieldValues`), so candidate generation is a cheap union of
token postings. Structured finders (`findByArticle`, …) hit the dimension
indexes directly.

## 4. Normalization

`CaseSearchNormalizer` is pure, deterministic string normalization — no
stemming, no opaque ML transforms.

- **lowercase + trim**
- **punctuation → single space**, repeated whitespace collapsed
- **article-variant folding**: `Article 21`, `Art. 21`, `art 21`, `article21`,
  `art21` all normalize to text `article 21` and to the article key `21`;
  `Article 19(1)(a)` → key `191a`; `Article 323A` → key `323a`.
- **match quality** (`matchWeight`): exact `1.0` > whole-value prefix `0.7` >
  token prefix `0.6` > whole-value substring `0.4` > token substring `0.35` >
  none `0.0`.

Article *keys* are also matched directly against the `article` field values, so
`findByArticle('191a')` and `findByArticle('Article 19(1)(a)')` resolve the same
cases.

## 5. Ranking

Deterministic, explainable, stable and testable.

```
score(case) = Σ over matched fields of  fieldWeight × matchQuality
            + UPSC-relevance boost when an UPSC filter is active
```

Field weights (`searchFieldWeights`) implement the documented priority:
case name 100 > alias 90 > citation 80 > article/act/doctrine 60 > keyword 55 >
section 55 > judge 50 > issue 40 > holding 30 > ratio 30 > reasoning 25 >
outcome 25 > significance 25 > upsc 20 > timeline 15 > free text 10.

**Tie-break** (total order): score desc → year desc → case name asc → case ID
asc. Two runs of the same query return byte-identical orderings.

## 6. Search API

```dart
final engine = CaseSearchEngine();                 // full corpus + P5 graph

engine.search(CaseSearchQuery(term: 'basic structure', filters: ..., limit: 10));
engine.searchWithFilters('privacy', CaseSearchFilters(articles: {'21'},
    upscDimensions: {CaseSearchUpscDimension.mains}));
engine.findExact('KESAVANANDA');                   // canonical ID / name / unique alias
engine.findByArticle('21');                        // Article 21 | Art. 21 | article21
engine.findByAct('Passports Act, 1967');
engine.findByDoctrine('Basic Structure');          // ID or name → graph roles
engine.findByJudge('Khanna');
engine.findByYear(1973);
engine.findByYearRange(1975, 1980);
engine.findByRelationship('KESAVANANDA', type: PrecedentRelationshipType.followed);
engine.findRelatedCases('KESAVANANDA', maxHops: 1);
engine.findByUpscRelevance(CaseSearchUpscDimension.mains,
    minimum: RelevanceLevel.high);
engine.autocomplete('golak');                      // List<String>
engine.suggestions('khanna');                      // List<CaseSearchSuggestion>
```

Filters compose and narrow (Article 21 AND privacy AND mains). An empty query
with no filters browses the whole corpus in tie-break order; a non-blank term
that matches nothing returns **no** results (not the whole corpus).

## 7. P5 integration boundary

| P6 | P5 (unchanged, reused) |
|---|---|
| `findByRelationship(...)` | `PrecedentGraphService.incoming/outgoingRelationships`, `relatedCases`, `casesFollowing/Overruling/Distinguishing` |
| `findByDoctrine(...)` | `DoctrineRelationshipService.getCasesForDoctrine`, `allDoctrines`, `getCasesEstablishing` |
| `findRelatedCases(maxHops>1)` | `LegalGraphTraversalService.neighborsWithinHops` |
| relationship filter | graph edges by `PrecedentRelationshipType` |

P6 does **not** rebuild precedent/doctrine graphs, store relationships, run
traversals, or compute graph analytics. Those remain P5's job.

## 8. Evidence discipline

Search never invents or synthesizes legal facts. It ranks and filters existing
verified records. Every `CaseSearchResult` exposes its `evidenceStatus`
(`verified` / `editorial` / `unverified`) derived from the record's own evidence
IDs against `CaseOfficialSources`; the `evidenceOnly` filter narrows to verified
records. P4/P5 evidence validation architecture is not duplicated.

## 9. Offline-first rationale

The corpus is ~49 cases — small enough that in-memory inverted indexes rebuild
in milliseconds and answer every query deterministically with zero network, zero
external services and zero vendor lock-in. The design stays compatible with
growth: the index is constructed from data, so adding Phase-III cases only
requires the corpus to grow; the token keyword index and structured dimension
indexes scale comfortably to the low thousands of records before any
architecture change is warranted (see *Extension strategy*).

## 10. Limitations

- **Clause-form article ambiguity**: normalizing strips punctuation, so
  `Article 15(6)` and `Article 156` both key to `156`. Full-text matching on the
  original strings still distinguishes them; only the bare-key filter path
  conflates them.
- **No fuzzy / typo tolerance**: matching is exact/prefix/substring only, by
  design (deterministic, no ML).
- **Shared aliases are ambiguous for exact lookup**: e.g. `Capitation Fee Case`
  is shared by `UNNIKRISHNAN` and `MOHINI_JAIN`; `findExact` returns `null` for
  such aliases while `search` returns both owners.
- **Petitioner/respondent fields are not indexed** because the P3 corpus does
  not populate them; party names are still searchable through the case name.
- **No persistence**: the index is rebuilt on construction (in-memory only).

## 11. Extension strategy

- **More fields** → extend `searchableFieldValues`; weights live in
  `searchFieldWeights`.
- **Fuzzy matching** → replace the pure-prefix `matchWeight` with an
  edit-distance layer behind the same function signature (keeps the ranking
  contract).
- **Larger corpora** → persist the token postings or back the engine with a
  lightweight FTS; the engine's public API and result model are already
  serializable, so consumers need no changes.
- **New graph dimensions** → the engine already delegates to P5; add finders
  that call new P5 methods without touching the graph internals.
