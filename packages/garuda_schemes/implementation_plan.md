# GARUDA Government Schemes Knowledge Library — Implementation Plan

**Prompt:** TITAN-KO-011.0 (re-implementation)
**Package:** `packages/garuda_schemes`
**Baseline:** `packages/garuda_reports`, `packages/garuda_committees` (verified reference architecture)
**Status:** Approved — full implementation

---

## 1. Scope

Rebuild the incomplete `garuda_schemes` scaffold into a production-ready,
evidence-backed Government Schemes Knowledge Library consistent with the
verified TITAN GARUDA package architecture.

## 2. Existing-State Audit (what already exists)

The previous attempt left only a partial domain scaffold. **No existing work
is deleted**; the scaffold is retained and extended.

| File | State | Disposition |
|---|---|---|
| `lib/domain/entities/scheme_enums.dart` | Complete (SchemeType, SchemeCategory, SchemeStatus, FundingPatternType, SchemeImplementationLevel, SchemeBenefitType, BudgetAllocationType, SdgGoal, SchemeRelationshipType) | **Keep**, append `SchemeSector` + `RuralUrbanScope` |
| `lib/domain/entities/scheme_benefit.dart` | Complete immutable value object | **Keep** |
| `lib/domain/entities/scheme_component.dart` | Complete immutable value object | **Keep** |
| `lib/domain/entities/scheme_relationship.dart` | Complete immutable value object | **Keep** |
| `lib/domain/entities/scheme_timeline.dart` | Complete immutable value object | **Keep** |
| `pubspec.yaml` | Correct cross-package dependency set | **Keep** |
| `analysis_options.yaml` | Lints | **Keep** |

**Missing entirely** (to be created): central `SchemeKnowledgeObject`,
ministry/beneficiary/funding value models, Phase-I corpus, repository, search
engine, validator, ingestion pipeline, analytics engine, editorial service,
public library export, tests, docs, commit.

## 3. Target Architecture (mirrors `garuda_reports` / `garuda_committees`)

```
lib/
├── garuda_schemes.dart                        # public package export
├── domain/entities/
│   ├── scheme_enums.dart                      # [extended]
│   ├── scheme_ministry.dart                   # Ministry enum (analytics key)
│   ├── scheme_beneficiary.dart                # BeneficiaryGroup enum (filter key)
│   ├── scheme_funding.dart                    # SchemeFundingDetail value object
│   ├── scheme_benefit.dart                    # [kept]
│   ├── scheme_component.dart                  # [kept]
│   ├── scheme_relationship.dart               # [kept]
│   ├── scheme_timeline.dart                   # [kept]
│   └── scheme_knowledge_object.dart           # central Knowledge Object
├── data/
│   ├── scheme_corpus_agriculture.dart         # agri, rural, food security
│   ├── scheme_corpus_welfare.dart             # health, education, women/child, social justice, tribal
│   ├── scheme_corpus_economy.dart             # financial inclusion, employment, skill, MSME/industry
│   ├── scheme_corpus_infrastructure.dart      # housing, water/sanitation, energy, infra, digital, environment, S&T
│   └── scheme_seed_corpus.dart                # combiner + expected corpus constants
├── repositories/
│   ├── scheme_repository.dart                 # abstract + SchemeSearchQuery + SchemeCorpusReport
│   └── in_memory_scheme_repository.dart       # pre-seeded Phase-I impl
├── search/scheme_search_engine.dart
├── validators/scheme_validator.dart
├── ingestion/scheme_ingestion_pipeline.dart
├── analytics/scheme_analytics_engine.dart
└── services/scheme_editorial_service.dart
test/
├── domain/scheme_knowledge_object_test.dart
├── repositories/scheme_repository_test.dart
├── search/scheme_search_engine_test.dart
├── validators/scheme_validator_test.dart
├── ingestion/scheme_ingestion_pipeline_test.dart
├── analytics/scheme_analytics_engine_test.dart
├── services/scheme_editorial_service_test.dart
└── regression/garuda_schemes_regression_test.dart
```

## 4. Domain Model (Phase 2)

`SchemeKnowledgeObject` (immutable, full JSON round-trip) fields:

- Identity: `id`, `officialName`, `shortName`
- Typed enums: `schemeType`, `category`, `sector`, `ministry`, `status`
- Governance: `department`, `launchDate`, `implementingAgency`
- Beneficiaries: `beneficiaries` (List<BeneficiaryGroup>), `targetBeneficiaries`
  (free-text), `eligibility` (List<String>)
- Content: `objectives`, `keyFeatures`, `benefits` (List<SchemeBenefit>),
  `components` (List<SchemeComponent>), `coverage`
- Funding: `funding` (SchemeFundingDetail: pattern, centralShare, stateShare,
  financialAssistance, budgetOutlay)
- Scope: `geographicScope`, `ruralUrbanScope`
- Knowledge-graph links (ID strings, matching reports/committees contract):
  `relatedArticleIds`, `relatedActIds`, `relatedCaseLawIds`,
  `relatedDoctrineIds`, `relatedCommitteeIds`, `relatedReportIds`,
  `relatedCurrentAffairsIds`, `relatedPyqIds`, `relatedSchemeIds`,
  `predecessorSchemeIds`, `successorSchemeIds`, `subsumedBySchemeId`,
  `sdgGoals`, `relationships` (List<SchemeRelationship>)
- Evidence/editorial: `officialSource` (required), `evidenceIds` (required),
  `lastVerifiedDate`, `upscRelevance`, `keywords`, `version`,
  `editorialStatus`, `metadata`
- `toGarudaKnowledgeObject()` bridge → `garuda_editor` `KnowledgeObject`
- `copyWith`, `toJson`, `fromJson`

Supporting value models: `SchemeMinistry` enum (~35 ministries),
`BeneficiaryGroup` enum (~22 groups), `SchemeSector` enum (broad sectors),
`RuralUrbanScope` enum, `SchemeFundingDetail` value object.

## 5. Phase-I Corpus (Phase 3)

~55–65 **real, traceable** schemes across all 19 listed sectors. Every record
carries an official source (scheme portal or parent ministry domain), internal
evidence IDs, a last-verified date, and an editorial status. No fabricated or
placeholder records. Coverage claim is stated exactly (count of verified
records), never inflated.

## 6. Repository & Search (Phases 4–5)

`SchemeRepository` + `InMemorySchemeRepository` (pre-seeded) supporting: by ID,
official name, acronym, ministry, department, category, sector, beneficiary,
state/UT, launch year, status, article, act, committee, report, PYQ, current
affairs, related scheme, and full multi-field search via `SchemeSearchEngine`.
Search engine: exact/prefix/keyword/autocomplete/suggestions/related-scheme
discovery + filters.

## 7. Validation & Ingestion (Phases 6–7)

`SchemeValidator` gates production-readiness on **mandatory evidence**
(official source + evidence IDs + ministry + valid status + dates + required
identity fields), detects duplicates, broken relationships, invalid
cross-package references, missing editorial metadata, malformed JSON and
placeholder records. `SchemeIngestionPipeline` implements the full chain
source→parse→map→validate→resolve→register→index→editorial→publish, with a
JSON payload path and a CSV path, plus an adapter point for future official
notification ingestion.

## 8. Cross-Package Graph & Analytics (Phases 8–9)

Relationships are established **only where supported by domain evidence**
(explicit legal/constitutional/committee/report bases). `SchemeAnalyticsEngine`
produces machine-readable distributions: by ministry, category, sector,
beneficiary, launch year, status, constitutional/act/PYQ/CA linkage frequency,
most-interconnected schemes, SDG coverage, corpus completeness.

## 9. Editorial Integration (Phase 10)

`SchemeEditorialService` mirrors `ReportEditorialService`: submits into the
GARUDA Editorial Production Engine (`garuda_editor`), advances the 10-state
lifecycle, enforces quality gates on publication, and returns the published
object with updated version/status. This registry is the shared GARUDA
knowledge index consumed by cross-package search — consistent with the
reference packages. (The `garuda_knowledge` `KnowledgeIndex` operates on a
distinct internal type and is not consumed by the reference packages; it is
therefore not introduced here.)

## 10. Verification (Phases 11–13)

- `flutter analyze` on `garuda_schemes` → 0 issues
- `flutter test` on `garuda_schemes` → all green (domain, repository, search,
  validator, ingestion, analytics, editorial, regression)
- Repository-wide: root `flutter test`, per-package GARUDA suites, `pytest`
  must remain green; new vs pre-existing failures clearly separated
- Phase 13 completeness checklist must be fully checked before success claim

## 11. Documentation (Phase 14)

- `packages/garuda_schemes/walkthrough.md` (full engineering walkthrough)
- This `implementation_plan.md` (updated to final state)

## 12. Git (Phase 15)

Commit `feat(garuda_schemes): complete GARUDA Government Schemes Knowledge
Library (TITAN-KO-011.0)` only after analyze/test/regression are satisfactory;
push to the current TITAN development branch.

---

## Execution Status (final)

Implemented and verified.

| Deliverable | Status | Evidence |
|---|---|---|
| Central `SchemeKnowledgeObject` | ✅ | `lib/domain/entities/scheme_knowledge_object.dart` |
| Supporting value models (Ministry, Beneficiary, Funding, Sector/RuralUrban) | ✅ | `scheme_ministry.dart`, `scheme_beneficiary.dart`, `scheme_funding.dart`, extended `scheme_enums.dart` |
| Phase-I corpus (real, traceable) | ✅ | 67 records across 4 thematic corpus files + `scheme_official_sources.dart` (67 official portals, 1:1) |
| Repository + in-memory impl | ✅ | `repositories/scheme_repository.dart`, `in_memory_scheme_repository.dart` |
| Search engine | ✅ | `search/scheme_search_engine.dart` |
| Validator (evidence-gated) | ✅ | `validators/scheme_validator.dart` |
| Ingestion pipeline | ✅ | `ingestion/scheme_ingestion_pipeline.dart` |
| Analytics engine | ✅ | `analytics/scheme_analytics_engine.dart` |
| Editorial integration | ✅ | `services/scheme_editorial_service.dart` |
| Public package export | ✅ | `lib/garuda_schemes.dart` |
| Tests | ✅ | 55/55 (domain, repo, search, validator, ingestion, analytics, editorial, regression) |
| `flutter analyze` | ✅ | 0 issues |
| Repository-wide regression | ✅ | root `flutter test` green, all 14 `garuda_*` packages green, `pytest` 99 passed |
| Documentation | ✅ | `walkthrough.md`, this `implementation_plan.md` |
| Git commit + push | Phase 15 | see commit log |
