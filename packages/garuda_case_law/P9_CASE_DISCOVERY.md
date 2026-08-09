# P9 — Case Discovery & Exploration Services

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 9 of GARUDA Landmark Case Law)
**Base:** P8 `Export & Rendering` at commit `1848b7c`
**Status:** ✅ P9 implemented & verified (0 analyzer issues, 473 package tests green, 49/49 corpus-wide discovery)

---

## 1. Purpose

P9 is the **application/service layer** that makes the already-validated P3–P8
knowledge genuinely navigable. It composes the P3 corpus, P4 Judgment
Intelligence, P5 Precedent & Doctrine Graph, P6 search and P7 validation
guarantees into three discovery capabilities:

1. **Related case discovery** — deterministic, explainable discovery of cases
   related to a supplied case.
2. **Doctrine / Article / Act collections** — deterministic derived collections
   of all cases associated with a doctrine, constitutional Article or Act.
3. **Precedent navigation** — deterministic traversal over the existing P5 graph
   (direct precedents, ancestors/descendants, chains, paths).

P9 is **not** a UI phase. It is a reusable, domain-facing service and result
model layer a later TITAN application consumes.

## 2. Where it lives

```
lib/discovery/
  domain/discovery_reason.dart        DiscoveryReasonType + DiscoveryReason
  domain/related_case_result.dart     RelatedCaseResult
  service/case_discovery_service.dart CaseDiscoveryService — facade
```

All files are exported from the package barrel `garuda_case_law.dart`.

## 3. Architecture

`CaseDiscoveryService` is the single public entry point. At construction it
resolves (or builds once) the shared P5 `LegalGraph`, wires the existing P5
services (`PrecedentGraphService`, `DoctrineRelationshipService`,
`LegalGraphTraversalService`) onto that same graph, and reuses the existing P6
`CaseSearchEngine` built over `CaseSeedData.cases`. Every dependency is
injectable for testing; defaults always derive from the canonical offline seeds.

```
P3 CaseKnowledgeObject corpus
  │
P5 LegalGraph ── PrecedentGraphService      ── direct precedents, edges, chains
  │         └─ DoctrineRelationshipService  ── shared-doctrine discovery
  │         └─ LegalGraphTraversalService   ── paths, chains
P6 CaseSearchEngine ── findByArticle / findByAct / findByDoctrine (collections)
  │
  └─ CaseDiscoveryService  (P9 facade)
```

P9 introduces **no** new domain entities, repositories or persistence. A
collection is a deterministic query result; navigation state is never stored.

## 4. Related case discovery — what "related" means

`discoverRelatedCases(caseId)` returns cases related to a source case. A result
is returned only when the source case and the result share at least one
objectively computable, validated fact:

| Reason kind | Source of truth | Example label |
|---|---|---|
| `graphRelationship` | direct P5 case → case edge | `direct precedent: MINERVA_MILLS followed KESAVANANDA` |
| `sharedDoctrine` | both cases engage the same validated doctrine (P5 edges) | `shared doctrine: BASIC_STRUCTURE` |
| `sharedArticle` | both reference the same constitutional Article (P3 `relatedArticles`) | `shared article: 21` |
| `sharedAct` | both reference the same Act (P3 `relatedActs`) | `shared act: indian penal code 1860` |

Every reason carries its **references** (edge id, doctrine id, article key or
act name) and its **provenance** (which validated corpus field or graph edge
establishes it), so every result is auditable back to P3–P7 data.

**P9 does NOT claim legal similarity.** It performs no wording comparison, no
holding/ratio scoring and no inference. "Related" means *shares a validated,
explainable connection* — nothing more. There is no similarity threshold, no
weight vector and no AI/ML model anywhere in the layer.

### Ordering

- **Within a result**, reasons are ordered by a fixed kind priority (graph
  relationships first, then shared doctrine, shared article, shared Act), then
  label ascending.
- **Across results**, cases are ordered by the number of independent reasons
  (descending), then by the documented P6 tie-break convention: judgment year
  descending, case name ascending, case ID ascending.

Ordering is deterministic and explainable — more independent evidence-backed
connections rank a case higher, never an opaque score.

## 5. Doctrine / Article / Act collections

`casesForDoctrine`, `casesForArticle` and `casesForAct` are thin, deterministic
reuse of the existing P6 engine (`findByDoctrine`, `findByArticle`,
`findByAct`). They:

- return only valid corpus case IDs (never fabricated membership);
- order deterministically (P6 scoring + tie-break);
- resolve identifier variants (`BASIC_STRUCTURE` / `Basic Structure Doctrine`,
  `21` / `Article 21`, `Indian Penal Code` / `Indian Penal Code, 1860`);
- return an empty collection for unknown/unassociated identifiers.

No persistent collection storage is created — a collection is a query result.

## 6. Precedent navigation

Navigation reads the P5 graph as-is; **no edge is created or modified**:

| Method | Semantics |
|---|---|
| `directPrecedents(id)` | cases the queried case directly relies on (P5 authority edges) |
| `outgoingRelationships(id)` / `incomingRelationships(id)` | raw P5 case → case edge sets |
| `relationshipsBetween(a, b)` | all P5 edges between two cases |
| `predecessorChain(id)` / `successorChain(id)` | longest simple P5 chains (reused verbatim) |
| `pathBetween(a, b)` | shortest P5 path, or null when disconnected |
| `ancestors(id)` / `descendants(id)` | transitive closure over P5 **authority** edges (cycle-safe, sorted) |

`ancestors`/`descendants` follow only the authority edge types that express
reliance on an earlier decision (`followed`, `applied`, `affirmed`, `approved`,
`clarified`, `expanded`), mirroring the P5 `PrecedentGraphService` authority
semantics. Chain and path methods reuse P5's own, broader directed-edge
semantics untouched.

## 7. Citation integrity

**P5 precedent relationships are NOT citations, and P9 never treats them as
such.** The P5 edge vocabulary (`followed`, `overruled`, `distinguished`,
`related`, `affirmed`, `reversed`, `applied`, `expanded`, `limited`,
`clarified`, `approved`) contains no `cites` type, and the corpus `citations`
field holds reporter citations (AIR / SCC / SCR), not citation relationships.
P9 therefore:

- never answers "which cases cited X";
- never labels a precedent edge or discovery reason as a citation;
- exposes only the P5 relationship vocabulary as-is.

Full citation extraction remains out of scope.

## 8. P4 / P6 / P8 integration

- **P4** — Judgment Intelligence is reused as-is through the corpus and graph;
  P9 generates no holdings, ratios, doctrine applications or UPSC claims.
- **P6** — the search engine is reused (collections) and resolved through
  (`findExact`) for canonical IDs; it is never rewritten or duplicated, and no
  second ranking system is introduced.
- **P8** — P9 results carry the full `CaseKnowledgeObject` on
  `RelatedCaseResult.caseObject` (mirroring `CaseSearchResult.caseObject`), so a
  later UI/renderer can consume discovery output without re-querying the
  corpus. P9 does not modify P8.

## 9. Evidence constraints

- Every reason traces to validated P3–P7 data; references and provenance are
  never invented.
- Graph reasons carry the actual P5 edge id and the edge's recorded provenance.
- Shared-doctrine reasons join the provenances of both case→doctrine edges.
- Shared-article and shared-Act reasons use the corpus `relatedArticles` /
  `relatedActs` fields directly (normalized for comparison).
- No new legal evidence is acquired; no evidence IDs are fabricated.

## 10. Offline & determinism

- **Offline:** everything is in-memory from local seeds. No HTTP, external API,
  LLM, embedding or vector store.
- **Deterministic:** identical corpus + identical query ⇒ identical results.
  All iteration is converted to documented deterministic orders; there is no
  random ordering, timestamp ranking or machine-dependent state.

## 11. API examples

```dart
final service = CaseDiscoveryService();

// Related cases, each explainable
final results = service.discoverRelatedCases('MINERVA_MILLS');
for (final r in results.take(5)) {
  print('${r.caseId} — ${r.reasons.map((x) => x.label).join('; ')}');
}

// Collections
service.casesForDoctrine('BASIC_STRUCTURE');   // 8 cases
service.casesForArticle('21');                 // 28 cases
service.casesForAct('Indian Penal Code, 1860'); // 5 cases

// Navigation
service.directPrecedents('MINERVA_MILLS');     // [followed → KESAVANANDA]
service.ancestors('MINERVA_MILLS');            // [KESAVANANDA]
service.descendants('KESAVANANDA');            // [IR_COELHO, L_CHANDRA_KUMAR, MINERVA_MILLS]
service.pathBetween('GOLAKNATH', 'KESAVANANDA'); // GOLAKNATH -> related KESAVANANDA
```

## 12. Explicit limitations

- P9 does **not** infer legal relationships, similarity or citations.
- `discoverRelatedCases` is direct (one-hop) by design; it does not expand
  multi-hop neighborhoods, because a multi-hop "reason" would be less
  explainable.
- `ancestors`/`descendants` are authority-reliance closures, not exhaustive
  "citation" lists.
- Collections reuse P6's query semantics; results outside a doctrine's corpus
  coverage surface as empty, never fabricated.
- P9 builds no persistent collections, sessions, bookmarks or user state.

## 13. Tests

`test/discovery/` covers related discovery, collections, precedent navigation,
citation safety, evidence integrity, determinism, offline behavior and
corpus-wide verification (all 49 cases / 20 doctrines, graph-unchanged
guarantees). Full run: **473 package tests green** (417 baseline + 56 P9).
