# P5 — Precedent & Doctrine Graph

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 5 of GARUDA Landmark Case Law)
**Base:** P4 `Judgment Intelligence` at commit `61f2653`
**Status:** ✅ P5 implemented & verified (0 analyzer issues, all tests green)

---

## 1. What P5 adds

A dedicated, **evidence-backed legal relationship graph** over the existing
49-case landmark corpus and the canonical `garuda_doctrine` library:

- **Case → Case precedent edges** (`followed`, `overruled`, `distinguished`,
  `related`, plus the remaining `PrecedentRelationshipType` semantics),
- **Case → Doctrine edges** (`establishes`, `applies`, `expands`, `follows`,
  `engages`, …) — the *reverse* navigation (doctrine → its cases) is first
  class,
- **Multi-hop traversal** (N-hop neighborhoods, related-case expansion,
  shortest paths, predecessor/successor chains),
- **Integrity validation** and **analytics** derived from the actual graph,
- an **integration bridge** onto the generic `garuda_graph` package.

## 2. The garuda_graph reuse decision

`garuda_graph` was inspected (domain, repository, linking, ontology, scoring,
search, validation). It provides a *generic* `KnowledgeLink` /
`KnowledgeNodeRef` persistence graph.

**Why it cannot safely carry the legal graph:**

1. **The legal relationship vocabulary is absent.** `garuda_graph`'s
   `KnowledgeRelationshipType` is generic (`references`, `overrules`,
   `relatedTo`, `interprets`, …). Only `overrules` overlaps with the corpus's
   legal semantics; `followed`, `distinguished`, `applied`, `affirmed`,
   `clarified`, `expanded`, `limited`, `approved` have no representation.
   Extending the shared enum would modify `garuda_graph` and risk its
   exhaustive-switch consumers — an architectural change P5 is not authorised
   to make.
2. **The canonical legal semantics already live in `garuda_case_law`.**
   `PrecedentRelationship` + `PrecedentRelationshipType` are the authoritative
   value objects. Duplicating them into `garuda_graph` would duplicate the
   generic graph architecture, which the prompt forbids.
3. **The legal graph is a read-side, corpus-derived projection.** It builds an
   immutable index over the verified corpora. `garuda_graph` is a mutable
   persistence layer (`saveLink`/`deleteLink`) — inappropriate for an
   evidence-first integrity graph.

**Decision:** a thin, domain-specific abstraction lives inside
`garuda_case_law` (`lib/graph/`), reusing existing legal semantics. To still
"reuse `garuda_graph` where appropriate", `GarudaKnowledgeGraphBridge` projects
the legal graph onto `garuda_graph`'s generic `KnowledgeLink` model for
cross-package integration (documented as lossy-by-design). No
`garuda_graph` code was modified.

## 3. Architecture

```
lib/graph/
  domain/
    doctrine_relationship_type.dart   # case↔doctrine edge vocabulary (+ specificity)
    legal_graph_node_type.dart        # caseLaw | doctrine
    legal_graph_node_ref.dart         # canonical node reference (caseId / doctrineId)
    legal_graph_edge.dart             # sealed LegalGraphEdge → PrecedentGraphEdge | DoctrineGraphEdge
    legal_graph.dart                  # immutable aggregate + adjacency indexes + serialization
    legal_graph_path.dart             # traversal result model
  data/
    legal_graph_seed.dart             # THE graph is derived here — nothing else invents edges
  service/
    precedent_graph_service.dart      # case → case queries
    doctrine_relationship_service.dart# case ↔ doctrine + reverse doctrine → case lookup
    legal_graph_traversal_service.dart# multi-hop BFS, paths, chains, P4-search integration
  validation/
    legal_graph_validator.dart        # missing node, invalid ID, duplicate edge,
                                      # self-loop, invalid type, missing/unregistered evidence
  analytics/
    legal_graph_analytics.dart        # size, type distribution, hubs, isolation, connectivity, chains
  integration/
    garuda_knowledge_graph_bridge.dart# legal graph → garuda_graph KnowledgeLinks
```

Search integrates with the existing P4 `JudgmentIntelligenceSearchEngine`
(`searchNeighborhood`); editorial validation reuses the P3/P4 evidence registry
(`CaseOfficialSources`) and the doctrine records — no editorial architecture is
duplicated.

## 4. Data-quality rule — how edges are derived (never invented)

Every edge in the graph traces to a verified source:

| Edge | Evidence source |
|---|---|
| `followed` / `overruled` / `distinguished` / `related` | the case record's `precedentsFollowed` / `precedentsOverruled` / `precedentsDistinguished` / `relatedCases` fields |
| structured precedent edges | the case record's `precedentRelationships` |
| case → doctrine | the case record's `doctrines` field (role `engages`) and the canonical doctrine record's `originatingCase` / `landmarkCases` / `subsequentCases` / `expandedBy` / `limitedBy` / `distinguishedIn` case references |

Doctrine-record case references are resolved against the corpus by a
**conservative** name resolver: an exact normalized name/alias match, or an
exact petitioner-prefix **plus exact respondent** match. Ambiguous or
unresolvable references are dropped — a reference is never guessed
(e.g. *M.C. Mehta v. Kamal Nath* does **not** resolve to the Taj Trapezium
case; *State of Rajasthan v. G. Chawla* does **not** resolve to
`STATE_RAJASTHAN_V_UNION`). Self-loops and duplicate triples are rejected at
build and counted. `test/graph/corpus_graph_integrity_test.dart` reconstructs
the full expected edge set from the raw corpus fields and asserts the graph
contains **exactly** that set — no fabricated or placeholder relationships.

## 5. Graph statistics (derived, not hard-coded)

- **Nodes:** 69 — 49 cases (20 Phase-I + 29 Phase-II) + 20 doctrines.
- **Edges:** 125 — 106 case→case + 19 case→doctrine.

| Case→case type | Count |
|---|---|
| followed | 18 |
| overruled | 5 |
| distinguished | 4 |
| related | 79 |

| Case→doctrine role | Count |
|---|---|
| establishes | 5 |
| applies | 7 |
| expands | 1 |
| follows | 1 |
| engages | 5 |

- **Doctrine linkage:** BASIC_STRUCTURE 8 cases · MANIFEST_ARBITRARINESS 3 ·
  POLLUTER_PAYS 2 · PROPORTIONALITY 2 · SEVERABILITY 1 ·
  PROSPECTIVE_OVERRULING 1 · HARMONIOUS_CONSTRUCTION 1 ·
  PRECAUTIONARY_PRINCIPLE 1.
- **Most connected cases:** KESAVANANDA (14), VELLORE_CITIZENS (14),
  MANEKA_GANDHI (12), M_NAGARAJ (12), DK_BASU (11).
- **Isolated cases (no recorded edge):** OLGA_TELLIS, SUCHITA_SRIVASTAVA.
- **Connectivity:** 18 weakly-connected components; largest has 43 nodes.
- **Longest precedent chain:** `MINERVA_MILLS -followed→ KESAVANANDA
  -overruled→ GOLAKNATH -overruled→ SAJJAN_SINGH` (3 hops).

## 6. Files

**Modified (3 source files + lockfile):**
- `lib/domain/entities/case_enums.dart` — added `related` to
  `PrecedentRelationshipType` (additive; no exhaustive switches exist).
- `lib/garuda_case_law.dart` — exported the new `graph/` module.
- `pubspec.yaml` / `pubspec.lock` — added the `garuda_graph` dependency for the
  integration bridge.

**Created (lib):** `lib/graph/{domain,data,service,validation,analytics,integration}/*`.
**Created (test):** `test/graph/*` (7 suites, 97 tests).
**Created (doc):** this file.
