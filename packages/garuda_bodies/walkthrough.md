# GARUDA Government Commissions & Statutory Bodies Library — Engineering Walkthrough

**Prompt:** TITAN-KO-012.0
**Package:** `packages/garuda_bodies`
**Status:** Implemented and verified

---

## 1. Purpose & Scope

The `garuda_bodies` package is the GARUDA Government Commissions & Statutory
Bodies Knowledge Library for Project TITAN. It provides India's comprehensive,
structured repository of Constitutional bodies, Statutory bodies, Regulatory
bodies, National Commissions, Authorities, Boards and Tribunals — every body
modelled as a first-class, evidence-backed, searchable **Body Knowledge Object**
linked to the Constitution, Acts, Cases, Doctrines, Committees, Reports,
Schemes, Current Affairs, PYQs, SDGs and related Bodies.

## 2. Architecture

The package follows the verified TITAN GARUDA architecture (Clean Architecture,
SOLID, DDD, offline-first, JSON-first) established by `garuda_schemes`,
`garuda_reports` and `garuda_committees`:

```
lib/
├── garuda_bodies.dart                 # public package export
├── domain/entities/
│   ├── body_enums.dart                # BodyType, BodyCategory, ConstitutionalBasis,
│   │                                  #   StatutoryBasis, BodyJurisdiction,
│   │                                  #   AppointmentAuthority, TenureType,
│   │                                  #   ReportingAuthority, BodyStatus,
│   │                                  #   BodyIndependence, UpscRelevanceLevel,
│   │                                  #   RelevanceLevel, BodyRelationshipType
│   ├── body_relationship.dart         # BodyRelationship value object
│   └── body_knowledge_object.dart     # central Body Knowledge Object
├── data/
│   ├── body_official_sources.dart     # official-source/evidence registry (43 portals)
│   ├── body_corpus_support.dart       # DRY record factory (mandatory evidence)
│   ├── body_corpus_constitutional.dart# constitutional bodies + national commissions (11)
│   ├── body_corpus_regulatory.dart    # statutory/regulatory/national bodies (32)
│   └── body_seed_corpus.dart          # combiner + expected counts (43)
├── repositories/
│   ├── body_repository.dart           # abstract contract + BodyCorpusReport
│   └── in_memory_body_repository.dart # offline-first, pre-seeded impl
├── search/body_search_engine.dart     # multi-field, relevance-ranked search
├── validators/body_validator.dart     # evidence-gated publication validator
├── ingestion/body_ingestion_pipeline.dart # JSON/CSV/official-source adapter
├── analytics/body_analytics_engine.dart   # machine-readable distributions
└── services/body_editorial_service.dart   # GARUDA Editorial Engine integration
test/                                  # domain/repo/search/validator/ingestion/
                                       # analytics/editorial/regression suites
```

## 3. Domain Model

`BodyKnowledgeObject` is the central entity. It carries:

- **Identity:** `id`, `officialName`, `shortName` (acronym)
- **Typed classification:** `bodyType`, `category`, `constitutionalBasis`,
  `statutoryBasis`, `bodyStatus`, `bodyIndependence` (all enums)
- **Constitutional/statutory basis:** `establishingArticleIds`
  (e.g. "Article 324"), `establishingActIds` (e.g. "Reserve Bank of India Act,
  1934"), `yearEstablished`, `parentMinistry`, `headquarters`, `jurisdiction`
- **Governance:** `mandate`, `powers`, `functions`, `composition`,
  `appointmentMechanism`, `appointmentAuthority`, `tenure`, `tenureType`,
  `removalMechanism`, `eligibilityQualifications`, `reportingAuthority`,
  `financialStructure`, `importantProvisions`
- **UPSC relevance:** `upscRelevance`, `prelimsRelevance`, `mainsRelevance`,
  `interviewRelevance` (typed relevance levels)
- **Knowledge graph:** `relatedArticleIds`, `relatedActIds`,
  `relatedCaseLawIds`, `relatedDoctrineIds`, `relatedCommitteeIds`,
  `relatedReportIds`, `relatedSchemeIds`, `relatedCurrentAffairsIds`,
  `relatedPyqIds`, `relatedBodyIds`, `sdgGoals`, `relationships`
- **Evidence/editorial:** `officialSource` (required), `evidenceIds`
  (required), `lastVerifiedDate`, `keywords`, `version`, `editorialStatus`,
  `metadata`

The entity is immutable (`@immutable`), offers `copyWith`, full JSON
`toJson`/`fromJson` round-trip, and a `toGarudaKnowledgeObject()` bridge into
the GARUDA Editorial Production Engine.

## 4. Phase-I Corpus

**43 real, traceable Indian bodies**:

- **11 constitutional bodies / national constitutional commissions:** Election
  Commission (Art 324), UPSC (Arts 315-323), Finance Commission (Art 280),
  CAG (Art 148), Attorney General (Art 76), State PSCs, State Election
  Commissions (Arts 243K/243ZA), State Finance Commissions (Arts 243I/243Y),
  NCSC (Art 338), NCST (Art 338A), NCBC (Art 338B).
- **32 statutory / regulatory / national bodies:** CIC, CVC, Lokpal, NHRC,
  NCW, NCM, NCDRC, CCI, SEBI, RBI, TRAI, IRDAI, PFRDA, NGT, CPCB, NDMA,
  FSSAI, NMC, UGC, AICTE, NCISM, NCAHP, NIA, IBBI, NCPCR, UIDAI, CERC,
  APTEL, NABARD, SIDBI, IFSCA, CBI.

Every record is built from the Constitution, establishing Acts and official
body portals, with an `officialSource` (traceable official portal), `evidenceIds`
(registry-driven, one per body), a corpus-wide `lastVerifiedDate`
(`2026-06-30`) and `evidenceVerified` editorial status. **No fabricated or
placeholder records exist**; `expectedBodyCorpus` (43) states exactly the
verified count.

## 5. Source / Evidence Strategy

- **Mandatory evidence rule:** a Body cannot be production-ready without a
  non-empty `officialSource` and non-empty `evidenceIds`; the validator blocks
  publication otherwise.
- `body_official_sources.dart` is the single auditable registry (43 real
  portals: `eci.gov.in`, `upsc.gov.in`, `rbi.org.in`, `sebi.gov.in`, etc.),
  1:1 with the corpus.
- Official-source URLs are format-checked and rejected if they point to known
  non-official domains.

## 6. Search

`BodySearchEngine` provides:
- multi-field `search` and `searchRanked` (name, acronym, body type, category,
  ministry, jurisdiction, appointment authority, year, status, UPSC relevance,
  keyword, article, act, committee, report, scheme, current affairs, PYQ,
  related body),
- relevance scoring (exact name/acronym and article/act matches outrank
  keyword-only matches),
- `findByExactName`, `autocomplete`, `suggestKeywords`,
- `relatedBodies` (explicit `relatedBodyIds` first, then semantic
  type/category/jurisdiction/ministry overlap).

## 7. Validation

`BodyValidator` gates publication-readiness and detects:
- missing identity fields, missing legal basis, malformed Article references
  (regex-validated: `Article 324`, `Article 15(3)`, `Article 243ZA`),
- contradictory constitutional-basis metadata,
- broken/malformed Act references, malformed URLs, non-official source domains,
- missing mandatory evidence, placeholder records, missing mandate,
- incomplete appointment/tenure/removal data for constitutional bodies,
- missing year of establishment, duplicate IDs and duplicate names,
- invalid relationship references, malformed serialization,
- published-without-evidence.

## 8. Ingestion

`BodyIngestionPipeline` implements:

```
Official Source → Raw Payload → Normalize → Knowledge Object Mapping →
Validation → Relationship Resolution → Repository Registration →
GARUDA Editorial Queue → Publication
```

with `ingestRawPayloads` (JSON maps), `ingestCsv` (semicolon-separated list
columns, quoted-cell support) and `fromOfficialSource` (adapter point for
future statutory-notification/portal ingestion). Every ingested object is
submitted into the GARUDA Editorial Production Engine registry.

## 9. Relationships

Cross-links are established **only where supported by domain evidence**:
constitutional articles (e.g., Art 324 → ECI, Art 279A → GST Council),
establishing Acts (e.g., RBI Act 1934, SEBI Act 1992, RTI Act 2005), case law
(e.g., *Vineet Narain v. Union of India* → CBI), committees (e.g.,
`comm_fc_15th_2017` → Finance Commission), reports (e.g., `rep_cag_official` →
CAG), schemes (e.g., `sch_pmjdy` → RBI), PYQs and related bodies (e.g., ECI →
State Election Commissions, CVC → CBI, SEBI/RBI/IRDAI/PFRDA financial
regulators). No artificial relationships are fabricated.

## 10. Analytics

`BodyAnalyticsEngine` produces machine-readable distributions: by body type,
category, ministry, constitutional/statutory basis, jurisdiction, year,
UPSC relevance; top-linked articles/acts/cases/doctrines/committees/reports/
schemes/PYQs/current affairs; most-interconnected bodies; evidence coverage;
corpus coverage. `BodyCorpusReport` (repository) exposes the same coverage
contract.

## 11. Editorial Integration

`BodyEditorialService` integrates with the GARUDA Editorial Production Engine:
submits bodies into the 10-state lifecycle, advances stages, computes quality
scores, and publishes only through the quality gate (evidence + official source
+ approval + score ≥ 80). The workflow-engine registry is the shared GARUDA
knowledge index — consistent with the reference packages.

## 12. Test Results

- `flutter analyze`: **0 issues**
- `flutter test` (garuda_bodies): **57/57 passed**
  - domain (7), repository (9), search (9), validator (17), ingestion (5),
    analytics (5), editorial (5), regression (1)
- `pytest` (repository-wide): **99 passed**
- Root `flutter test`: passed (all existing suites green)
- All 15 `garuda_*` packages pass their suites (no new regressions)

## 13. Known Limitations

- Phase-I corpus is 43 verified bodies; additional bodies (State-level,
  international or sectoral regulators) can be appended additively via the
  registry + corpus files.
- Report/committee/case cross-links are deliberately sparse (evidence-based).
- Current-affairs links are populated via ingestion rather than pre-seeded.
- `garuda_bodies` is a standalone package; wiring into the root
  application/`garuda_knowledge` index is a downstream integration step
  (consistent with the other standalone GARUDA packages).

## 14. Verification Status

✅ Domain complete · ✅ Central Body Knowledge Object · ✅ Corpus exists with
real data · ✅ Official evidence · ✅ Repository · ✅ Search (relevance-ranked) ·
✅ Validator · ✅ Ingestion · ✅ Relationships · ✅ Analytics · ✅ Editorial
integration · ✅ Public exports · ✅ Tests pass (57/57) · ✅ Analyze clean ·
✅ Regression clean · ✅ Documentation (`implementation_plan.md`,
`walkthrough.md`).
