# GARUDA International Organisations, Groupings & Global Institutions Library — Engineering Walkthrough

**Prompt:** TITAN-KO-013.0
**Package:** `packages/garuda_international`
**Status:** Implemented and verified

---

## 1. Purpose & Scope

The `garuda_international` package is the GARUDA International Organisations,
Groupings & Global Institutions Knowledge Library for Project TITAN. It
converts important international organisations, institutions, alliances,
forums, financial institutions, treaty organisations, regional groupings and
global governance bodies into structured, evidence-backed, searchable
**International Knowledge Objects**, designed specifically for UPSC
(Prelims/Mains/Essay/Interview) with India-centric intelligence.

## 2. Architecture

The package follows the verified TITAN GARUDA architecture (Clean Architecture,
SOLID, DDD, offline-first, JSON-first) established by `garuda_bodies`,
`garuda_schemes` and `garuda_reports`:

```
lib/
├── garuda_international.dart            # public package export
├── domain/entities/
│   ├── international_enums.dart         # InternationalBodyType, Category,
│   │                                    #   MembershipType/Scope, IndiaRelationshipStatus,
│   │                                    #   HeadquartersRegion, DecisionMakingModel,
│   │                                    #   FundingModel, TreatyStatus, InstitutionalStatus,
│   │                                    #   UpscRelevanceLevel, RelevanceLevel,
│   │                                    #   GeographicalRegion, GlobalIssueArea,
│   │                                    #   InternationalRelationshipType
│   ├── international_relationship.dart  # InternationalRelationship value object
│   └── international_knowledge_object.dart # central International Knowledge Object
├── data/
│   ├── international_official_sources.dart   # official-source/evidence registry (66)
│   ├── international_corpus_support.dart     # DRY record factory (mandatory evidence)
│   ├── international_corpus_un.dart          # UN system (20)
│   ├── international_corpus_finance_trade.dart # Bretton Woods, trade, economic (17)
│   ├── international_corpus_regional.dart    # regional / political groupings (14)
│   ├── international_corpus_security_environment.dart # security + climate (15)
│   └── international_seed_corpus.dart        # combiner + expected counts (66)
├── repositories/
│   ├── international_repository.dart         # abstract contract + InternationalCorpusReport
│   └── in_memory_international_repository.dart # offline-first, pre-seeded impl
├── search/international_search_engine.dart   # multi-field, relevance-ranked
├── validators/international_validator.dart   # evidence-gated publication validator
├── ingestion/international_ingestion_pipeline.dart # JSON/CSV/official-source adapter
├── analytics/international_analytics_engine.dart   # machine-readable distributions
└── services/international_editorial_service.dart   # GARUDA Editorial Engine integration
test/                                        # domain/repo/search/validator/ingestion/
                                             # analytics/editorial/regression suites
```

## 3. Domain Model

`InternationalKnowledgeObject` is the central entity. It carries:

- **Identity:** `id`, `officialName`, `shortName`, `acronym`
- **Typed classification:** `bodyType`, `category`, `institutionalStatus`,
  `treatyStatus`, `membershipType`, `membershipScope`, `decisionMakingModel`,
  `fundingModel` (all enums)
- **Institutional:** `headquarters`, `headquartersRegion`, `establishedYear`,
  `foundingTreaty`, `legalBasis`, `secretariat`, `membershipCount`,
  `principalOrgans`, `leadershipStructure`, `votingMechanism`, `mandate`,
  `objectives`, `functions`, `powers`, `fundingMechanism`,
  `importantProgrammes`, `importantConventions`
- **Scope:** `geographicalRegion`, `issueAreas` (List<GlobalIssueArea>)
- **India intelligence:** `indiaMembership`, `indiaJoiningYear`, `indiaRole`,
  `observerStatus`, `indiaHostedEvents`, `indiaInitiatives`
- **UPSC intelligence:** `upscRelevance`, `prelimsRelevance`, `mainsRelevance`,
  `interviewRelevance`, `prelimsTraps`, `mainsThemes`, `essayThemes`,
  `interviewAreas`, `currentRelevance`, `indiaRelevance`
- **Knowledge graph (string-ID cross-package contract):** `relatedArticleIds`,
  `relatedActIds`, `relatedCaseLawIds`, `relatedDoctrineIds`,
  `relatedCommitteeIds`, `relatedReportIds`, `relatedSchemeIds`,
  `relatedCurrentAffairsIds`, `relatedPyqIds`, `relatedOrganisationIds`,
  `relationships`, `sdgGoals`
- **Evidence/editorial:** `officialSource` (required), `evidenceIds`
  (required), `lastVerifiedDate`, `keywords`, `version`, `editorialStatus`,
  `metadata`

The entity is immutable (`@immutable`), offers `copyWith`, full JSON
`toJson`/`fromJson` round-trip, and a `toGarudaKnowledgeObject()` bridge.

## 4. Phase-I Corpus

**66 real, traceable international organisations:**

- **UN system (20):** UN, UNSC, UNGA, ICJ, ICC, UNHRC, UNCTAD, UNDP, UNEP,
  UNESCO, UNICEF, UNHCR, UN Women, FAO, WHO, WFP, ILO, IMO, ICAO, WIPO
- **Finance & trade (17):** IMF, World Bank (IBRD), IDA, IFC, MIGA, BIS, ADB,
  AIIB, NDB, AfDB, IFAD, WTO, OECD, FATF, FSB, IEA, IRENA
- **Regional / political groupings (14):** G20, G7, BRICS, SCO, ASEAN, ARF,
  SAARC, BIMSTEC, QUAD, IORA, IBSA, Commonwealth, EU, African Union
- **Security / strategic (8):** NATO, INTERPOL, CTBTO, OPCW, IAEA, NSG, MTCR,
  Wassenaar Arrangement
- **Environment / climate (7):** UNFCCC, IPCC, CBD, IUCN, GCF, GEF, ISA

Every record is built from authoritative official sources (organisation
websites, UN/treaty depository sources, or official Government of India/MEA
pages where a body has no permanent secretariat), with an `officialSource`
(traceable URL), `evidenceIds` (registry-driven, one per organisation), a
corpus-wide `lastVerifiedDate` (`2026-06-30`) and `evidenceVerified` editorial
status. **No fabricated records, URLs or membership data**; `expectedInternationalCorpus`
(66) states exactly the verified count.

## 5. Evidence Methodology

- **Mandatory evidence rule:** an organisation cannot be production-ready
  without a non-empty `officialSource` and non-empty `evidenceIds`; the
  validator blocks publication otherwise.
- `international_official_sources.dart` is the single auditable registry (66
  real URLs), 1:1 with the corpus.
- Official-source URLs are format-checked and rejected if they point to known
  non-official domains (Wikipedia, Britannica, social media, etc.).
- Fields that cannot be reliably established are left `null`/empty (e.g., some
  `indiaJoiningYear` values) rather than invented.

## 6. India Relevance Model

Every organisation carries India-specific intelligence: `indiaMembership`
(founding member / full member / observer / dialogue partner / strategic
partner / association member / non-member / not applicable), `indiaJoiningYear`
where verified, `indiaRole`, `observerStatus`, `indiaHostedEvents`
(e.g., G20 New Delhi 2023, CBD COP11 Hyderabad 2012) and `indiaInitiatives`
(e.g., QUAD, OSOWOG). The validator enforces that a joining year is only
recorded where India is actually a member.

## 7. UPSC Intelligence

Each object provides `upscRelevance` (high/medium/low/none), `prelimsRelevance`,
`mainsRelevance`, `interviewRelevance`, plus structured `prelimsTraps`,
`mainsThemes`, `essayThemes` and `interviewAreas` (e.g., ICJ vs ICC, IMF vs
World Bank, "India is NOT a G7/NATO member", QUAD is an informal dialogue not
an alliance).

## 8. Search

`InternationalSearchEngine` provides:
- multi-field `search` and `searchRanked` (name, acronym, body type, category,
  region, headquarters region, founding year, membership type, India
  relationship, issue area, UPSC relevance, keyword, treaty, related
  organisation),
- relevance ranking favouring: exact name → acronym → name-contains → keyword →
  India relevance → UPSC relevance → relationship relevance,
- `findByExactName`, `autocomplete`, `suggestKeywords`,
- `relatedOrganisations` (explicit `relatedOrganisationIds` first, then
  category/region/issue-area overlap).

## 9. Validation

`InternationalValidator` gates publication-readiness and detects:
- missing identity, default-filled (unclassified) records,
- missing mandatory evidence, malformed/fabricated source URLs,
- invalid founding dates (year ≤ 0 or in the future),
- contradictory treaty metadata (treaty-based body without a founding treaty),
- invalid membership data (non-positive membership count),
- contradictory India-relationship metadata (non-member with a joining year),
- missing India joining year for founding members (non-blocking),
- placeholder records, missing mandate,
- duplicate IDs and duplicate names,
- broken treaty/convention references, invalid relationship references,
- malformed serialization, published-without-evidence.

## 10. Ingestion

`InternationalIngestionPipeline` implements:

```
Official Source → Load → Parse → Normalize → Knowledge Object Mapping →
Validation → Relationship Resolution → Repository Registration →
GARUDA Editorial Queue → Publication
```

with `ingestRawPayloads` (JSON maps), `ingestCsv` (semicolon-separated list
columns, quoted-cell support) and `fromOfficialSource` (adapter point for
future treaty/institutional-portal ingestion). Every ingested object is
submitted into the GARUDA Editorial Production Engine registry.

## 11. Relationship Mapping

Cross-links are established **only where semantically defensible**: WHO→health,
WTO→trade, IMF→macroeconomics/balance of payments, World Bank→development
financing, UNFCCC→climate governance, CBD→biodiversity, IAEA→nuclear
governance, FATF→money laundering/terror financing, WIPO→intellectual property,
ILO→labour, IMO→maritime governance, ICAO→civil aviation, UNSC→international
peace and security, G20→global economic governance, BRICS→emerging economies,
SCO→Eurasian security, QUAD→Indo-Pacific, BIMSTEC→Bay of Bengal cooperation.
Cross-package links use the string-ID contract (Constitution articles, acts,
schemes, PYQs, etc.); explicit `InternationalRelationship` edges link
organisations (e.g., UN→WHO parent, UN→UNEP parent, G20→AU member).

## 12. Analytics

`InternationalAnalyticsEngine` produces machine-readable distributions: by body
type, category, region, headquarters region, membership type, India
relationship, founding decade and UPSC relevance; top treaties/conventions and
Article/Act/Scheme/Current-Affairs/PYQ/SDG linkage frequencies;
most-interconnected organisations; India-relevant organisations; evidence
coverage and corpus completeness. `InternationalCorpusReport` (repository)
exposes the same coverage contract.

## 13. Editorial Integration

`InternationalEditorialService` integrates with the GARUDA Editorial Production
Engine: submits organisations into the 10-state lifecycle, advances stages,
computes quality scores, and publishes only through the quality gate (evidence
+ official source + approval + score ≥ 80). The workflow-engine registry is the
shared GARUDA knowledge index — consistent with the reference packages.

## 14. Test Results

- `flutter analyze`: **0 issues**
- `flutter test` (garuda_international): **56/56 passed**
  - domain (7), repository (9), search (9), validator (17), ingestion (5),
    analytics (5), editorial (5), regression (1)
- `pytest` (repository-wide): **99 passed**
- Root `flutter test`: passed (all existing suites green)
- All 16 `garuda_*` packages pass their suites (no new regressions)

## 15. Known Limitations

- Phase-I corpus is 66 verified organisations; additional bodies (e.g., more UN
  agencies, regional development banks, specialised initiatives) are additive
  via the registry + corpus files.
- Report/committee/case cross-links are deliberately sparse (evidence-based).
- Current-affairs links are populated via ingestion rather than pre-seeded.
- Bodies without a permanent secretariat (G20, G7, BRICS, QUAD, IBSA, NSG,
  MTCR) are sourced to official presidency/chair or Government of India (MEA)
  pages, and are explicitly classified as `forum`/`grouping` with no fixed HQ.
- `garuda_international` is a standalone package; wiring into the root
  application/`garuda_knowledge` index is a downstream integration step
  (consistent with the other standalone GARUDA packages).

## 16. Verification Status

✅ Domain complete · ✅ Central International Knowledge Object · ✅ Corpus
exists with real data · ✅ Official evidence · ✅ Repository · ✅ Search
(relevance-ranked) · ✅ Validator · ✅ Ingestion · ✅ Relationship mapping ·
✅ India intelligence · ✅ UPSC intelligence · ✅ Analytics · ✅ Editorial
integration · ✅ Public exports · ✅ Tests pass (56/56) · ✅ Analyze clean ·
✅ Regression clean · ✅ Documentation (`implementation_plan.md`,
`walkthrough.md`).
