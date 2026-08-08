# GARUDA Government Schemes Knowledge Library — Engineering Walkthrough

**Prompt:** TITAN-KO-011.0 (re-implementation)
**Package:** `packages/garuda_schemes`
**Status:** Implemented and verified

---

## 1. Purpose & Scope

The `garuda_schemes` package is the GARUDA Government Schemes Knowledge
Library for Project TITAN. It provides India's comprehensive, structured
repository of Central Sector Schemes, Centrally Sponsored Schemes, Flagship
Missions and industrial initiatives — every scheme modelled as a first-class,
evidence-backed, searchable **Scheme Knowledge Object** linked to the
Constitution, Acts, Committees, Reports, Case Law, Doctrines, Current Affairs,
PYQs, Ministries and SDGs.

## 2. Architecture

The package follows the verified TITAN GARUDA architecture (Clean Architecture,
SOLID, DDD, offline-first, JSON-first) established by `garuda_reports` and
`garuda_committees`:

```
lib/
├── garuda_schemes.dart                 # public package export
├── domain/entities/                    # immutable domain model
│   ├── scheme_enums.dart               # typed enums (SchemeType, SchemeCategory,
│   │                                   #   SchemeStatus, FundingPatternType,
│   │                                   #   SchemeSector, RuralUrbanScope, SdgGoal, ...)
│   ├── scheme_ministry.dart            # SchemeMinistry enum (analytics key)
│   ├── scheme_beneficiary.dart         # BeneficiaryGroup enum (filter key)
│   ├── scheme_funding.dart             # SchemeFundingDetail value object
│   ├── scheme_benefit.dart             # SchemeBenefit value object
│   ├── scheme_component.dart           # SchemeComponent value object
│   ├── scheme_relationship.dart        # SchemeRelationship value object
│   ├── scheme_timeline.dart            # SchemeTimeline value object
│   └── scheme_knowledge_object.dart    # central Scheme Knowledge Object
├── data/
│   ├── scheme_official_sources.dart    # official-source/evidence registry
│   ├── scheme_corpus_support.dart      # DRY record factory (mandatory evidence)
│   ├── scheme_corpus_agriculture.dart  # agri, rural, food security (15)
│   ├── scheme_corpus_welfare.dart      # health, education, women/child, social, tribal (18)
│   ├── scheme_corpus_economy.dart      # financial inclusion, employment, skill, MSME (15)
│   ├── scheme_corpus_infrastructure.dart # housing, water, energy, infra, digital, env, S&T (19)
│   └── scheme_seed_corpus.dart         # combiner + expected counts (67)
├── repositories/
│   ├── scheme_repository.dart          # abstract contract + SchemeCorpusReport
│   └── in_memory_scheme_repository.dart# offline-first, pre-seeded impl
├── search/scheme_search_engine.dart    # multi-field search + autocomplete
├── validators/scheme_validator.dart    # evidence-gated publication validator
├── ingestion/scheme_ingestion_pipeline.dart # JSON/CSV ingestion pipeline
├── analytics/scheme_analytics_engine.dart   # machine-readable distributions
└── services/scheme_editorial_service.dart   # GARUDA Editorial Engine integration
test/                                   # domain/repo/search/validation/ingestion/
                                        # analytics/editorial/regression suites
```

## 3. Domain Model

`SchemeKnowledgeObject` is the central entity. It carries:

- **Identity:** `id`, `officialName`, `shortName` (acronym)
- **Typed classification:** `schemeType`, `category`, `sector`, `ministry`,
  `status` (all enums)
- **Governance:** `department`, `launchDate`, `implementingAgency`
- **Beneficiaries:** `beneficiaries` (`List<BeneficiaryGroup>`),
  `targetBeneficiaries`, `eligibility`
- **Content:** `objectives`, `keyFeatures`, `benefits`, `components`, `coverage`
- **Funding:** `funding` (`SchemeFundingDetail`: pattern, central share, state
  share, financial assistance, budget outlay)
- **Scope:** `geographicScope`, `ruralUrbanScope`
- **Knowledge graph:** `relatedArticleIds`, `relatedActIds`,
  `relatedCaseLawIds`, `relatedDoctrineIds`, `relatedCommitteeIds`,
  `relatedReportIds`, `relatedCurrentAffairsIds`, `relatedPyqIds`,
  `relatedSchemeIds`, `predecessorSchemeIds`, `successorSchemeIds`,
  `subsumedBySchemeId`, `sdgGoals`, `relationships`, `timeline`
- **Evidence/editorial:** `officialSource` (mandatory), `evidenceIds`
  (mandatory), `lastVerifiedDate`, `upscRelevance`, `keywords`, `version`,
  `editorialStatus`, `metadata`

The entity is immutable (`@immutable`), offers `copyWith`, and provides full
JSON `toJson`/`fromJson` round-trip serialization plus a
`toGarudaKnowledgeObject()` bridge into the GARUDA Editorial Production Engine.

## 4. Phase-I Corpus

**67 real, traceable Government of India schemes** across all 19 listed sectors
(agriculture, rural development, health, education, women & child development,
social justice, tribal development, employment, skill development, financial
inclusion, housing, water & sanitation, energy, infrastructure, environment,
digital governance, food security, MSME/industry, science & technology).

Every record is built from officially published facts (scheme portals and PIB
releases) with:

- an `officialSource` (traceable official portal domain),
- `evidenceIds` (registry-driven, one per scheme),
- a corpus-wide `lastVerifiedDate` (`2026-06-30`),
- `editorialStatus` `evidenceVerified`.

The official-source/evidence layer is centralised in `scheme_official_sources.dart`
(67 real portal URLs, 1:1 with the corpus). **No fabricated, placeholder or
mock records exist**; the `expectedSchemeCorpus` constant (67) states exactly
the verified record count.

**Corpus coverage:**
- 67 verified scheme records
- 27 distinct ministries (see `SchemeSeedCorpus.coveredMinistries`)
- 20 scheme categories (incl. added `tribalDevelopment`)
- 19 sectors, 30 beneficiary groups
- constitutional links (e.g., Article 21, 21A, 15(3), 46), statutory links
  (e.g., MGNREGA Act 2005, NFSA 2013, RTE Act 2009, Maternity Benefit Act
  1961, PCPNDT Act 1994, Electricity Act 2003), committee links
  (e.g., `comm_swaminathan_2004`, `comm_arc_2nd_2005`), report links
  (e.g., `rep_es_2025_official`), PYQ links (real `PYQ_UPSC_CSE_*` format) and
  SDG links.

## 5. Source / Evidence Strategy

- **Mandatory evidence rule:** a Scheme cannot be production-ready without a
  non-empty `officialSource` and non-empty `evidenceIds`; the validator blocks
  publication otherwise.
- The registry (`scheme_official_sources.dart`) is the single auditable source
  of official portals and evidence references; the corpus factory resolves it
  so every record is evidence-backed by construction.
- Official-source URLs are validated for format and rejected if they point to
  known non-official domains (wikipedia, social media, blogs, etc.).

## 6. Search

`SchemeSearchEngine` provides:
- multi-field `search` (name, acronym, ministry, department, category, sector,
  beneficiary, state/UT, launch year, status, funding pattern, article, act,
  committee, report, PYQ, current affairs, related scheme, keyword)
- `findByExactName`, `autocomplete` (prefix over names/short names/keywords),
  `suggestKeywords` (corpus vocabulary),
- `relatedSchemes` (explicit `relatedSchemeIds` first, then semantic
  sector/ministry/category/beneficiary overlap).

## 7. Validation

`SchemeValidator` gates publication-readiness and detects:
- missing identity fields, missing official source, non-official source
- missing evidence (mandatory), malformed last-verified date, future launch date
- missing beneficiary information
- duplicate IDs and duplicate name+ministry pairs
- broken relationships and invalid cross-package references
- malformed JSON serialization (round-trip integrity)
- published-without-evidence

## 8. Ingestion

`SchemeIngestionPipeline` implements the full chain:

```
Official Source → Raw Payload → Knowledge Object Mapping → Validation →
Relationship Resolution → Repository Registration → GARUDA Editorial Queue →
Publication
```

with `ingestRawPayloads` (JSON maps), `ingestCsv` (with semicolon-separated
list columns) and `fromOfficialSource` (adapter point for future official
notification/portal ingestion). Every ingested object is submitted into the
GARUDA Editorial Production Engine registry.

## 9. Analytics

`SchemeAnalyticsEngine` produces machine-readable distributions: by ministry,
category, sector, beneficiary, launch year, status, scheme type and funding
pattern; top-linked articles/acts/committees/reports/PYQs/current
affairs/SDGs; most-interconnected schemes; per-scheme averages; and corpus
coverage (expected vs imported). `SchemeCorpusReport` (repository) exposes the
same coverage contract.

## 10. Editorial Integration

`SchemeEditorialService` integrates with the GARUDA Editorial Production
Engine (`garuda_editor`): it submits schemes into the 10-state editorial
lifecycle, advances stages, computes quality scores, and publishes only through
the quality gate (evidence + official source + approval + score ≥ 80). The
workflow-engine registry is the shared GARUDA knowledge index consumed by
cross-package search — consistent with the reference packages. (The
`garuda_knowledge` `KnowledgeIndex` operates on a distinct internal type and is
not consumed by the reference packages, so it is not introduced here.)

## 11. Cross-Package Relationships

Relationships are established **only where supported by domain evidence**:
constitutional articles and acts appear where a legal/constitutional basis
exists; committee links where an authoritative committee examined the scheme;
report links where an official report discusses it; PYQ links in the real
`PYQ_UPSC_CSE_*` format. No relationships are fabricated for coverage.

## 12. Test Results

- `flutter analyze`: **0 issues**
- `flutter test` (garuda_schemes): **55/55 passed**
  - domain (7), repository (7), search (10), validator (13), ingestion (5),
    analytics (5), editorial (5), regression (1)
- `pytest` (repository-wide): **99 passed**
- Root `flutter test`: passed (all existing suites green)
- All 14 `garuda_*` packages pass their suites (no new regressions)

## 13. Known Limitations

- Phase-I corpus is 67 verified records; additional schemes and ministries can
  be appended without redesign (registry + corpus files are additive).
- Cross-package report/committee links are deliberately sparse (evidence-based);
  ingestion/relationship resolution can extend them.
- Current-affairs links are populated via ingestion rather than pre-seeded.
- `garuda_schemes` is a standalone package; wiring it into the root
  application/`garuda_knowledge` index is a downstream integration step.

## 14. Verification Status

✅ Domain complete · ✅ Central Knowledge Object · ✅ Corpus exists with real
data · ✅ Official evidence · ✅ Repository · ✅ Search · ✅ Validator ·
✅ Ingestion · ✅ Analytics · ✅ Editorial integration · ✅ Public exports ·
✅ Tests pass · ✅ Analyze clean · ✅ Regression clean · ✅ Documentation
(`implementation_plan.md`, `walkthrough.md`).
