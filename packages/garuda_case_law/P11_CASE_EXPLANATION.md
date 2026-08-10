# P11 — Evidence-Backed Case Explanations

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 11 of GARUDA Landmark Case Law)
**Base:** P10 `Cross-Case Analysis` at commit `8e2c01c`
**Status:** ✅ P11 implemented & verified (0 analyzer issues, P3–P10 baseline + P11 tests green, 49/49 corpus-wide explanation)

---

## 1. Purpose

P11 is a **deterministic, offline-first knowledge-product composition layer** over
the already-validated P3–P10 GARUDA Case Law corpus. It answers:

> What do the existing validated records say about one canonical case — as a
> structured, human-readable, provenance-preserving explanation?

P11 produces a single immutable **`CaseExplanation`** for a canonical case: its
identity and overview (P3), framed issues, holdings, reasoning, outcome and
significance (P4), the doctrines it engages and its precedent edges (P5), its
related cases with the recorded reasons they were discovered (P9), cross-case
context (P10), optional UPSC relevance (P3/P4) and its recorded evidence (P8).

P11 is **not** an AI answer generator and **not** a legal-reasoning engine. It
never invents an explanation, never infers new legal propositions, never
independently determines what the law is and never fabricates a legal
relationship. Every statement in every section is **composed verbatim** from
existing validated P3–P10 source data, carries its **source references** and its
**provenance**, and nothing is presented without a traceable origin.

Missing data is represented by an **absent section** — never by fabricated
content. Output is **deterministic**: identical corpus + identical services
produce byte-identical structured output, in the fixed section order, with sorted
references and sorted statements.

## 2. Where it lives

```
lib/explanation/
  domain/explanation_enums.dart          ExplanationSectionType (fixed section
                                         vocabulary + ordering)
  domain/explanation_section.dart        ExplanationSection / ExplanationStatement
  domain/case_explanation.dart           CaseExplanation (immutable knowledge product)
  service/case_explanation_service.dart  CaseExplanationService (composition)
```

The barrel `lib/garuda_case_law.dart` re-exports the four P11 files so consumers
get the whole layer from one import.

## 3. Architecture

```
          ┌──────────────────────────────────────────────┐
          │              CaseExplanationService          │
          │  deterministic, offline-first, immutable out │
          └───────────────┬──────────────────────────────┘
                          │  composes ONLY existing validated data
    ┌───────────┬─────────┼──────────┬──────────────┬─────────────┐
    ▼           ▼         ▼          ▼              ▼             ▼
   P3 corpus   P4 Judgment  P5 graph   P6 search    P9 discovery  P10 cross-case
   (identity,  Intelligence (doctrines, (canonical   (related      (chronology,
   overview,   (issues,     precedent   resolution,  cases +       chains,
   articles,   holdings,    edges,      aliases)     reasons)      comparison,
   acts,       reasoning,   doctrine    │                         doctrine
   evidence,   outcome,     roles)      ▼                         analysis)
   UPSC        significance,            P8 EvidenceEntry
   relevance)  UPSC)                    (evidence registry)
```

The service takes every dependency as an optional constructor argument and
defaults each one to the canonical in-memory corpus + services, so the default
constructor is deterministic and offline-first. Every builder re-reads the
already-validated models and returns `null` when no evidence exists for a
section.

## 4. `CaseExplanation`

The immutable knowledge product. A single explanation:

```dart
CaseExplanation(
  caseId: 'KESAVANANDA',
  caseName: 'Kesavananda Bharati v. State of Kerala',
  sections: [ ExplanationSection(...), ... ],
)
```

- **`caseId` / `caseName`** — canonical corpus identity of the explained case.
- **`sections`** — present sections, in the fixed deterministic order below.
  A section exists only when validated evidence exists for it.
- **`explanationKind`** — fixed marker `evidence-backed-case-explanation`.
- **`isEmpty`** — whether no section is presentable.
- **`sectionOf(type)` / `hasSection(type)`** — accessors for one section.
- **`referencedIds`** — every canonical identifier referenced anywhere in the
  explanation, including the case's own ID, de-duplicated and sorted. This is
  the *raw* list and intentionally includes non-case identifiers (doctrine IDs,
  edge IDs `e:…`, holding IDs, issue IDs, evidence IDs and normalized article
  keys such as `13`/`368`). It is **not** a list of case IDs — see
  `referencedCaseIds` below for the case-only filter.

### `ExplanationStatement`

One presented, evidence-backed item:

```dart
ExplanationStatement(
  label: 'Holding 1',            // deterministic presentation label
  text: '… verbatim validated content …',
  sourceRefs: ['KESAVANANDA', 'hol_kesavananda_1'],  // never empty
  provenance: 'p4:holdings',     // which validated field establishes it
)
```

- `sourceRefs` is **never empty** (asserted) — every statement names what
  establishes it.
- `provenance` records the validated corpus/graph/analysis field the content
  traces to (e.g. `p4:holdings`, `corpus:relatedArticles`,
  `doctrine:BASIC_STRUCTURE.originatingCase`, `p10:chronology`).

### `ExplanationSection`

A titled list of statements for one `ExplanationSectionType`, exposing:

- **`title`** — human-readable section heading.
- **`provenance`** — the unique, sorted, `;`-joined provenance markers of its
  statements.
- **`references`** — the unique, sorted canonical references of its statements.

## 5. `CaseExplanationService`

The composition service. Public API:

```dart
final service = CaseExplanationService();          // canonical offline corpus

CaseExplanation? explain('KESAVANANDA');           // by ID or by case name
List<CaseExplanation> explainAll();                // whole corpus, corpus order
bool hasCase(String idOrName);                     // resolvability
Set<String> get caseIds;                           // canonical corpus IDs
List<String> referencedCaseIds(explanation);       // case-only refs, incl. self
List<String> otherCaseIds(explanation);            // referenced cases ≠ self
```

`explain` resolves a canonical ID **or** case name through the P6 search engine,
then deterministically builds the sections in the fixed order below. Unknown
identifiers yield `null` — never an empty or invented explanation.

### Fixed section order

`identity → overview → issues → holdings → reasoning → outcome → legalSignificance
→ doctrines → articles → acts → relatedCases → precedentContext → crossCaseContext
→ upscRelevance → evidence`

The order is fixed so that serialization and comparison are deterministic.

## 6. P3–P10 reuse

| Section(s) | Built from | Never re-derived |
|---|---|---|
| `identity`, `overview`, `articles`, `acts`, `evidence` | P3 corpus fields (verbatim) | — |
| `issues`, `holdings`, `reasoning`, `outcome`, `legalSignificance`, `upscRelevance` | P4 Judgment Intelligence (with P3 fallbacks for issues/outcome/significance) | legal conclusions |
| `doctrines` | P5 case ↔ doctrine edges (doctrine name + role) | doctrine content |
| `precedentContext` | P5 case → case edges (verbatim relationship type) | overruling/refinement/extension |
| `relatedCases` | P9 discovery reasons (verbatim reason labels) | legal similarity |
| `crossCaseContext` | P10 analysis (chronology, chains, comparison, doctrine analysis) | causation / evolution |
| evidence registry | P8 `EvidenceEntry` resolution | evidence content |

P11 reuses each layer's **algorithms and results as-is** — it never recreates a
P10 algorithm, never recomputes the graph, never re-runs discovery logic and
never restates an edge as anything other than the recorded relationship.

## 7. Source hierarchy

Every statement declares its source with a `provenance` marker. The full marker
vocabulary is drawn only from in-package validated sources:

- **`corpus:*`** — a P3 corpus field (`corpus:caseName`, `corpus:facts`,
  `corpus:relatedArticles`, `corpus:precedentsOverruled`, `corpus:presentStatus`,
  `corpus:evidenceIds`, …).
- **`p4:*`** — a P4 Judgment Intelligence field (`p4:issues`, `p4:holdings`,
  `p4:reasoning.summary`, `p4:outcome`, `p4:judicialSignificance`,
  `p4:upscIntelligence`, `p4:ratios`).
- **`doctrine:<ID>.<role>`** — a P5 doctrine-relationship provenance
  (`doctrine:BASIC_STRUCTURE.originatingCase`, `.expandedBy`, `.landmarkCases`,
  …).
- **`p10:*`** — a P10 analysis result (`p10:chronology`, `p10:precedentChain`,
  and P10 observation/attribute provenances).

There is **no external marker**: no URL, API, network, LLM, embedding or
remote-database provenance ever appears. The offline test pins this.

## 8. Deterministic composition

- **Fixed section order** (above) for every explanation.
- **Sorted statements** within each section; **sorted, de-duplicated** references
  within each section and within `referencedIds`.
- **Sorted** `referencedCaseIds` and `otherCaseIds`.
- Identical corpus + identical services ⇒ **byte-identical** `toJson()` output.
  Pinned by same-instance and cross-instance determinism tests.

## 9. Provenance

Every meaningful statement is traceable:

- `sourceRefs` is non-empty (asserted) and names canonical identifiers.
- `provenance` names the validated field/edge/analysis the content came from.
- Sections aggregate a non-empty, unique, sorted provenance.
- **Case IDs are always real.** `referencedCaseIds` filters the raw
  `referencedIds` against the validated corpus, so doctrine IDs, edge IDs,
  holding IDs, issue IDs, evidence IDs and article keys are never returned as
  case IDs — only identifiers that resolve to a corpus case are returned.

## 10. Evidence boundaries

- Content is **verbatim**: holdings, citations, reasons, roles and observations
  are re-presented exactly as recorded, punctuation included (e.g. an Act is
  surfaced as `Passports Act, 1967`, not normalized).
- Citations appear **only** where the corpus records them (identity/evidence
  sections), each tracing to a `corpus:` field.
- Every precedent-context statement carries its `e:` edge reference, proving it
  is a recorded P5 edge and not an inference.
- No statement text is empty or a placeholder.

## 11. Missing-data behavior

Missing data is an **absent section**, never fabricated content:

- A sparse/disconnected case emits `identity` (and the recorded UPSC relevance
  fields), and **omits** every content section: overview, issues, holdings,
  reasoning, outcome, legalSignificance, doctrines, articles, acts,
  relatedCases, precedentContext and crossCaseContext.
- A case without P4 intelligence emits no holdings/issues/reasoning/outcome.
- A case without doctrine/Act context omits those sections.
- A case without edges emits no precedent-context and no related-case sections,
  and references no other case (`otherCaseIds` is empty).
- Missing context means no chronology, no chains, no comparison — never a
  fabricated "no relation" or "same position" verdict.

## 12. Legal safety

P11 never invents — pinned by the legal-safety test suite:

- **No invented citations** — citation statements only exist where the corpus
  records them (identity/evidence), each with `corpus:` provenance.
- **No invented precedent relationships** — a P5 relationship word
  (`followed`, `overruled`, `distinguished`, `affirmed`, `reversed`, `applied`,
  `expanded`, `limited`, `clarified`, `approved`) appears in a composed section
  only when the statement carries a recorded `e:` edge. Precedent-context labels
  are verbatim P5 relationship labels (e.g. `overruled (outgoing)`).
- **No inferred overruling / refinement / extension** — `refined`,
  `refinement`, `extended`, `extension` and `evolved from` never appear in the
  composed sections.
- **No current-law claims** — `current law` never appears in composed sections.
- **No legal-similarity claims** — `legally similar`, `legal similarity` and
  `similarity score` never appear; shared articles/doctrines are surfaced as
  recorded shared attributes, never as a similarity verdict.
- **No unsupported evolution** — composed sections never narrate doctrine or
  precedent evolution; chronology is position, never causation.

Remember the P10 boundaries P11 preserves: **chronology ≠ causation**,
**precedent relationship ≠ citation**, **shared doctrine ≠ legal similarity**,
**P10 structural observation ≠ legal conclusion**.

## 13. Offline operation

P11 runs entirely on the in-memory seeded corpus and in-memory services. There is
no network, no LLM, no AI, no embeddings, no external API and no remote
database. The default constructor builds the corpus + P5 graph from bundled seed
data and the full corpus can be explained synchronously with no async IO. The
provenance-marker test pins that every statement traces to an in-package source.

## 14. Deterministic operation

See §8. `explainAll()` is order-stable (canonical corpus order); every
explanation serializes byte-identically across repeated calls and across fresh
service instances.

## 15. API examples

```dart
import 'package:garuda_case_law/garuda_case_law.dart';

final service = CaseExplanationService();

// Resolve by ID or by case name.
final byId = service.explain('MANEKA_GANDHI')!;
final byName = service.explain('Maneka Gandhi v. Union of India')!;
assert(byId.toJson() == byName.toJson());

// Iterate sections in fixed order; statements carry their own source + provenance.
for (final section in byId.sections) {
  print('${section.title} [${section.provenance}]');
  for (final s in section.statements) {
    print('  ${s.label}: ${s.text}  <- ${s.provenance}');
  }
}

// Case-only references, always resolvable against the validated corpus.
final referenced = service.referencedCaseIds(byId); // includes MANEKA_GANDHI
final others = service.otherCaseIds(byId);          // other cases it touches

// Whole corpus, offline and deterministic.
for (final explanation in service.explainAll()) {
  final identity = explanation.sectionOf(ExplanationSectionType.identity)!;
  // ...
}
```

## 16. Explicit exclusions

P11 deliberately does **not**:

- generate free-text answers or opinions;
- determine what the current law is;
- infer overruling, refinement, extension, approval or disapproval from holdings
  or chronology;
- claim legal similarity or compute similarity scores;
- narrate legal/doctrine evolution;
- invent citations, precedent relationships or evidence;
- recreate P10 algorithms or any P3–P10 algorithm;
- introduce a second rendering framework (it reuses P8's `EvidenceEntry`
  registry for evidence presentation);
- perform any network, LLM, AI, embedding, external-API or remote-database work.

## 17. Tests

`test/explanation/` — 90 P11 tests across:

- `case_explanation_domain_model_test.dart` — model invariants, serialization.
- `case_explanation_basic_test.dart` — core explanation, fixed order, UPSC.
- `case_explanation_relationships_test.dart` — P5 doctrines/precedent, P3
  articles/Acts, P9 related cases.
- `case_explanation_p10_integration_test.dart` — P10 context integration.
- `case_explanation_provenance_test.dart` — traceability, no fabricated IDs,
  determinism.
- `case_explanation_corpus_test.dart` — 49/49 corpus verification, determinism,
  offline.
- `case_explanation_missing_data_test.dart` — sparse/disconnected behavior.
- `case_explanation_legal_safety_test.dart` — legal-safety boundaries.
- `synthetic_corpus.dart` — test-only corpus exercising missing-data behavior.
