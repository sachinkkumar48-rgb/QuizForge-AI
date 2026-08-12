# P16 — Knowledge Product Navigator & Cross-Referencing

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 16 of GARUDA Landmark Case Law)
**Base:** P15 `Question-Answer Knowledge Products` at commit `69ad512`
**Status:** ✅ P16 implemented & verified (STATE D) — formatting clean, `flutter analyze` clean, 72/72 P16 tests, full-suite 1095/1095, P3–P15 regression intact, deterministic & offline-first.

---

## 1. Purpose

P16 is a **deterministic, offline-first composition / read / navigation layer**
over the already-validated P11–P15 knowledge products. It answers:

> For one validated entity (a case, doctrine, provision, topic or question
> product), what other validated knowledge products are reachable through
> relationships the repository already supports — and why does each edge exist?

P16 produces immutable **`KnowledgeProductCollection`**s of
**`KnowledgeProductReference`**s. Every reference names its concrete
relationship kind, its provenance source, its evidence references and its
origin/destination product identities, so that *why the edge exists* is always
answerable.

P16 is **not** a new legal knowledge layer, a new graph, a new search engine,
a new evidence registry, a new repository, or a rendering/UI framework. It
introduces **no** new legal relationship, **no** AI/LLM functionality, **no**
network calls, **no** persistence and **no** caching. It only composes the
existing validated P5 graph services and P11–P15 product services.

## 2. Where it lives

```
lib/navigation/
├── domain/
│   ├── knowledge_product_type.dart          # KnowledgeProductType
│   ├── navigation_relationship_type.dart    # NavigationRelationshipType, P5 labels
│   ├── navigation_direction.dart            # NavigationDirection
│   ├── knowledge_product_reference.dart     # KnowledgeProductReference
│   └── knowledge_product_collection.dart    # KnowledgeProductCollection
└── service/
    └── knowledge_product_navigator_service.dart  # KnowledgeProductNavigatorService
```

Public P16 API is exported from `lib/garuda_case_law.dart` under the
"Knowledge Product Navigator & Cross-Referencing (TITAN-KO-015.0 P16)"
comment block. No unrelated exports were reorganised.

## 3. Architecture

Conceptually P16 is a **terminal composition layer** above P11–P15:

```
P16 KnowledgeProductNavigatorService
↓ composes
P11–P15 Knowledge Products (CaseExplanation / Doctrine / Statute / Topic / Question)
↓ resolved via
P5/P6/P9 validated capabilities (PrecedentGraph, DoctrineRelationship, Search)
↓
P3/P4 corpus and intelligence
```

P16 depends **downward** on P3–P15. Nothing in P3–P15 depends on P16. No P16
domain model is referenced by an earlier phase, and no P3–P15 domain model was
modified for P16.

The navigator is a **read-only** composition service: it calls the existing
product services and graph services and never mutates them.

## 4. Public API

### Domain abstractions

- `KnowledgeProductType` — the destination product kinds (case, doctrine,
  provision, topic, question). Enum order is also the deterministic group
  order.
- `NavigationRelationshipType` — the concrete relationship kinds P16 may emit
  (see §6). `isLegalRelationship` distinguishes P5 legal edges from non-legal
  associations.
- `NavigationDirection` — `outgoing` / `incoming` traversal orientation,
  preserved from the underlying relationship.
- `KnowledgeProductReference` — one immutable navigable edge: origin + type,
  destination + type, `provisionType`, `relationshipType`, `specificTypeLabel`,
  `direction`, `provenance`, `evidenceRefs`, `toProductYear`. Immutable,
  value-equal, JSON-serialisable, validated on construction.
- `KnowledgeProductCollection` — an immutable, de-duplicated, deterministically
  ordered set of references for one origin. Provides `ofType`, `ofRelationship`,
  `withDirection`, `toAnyOf` and `destinationIds`.

### Navigator service

- `findAllProductsForCase(caseIdOrName)` → case + P5 precedents (in/out) +
  doctrines engaged + provisions referenced + topic memberships + question.
- `findAllProductsForDoctrine(idOrName)` → doctrine + constituent cases +
  question.
- `findAllProductsForProvision(ProvisionType, ref)` → provision + referencing
  cases + question.
- `findAllProductsForTopic(idOrName)` → topic + member cases + question.
- `findAllProductsForQuestion(productId)` → question + its source.
- `findAllProductsFor(type, id)` — generalised dispatch.
- `findRelatedProducts(type, id)` — same as `findAllProductsFor` but drops the
  primary root.
- `navigateRelationship(collection, relationship)` — filter to one relationship
  kind.
- `resolve(reference)` / `resolveAll(collection)` / `resolvable(reference)` —
  resolve a reference to the actual P11–P15 product (or `null` when missing).
- Resolution helpers: `hasCase`, `hasDoctrine`, `hasProvision`, `hasTopic`,
  `resolveCaseId`, `resolveDoctrineId`, `resolveProvisionId`, `resolveTopic`.

Unknown entities yield an **empty** collection; they are never fabricated.

## 5. Deterministic ordering

Every collection orders references by a stable, documented key:

1. **product type order** — case → doctrine → provision → topic → question
   (`KnowledgeProductType.sortIndex`); the primary product sorts inside its
   own type;
2. **chronological year** — case products ascending by publication year;
3. **provision kind** — provision products by `ProvisionType` (article → act →
   section);
4. **canonical display name** — ascending;
5. **canonical ID** — ascending (final tie-break).

No ranking by legal importance, relevance, "best match" or presumed authority
is applied; no score/rank field exists on a reference.

## 6. Supported relationship types & evidence sources

Every relationship maps to exactly one validated source. There is no generic
`related`/`similar`/`connected` edge.

| Relationship | Meaning | Source | Legal? |
|---|---|---|---|
| `primary` | the origin's own product (root of a result) | the producing product service (`p16:primary:...`) | no |
| `precedent` | P5 case → case edge | `PrecedentGraphService` outgoing/incoming (`p5:precedentGraph`); `specificTypeLabel` = verbatim P5 type (e.g. `followed`, `overruled`, `distinguished`, `related`) | yes |
| `engagesDoctrine` | P5 case ↔ doctrine edge | `DoctrineRelationshipService` (`p5:doctrineGraph`); `specificTypeLabel` = verbatim P5 role (e.g. `engages`, `establishes`) | yes |
| `referencesProvision` | case references an Article/Act/section | the P3/P13 provision map (`p13:provisionRefMap`) — **never** a fabricated P5 edge | no |
| `topicMembership` | case is a P14 topic member | `TopicSyllabusConfig` memberships (`p14:membership`) | no |
| `questionSource` | P15 question product ↔ its source | the question product's own `sourceType`/`sourceId` (`p15:questionProduct`) | no |

**Case ↔ Case** and **Case ↔ Doctrine** use the validated P5 graph edges, with
direction, relationship type and edge identity/provenance preserved verbatim.
**Case ↔ Provision** uses the existing P3/P13 provision-association mechanism
(`StatuteKnowledgeProductService.provisionRefMap`). **Case ↔ Topic** uses the
P14 membership configuration. **Question ↔ Source** uses the P15 product's own
source. Doctrine/Provision/Topic products resolve through the existing
P12/P13/P14 services; nothing is reconstructed.

## 7. Directionality

P16 never imposes artificial symmetry. A P5 case → case edge is preserved with
its orientation: for origin `A`, an edge `A → B` is emitted as **outgoing**, and
an edge `B → A` is emitted as **incoming**. Both are exposed explicitly via the
`direction` field and the `withDirection` filter. Incoming relationships are
never rewritten as outgoing ones. A relationship that has no inherent direction
(the primary root) carries `direction == null`.

## 8. Provenance

Every reference preserves the origin and destination identities, the
relationship type, the provenance source string and the evidence references,
so the question *"why does this navigation edge exist?"* is always answerable:

- **P5 precedent edge** — evidence = `[edgeId, ...edgeEvidenceIds]`, provenance
  = the edge's recorded provenance (e.g. `corpus:precedentsFollowed`).
- **P5 doctrine edge** — evidence = `[edgeId, ...edgeEvidenceIds]`, provenance =
  the edge's provenance (e.g. `corpus:doctrines`).
- **P13 provision association** — provenance = `p13:provisionRefMap`, evidence =
  the raw corpus reference (e.g. `Article 21`).
- **P14 topic membership** — provenance = `p14:membership`, evidence = the
  membership signal (`<signalField>:<signalValue>`).
- **P15 question source** — provenance = `p15:questionProduct`, evidence = the
  question product ID.

No synthetic provenance is created; no claim of evidence is made where none
exists.

## 9. Product resolution & missing-product behavior

Every returned destination is resolved through the existing P11–P15 services:

| Destination | Resolved by |
|---|---|
| case | `CaseExplanationService.explain` |
| doctrine | `DoctrineKnowledgeProductService.build` |
| provision | `StatuteKnowledgeProductService.build(type, id)` |
| topic | `TopicKnowledgeProductService.build` |
| question | the P15 `buildAll()` product registry |

If a relationship points to an entity for which a product cannot currently be
resolved (e.g. a sparse case with no P4 intelligence has no P15 question
product), P16 **omits** that reference deterministically. It never fabricates a
product, never builds a fake placeholder and never returns an unresolvable
destination. `resolveAll` also drops any reference that later fails to resolve.

## 10. Legal-safety boundaries

- No legal **similarity**, **authority**, **overruling**, **refinement**,
  **extension**, **doctrinal evolution**, **causation**, **importance**,
  **correctness** or **current-law status** is inferred from navigation.
- A `related` P5 precedent remains a typed P5 edge (`specificTypeLabel:
  related`), never a generic "related" relationship kind.
- P14 **topic membership is a pedagogical grouping, not a legal relationship**;
  it is never confused with a P5 precedent (`isLegalRelationship == false`).
- **Provision association** is sourced from the P3/P13 map, never from a
  fabricated P5 edge.
- Ordering is structural, never an editorial importance ranking.
- The P5 graph is **never mutated** by navigation.

## 11. Offline behavior

P16 makes **no network calls**, uses **no LLM / external API**, and introduces
**no new runtime dependency**. It reads only the in-memory canonical corpus and
the existing offline services. Output is fully deterministic: identical inputs
produce structurally identical collections regardless of time, randomness or
machine.

## 12. Explicit exclusions

P16 does **not** create: a new graph / precedent graph / search engine /
evidence registry / repository / rendering framework; a generic
`KnowledgeProduct` inheritance hierarchy; a similarity algorithm; a relevance
ranking system; embeddings or vector search; AI/LLM functionality; network
calls; persistence; caching; UI or Flutter screens/widgets; user-defined
relationships; learning paths, prerequisites, curricula or study collections;
question sets or assessment/scoring; or new legal corpus data. Those belong to
future work or other GARUDA packages.

## 13. Examples

```dart
final nav = KnowledgeProductNavigatorService(); // canonical offline corpus

// Everything reachable from a case.
final col = nav.findAllProductsForCase('KESAVANANDA');
for (final r in col.references) {
  print('${r.relationshipType.name}/${r.specificTypeLabel} '
      '${r.direction?.name} -> ${r.toProductType.name}:${r.toProductId} '
      '(${r.provenance})');
}

// Incoming precedent edges only.
final incoming = col.withDirection(NavigationDirection.incoming);

// Related products (excluding the case's own product).
final related = nav.findRelatedProducts(KnowledgeProductType.caseLaw, 'KESAVANANDA');

// Resolve every reference to a real product.
final products = nav.resolveAll(col); // List<Object>, no nulls
```
