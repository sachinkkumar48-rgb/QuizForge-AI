# P10 — Evidence-Bounded Cross-Case Analysis

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 10 of GARUDA Landmark Case Law)
**Base:** P9 `Case Discovery & Exploration` at commit `ad22793`
**Status:** ✅ P10 implemented & verified (0 analyzer issues, 566 package tests green, 49/49 corpus-wide analysis)

---

## 1. Purpose

P10 is a **deterministic, offline-first composition/analysis layer** over the
already-validated P3–P9 GARUDA Case Law corpus. It answers:

> What do the existing validated case records show when those cases are compared?

It does **not** answer "which cases are legally similar", "did the law evolve
from X to Y", "was A overruled by B" or "is doctrine D the same as doctrine E".
Those are legal conclusions that P10 may never derive on its own — they are only
ever surfaced when an *authoritative* P5 graph edge or P3 record already
establishes them, and even then they are surfaced verbatim as evidence, never
re-derived.

P10 enables five capabilities, all built **only** from existing data:

1. **Case comparison** — deterministic comparison of two or more cases, clearly
   separating factual source data from structural observation.
2. **Chronological analysis** — deterministic ordering using authoritative dates.
3. **Precedent-chain analysis** — P5/P9 chain navigation enriched with P4
   intelligence, preserving P5 relationship semantics exactly.
4. **Doctrine-oriented analysis** — deterministic analysis of the cases belonging
   to a validated doctrine.
5. **Multi-case synthesis** — evidence-preserving aggregation of a selected set.

P10 is **not** a UI phase and **not** a legal-reasoning engine. It is a reusable,
domain-facing service and result-model layer a later TITAN application consumes.

## 2. Where it lives

```
lib/analysis/
  domain/analysis_enums.dart                  SharedAttributeKind, StructuralObservationType,
                                               PrecedentChainDirection
  domain/structural_observation.dart          StructuralObservation
  domain/case_comparison.dart                 CaseComparisonResult / CaseComparisonItem / SharedAttribute
  domain/chronology.dart                      ChronologyAnalysis / ChronologicalCaseEntry
  domain/precedent_chain_analysis.dart        PrecedentChainAnalysis / PrecedentChainEntry / PrecedentRelationshipStep
  domain/doctrine_analysis.dart               DoctrineAnalysisResult / DoctrineCaseEntry
  domain/case_synthesis.dart                  CaseSynthesis / SynthesisCaseEntry / SynthesisAggregate / SynthesisDiscoveryLink
  service/cross_case_analysis_service.dart    CrossCaseAnalysisService — facade
```

All files are exported from the package barrel `garuda_case_law.dart`.

## 3. Architecture

`CrossCaseAnalysisService` is the single public entry point. At construction it
resolves (or builds once) the shared P5 `LegalGraph`, wires the existing P5
services (`PrecedentGraphService`, `DoctrineRelationshipService`,
`LegalGraphTraversalService`) onto that same graph, reuses the existing P6
`CaseSearchEngine` (built over `CaseSeedData.cases`) for exact case resolution,
and builds a P9 `CaseDiscoveryService` on the same instances for synthesis
discovery context. Every dependency is injectable for testing.

```
P3 CaseSeedData (49 records, P4-enriched)
  │
P4 JudgmentIntelligence ── holdings, ratios, issues, outcome, significance
P5 LegalGraph ── PrecedentGraphService      ── case → case edges (verbatim)
  │         └─ DoctrineRelationshipService  ── case ↔ doctrine edges (roles verbatim)
  │         └─ LegalGraphTraversalService   ── predecessorChain / successorChain (verbatim)
P6 CaseSearchEngine ── findExact (canonical ID / name / alias resolution)
P9 CaseDiscoveryService ── discovery reasons for synthesis links
  │
  └─ CrossCaseAnalysisService  (P10 facade)
```

P10 introduces **no** new persistent domain entities, repositories or storage.
Every analysis result is a derived, immutable value recomputed on demand.

## 4. Case comparison — semantics

`compareCases(ids)` and `compareTwo(a, b)` compare two or more existing cases.
The result is **always** split into two clearly-labelled layers:

| Layer | What it is | Example |
|---|---|---|
| **Factual source data** (`items`) | What each P3/P4 record actually says: identity, citation, year, bench, judges, P4 holdings/ratios/issues, P4 outcome, P4 significance, P3 articles/Acts, P5 doctrine membership, evidence IDs | `KESAVANANDA` has 2 holdings, 3 ratios, 3 issues; outcome `upheldWithDirections` |
| **Structural observation** (`sharedAttributes` + `observations`) | What deterministic comparison can safely derive: shared articles/Acts/doctrines, pairwise chronology, verbatim P5 edges, holding/ratio/issue/outcome differences | `MINERVA_MILLS followed KESAVANANDA` (edge, verbatim); `Article 14` shared by both |

### Shared attributes

A structured attribute is recorded only when it is present in **at least two**
compared cases, with the exact set of cases that carry it:

- **Article** — P3 `relatedArticles`, normalized via `CaseSearchNormalizer`
  (so `Article 21`, `Art. 21`, `21` compare equal).
- **Act** — P3 `relatedActs`, normalized text.
- **Doctrine** — P5 case → doctrine edges (canonical doctrine ID).
- **Judge** — exact P3 `judges` name, normalized for grouping.

A shared attribute is **exposed explicitly as a shared attribute** (e.g.
`shared doctrine: BASIC_STRUCTURE`, `shared article: 14`). It is **never**
reworded into "these cases are legally similar" or a similarity score.

### Structural observations

Observations are derived, evidence-bounded statements. Types:

- `chronologicalOrder` — `A (year) precedes B (year)`, from `corpus:year`.
- `graphRelationship` — an explicit P5 case → case edge between the compared
  cases, label verbatim (`MINERVA_MILLS followed KESAVANANDA`), provenance from
  the edge.
- `holdingDifference` / `ratioDifference` / `issueDifference` /
  `outcomeDifference` — the compared cases differ along that dimension
  (provenance `p4:holdings` etc.).
- `noSharedAttributes` — the compared cases share no structured attribute.

Every observation carries its **references** (case IDs, edge ID, doctrine ID)
and its **provenance**, so it can always be traced back to P3–P7 data.

## 5. Chronological analysis

`chronologicalAnalysis(ids)` orders a selected set of cases deterministically
using the **authoritative existing dates**: judgment year ascending, then
judgment date ascending, then case name ascending, then case ID ascending.

It exposes:

- ordered `entries` with 0-based `position`;
- `earliest` / `latest` / `yearSpan`;
- `positionOf`, `before`, `after` for predecessor/successor reading of any
  sequence.

Chronology is a **structural fact**. It is never turned into a claim that the
later case overruled, refined or extended the earlier one — that requires an
authoritative edge, not a date ordering.

## 6. Precedent-chain analysis

`precedentChainAnalysis(id, {direction})` reuses the P5 traversal
`predecessorChain` / `successorChain` **verbatim** and enriches each node with
its P4 case intelligence (holdings, ratios, issues) and its chronology.

- The chain always starts at the anchor case; a case with no incoming/outgoing
  chain edges yields a single-node chain.
- The P5 edge used to reach each entry is recorded as a
  `PrecedentRelationshipStep` with its `edgeId`, `typeLabel`, source/target and
  **provenance**.
- Relationship types are preserved **exactly** (`followed`, `overruled`,
  `distinguished`, `applied`, …). No edge is created, modified or
  reinterpreted.

## 7. Doctrine-oriented analysis

`doctrineAnalysis(doctrineIdOrName)` analyzes the cases belonging to a validated
doctrine using the existing P5 case → doctrine edges and P4 intelligence:

- member cases in chronological order;
- each member's P5 **role** verbatim (`establishes`, `applies`, `develops`,
  `follows`, `expands`, `limits`, `distinguishes`, `engages`) with its edge ID
  and provenance — the role is recorded P5 evidence, not a P10 inference;
- each member's P4 holdings/ratios/issues/outcome;
- P5 precedent edges **among** the members;
- a single structural observation (the doctrine's corpus year span).

`doctrineAnalysis` **never claims** that "the doctrine evolved from X to Y".
The consumer observes the progression from the underlying chronological
evidence and the recorded roles.

## 8. Multi-case synthesis

`synthesize(ids)` produces an **evidence-preserving aggregation** of a selected
set of cases:

- one `SynthesisCaseEntry` per case: identity, citation, chronology, P4
  holdings/ratios/issues/outcome/significance, doctrine/article/Act membership,
  evidence IDs, and the P5 edges that touch another selection member;
- a `SynthesisAggregate` of deterministic facts: distinct doctrines/articles/Acts,
  year span, holding/ratio/issue totals, and the attributes **common to every**
  selected case;
- all P5 case → case edges **among** the selection;
- P9 discovery links among the selection, with their P9 reasons;
- a single structural observation (the selection's year span).

Synthesis is an aggregation, **not** a narrative. It re-presents validated data
and structured facts; it never invents a legal conclusion or an authoritative
summary.

## 9. Provenance

Every analytical result remains traceable to existing P3–P7 evidence and/or P9
discovery information:

- case IDs are canonical corpus IDs; doctrine IDs are canonical doctrine IDs;
- article/Act references are normalized from P3 `relatedArticles`/`relatedActs`;
- graph observations carry the P5 `edgeId` and the edge's provenance;
- doctrine roles carry the P5 edge provenance
  (`doctrine:<id>.originatingCase`, `corpus:doctrines`, …);
- text fields (holdings/ratios/issues) are read from P4 **verbatim** — never
  regenerated, never reinterpreted.

P10 invents no evidence IDs, no citations and no graph relationships.

## 10. Evidence boundaries — observed vs derived

The boundary between the two layers is explicit in every result:

- **Observed evidence** (`items`, `caseObject`, provenance-carrying facts) — what
  the validated records and graph edges say.
- **Derived structural observation** (`sharedAttributes`, `observations`,
  `aggregate`) — what deterministic comparison/aggregation safely derives from
  that evidence (chronology, shared attributes, edge membership, differences,
  counts, spans).

A derived observation is always labelled with its kind and carries the
references and provenance that establish it. A structural observation is never a
legal verdict.

## 11. Citation safety

P10 **never** reports a P5 precedent relationship as a citation. The P5 graph
has no generic `cites` relationship, and P10 does not fabricate one:

- a `followed` edge is exposed as `followed`, never as "cited";
- an `overruled` edge is exposed as `overruled`, never as "cites";
- no citation vocabulary (`cites`, `cited`, `citation`) is produced anywhere in
  P10 output as a relationship label.

## 12. Legal-inference limitations

P10 **never** automatically classifies cases as overruled/overruling,
refined/refinement, extended/extension, reversed, "established law" or "changed
the law" based on a precedent edge plus different holdings. Those classifications
are surfaced **only** when the repository already contains an explicit,
authoritative edge (e.g. `corpus:precedentsOverruled`), and even then they are
recorded as the edge, with its provenance.

When no authoritative classification exists, P10 exposes only evidence-bounded
observations: earlier/later case, related precedent relationship (verbatim),
holding/ratio/issue difference, doctrine overlap, chronological progression.

If an explicit legal-evolution classification cannot be established from
existing authoritative evidence, P10 does **not** infer it.

## 13. Offline & determinism

- **Offline-first:** P10 reads only the in-memory validated corpus and graph. No
  HTTP, web search, LLM, embeddings, vector store or external service is
  involved, and no new dependency is introduced.
- **Deterministic:** identical corpus + identical query ⇒ identical results.
  Iteration is always converted to a documented deterministic order (attribute
  kind → value; observation type → label; edge source → type → target; case
  chronology), and results are serialized in that order.

## 14. API usage

```dart
final analysis = CrossCaseAnalysisService();

// A. Case comparison (2+ cases; unknown IDs reported on unresolvedCaseIds)
final comparison = analysis.compareTwo('MINERVA_MILLS', 'KESAVANANDA');
for (final item in comparison.items) {
  print('${item.caseId} ${item.holdings.length} holding(s)');
}
for (final shared in comparison.sharedAttributes) {
  print('${shared.kind.name}: ${shared.value} ← ${shared.caseIds}');
}
for (final obs in comparison.observations) {
  print('${obs.type.name}: ${obs.label} (${obs.provenance})');
}

// B. Chronology
final chrono = analysis.chronologicalAnalysis(['MINERVA_MILLS', 'KESAVANANDA']);
print('${chrono.earliest!.caseId} → ${chrono.latest!.caseId}, span ${chrono.yearSpan}');

// C. Precedent chain (P5 verbatim, enriched with P4)
final chain = analysis.precedentChainAnalysis('KESAVANANDA')!;
for (final entry in chain.entries) {
  print('${entry.caseId} ${entry.relationshipFromPrevious?.typeLabel ?? '(anchor)'}');
}

// D. Doctrine analysis
final doctrine = analysis.doctrineAnalysis('BASIC_STRUCTURE');
for (final member in doctrine.cases) {
  print('${member.caseId} ${member.role}');
}

// E. Synthesis
final synthesis = analysis.synthesize(['MINERVA_MILLS', 'KESAVANANDA']);
print('${synthesis.aggregate.commonDoctrines} common doctrines');
```

## 15. Explicit exclusions

P10 does **not** implement: Flutter UI; visual timelines; graph rendering;
AI/LLM; semantic embeddings; vector search; external APIs; web search/scraping;
new legal evidence or new case corpus; citation extraction; automatic legal
conclusions; automatic overruling/refinement/extension classification (without
explicit authoritative evidence); personalization; user accounts; bookmarks;
study plans; progress tracking; persistent analysis sessions; persistent
comparison storage; new P5 graph edges; rewriting P6 or P9.
