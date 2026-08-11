# P13 — Evidence-Backed Statute / Article Knowledge Products

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 13 of GARUDA Landmark Case Law)
**Base:** P12 `Doctrine Knowledge Products` at commit `11c57d1`
**Status:** ✅ P13 implemented & verified

---

## 1. Purpose

P13 is a **deterministic, offline-first knowledge-product composition layer** over
the already-validated P3–P12 GARUDA Case Law + Constitution + Acts + Doctrine
corpora. It answers:

> What do the existing validated records say about one verified constitutional
> Article or statutory provision — as a structured, provision-level,
> provenance-preserving knowledge product?

P13 produces a single immutable **`StatuteKnowledgeProduct`** for a provision
referenced by the case-law corpus: its identity (the verbatim P3 corpus
references that fold to the canonical key, plus the canonical key itself), an
overview only where the provision resolves to the canonical
`garuda_constitution` / `garuda_acts` records (identity metadata verbatim), its
**verified associated cases** (cases whose own validated P3 fields reference the
provision), **safely associated doctrines** (via a validated two-step path: an
associated case is a recorded P5 member of the doctrine), precedent
relationships among the associated cases (P5 case → case edges), chronology and
structural observations (P10 ordering), UPSC information already attached to the
associated cases (P3/P4), evidence/provenance (P8 registry + provision-corpus
records), and one P11 `CaseExplanation` per associated case.

P13 is **not** a legal-reasoning engine and **not** a statute-research tool. It
never invents constitutional text, statutory text, citation, case association,
doctrine association, precedent, overruling, refinement, extension, doctrinal
evolution, current-law status or legal conclusions. Every statement in every
section is **composed verbatim** from existing validated P3–P12 source data,
carries its **source references** and its **provenance**, and nothing is
presented without a traceable origin.

Missing data is represented by an **absent section** — never by fabricated
content. Output is **deterministic**: identical corpus + identical services
produce byte-identical structured output, in the fixed section order, with sorted
references and sorted statements.

## 2. Where it lives

```
lib/statute_product/
  domain/statute_product_enums.dart         ProvisionType (article/act/section) +
                                             StatuteSectionType (fixed section
                                             vocabulary + ordering)
  domain/statute_product_section.dart       StatuteSection / StatuteStatement
  domain/statute_knowledge_product.dart     StatuteKnowledgeProduct (immutable
                                             knowledge product)
  service/statute_knowledge_product_service.dart
                                             StatuteKnowledgeProductService
                                             (composition)
```

The barrel `lib/garuda_case_law.dart` re-exports the four P13 files so consumers
get the whole layer from one import.

## 3. Architecture

```
          ┌─────────────────────────────────────────────────────┐
          │           StatuteKnowledgeProductService            │
          │  deterministic, offline-first, immutable output     │
          └──────────────┬──────────────────────────────────────┘
                         │  composes ONLY existing validated data
   ┌───────────┬─────────┼───────────┬───────────────┬──────────────┐
   ▼           ▼         ▼           ▼               ▼              ▼
  garuda_    garuda_    P3 corpus   P5 graph        P6 search     P10 CrossCase
  constitution acts     (related    (case→doctrine, (canonical     Analysis
  (Article     (Act     Articles,    case→case       provision     (chronological
  identity     identity  relatedActs, edges, roles)  normalization  ordering)
  metadata)    metadata  sections,                │  via P6)      │
                         evidence,  │              │              │
                         UPSC)      │              ▼              ▼
                                     ▼          P11 CaseExplanation
                                   P8 EvidenceEntry   (one per associated case)
                                   (evidence labels)
```

The service builds over the same shared graph/search/analysis/explanation
services P12 uses. It adds only the canonical `garuda_constitution` /
`garuda_acts` records (for identity enrichment) and derives a provision → raw
reference → case map from the validated corpus. It never becomes the source of
truth for any lower layer: the corpus fields, the P5 edges, the P8 registry and
the canonical records remain the authority.

## 4. Domain model

`StatuteKnowledgeProduct` mirrors the P12 `DoctrineKnowledgeProduct` shape:

- `provisionType` — `ProvisionType.article | act | section`
- `provisionId` — the canonical normalized provision key (`14`, `21a`,
  `representation of the people act 1951`, `section 154 crpc`)
- `provisionName` — the first verbatim corpus reference (sorted) that folds to
  the key (e.g. `Article 14`)
- `rawReferences` — every verbatim corpus reference that folds to the key,
  unique and sorted
- `sections` — `List<StatuteSection>` in the fixed `StatuteSectionType` order;
  a section is present only when validated evidence exists
- `caseExplanations` — one P11 `CaseExplanation` per associated case, in the
  same chronological order as the `associatedCases` section
- `sectionOf` / `hasSection` / `referencedIds` / `toJson` / `fromJson` /
  value equality

A `StatuteSection` is a list of `StatuteStatement`s; every statement carries a
non-empty `sourceRefs` and a `provenance` naming the validated source field.
Sections aggregate a sorted, de-duplicated `references` list and a sorted,
`;`-joined `provenance` string.

The fixed `StatuteSectionType` vocabulary:

1. `identity` — provision kind, canonical key, resolution status, and every
   verbatim corpus reference
2. `overview` — canonical identity metadata, verbatim, only where the provision
   resolves to the constitution/acts corpus (never legal interpretation)
3. `associatedCases` — the verified cases that reference the provision,
   chronological
4. `doctrines` — safely associated doctrines (validated case↔article AND
   case↔doctrine evidence), roles verbatim
5. `precedentRelationships` — P5 case → case edges among the associated cases
6. `chronology` — earliest / latest / year span of the associated cases (P10)
7. `structuralObservations` — deterministic structural facts (case count, IDs)
8. `upscRelevance` — UPSC relevance already attached to the associated cases
9. `evidence` — P8 `EvidenceEntry` resolution of the associated cases' evidence
   IDs + provision-corpus recorded citations / evidence references

## 5. Supported provision types

- **`article`** — a constitutional Article, from `CaseKnowledgeObject.relatedArticles`.
- **`act`** — an Act / Statute, from `CaseKnowledgeObject.relatedActs`.
- **`section`** — a statutory section construed by a case, from
  `CaseKnowledgeObject.sections`.

`CaseKnowledgeObject.statutes` is empty in the validated corpus and is therefore
not a P13 provision source; P13 never invents a provision kind.

## 6. Resolution / normalization

Resolution reuses the existing P6 `CaseSearchNormalizer`:

- Article references normalize via `CaseSearchNormalizer.normalizeArticle`:
  `Article 21`, `Art. 21`, `article21`, `21` → `21`; `Article 21A` → `21a`.
- Act references normalize via `CaseSearchNormalizer.normalizeText`, with a
  leading article-word `the ` folded so `The X, 1951` and `X, 1951` normalize
  consistently.
- Section references normalize via `CaseSearchNormalizer.normalizeText`.

Normalization is **purely textual and deterministic**. Equivalent textual forms
fold consistently; **legally distinct provisions are never merged by assumption**
— `21a` (Article 21A) and `21` (Article 21) are separate products, and a
clause-form key never merges into its base article. Unknown or missing input
resolves to nothing (`build` returns `null`) and never fabricates a provision.

A provision is *known* only when the validated corpus actually references it;
the resolution universe is derived from the cases' own fields. `build` returns a
product only for such a provision.

## 7. Case association rules

A case is associated with a provision **only when the case's own validated
corpus field** (`relatedArticles` / `relatedActs` / `sections`) contains a
reference that normalizes to the provision key. Association is **never** inferred
from:

- doctrine membership,
- graph connectivity,
- legal similarity,
- chronological proximity,
- P9 discovery,
- the `garuda_constitution` `ArticleKnowledgeObject.caseLaw` records (a separate
  corpus, not used for association).

Aggregations carry no duplicates, use canonical case IDs, and are ordered
deterministically (chronologically).

## 8. Doctrine association rules

Doctrine inclusion is **conservative**. A doctrine is included in a provision
product **only** through a validated two-step path:

1. a case is associated with the provision (evidence-backed, section 7), AND
2. that case is a recorded P5 case → doctrine member of the doctrine, AND
3. the doctrine resolves to a canonical `garuda_doctrine` record.

Every included doctrine therefore has an explainable basis (a case that
references the provision and is a recorded P5 member of the doctrine). Roles are
verbatim P5 edge evidence (`establishes`, `applies`, …). A doctrine is **never**
inferred from an article mention alone. If evidence cannot establish a safe
doctrine↔provision relationship, the doctrine is **omitted** — missing evidence
means absence, not fabrication.

## 9. Chronology semantics

The associated cases are ordered deterministically using P10's
`chronologicalAnalysis` (judgment year asc, judgment date asc, case name asc,
case ID asc). The `chronology` section presents the earliest, latest and year
span.

**Chronological ordering does not establish legal causation or doctrinal
evolution.** P13 never infers legal evolution, expansion, narrowing, overruling,
refinement, extension, doctrinal shift, current-law status or causation from
chronological position. Chronology is **position, not causation**.

## 10. Evidence / provenance

Every P13 statement carries non-empty `sourceRefs` and a `provenance` string
naming the validated source layer:

- `corpus:relatedArticles` / `corpus:relatedActs` / `corpus:sections` — the P3
  corpus field that establishes a provision reference / case association
- `p5:caseDoctrineEdges` — the P5 case → doctrine edges for doctrine statements
- P5 edge `provenance` — for precedent-relationship statements
- `p10:chronology` — P10 chronological ordering
- `corpus:upscRelevance` — UPSC relevance on the associated cases
- `corpus:evidenceIds` — evidence IDs on the associated cases (presented via P8
  `EvidenceEntry` registry resolution)
- `constitution:ArticleKnowledgeObject` / `acts:ActKnowledgeObject` — canonical
  identity metadata where the provision resolves

Nothing is presented without a traceable origin, and no external evidence is
introduced merely to enrich the product.

## 11. Legal-safety boundaries

P13 re-presents validated evidence and never derives legal meaning. It does not:

- invent citations, constitutional text, statutory text, or sources,
- invent case or doctrine associations (sections 7–8),
- invent precedent relationships (only recorded P5 edges appear),
- claim overruling, refinement, extension, narrowing or doctrinal evolution,
- assert current-law status,
- assert legal similarity.

The legal-safety tests scan every composed statement for this vocabulary and
require a recorded P5 edge (`e:…`) whenever a relationship word appears.

## 12. Determinism

Identical corpus state + identical input → byte-identical serialized output.

Deterministic by construction:

- provision keys derive from the P6 normalizer (pure string transform),
- case / doctrine / reference collections are sorted,
- the section order is the fixed `StatuteSectionType` order,
- chronology uses P10's deterministic comparator,
- `buildAll` orders article → act → section, then key ascending.

No unordered iteration, timestamps, random IDs, machine paths or
nondeterministic ordering is used.

## 13. Offline behavior

P13 operates entirely offline. No network, HTTP, APIs, LLM, embeddings, remote
databases or external runtime services. All results derive from the in-memory
validated corpus and the canonical in-memory `garuda_constitution`,
`garuda_acts`, `garuda_doctrine` and P5/P6/P8/P10/P11 services.

## 14. Limitations

- **No full statute corpus.** P13 does not build or download a Constitution /
  Bare Act corpus; it is an intersection layer over existing validated case-law
  evidence. A full statute knowledge corpus is a future phase.
- **Partial canonical coverage.** The `garuda_constitution` corpus covers a
  subset of the 448 constitutional Articles; provisions outside it resolve
  verbatim-only (identity from the case corpus, no overview).
- **No section corpus.** Statutory sections carry no canonical section records;
  section products are verbatim-only.
- **Constitution `caseLaw` records are not reused.** The `garuda_constitution`
  package records its own case-law lists per Article; these are a separate
  corpus and are deliberately not used for case association, to keep a single,
  evidence-bounded association source.

## 15. API usage

```dart
final service = StatuteKnowledgeProductService(); // canonical corpus, offline

service.hasProvision(ProvisionType.article, 'Article 21');       // true
service.resolveProvisionId(ProvisionType.article, 'Art. 21');    // '21'
service.build(ProvisionType.article, 'Article 21');              // product?
service.build(ProvisionType.article, 'Article 999');             // null
service.provisionIds(ProvisionType.act);                         // sorted keys
service.buildAll();                                              // all products
service.referencedCaseIds(product);                              // corpus case IDs

final product = service.build(ProvisionType.article, 'Article 21')!;
product.sectionOf(StatuteSectionType.associatedCases);           // section?
product.hasSection(StatuteSectionType.doctrines);                // bool
product.caseExplanations;                                        // P11 explanations
product.toJson();                                                // serializable
```

## 16. Explicit exclusions

- No `garuda_statutes` package and no new statute corpus.
- No AI / LLM functionality.
- No legal reasoning or current-law determination.
- No inference of doctrinal evolution or legal causation from chronology.
- No modification to any completed P3–P12 phase.
