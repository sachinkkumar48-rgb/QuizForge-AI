# GARUDA Government Reports, Surveys, Indices & Development Indicators — Engineering Walkthrough

**Prompt:** TITAN-KO-014.0 (expansion / productionization)
**Package:** `packages/garuda_reports`
**Status:** Implemented and verified

---

## 1. Purpose & Scope

The `garuda_reports` package is the GARUDA Reports, Surveys, Indices &
Development Indicators Knowledge Library for Project TITAN. It provides India's
structured repository of Government of India and international/multilateral
official publications — every record modelled as a first-class, evidence-backed,
searchable **Knowledge Object** linked to the Constitution, Acts, Committees,
Schemes, Bodies, International Organisations, Case Law, Doctrines, Current
Affairs, PYQs and SDGs.

## 2. Architecture

Clean Architecture, SOLID, DDD, offline-first, JSON-first — consistent with the
other GARUDA packages:

```
lib/
├── garuda_reports.dart              # public package export
├── domain/entities/                 # immutable domain model
│   ├── report_enums.dart            # typed enums (ReportCategory, ReportType,
│   │                                #   PublicationFrequency, RelevanceLevel,
│   │                                #   IndicatorTrend, EditorialStatus, ...)
│   ├── report_knowledge_object.dart # central Report Knowledge Object
│   ├── index_knowledge_object.dart  # Index (rankings) Knowledge Object
│   ├── survey_knowledge_object.dart # Survey Knowledge Object
│   ├── indicator_knowledge_object.dart  # Indicator (development stats) KO
│   ├── chapter_knowledge_object.dart    # Chapter value object
│   ├── recommendation_knowledge_object.dart  # Recommendation value object
│   ├── report_statistic.dart / report_table.dart / report_chart.dart
│   └── report_relationship.dart    # typed relationship value object
├── data/
│   ├── report_official_sources.dart # official-source + evidence registry
│   ├── report_corpus_support.dart   # corpus enrichment (lastVerifiedDate,
│   │                                #   evidenceVerified status, coverage)
│   ├── report_seed_corpus.dart      # Phase-I seed corpus composition
│   ├── report_corpus_reports.dart   # Indian official reports
│   ├── report_corpus_reports_global.dart  # NITI Aayog & international reports
│   ├── report_corpus_indices.dart   # national & global indices/rankings
│   ├── report_corpus_surveys.dart   # official surveys (NFHS, PLFS, HCES, ASI)
│   └── report_indicator_corpus.dart # first-class development indicators
├── repositories/                    # ReportRepository interface + in-memory impl
├── search/report_search_engine.dart # multi-dimensional search + related reports
├── validators/report_validator.dart # publication-readiness validation
├── ingestion/report_ingestion_pipeline.dart  # JSON/CSV/multi-type ingestion
├── analytics/report_analytics_engine.dart    # completeness & linkage metrics
└── services/report_editorial_service.dart    # GARUDA Editorial integration
```

## 3. Phase-I Corpus

The Phase-I corpus ships **31 reports**, **9 indices**, **4 surveys** and
**25 indicators**, every one carrying an official source URL, resolvable
evidence ID, `lastVerifiedDate` and `evidenceVerified` editorial status.

| Group | Coverage |
| --- | --- |
| Indian official reports | Economic Survey, Union Budget, India Year Book, Finance Commissions (15th & 16th), CAG, RBI AR, SEBI AR, NCRB Crime in India, ISFR, ADSI, Census 2011, State of Indian Agriculture, UDISE+, National Health Accounts, CEA Annual Report |
| NITI Aayog & international | ADP Delta Rankings, WDR 2024, IMF WEO, UNESCO GEM, UNICEF SoWC, FAO SOFI, WHO WHS, IPCC AR6, UNDP HDR, UN WPP, RSF WPFI, Transparency CPI, ILO WESO, WTO WTR 2024, UNEP EGR 2024 |
| Indices | SDG India Index, NITI MPI, GHI, GII, HDI, Gender Gap, EODB, LEADS, EPI |
| Surveys | NFHS-5, PLFS 2022-23, HCES 2022-23, ASI 2022-23 |
| Indicators | TFR, stunting, institutional births, unemployment, LFPR, MPCE (rural/urban), GDP growth, CPI inflation, GNPA, forest cover, HDI, GHI score, GII rank, gender gap, MPI, population, CPI score/rank, WPFI rank, literacy, sex ratio, agri-GVA share, OOP health expenditure |

**No fabricated reports, statistics, URLs or rankings.** Every record is drawn
from officially published sources and its evidence ID resolves against
[`ReportOfficialSources`](lib/data/report_official_sources.dart).

## 4. Evidence Infrastructure (production-grade)

- `ReportOfficialSources` — canonical map of every record ID → official URL and
  every evidence ID → official reference; `evidenceCoverage` is measurable.
- `ReportCorpusSupport` — enrichment applied at seed time: stamps
  `lastVerifiedDate`, promotes records to `evidenceVerified`, and resolves
  missing `officialUrl`/`evidenceIds` so **no corpus record can exist without a
  traceable official source and evidence**.
- Whole-corpus evidence coverage is asserted `> 0.99` in the regression suite.

## 5. Search, Validation, Ingestion, Analytics

- **Search** — `ReportSearchQuery` gained `institution` and `ministry` filters;
  new `findRelatedReports` ranks related reports by shared category, themes,
  sectors, SDGs and cross-package links (exposed as `getRelatedReports` on the
  repository).
- **Validation** — `ReportValidator` now rejects placeholder content, malformed
  dates, implausible years, contradictory reporting periods and malformed
  indicator values, and flags broken cross-package references (articles, acts,
  committees, schemes, bodies, international organisations, current affairs,
  PYQs, case law). New `validateIndex` and `validateSurvey` cover indices and
  surveys.
- **Ingestion** — the pipeline gained `importIndices`, `importSurveys`,
  `importIndicators` and `ingestStructured` (mixed-type routing by
  `objectType`); `saveIndicator` added to the repository. All types flow into
  the editorial engine via the generic `submitKnowledgeObject`.
- **Analytics** — `ReportAnalyticsReport` gained `indiaCoverageCount`,
  `sdgDistribution`, `evidenceCoverage`, `indicatorFrequency`,
  `rankingFrequency`, `crossPackageLinkFrequency`, `mostInterconnectedReports`
  and JSON serialization (`toJson`).

## 6. Editorial Integration

`ReportEditorialService` bridges every object type into the GARUDA Editorial
Production Engine. No record becomes publishable merely by ingestion: official
source + evidence + editorial approval + quality-score gate are enforced.

## 7. Verification

- `flutter analyze` on `garuda_reports` and `garuda_committees`: **0 issues**.
- `garuda_reports` test suite: **83 tests green** (domain, evidence, validator,
  search, multi-type ingestion, analytics, editorial, regression).
- Root `pytest`: **green** (exit 0).
- Root `flutter analyze` failures are confined to pre-existing `project_titan/`
  issues unrelated to this package.
