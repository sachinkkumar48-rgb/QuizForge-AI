# P12 — Evidence-Backed Doctrine Knowledge Products

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 12 of GARUDA Landmark Case Law)
**Base:** P11 `Case Explanations` at commit `2cb07de`
**Status:** ✅ P12 implemented & verified

---

## 1. Purpose

P12 is a **deterministic, offline-first knowledge-product composition layer** over
the already-validated P3–P11 GARUDA Case Law + Doctrine corpus. It answers:

> What do the existing validated records say about one canonical Constitutional
> Doctrine — as a structured, doctrine-level, provenance-preserving knowledge
> product?

P12 produces a single immutable **`DoctrineKnowledgeProduct`** for a canonical
doctrine: its identity and overview (verbatim from the canonical `garuda_doctrine`
record), its constituent cases with their recorded P5 roles (via the P10 doctrine
analysis), the Articles/Acts referenced by those cases (P3 corpus), precedent
relationships among members (P5 case → case edges), chronology and structural
observations (P10), UPSC information already attached to the constituent cases
(P3/P4), evidence/provenance (P8 registry + doctrine record), and one P11
`CaseExplanation` per constituent case.

P12 is **not** a legal-reasoning engine and **not** a doctrine-research tool. It
never invents doctrine development, precedent, citation, current-law status or
legal conclusions. Every statement in every section is **composed verbatim** from
existing validated P3–P11 source data, carries its **source references** and its
**provenance**, and nothing is presented without a traceable origin.

Missing data is represented by an **absent section** — never by fabricated
content. Output is **deterministic**: identical corpus + identical services
produce byte-identical structured output, in the fixed section order, with sorted
references and sorted statements.

## 2. Where it lives

```
lib/doctrine_product/
  domain/doctrine_product_enums.dart         DoctrineSectionType (fixed section
                                             vocabulary + ordering)
  domain/doctrine_product_section.dart       DoctrineSection / DoctrineStatement
  domain/doctrine_knowledge_product.dart     DoctrineKnowledgeProduct (immutable
                                             knowledge product)
  service/doctrine_knowledge_product_service.dart
                                             DoctrineKnowledgeProductService
                                             (composition)
```

The barrel `lib/garuda_case_law.dart` re-exports the four P12 files so consumers
get the whole layer from one import.

## 3. Architecture

```
          ┌─────────────────────────────────────────────────────┐
          │          DoctrineKnowledgeProductService            │
          │  deterministic, offline-first, immutable output     │
          └──────────────┬──────────────────────────────────────┘
                         │  composes ONLY existing validated data
   ┌───────────┬─────────┼───────────┬───────────────┬──────────────┐
   ▼           ▼         ▼           ▼               ▼              ▼
  garuda_    P3 corpus  P4 Judgment  P5 graph        P9 discovery   P10 doctrine
  doctrine   (articles, Intelligence (case→doctrine, (shared         analysis
  record     acts,      (UPSC        case→case        member       (chronology,
  (identity,  themes,    already     edges, roles)    overlap      observations,
  overview,   subjects,  attached)                    context)     constituent
  evidence)   evidence) │             │                            cases)
                        ▼             ▼                            │
                      P6 search    P11 CaseExplanation             ▼
                     (canonical    (one per constituent case)   P8 EvidenceEntry
                     resolution)                                 (evidence registry)
```

The service takes every dependency as an optional constructor argument and
defaults each one to the canonical in-memory corpus + services, so the default
constructor is deterministic and offline-first. Every section builder re-reads
the already-validated models and returns `null` when no validated evidence exists
for that section.

## 4. `DoctrineKnowledgeProduct`

The immutable knowledge product. One doctrine:

```dart
DoctrineKnowledgeProduct(
  doctrineId: 'BASIC_STRUCTURE',
  doctrineName: 'Basic Structure Doctrine',
  sections: [ DoctrineSection(...), ... ],
  caseExplanations: [ CaseExplanation(...), ... ],   // one per constituent case
)
```

- **`doctrineId` / `doctrineName`** — canonical `garuda_doctrine` identity.
- **`sections`** — present sections, in the fixed deterministic order below. A
  section exists only when validated evidence exists for it.
- **`caseExplanations`** — one P11 `CaseExplanation` per constituent case, in the
  same chronological order as the `constituentCases` section. Reuses P11 directly
  — P12 never re-implements case explanation logic.
- **`doctrineKind`** — fixed marker `evidence-backed-doctrine-knowledge-product`.
- **`isEmpty`** — whether no section is presentable.
- **`sectionOf(type)` / `hasSection(type)`** — accessors for one section.
- **`referencedIds`** — every canonical identifier referenced anywhere in the
  product, including the doctrine's own ID and the referenced identifiers of each
  embedded P11 explanation, de-duplicated and sorted. This is the *raw* list and
  intentionally includes non-case identifiers (doctrine IDs, edge IDs `e:…`,
  holding IDs, issue IDs, evidence IDs and normalized article keys such as
  `13`/`368`). It is **not** a list of case IDs — see
  `referencedCaseIds` below for the case-only filter.

### `DoctrineStatement`

One presented, evidence-backed item:

```dart
DoctrineStatement(
  label: 'Constituent case 1',           // deterministic presentation label
  text: 'Kesavananda Bharati v. State of Kerala (1973) — Establishes',
  sourceRefs: ['KESAVANANDA', 'e:...|establishes|BASIC_STRUCTURE', 'BASIC_STRUCTURE'],
  provenance: 'doctrine:BASIC_STRUCTURE.originatingCase',  // never empty
)
```

- `sourceRefs` is **never empty** (asserted) — every statement names what
  establishes it.
- `provenance` records the validated doctrine-record/corpus/graph/analysis field
  the content traces to (e.g. `doctrine:BASIC_STRUCTURE.originatingCase`,
  `doctrine:BASIC_STRUCTURE.officialDefinition`, `corpus:relatedArticles`,
  `p5:caseDoctrineEdges`, `p10:chronology`, `structural:chronology`).

### Section vocabulary (`DoctrineSectionType`)

Sections appear in this fixed order; a section is present only when validated
evidence exists:

1. `identity` — doctrine ID, name, origin, category, recorded status, aliases
   (from the doctrine record).
2. `overview` — official definition, plain-language explanation, one-line
   summary, purpose, scope, detailed explanation, Garuda explanation and recorded
   current position (verbatim from the doctrine record).
3. `constituentCases` — the doctrine's members with their recorded P5 roles
   (`Establishes`, `Applies`, …), via P10 doctrine analysis over P5 edges.
4. `articles` — constitutional Articles referenced by the member cases (P3
   `relatedArticles`), grouped and deterministically sorted.
5. `acts` — Acts referenced by the member cases (P3 `relatedActs`), grouped and
   deterministically sorted.
6. `precedentRelationships` — P5 case → case edges among the members, verbatim
   (`followed`, `overruled`, `distinguished`, …), never a citation.
7. `chronology` — earliest / latest / year span of the members (P10 chronology).
8. `structuralObservations` — P10 structural observations plus a deterministic
   *shared-constituent-case* overlap, explicitly marked as a non-legal structural
   grouping.
9. `upscRelevance` — UPSC information already attached to the member cases
   (relevance levels, themes, subjects), presented per case — never ranked.
10. `evidence` — doctrine-record primary source/citations/evidence references and
    each member's evidence IDs resolved through the P8 `EvidenceEntry` registry.

## 5. Service

`DoctrineKnowledgeProductService` builds products:

```dart
final service = DoctrineKnowledgeProductService();       // canonical corpus
final product = service.build('BASIC_STRUCTURE');        // DoctrineKnowledgeProduct?
final all     = service.buildAll();                      // 20 products, record order

service.doctrineIds;      // canonical doctrine IDs
service.hasDoctrine(...); // resolves by ID, name or normalized ID
service.resolveDoctrineId(...); // → canonical ID or null
service.referencedCaseIds(product); // case-only filter of referencedIds
```

`build` resolves the doctrine (by canonical ID, normalized name or normalized ID),
returns `null` for unknown input, and composes only existing validated evidence.
`buildAll` covers every canonical doctrine in `garuda_doctrine` record order.

## 6. Source hierarchy

Precedence of sources, highest first. P12 never creates a competing source of
truth:

1. canonical `garuda_doctrine` record (identity, overview, doctrine evidence);
2. P5 case → doctrine and case → case edges (constituent roles, precedent
   relationships — verbatim edge semantics);
3. P3 corpus fields (articles, acts, themes, subjects, relevance, evidence IDs);
4. P4 judgment intelligence (UPSC information already attached to cases);
5. P6 search engine (canonical doctrine/case resolution);
6. P9 discovery (related-case context, shared-member structural overlap);
7. P10 doctrine analysis (chronology, structural observations, member entries);
8. P11 case explanations (one per constituent case, reused directly).

## 7. P3–P11 reuse

- **P3** — corpus fields (`relatedArticles`, `relatedActs`, `themes`,
  `subjects`, `prelimsRelevance`/`mainsRelevance`/`essayRelevance`/
  `interviewRelevance`, `evidenceIds`, `caseName`, `year`) are read verbatim.
- **P4** — UPSC intelligence already attached to constituent cases is presented
  as-is; no new UPSC intelligence is created.
- **P5** — constituent cases come from the P5 case → doctrine edges (via P10);
  precedent relationships among members are P5 case → case edges verbatim; roles
  are recorded P5 edge evidence. The graph is never mutated.
- **P6** — doctrine/case resolution reuses the P6 search engine and P5
  doctrine-node lookup; no search/index logic is duplicated.
- **P7** — the evidence-verification predicate is reused through the P8
  `EvidenceEntry` registry.
- **P8** — evidence presentation reuses `EvidenceEntry.fromId`; P12 exposes a
  structured product that P8 can render later. No new rendering system.
- **P9** — the discovery service is composed (used for shared-member context);
  discovery never fabricates doctrine membership.
- **P10** — `CrossCaseAnalysisService.doctrineAnalysis` is the single source of
  the constituent-case section, chronology and P10 structural observations.
- **P11** — `CaseExplanationService.explain` is reused for every constituent
  case; P12 never re-implements explanation logic.

## 8. Evidence / provenance

Every substantive statement carries non-empty `sourceRefs` and a `provenance`
string naming the validated field that establishes it. Provenance is one of:

- `doctrine:<ID>.<field>` — doctrine-record field (e.g. `.officialDefinition`,
  `.originatingCase`, `.currentStatus`, `.citations`);
- `p5:caseDoctrineEdges` — P5 case → doctrine edge membership;
- `corpus:relatedArticles` / `corpus:relatedActs` / `corpus:themes` /
  `corpus:subjects` / `corpus:upscRelevance` / `corpus:evidenceIds` — P3 fields;
- `p10:chronology` — P10 chronology;
- `structural:chronology` — the P10 chronological-span observation;
- `doctrine:<ID>.<field>`-style record provenance for evidence statements, plus
  the P8 `EvidenceEntry` resolution of each member's evidence IDs.

Evidence IDs are only ever presented through the P8 registry resolution — nothing
is guessed, and unregistered IDs are presented as unresolved, never invented.

## 9. Legal-safety boundaries

P12 **never** infers or states unsupported:

- doctrinal evolution / development / expansion / narrowing / strengthening /
  weakening;
- overruling, refinement or extension beyond a recorded P5 edge;
- current-law status, legal validity, binding authority or citation
  relationships;
- legal similarity, "related doctrine" or any similarity scoring.

The composed sections (`constituentCases`, `precedentRelationships`,
`chronology`, `structuralObservations`) carry no citation vocabulary, no
"current law" claims, and no evolution/development claims. A relationship word
(`overruled`, `expanded`, `limited`, …) appears **only** where a recorded P5 edge
(`e:…`) backs it, surfaced verbatim with its P5 provenance.

P12 keeps the explicit boundaries:

**chronology ≠ causation** — the chronology section only orders members by their
authoritative dates; it never says a later case changed the doctrine.

**precedent relationship ≠ citation** — P5 edges are presented as recorded
relationships, never as citations.

**shared doctrine/overlap ≠ legal similarity** — the shared-constituent-case
overlap is presented as a structural grouping and its text explicitly says it is
"a structural grouping, not a legal relationship".

**structural observation ≠ legal conclusion** — P10 observations are re-presented
verbatim with their provenance; P12 never turns them into a verdict.

## 10. Missing-data behavior

- **Doctrine with no resolvable constituent cases** (`SPARSE_DOCTRINE` path) —
  identity, overview and doctrine-record evidence are still presented;
  member-derived sections (`constituentCases`, `articles`, `acts`,
  `precedentRelationships`, `chronology`, `structuralObservations`,
  `upscRelevance`) are **absent**; `caseExplanations` is empty; the product is
  still non-empty and never crashes.
- **Single-case doctrine** — resolves with one member; chronology collapses to a
  single point; no intra-doctrine precedent edge is invented.
- **Disconnected cases** (present in the corpus, linked to no doctrine) are never
  members of any product and never appear in any constituent statement.
- **Missing optional data** (articles, Acts, UPSC, P10 observations) → the
  corresponding section is absent.
- No placeholders (`N/A`, `TBD`), no empty statement text, no fabricated
  identifiers.

## 11. Determinism

Identical corpus + identical services produce byte-identical output:

- sections appear in the fixed `DoctrineSectionType` order;
- member cases follow P10's chronological order;
- articles/Acts are grouped and sorted by normalized key;
- themes/subjects are sorted;
- references within a section and `referencedIds` are de-duplicated and sorted;
- embedded P11 explanations are P11's own deterministic output.

Repeated and cross-instance generation is tested to be equal.

## 12. Offline

P12 introduces no network, no API, no LLM, no embeddings, no vector database, no
remote database and no external service. It reads only the in-memory validated
corpus, the canonical `garuda_doctrine` records and the composed services. No new
runtime dependency is introduced.

## 13. Exclusions

P12 does **not** include:

- Flutter UI / application screens;
- persistence, repositories, bookmarks, user collections, saved products or
  accounts;
- AI/LLM, embeddings, vector search, web search, web scraping or external legal
  databases;
- new legal evidence or new UPSC intelligence (no ranking, no exam prediction,
  no study plans);
- a generic `KnowledgeProduct` framework refactor;
- a second rendering/export framework;
- modification of the P5/P9/P10 algorithms or the P11 explanation logic;
- inferred doctrine evolution, "related doctrine" claims or legal-similarity
  verdicts.

## 14. Future extension boundaries

P12 is the **doctrine-level** knowledge product. Its intended successors compose
this product — they do not re-implement it:

- P8 rendering of doctrine products;
- application/learning layers (collections, study plans) that consume the product.

Any such layer must consume the existing structured product and must not add legal
evidence or reasoning inside P12.

---

## 15. Verification summary

- **Tests:** `test/doctrine_product/*` — domain model, resolution, P5/P6,
  P9/P10/P11 integration, evidence/provenance, legal safety, determinism/offline,
  missing data and corpus-wide verification.
- **Corpus:** all 20 canonical doctrines resolve; `buildAll` returns 20 products;
  no invalid case/doctrine/edge/evidence identifiers; the graph is never mutated;
  repeated and cross-instance generation is byte-identical.
- **Regression:** the full existing P3–P11 `garuda_case_law` suite remains green.
- **Analyzer / format:** clean.
