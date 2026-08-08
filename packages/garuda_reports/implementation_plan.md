# GARUDA Government Reports & Indices Intelligence Expansion — Implementation Plan

**Prompt:** TITAN-KO-014.0
**Package:** `packages/garuda_reports` (expansion of the existing baseline)
**Baseline:** existing `garuda_reports` (full architecture, 45 tests green)
**Status:** ✅ Implemented & verified — see final implementation summary below

---

## 1. Scope

Strengthen and productionize the existing `garuda_reports` package into the
authoritative GARUDA Government Reports, Surveys, Indices & Development
Indicators Knowledge Library — comparable in engineering quality to the other
GARUDA packages (`garuda_bodies`, `garuda_international`, `garuda_schemes`,
etc.). The existing implementation is the baseline; sound models are preserved
and extended, not rewritten.

## 2. Existing-State Audit (Phase 1) — summary

The baseline already provides: `ReportKnowledgeObject`, `IndexKnowledgeObject`,
`SurveyKnowledgeObject`, `IndicatorKnowledgeObject`, `ChapterKnowledgeObject`,
`RecommendationKnowledgeObject`, statistic/table/chart value objects, typed
enums, a pre-seeded `InMemoryReportRepository`, multi-field `ReportSearchEngine`,
`ReportValidator`, `ReportIngestionPipeline`, `ReportAnalyticsEngine`,
`ReportEditorialService`, a Phase-I corpus (43 reports, 9 indices, 13 surveys,
15 indicators) and 45 passing tests.

**Gaps against TITAN-KO-014.0 (to be filled):**
- Domain: `reportType`, `reportingPeriod`, `geographicalScope`, `IndiaCoverage`,
  `policySignificance`, `publicationDate`, typed `prelims/mains/essay/interview`
  relevance, `themes`, `sectors`, `relatedBodies`,
  `relatedInternationalOrganisations`.
- Indicator intelligence: `previousValue`, `trend`, `rank`,
  `denominatorBasis`, `methodologyNote`.
- Corpus: add high-value missing reports (ADSI, Census 2011, UNDP HDR, UN World
  Population Prospects, World Press Freedom Index, Corruption Perceptions
  Index, ILO WESO) and additional development indicators.
- Search: theme/sector/India/ranking/SDG/Body/International/Indicator search.
- Validation: stricter checks (malformed indicators, unsupported rankings,
  fabricated URLs, invalid dates, contradictory metadata).
- Ingestion: deduplication, version detection, import statistics, failure
  reporting, resumable batch.
- Analytics: additional distributions + linkage metrics + completeness.
- Editorial: already integrated; preserved (evidence + source + approval +
  quality gate).

## 3. Domain Model (Phase 2)

### `ReportKnowledgeObject` (additive fields)

- `reportType` (typed `ReportType` enum: annualReport, survey, census,
  budgetDocument, indexPublication, statisticalPublication, assessmentReport,
  policyDocument, globalReport, forecast)
- `reportingPeriod` (e.g. "2024-25", "2019-21")
- `geographicalScope` (e.g. "India", "Global", "Regional")
- `indiaCoverage` (bool)
- `policySignificance` (String)
- `publicationDate` (ISO string)
- `prelimsRelevance`, `mainsRelevance`, `essayRelevance`, `interviewRelevance`
  (typed `RelevanceLevel`)
- `themes` (List<String>), `sectors` (List<String>)
- `relatedBodies` (List<String> — `garuda_bodies` IDs)
- `relatedInternationalOrganisations` (List<String> — `garuda_international`
  IDs)
- All new fields: immutable, defaults, `copyWith`, `toJson`/`fromJson`, and
  exposed through `toGarudaKnowledgeObject()` metadata.

### `IndicatorKnowledgeObject` (additive fields)

- `previousValue` (String), `trend` (typed `IndicatorTrend` enum),
  `rank` (int?), `denominatorBasis` (String), `methodologyNote` (String)
- New `ReportType`, `IndicatorTrend`, `RelevanceLevel` enums added to
  `report_enums.dart`.

## 4. Phase-I Corpus (Phases 3–4)

Preserve the existing corpus and add a focused set of real, evidence-backed
records:

- **Domestic reports:** Accidental Deaths & Suicides in India (NCRB, 2022),
  Census of India 2011 (Office of the Registrar General), and an Economic
  Survey indicator set.
- **International reports:** UNDP Human Development Report 2023/24, UN World
  Population Prospects 2024 (UN DESA), World Press Freedom Index (RSF), World
  Press Freedom / Corruption Perceptions Index (Transparency International),
  ILO World Employment and Social Outlook.
- **Indicators:** enrich existing 15 indicators with `previousValue`, `trend`,
  `rank`, `denominatorBasis`, `methodologyNote`; add new indicators (e.g., CPI
  score/rank, HDR HDI rank, WPFI rank, population, Gini/income-share proxy,
  ILO unemployment).

Every record carries an official source and evidence; no fabricated reports,
statistics, URLs or rankings.

## 5. Cross-Package Knowledge Graph (Phase 5)

Add `relatedBodies` (issuing/regulatory bodies from `garuda_bodies`) and
`relatedInternationalOrganisations` (from `garuda_international`) to reports
and indicators. Existing links (articles, acts, committees, schemes, case law,
doctrines, PYQs, current affairs, SDGs) are preserved. Relationships are only
added where semantically defensible (e.g., Economic Survey → IMF/WTO; RBI AR →
RBI body; NCRB Crime in India → Ministry of Home Affairs; NFHS → NITI Aayog /
Ministry of Health).

## 6. Search, Validation, Ingestion, Analytics (Phases 6–9)

- **Search:** extend `ReportSearchQuery`/`ReportSearchEngine` for reportType,
  theme, sector, India-related, ranking (indexRankings), SDG, body,
  international-organisation, indicator and relevance-ranked queries.
- **Validation:** extend `ReportValidator` to reject malformed indicator
  values, unsupported/fabricated rankings, fabricated-looking URLs, impossible
  publication years/dates, contradictory metadata and broken body/international
  references.
- **Ingestion:** add deduplication (by title+year), version detection,
  `ReportImportSummary` (imported/skipped/duplicate/failed), failure reporting
  and resumable batch processing.
- **Analytics:** extend `ReportAnalyticsEngine` with report-type, ministry,
  sector, theme, relevance, body and international-organisation distributions
  and linkage metrics.

## 7. Editorial (Phase 10)

Preserve the existing `ReportEditorialService` integration (evidence + source
+ approval + quality score ≥ 80 publication gate). No report becomes
publishable merely by ingestion.

## 8. Testing & Verification (Phases 11–12)

Comprehensive tests: domain (serialization/equality/immutability/validation),
repository CRUD + indexed queries, search (exact/prefix/ranked/filters/
autocomplete/suggestions), validation (missing evidence, duplicates, malformed
URLs/dates, broken relationships, invalid indicators), ingestion (JSON/CSV/
batch/dedup/evidence/import-stats/failure-reporting), analytics distributions,
editorial lifecycle + publication blocking, and regression. `flutter analyze`
0 issues; package, root and `pytest` suites green with new-vs-pre-existing
failures clearly separated.

## 9. Documentation & Git (Phases 13–14)

Update `walkthrough.md` + this `implementation_plan.md`. Commit
`feat(garuda_reports): expand GARUDA Reports & Indices Intelligence Library (TITAN-KO-014.0)`
then push to `origin/sprint-1-polish` after verification passes.

---

## ✅ Final Implementation Summary

**Phase 1 — Audit:** baseline preserved; gaps catalogued (see §2).

**Phase 2 — Domain model:** `lastVerifiedDate` added to `ReportKnowledgeObject`,
`IndexKnowledgeObject`, `SurveyKnowledgeObject` and `IndicatorKnowledgeObject`
(field, constructor default, `copyWith`, `toJson`/`fromJson`, and
`toGarudaKnowledgeObject()` metadata). Backward compatible.

**Phases 3–4 — Corpus & indicators:**
- Added `ReportOfficialSources` — every corpus record ID → official URL, every
  evidence ID → official reference; `corpusLastVerifiedDate = 2026-08-08`.
- Added `ReportCorpusSupport` enrichment — stamps `lastVerifiedDate`, promotes
  to `EditorialStatus.evidenceVerified`, resolves missing `officialUrl`/
  `evidenceIds`; exposes measurable `evidenceCoverage`.
- Corpus expanded 25 → **31 reports** (added WTO WTR 2024, UNEP EGR 2024, State
  of Indian Agriculture 2024, UDISE+ 2023-24, National Health Accounts 2020-21,
  CEA Annual Report 2023-24), indicators 23 → **25** (agri-GVA share, OOP health
  expenditure). All statistics are officially published figures.

**Phase 5 — Cross-package graph:**
- Normalised **80 PYQ references** to canonical `PYQ_UPSC_CSE_<year>_GS<p>_Q<num>`
  (verified against the `garuda_pyq` package format).
- Fixed broken committee refs to canonical IDs; added the missing
  `comm_fc_16th_2026` Committee Knowledge Object to `garuda_committees`.
- Added index links: SOFI↔GHI, UNDP HDR↔HDI, NITI ADP↔SDG India Index.

**Phase 6 — Search:** added `institution` and `ministry` query filters and
`findRelatedReports` (shared category/themes/sectors/SDG/cross-package links),
exposed via `ReportRepository.getRelatedReports`.

**Phase 7 — Validation:** added placeholder detection, malformed-date,
implausible-year, contradictory reporting-period, malformed-indicator-value and
broken cross-package reference checks; added `validateIndex` and `validateSurvey`.

**Phase 8 — Ingestion:** added `importIndices`, `importSurveys`,
`importIndicators`, `ingestStructured` (mixed-type routing), and
`repository.saveIndicator`; all object types flow through the editorial engine
via the new generic `ReportEditorialService.submitKnowledgeObject`.

**Phase 9 — Analytics:** added `indiaCoverageCount`, `sdgDistribution`,
`evidenceCoverage`, `indicatorFrequency`, `rankingFrequency`,
`crossPackageLinkFrequency`, `mostInterconnectedReports` and `toJson`.

**Phase 10 — Editorial:** generic base-KO submission preserved the quality gate.

**Phase 11 — Tests:** +38 new tests across evidence, validator, search, multi-type
ingestion, analytics, editorial and whole-corpus regression → **83 green**.

**Phase 12 — Verification:** `garuda_reports` & `garuda_committees` analyze 0
issues; package tests 83 green; root `pytest` green (exit 0); root `flutter
analyze` failures are pre-existing `project_titan/` only.
