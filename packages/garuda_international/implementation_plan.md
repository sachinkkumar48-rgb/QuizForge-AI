# GARUDA International Organisations, Groupings & Global Institutions Library — Implementation Plan

**Prompt:** TITAN-KO-013.0
**Package:** `packages/garuda_international`
**Baseline:** `garuda_bodies`, `garuda_schemes`, `garuda_reports` (verified reference architecture)
**Status:** Approved — full implementation

---

## 1. Scope

Implement `garuda_international` — a production-ready, evidence-backed knowledge
library of international organisations, groupings and global institutions,
modelled as permanent, interconnected `InternationalKnowledgeObject` instances
on the verified TITAN GARUDA architecture. Designed specifically for UPSC
(Prelims/Mains/Essay/Interview) with India-centric intelligence.

## 2. Target Architecture (mirrors `garuda_bodies` / `garuda_schemes`)

```
lib/
├── garuda_international.dart             # public package export
├── domain/entities/
│   ├── international_enums.dart          # typed enums (see §3)
│   ├── international_relationship.dart   # InternationalRelationship value object
│   └── international_knowledge_object.dart # central International Knowledge Object
├── data/
│   ├── international_official_sources.dart  # official-source/evidence registry
│   ├── international_corpus_support.dart    # DRY record factory (mandatory evidence)
│   ├── international_corpus_un.dart         # UN system (20)
│   ├── international_corpus_finance_trade.dart # Bretton Woods, trade, economic (17)
│   ├── international_corpus_regional.dart   # regional / political groupings (14)
│   ├── international_corpus_security_environment.dart # security + climate (15)
│   └── international_seed_corpus.dart       # combiner + expected counts
├── repositories/
│   ├── international_repository.dart        # abstract contract + InternationalCorpusReport
│   └── in_memory_international_repository.dart # offline-first, pre-seeded impl
├── search/international_search_engine.dart  # multi-field, relevance-ranked
├── validators/international_validator.dart  # evidence-gated publication validator
├── ingestion/international_ingestion_pipeline.dart # JSON/CSV/official-source adapter
├── analytics/international_analytics_engine.dart   # machine-readable distributions
└── services/international_editorial_service.dart   # GARUDA Editorial Engine integration
test/                                        # domain/repo/search/validator/ingestion/
                                             # analytics/editorial/regression suites
```

## 3. Domain Model

`InternationalKnowledgeObject` (immutable, full JSON round-trip,
`toGarudaKnowledgeObject` bridge) fields:

- Identity: `id`, `officialName`, `shortName`, `acronym`
- Typed classification: `bodyType`, `category`, `institutionalStatus`,
  `treatyStatus`, `membershipType`, `membershipScope`, `decisionMakingModel`,
  `fundingModel`
- Institutional: `headquarters`, `headquartersRegion`, `establishedYear`,
  `foundingTreaty`, `legalBasis`, `secretariat`, `membershipCount`,
  `principalOrgans`, `leadershipStructure`, `votingMechanism`,
  `mandate`, `objectives`, `functions`, `powers`, `fundingMechanism`,
  `importantProgrammes`, `importantConventions`
- Scope: `geographicalRegion`, `issueAreas` (List<GlobalIssueArea>)
- India intelligence: `indiaMembership`, `indiaJoiningYear`, `indiaRole`,
  `indiaHostedEvents`, `indiaInitiatives`, `observerStatus`
- UPSC intelligence: `upscRelevance`, `prelimsRelevance`, `mainsRelevance`,
  `interviewRelevance`, `prelimsTraps`, `mainsThemes`, `essayThemes`,
  `interviewAreas`, `currentRelevance`, `indiaRelevance`
- Knowledge graph (string-ID cross-package contract): `relatedArticleIds`,
  `relatedActIds`, `relatedCaseLawIds`, `relatedDoctrineIds`,
  `relatedCommitteeIds`, `relatedReportIds`, `relatedSchemeIds`,
  `relatedCurrentAffairsIds`, `relatedPyqIds`, `relatedOrganisationIds`,
  `relationships`, `sdgGoals` (descriptor strings)
- Evidence/editorial: `officialSource` (required), `evidenceIds` (required),
  `lastVerifiedDate`, `keywords`, `version`, `editorialStatus` (garuda_editor),
  `metadata`

Typed value models: `InternationalBodyType`, `InternationalCategory`,
`MembershipType`, `MembershipScope`, `IndiaRelationshipStatus`,
`HeadquartersRegion`, `DecisionMakingModel`, `FundingModel`, `TreatyStatus`,
`InstitutionalStatus`, `UpscRelevanceLevel`, `RelevanceLevel`,
`GeographicalRegion`, `GlobalIssueArea`, `InternationalRelationshipType`,
`InternationalRelationship` value object.

## 4. Phase-I Corpus

~60–66 **real, traceable** international organisations:

- **UN system (20):** UN, UNSC, UNGA, ICJ, ICC, UNHRC, UNCTAD, UNDP, UNEP,
  UNESCO, UNICEF, UNHCR, UN Women, FAO, WHO, WFP, ILO, IMO, ICAO, WIPO
- **Finance & trade (17):** IMF, World Bank, IDA, IFC, MIGA, BIS, ADB, AIIB,
  NDB, AfDB, IFAD, WTO, OECD, FATF, FSB, IEA, IRENA
- **Regional / political groupings (14):** G20, G7, BRICS, SCO, ASEAN, ARF,
  SAARC, BIMSTEC, QUAD, IORA, IBSA, Commonwealth, EU, African Union
- **Security (8):** NATO, INTERPOL, CTBTO, OPCW, IAEA, NSG, MTCR, Wassenaar
- **Environment / climate (7):** UNFCCC, IPCC, CBD, IUCN, GCF, GEF, ISA

Every record carries an official-source URL (real organisation/treaty/GoI
domain), evidence references, last-verified date, `evidenceVerified` editorial
status, India membership/status and UPSC relevance. **No fabricated records,
URLs or membership data**; `expectedInternationalCorpus` states exactly the
verified count.

## 5. Repository & Search

`InternationalRepository` + `InMemoryInternationalRepository` (pre-seeded)
supporting: by ID, name, acronym, category, body type, region, headquarters,
founding year, treaty, membership, India relationship, sector, issue area,
UPSC relevance, keyword, related organisation, relationship type, and
multi-criteria search via `InternationalSearchEngine` (exact/prefix/acronym/
keyword/category/region/membership/India/treaty/sector/autocomplete/
related-organisation discovery, relevance-ranked favouring name → acronym →
keyword → India relevance → UPSC relevance → relationship relevance).

## 6. Validation & Ingestion

`InternationalValidator` gates publication-readiness on mandatory evidence and
official source; detects duplicate IDs/organisations, missing name/type,
malformed/fabricated URLs, invalid membership data, contradictory institutional
metadata, invalid founding dates, broken treaty references, broken
cross-package relationships, invalid relationship types, placeholder records
and incomplete India relationship metadata. `InternationalIngestionPipeline`
implements source → load → parse → normalize → extract → validate → map →
register → relationship resolution → index → editorial queue with JSON, CSV
and official-source adapter paths (resumable batch ingestion).

## 7. Relationships & Analytics

Cross-links are established **only where semantically defensible** (WHO→health,
WTO→trade, IMF→macroeconomics, UNFCCC→climate governance, IAEA→nuclear
governance, FATF→money laundering, etc.). `InternationalAnalyticsEngine`
produces machine-readable distributions: by type, category, region, membership
type, India relationship, issue area, founding decade, UPSC relevance; treaty/
convention/relationship frequency; Constitution/Act/Scheme/Current-Affairs/PYQ/
SDG linkage frequency; most-interconnected organisations; India-relevant
organisations; evidence coverage; corpus completeness.

## 8. Editorial Integration

`InternationalEditorialService` mirrors the reference services: submits into
the GARUDA Editorial Production Engine, advances the lifecycle, quality-gates
publication (evidence + official source + approval + score ≥ 80).

## 9. Verification

- `flutter analyze` → 0 issues
- `flutter test` (garuda_international) → all green
- Root `flutter test`, all `garuda_*` packages, `pytest` → green (no new
  regressions; new vs pre-existing failures clearly separated)
- Phase-13 completeness checklist fully checked before any success claim

## 10. Documentation & Git

`walkthrough.md` + this `implementation_plan.md` finalized. Commit
`feat(garuda_international): implement GARUDA International Organisations and Global Institutions Library (TITAN-KO-013.0)` then push to `origin/sprint-1-polish` only after verification passes.

---

## Execution Status (final)

Implemented and verified.

| Deliverable | Status | Evidence |
|---|---|---|
| Central `InternationalKnowledgeObject` | ✅ | `lib/domain/entities/international_knowledge_object.dart` |
| Typed value models (body type, category, membership, India relationship, HQ region, decision/funding models, treaty/institutional status, regions, issue areas, relevance, relationship) | ✅ | `international_enums.dart`, `international_relationship.dart` |
| Phase-I corpus (real, traceable) | ✅ | 66 organisations across 4 corpus files; `international_official_sources.dart` (66 URLs, 1:1) |
| Repository + in-memory impl | ✅ | `repositories/international_repository.dart`, `in_memory_international_repository.dart` |
| Search engine (relevance-ranked) | ✅ | `search/international_search_engine.dart` |
| Validator (evidence-gated) | ✅ | `validators/international_validator.dart` |
| Ingestion pipeline | ✅ | `ingestion/international_ingestion_pipeline.dart` |
| Relationship mapping | ✅ | evidence-backed cross-links + `InternationalRelationship` edges |
| India intelligence | ✅ | `indiaMembership`, `indiaJoiningYear`, `indiaRole`, hosted events, initiatives |
| UPSC intelligence | ✅ | relevance levels, `prelimsTraps`, `mainsThemes`, `essayThemes`, `interviewAreas` |
| Analytics engine | ✅ | `analytics/international_analytics_engine.dart` |
| Editorial integration | ✅ | `services/international_editorial_service.dart` |
| Public package export | ✅ | `lib/garuda_international.dart` |
| Tests | ✅ | 56/56 (domain, repo, search, validator, ingestion, analytics, editorial, regression + corpus integrity) |
| `flutter analyze` | ✅ | 0 issues |
| Repository-wide regression | ✅ | root `flutter test` green, all 16 `garuda_*` packages green, `pytest` 99 passed |
| Documentation | ✅ | `walkthrough.md`, this `implementation_plan.md` |
| Git commit + push | Phase 15 | see commit log |
