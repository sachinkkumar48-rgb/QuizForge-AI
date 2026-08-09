# GARUDA Landmark Case Law Intelligence Library — Walkthrough

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phases 1-3)
**Status:** P3 (Phase-II landmark case corpus) implemented & verified

---

## What this package is

A knowledge library of **49 real Indian landmark judgments** — every record is a
first-class, evidence-backed `CaseKnowledgeObject` that is searchable and
connected to the Constitution, Acts, Doctrines, Bodies, Schemes, Committees,
Reports, International Organisations, Current Affairs and PYQs, following the
GARUDA engineering conventions shared with `garuda_reports`, `garuda_schemes`,
`garuda_bodies` and `garuda_international`.

## Layered architecture

```
Domain      CaseKnowledgeObject  (≈90 fields; copyWith, equality, toJson/fromJson,
                                 toGarudaKnowledgeObject interop)
            CaseStatus | CourtLevel | CaseType | RelevanceLevel |
            PrecedentRelationshipType  (case_enums.dart)
            PrecedentRelationship      (precedent_relationship.dart)

Data        landmark_cases_phase1.dart   (20 Phase-I cases, article refs normalized)
            landmark_cases_phase2.dart   (29 Phase-II cases)
            case_seed_data.dart          (CaseSeedData.cases = phase1 + phase2, enriched)
            case_corpus_support.dart     (enrichCase + evidence coverage metric)
            case_official_sources.dart   (evidence registry → official sources)

Infra       repositories/                (CaseRepository + InMemoryCaseRepository)
            validators/case_validator.dart
            analyzer/case_analyzer.dart  (CaseAnalysisReport)

Search      search/domain/               (CaseSearchQuery | CaseSearchFilters |
                                         CaseSearchResult | CaseSearchSuggestion)
            search/data/                 (CaseSearchNormalizer | CaseSearchIndex)
            search/service/              (CaseSearchEngine — see P6_CASE_SEARCH_ENGINE.md)

Validation  validation/                  (CorpusValidator orchestrates the existing
                                         validators + corpus-level & cross-package
                                         integrity — see P7_CORPUS_VALIDATION.md)
```

## Quick start

```dart
import 'package:garuda_case_law/garuda_case_law.dart';

final repo = InMemoryCaseRepository();

// Full corpus
final cases = await repo.getCases();            // 49 cases

// Find a case by ID, objectId, citation or alias
final kesavananda = await repo.findCase('KESAVANANDA');

// Query by constitutional article
final art21 = await repo.getCasesByArticle('21');  // e.g. Maneka Gandhi, Puttaswamy

// Evidence-backed record
final puttaswamy = await repo.findCase('PUTTASWAMY');
puttaswamy.evidenceIds;          // [ev_PUTTASWAMY_official]
puttaswamy.officialSource;       // https://main.sci.gov.in/judgments
puttaswamy.lastVerifiedDate;     // 2026-08-08
puttaswamy.doctrines;            // [PROPORTIONALITY]
```

## Evidence model

- Every case derives an evidence ID `ev_<caseId>_official` (`CaseOfficialSources`).
- `CaseCorpusSupport.evidenceCoverage(cases)` reports the fraction of records
  with a resolvable evidence ID — asserted at **1.0** in the integrity suite.
- `toGarudaKnowledgeObject()` bridges each case into the GARUDA editorial engine
  (`garuda_editor`), mapping `editorialStatus` → `EditorialStatus` and packing
  articles, doctrines, cross-links and UPSC relevance into metadata.

## Testing

```bash
flutter analyze            # 0 issues
flutter test               # 28 tests pass
```

Coverage: `test/data/case_corpus_integrity_test.dart` (15 integrity checks),
`test/domain`, `test/repositories`, `test/validators`, `test/analyzer`.

## Scope notes / limitations

- P3 covers the corpus. Search engine, ingestion pipeline, expanded validator,
  analytics engine and editorial service are subsequent phases of TITAN-KO-015.0.
- Legacy Phase-I PYQ references (`PYQ_UPSC_2020_01` style) are preserved as-is;
  canonical `PYQ_UPSC_CSE_*` references apply to new records.
