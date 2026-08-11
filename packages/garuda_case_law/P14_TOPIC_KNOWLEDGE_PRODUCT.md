# P14 — Evidence-Bounded UPSC Topic Knowledge Products

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 14 of GARUDA Landmark Case Law)
**Base:** P13 `Statute Knowledge Products` at commit `c7bd5ff`
**Status:** ✅ P14 implemented & verified

---

## 1. Purpose

P14 is a **deterministic, offline-first pedagogical topic knowledge-product
layer** over the already-validated P3–P13 GARUDA Case Law corpora. It answers:

> What do the existing validated records say about one pedagogical UPSC topic —
> as a structured, topic-level, provenance-preserving knowledge product?

P14 produces a single immutable **`TopicKnowledgeProduct`** for a canonical
pedagogical topic defined by the versioned P14 syllabus configuration: the topic
identity (canonical ID, name, normalized P4 syllabus area, pedagogical path and
the explicit declaration that the taxonomy is a pedagogical mapping — never a
claim of official UPSC syllabus), an editorial pedagogical overview, its
**member cases** (cases mapped through explicit P14 `TopicMembership` records
citing validated P3/P4 signals), **safely composed doctrines** (P12
`DoctrineKnowledgeProduct`s whose constituent cases are all topic members) and
**provisions** (P13 `StatuteKnowledgeProduct`s whose associated cases are all
topic members), chronology and structural observations (P10 ordering), UPSC
relevance already attached to the member cases (P4 verbatim), evidence /
provenance (P8 registry + P14 mapping), and one P11 `CaseExplanation` per member
case.

P14 is **not** a legal-reasoning engine, **not** a legal-relationship layer and
**not** an official UPSC syllabus taxonomy. A topic membership is a
**pedagogical grouping** of existing validated case-law knowledge for UPSC
preparation. It does **not** establish a legal relationship — precedent, legal
similarity, authority, overruling, refinement, extension, doctrinal evolution,
causation or current-law status — between the included entities. Legal
relationships among cases are established solely by the P5 precedent/doctrine
graph, which P14 never mutates. Every statement in every section is composed
verbatim from existing validated P3–P13 source data, carries its **source
references** and its **provenance**.

## 2. Where it lives

```
lib/topic_product/
├── data/topic_syllabus_config.dart        # versioned, immutable P14 syllabus config
├── domain/
│   ├── topic_product_enums.dart           # TopicMappingKind, TopicSectionType
│   ├── topic_product_section.dart         # TopicStatement, TopicSection
│   ├── topic_identity.dart                # TopicIdentity
│   ├── topic_membership.dart              # TopicMembership + TopicSignalField
│   └── topic_knowledge_product.dart       # TopicKnowledgeProduct
├── service/topic_knowledge_product_service.dart
└── validation/topic_mapping_validator.dart
test/topic_product/
├── synthetic_corpus.dart                  # test-only synthetic corpus/config/doctrines
├── topic_product_domain_model_test.dart
├── topic_product_resolution_test.dart
├── topic_product_mapping_test.dart
├── topic_product_aggregation_test.dart
├── topic_product_provenance_test.dart
├── topic_product_legal_safety_test.dart
├── topic_product_missing_data_test.dart
├── topic_product_determinism_offline_test.dart
└── topic_product_corpus_test.dart         # corpus-wide verification
```

All public types are exported through `lib/garuda_case_law.dart`.

## 3. Architecture

P14 is a composition layer: it reads P3–P13 products and models and composes
them deterministically into topic products. It introduces **no new legal
algorithm**. Specifically:

- **P4** — the normalized `UpscSyllabusArea` enum and per-case
  `UpscJudgmentIntelligence` (`mainsThemes`, `answerKeywords`, `essayThemes`,
  `relatedSyllabusAreas`) is the source of the syllabus-area vocabulary and the
  membership signals.
- **P10** — `CrossCaseAnalysisService.chronologicalAnalysis` orders the member
  cases (year asc, judgment date asc, name asc, ID asc). Position is never
  causation.
- **P11** — one `CaseExplanation` per member case, reused directly.
- **P12** — `DoctrineKnowledgeProductService.buildAll` +
  `doctrineMemberIds` (the P5 case → doctrine edge members) drives doctrine
  composition under the strict all-members rule.
- **P13** — `StatuteKnowledgeProductService.buildAll` + `provisionRefMap` (the
  P3 corpus provision references) drives provision composition under the same
  strict all-members rule.
- **P8** — `EvidenceEntry` resolves the member cases' evidence IDs.

The service is **offline-first**: the default constructor builds over the
canonical offline corpus and services, synchronously, with no network and no
LLM.

## 4. Domain model

- **`TopicIdentity`** — immutable identity of one pedagogical topic (ID, name,
  `UpscSyllabusArea` area, editorial pedagogical path, `TopicMappingKind`,
  config version). `isOfficialSyllabus` is always `false` for the current
  configuration: the repository holds no authoritative UPSC syllabus source.
- **`TopicMembership`** — the explicit, deterministic record that a case
  belongs to a topic. Carries the canonical topic ID, the case ID, the **signal
  field** (one of `TopicSignalField` — `p3:themes`, `p3:subjects`,
  `p4:mainsThemes`, `p4:answerKeywords`, `p4:essayThemes`,
  `p4:syllabusAreas`) and the **verbatim signal value** the case genuinely
  carries. This is the ONLY way a case enters a topic.
- **`TopicStatement` / `TopicSection`** — mirror the P11/P12/P13 section shape:
  label, verbatim text, non-empty source references, provenance. A section with
  no statements is omitted rather than emitted empty.
- **`TopicKnowledgeProduct`** — the immutable product: topic identity fields,
  chronologically ordered member case IDs, sections (fixed order), one P11
  `CaseExplanation` per member, embedded P12 doctrine products and P13 statute
  products. `referencedIds` aggregates every canonical identifier, sorted.

## 5. Syllabus configuration

`TopicSyllabusConfig` is a static, immutable, versioned configuration
(`UpscTopicSyllabus.config`, version `1`) that defines:

- the **mapping declaration** — the explicit statement of what topic membership
  is (a pedagogical grouping) and is not (a legal relationship, an official
  taxonomy);
- **twelve canonical topics** grouped under normalized P4 syllabus areas (GS II
  / GS III), each with an editorial pedagogical path;
- **explicit memberships** — every membership cites a validated P3/P4 signal
  string that the mapped case genuinely carries (verified verbatim against the
  49-case corpus);
- **editorial overviews** — one sentence per topic, surfaced as editorial.

The configuration is deliberately **small** — a static declaration, not a
generic syllabus engine and not a generic education taxonomy.

## 6. Membership signals (case → topic)

A case is mapped to a topic only when the mapping is supported by validated
P3/P4 data. The validator (`TopicMappingValidator`) enforces, for every
membership, that:

1. the topic ID is canonical;
2. the case exists in the corpus (no orphaned mapping);
3. the signal field is one of `TopicSignalField`;
4. the signal value is present **verbatim** in the cited field on the case
   (`missing-signal` otherwise);
5. when the case carries P4 `relatedSyllabusAreas`, the topic's area is among
   them (`area-mismatch` otherwise);
6. no duplicate exact membership exists.

Membership is **never** inferred from graph connectivity, chronology, doctrine
membership alone, P9 discovery, P10 analysis or legal similarity. Four cases
(`ADM_JABALPUR`, `LILY_THOMAS`, `VINEET_NARAIN`, `LALITA_KUMARI`) carry P4 data
but no validated signal that safely maps to a current topic — they are left
**unmapped** and reported informationally (`unmapped-case`), never fabricated
into a topic.

## 7. Doctrine composition (P12 reuse)

A P12 `DoctrineKnowledgeProduct` is embedded in a topic only when **every
constituent case** of the doctrine (the P5 case → doctrine edge members, via
`DoctrineKnowledgeProductService.doctrineMemberIds`) is already a topic member
(the **strict all-members rule**). No doctrine membership is invented, and a
doctrine with no resolvable constituent cases is never composed. This means,
for example, that `BASIC_STRUCTURE` is **not** composed into the amending-power
topic: one of its constituent cases (`M_NAGARAJ`) carries no validated
basic-structure signal and is therefore not a topic member — using the doctrine
edge to imply membership would violate the membership rule.

## 8. Provision composition (P13 reuse)

A P13 `StatuteKnowledgeProduct` is embedded in a topic only when **every
associated case** of the provision (the P3 corpus references, via
`StatuteKnowledgeProductService.provisionRefMap`) is already a topic member.
P13's own provision mapping is reused directly — P14 implements **no second
statute mapping engine**.

## 9. Chronology semantics

Member cases are presented in P10 chronological order (year asc, judgment date
asc, name asc, ID asc). Chronology is **position, not causation** — an earlier
case is not asserted to be the cause of, or precedent for, a later one.

## 10. Evidence / provenance

Every statement carries its provenance, e.g.:

- `p14:syllabusConfig.*` — identity, overview, declaration, version;
- `p14:membership; p14:syllabusConfig.memberships` — member-case statements;
- `p10:chronology` — chronology statements;
- `p3:subjects`, `p4:syllabusAreas` — structural observations;
- `p4:upscIntelligence.mainsThemes` — UPSC relevance (verbatim);
- `p12:DoctrineKnowledgeProduct`, `p13:StatuteKnowledgeProduct` — composition;
- `corpus:evidenceIds; p14:membership` — evidence, with P8 `EvidenceEntry`
  resolution.

`TopicSection.provenance` / `.references` aggregate the contained statements
(unique, sorted).

## 11. Legal-safety boundaries

- Topic membership is a **pedagogical grouping** and establishes **no** legal
  relationship.
- The mapping declaration is embedded in every product's identity section.
- No product ever claims official UPSC syllabus status.
- The P14 service holds **no** graph reference, performs **no** graph mutation,
  and adds **no** precedent or doctrine edges; the P5 graph stays authoritative.
- No section asserts precedent, overruling, refinement, extension, doctrinal
  evolution, causation or current-law status.

## 12. Determinism

Identical corpus + identical services produce **byte-identical** structured
output: canonical topics in ID order, sections in the fixed order (identity,
overview, memberCases, doctrines, provisions, chronology, structural
observations, upscRelevance, evidence), references and provenance sorted, member
cases in chronological order. There is no wall-clock, randomness or LLM input.

## 13. Offline behavior

The service is synchronous and offline-first: the default constructor builds
over the canonical offline corpus with no network dependency and no LLM.

## 14. Limitations

- The taxonomy is a **pedagogical mapping**; it is not and does not claim to be
  an official UPSC syllabus.
- Topics are static and versioned; changing the taxonomy is a configuration
  change, not a runtime operation.
- A case that carries P4 data but no validated signal is left unmapped (and
  reported) rather than guessed.
- Composition is intentionally conservative: a doctrine/provision is embedded
  only when fully contained within the topic.

## 15. API usage

```dart
final service = TopicKnowledgeProductService();          // canonical corpus
final identity = service.resolveTopic('amending_power_and_basic_structure');
final product = service.build('amending_power_and_basic_structure');
final all = service.buildAll();                          // 12 products
final topics = service.topicForCase('KESAVANANDA');      // mapped topics

final validator = TopicMappingValidator();
final result = validator.validate();                     // config vs corpus
final productsResult = validator.validateProducts();     // built products
```

## 16. Explicit exclusions

P14 does **not**: infer membership from graph/discovery/chronology; re-implement
case explanation, doctrine aggregation or statute aggregation; modify P7;
introduce a generic syllabus engine or education taxonomy; add AI/LLM; add
network dependencies; mutate the P5 graph; or claim official syllabus status.
