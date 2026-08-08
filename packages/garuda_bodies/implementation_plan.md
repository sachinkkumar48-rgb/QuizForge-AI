# GARUDA Government Commissions & Statutory Bodies Knowledge Library — Implementation Plan

**Prompt:** TITAN-KO-012.0
**Package:** `packages/garuda_bodies`
**Baseline:** `garuda_schemes`, `garuda_reports`, `garuda_committees` (verified reference architecture)
**Status:** Approved — full implementation

---

## 1. Scope

Implement `garuda_bodies` — a production-ready, evidence-backed knowledge
library of Indian constitutional bodies, statutory bodies, regulatory bodies,
national commissions, authorities, boards and tribunals, modelled as permanent,
interconnected `BodyKnowledgeObject` instances on the verified TITAN GARUDA
architecture.

## 2. Target Architecture (mirrors `garuda_schemes` / `garuda_reports`)

```
lib/
├── garuda_bodies.dart                      # public package export
├── domain/entities/
│   ├── body_enums.dart                     # BodyType, BodyCategory, ConstitutionalBasis,
│   │                                       #   StatutoryBasis, BodyJurisdiction,
│   │                                       #   AppointmentAuthority, TenureType,
│   │                                       #   ReportingAuthority, BodyStatus,
│   │                                       #   BodyIndependence, UpscRelevanceLevel,
│   │                                       #   RelevanceLevel, BodyRelationshipType
│   ├── body_relationship.dart              # BodyRelationship value object
│   └── body_knowledge_object.dart          # central Body Knowledge Object
├── data/
│   ├── body_official_sources.dart          # official-source/evidence registry
│   ├── body_corpus_support.dart            # DRY record factory (mandatory evidence)
│   ├── body_corpus_constitutional.dart     # constitutional bodies + national commissions
│   ├── body_corpus_regulatory.dart         # statutory / regulatory / national bodies
│   └── body_seed_corpus.dart               # combiner + expected counts
├── repositories/
│   ├── body_repository.dart                # abstract contract + BodyCorpusReport
│   └── in_memory_body_repository.dart      # offline-first, pre-seeded impl
├── search/body_search_engine.dart          # multi-field, relevance-ranked
├── validators/body_validator.dart          # evidence-gated publication validator
├── ingestion/body_ingestion_pipeline.dart  # JSON/CSV/official-source adapter
├── analytics/body_analytics_engine.dart    # machine-readable distributions
└── services/body_editorial_service.dart    # GARUDA Editorial Engine integration
test/                                      # domain/repo/search/validator/ingestion/
                                           # analytics/editorial/regression suites
```

## 3. Domain Model

`BodyKnowledgeObject` (immutable, full JSON round-trip, `toGarudaKnowledgeObject`
bridge) fields:

- Identity: `id`, `officialName`, `shortName`
- Typed classification: `bodyType`, `category`, `constitutionalBasis`,
  `statutoryBasis`, `bodyStatus`, `bodyIndependence`
- Constitutional/statutory basis: `establishingArticleIds` (e.g. "Article 324"),
  `establishingActIds` (e.g. "Reserve Bank of India Act, 1934"),
  `yearEstablished`, `parentMinistry`, `headquarters`, `jurisdiction`
- Governance: `mandate`, `powers`, `functions`, `composition`,
  `appointmentMechanism`, `appointmentAuthority`, `tenure`, `tenureType`,
  `removalMechanism`, `eligibilityQualifications`, `reportingAuthority`,
  `financialStructure`, `importantProvisions`
- UPSC relevance: `upscRelevance` (enum), `prelimsRelevance`,
  `mainsRelevance`, `interviewRelevance` (typed relevance levels)
- Knowledge graph (string-ID cross-package contract): `relatedArticleIds`,
  `relatedActIds`, `relatedCaseLawIds`, `relatedDoctrineIds`,
  `relatedCommitteeIds`, `relatedReportIds`, `relatedSchemeIds`,
  `relatedCurrentAffairsIds`, `relatedPyqIds`, `relatedBodyIds`,
  `sdgGoals` (descriptor strings), `relationships`
- Evidence/editorial: `officialSource` (required), `evidenceIds` (required),
  `lastVerifiedDate`, `keywords`, `version`, `editorialStatus` (garuda_editor),
  `metadata`

Supporting typed value models: `BodyType`, `BodyCategory`,
`ConstitutionalBasis`, `StatutoryBasis`, `BodyJurisdiction`,
`AppointmentAuthority`, `TenureType`, `ReportingAuthority`, `BodyStatus`,
`BodyIndependence`, `UpscRelevanceLevel`, `RelevanceLevel`,
`BodyRelationshipType`, `BodyRelationship` value object.

## 4. Phase-I Corpus

~40–45 **real, traceable** Indian bodies across constitutional, statutory,
regulatory and national categories (ECI, UPSC, Finance Commission, CAG,
Attorney General, State PSCs/Election/Finance Commissions, NCSC/NCST/NCBC,
CIC, CVC, Lokpal, NHRC, NCW, NCM, NCDRC, CCI, SEBI, RBI, TRAI, IRDAI, PFRDA,
NGT, CPCB, NDMA, FSSAI, NMC, UGC, AICTE, NCISM, NCAHP, NIA, IBBI, NCPCR,
UIDAI, CERC, APTEL, NABARD, SIDBI, IFSCA, CBI, …). Every record carries an
official portal source, evidence reference, last-verified date and
`evidenceVerified` editorial status. No fabricated or placeholder records;
`expectedBodyCorpus` states exactly the verified count.

## 5. Repository & Search

`BodyRepository` + `InMemoryBodyRepository` (pre-seeded) supporting: by ID,
name, acronym, body type, category, article, act, ministry, jurisdiction,
appointment authority, year established, status, keyword, UPSC relevance,
relationship, and multi-criteria search via `BodySearchEngine`
(exact/prefix/keyword/acronym/article/act/ministry/category/autocomplete/
suggestions/related-body discovery, relevance-ranked).

## 6. Validation & Ingestion

`BodyValidator` gates publication-readiness on mandatory evidence and official
source; detects duplicate IDs/bodies, missing name/type/basis, malformed
articles, broken act references, invalid relationship references, malformed
URLs, placeholder records, contradictory metadata, incomplete
appointment/tenure data. `BodyIngestionPipeline` implements
source → parse → normalize → extract → validate → map → register → index →
editorial queue with JSON, CSV and official-source adapter paths.

## 7. Relationships & Analytics

Cross-links are established **only where supported by domain evidence**.
`BodyAnalyticsEngine` produces machine-readable distributions: by type,
category, ministry, basis, jurisdiction, year, relevance, article/act linkage
frequencies, most-interconnected bodies, evidence coverage, corpus
completeness and editorial status.

## 8. Editorial Integration

`BodyEditorialService` mirrors `SchemeEditorialService`/`ReportEditorialService`:
submits into the GARUDA Editorial Production Engine, advances the lifecycle,
quality-gates publication (evidence + official source + approval + score ≥ 80).

## 9. Verification

- `flutter analyze` → 0 issues
- `flutter test` (garuda_bodies) → all green
- Root `flutter test`, all `garuda_*` packages, `pytest` → green (no new
  regressions; new vs pre-existing failures clearly separated)
- Phase-13 completeness checklist fully checked before any success claim

## 10. Documentation & Git

`walkthrough.md` + this `implementation_plan.md` finalized. Commit
`feat(garuda_bodies): implement GARUDA Government Commissions and Statutory
Bodies Library (TITAN-KO-012.0)` then push to `origin/sprint-1-polish` only
after verification passes.

---

## Execution Status (final)

Implemented and verified.

| Deliverable | Status | Evidence |
|---|---|---|
| Central `BodyKnowledgeObject` | ✅ | `lib/domain/entities/body_knowledge_object.dart` |
| Typed value models (BodyType, BodyCategory, basis, jurisdiction, appointment, tenure, reporting, status, independence, relevance, relationship) | ✅ | `body_enums.dart`, `body_relationship.dart` |
| Phase-I corpus (real, traceable) | ✅ | 43 bodies across `body_corpus_constitutional.dart` (11) and `body_corpus_regulatory.dart` (32); `body_official_sources.dart` (43 portals, 1:1) |
| Repository + in-memory impl | ✅ | `repositories/body_repository.dart`, `in_memory_body_repository.dart` |
| Search engine (relevance-ranked) | ✅ | `search/body_search_engine.dart` |
| Validator (evidence-gated) | ✅ | `validators/body_validator.dart` |
| Ingestion pipeline | ✅ | `ingestion/body_ingestion_pipeline.dart` |
| Relationship engine | ✅ | cross-package links + `BodyRelationship` edges |
| Analytics engine | ✅ | `analytics/body_analytics_engine.dart` |
| Editorial integration | ✅ | `services/body_editorial_service.dart` |
| Public package export | ✅ | `lib/garuda_bodies.dart` |
| Tests | ✅ | 57/57 (domain, repo, search, validator, ingestion, analytics, editorial, regression + corpus integrity) |
| `flutter analyze` | ✅ | 0 issues |
| Repository-wide regression | ✅ | root `flutter test` green, all 15 `garuda_*` packages green, `pytest` 99 passed |
| Documentation | ✅ | `walkthrough.md`, this `implementation_plan.md` |
| Git commit + push | Phase 15 | see commit log |
