# GARUDA Landmark Case Law Intelligence Library — Implementation Plan

**Prompt:** TITAN-KO-015.0 (Phases 1-3)
**Package:** `packages/garuda_case_law`
**Baseline:** existing `garuda_case_law` (20-case Phase-I corpus, 13 tests green)
**Status:** ✅ P1 (audit) & P2 (domain model) complete; P3 (landmark case corpus) complete & verified

---

## 1. Scope

Productionize `garuda_case_law` into the authoritative GARUDA Landmark Case Law
Knowledge Library — a corpus of real, evidence-backed Indian landmark judgments
connected to the Constitution, Acts, Doctrines, Bodies, Schemes, Committees,
Reports, International Organisations, Current Affairs and PYQs, following the
engineering conventions established by `garuda_reports`, `garuda_schemes`,
`garuda_bodies`, `garuda_committees` and `garuda_international`.

## 2. Existing-State Audit (Phase 1) — summary

The baseline provides: `CaseKnowledgeObject` (35+ fields, `toJson`/`fromJson`),
`CaseStatus`/`CourtLevel` enums, `CaseRepository` + offline-first
`InMemoryCaseRepository` seeded with 20 landmark cases, a repository-level
`CaseValidator`, a `CaseAnalyzer` (`CaseAnalysisReport`), a barrel export and 13
passing tests.

**Gaps identified against TITAN-KO-015.0:**
- Domain: no `copyWith`/equality/interop; no typed `CaseType`, `RelevanceLevel`,
  `PrecedentRelationshipType`; missing bench strength, neutral/reporter citation,
  parties, authoring judge, constitutional/legal questions, statutes/sections,
  precedent lists, related cases/bodies/schemes/international orgs/SDGs,
  themes/subjects, prelims/mains/essay/interview relevance, traps/themes/angles,
  doctrines, structured precedent relationships, official source/evidence.
- Corpus: only 20 cases; no environment, elections, criminal, economic/
  regulatory, federalism (beyond Bommai), women/children, tribunals; sparse
  cross-package links; article refs in bare-number format.
- Evidence: no official-source registry; evidence coverage not measurable.
- Search / ingestion / analytics / editorial: baseline only.

## 3. What P2 completed (Domain model)

- `case_enums.dart`: added `CaseType` (20 domains), `RelevanceLevel`,
  `PrecedentRelationshipType` + display-name extension.
- `precedent_relationship.dart`: `PrecedentRelationship` value object
  (source/target/type/note) with JSON + equality.
- `case_knowledge_object.dart`: expanded to a production model with ~90 fields —
  added `copyWith`, ID-keyed `operator ==`/`hashCode`, GARUDA editorial interop
  `toGarudaKnowledgeObject()` (maps `editorialStatus` → `EditorialStatus`,
  packages evidence/doctrines/cross-links), neutral/reporter citation, bench
  strength, judgment title, parties/petitioner/respondent, authoring judge,
  case type, jurisdiction, constitutional/legal questions, statutes/sections,
  precedent lists, related cases/bodies/schemes/international orgs, SDGs,
  themes/subjects, relevance levels, prelims traps / mains themes / interview
  angles, constitutional interpretation, legal principle, majority/minority/
  dissent, doctrines, structured precedent relationships, official source,
  publication/last-verified dates, evidence IDs. `toJson`/`fromJson` extended.
- `pubspec.yaml`: added `garuda_editor`, `garuda_doctrine`, `garuda_evidence`.
- Model verified: analyze clean, 13 baseline tests green.

## 4. What P3 completed (Phase-II landmark case corpus)

### 4.1 Evidence & official-source registry (`case_official_sources.dart`)
Every case resolves to an official source. Evidence IDs are derived uniformly
as `ev_<caseId>_official` and resolve against the Supreme Court of India's
official judgment portal. Corpus last-verified date: `2026-08-08`.

### 4.2 Corpus enrichment (`case_corpus_support.dart`)
`CaseSeedData.cases` = Phase-I (20) + Phase-II (29), each passed through
`enrichCase`, which guarantees a resolvable evidence ID, official source,
verification date and applies a curated cross-package enrichment pass to the 20
legacy Phase-I records (doctrines, precedent lists, related cases, acts,
reports, bodies, schemes, SDGs, themes/subjects, relevance levels, prelims
traps, mains themes, interview angles, constitutional interpretation, legal
principle, neutral citations, authoring judges, majority/dissent). Evidence
coverage is measurable and asserted at 100%.

### 4.3 Phase-II corpus (`landmark_cases_phase2.dart`) — 29 new cases
Real, verified landmark judgments (SC unless noted), each with citation, year,
court, bench strength, judges, facts, issues, arguments, decision, ratio,
significance, cross-links, UPSC intelligence and evidence:

| Category | Cases added |
|---|---|
| Judiciary / Tribunals / Judicial Review | L. Chandra Kumar (1997), SC Advocates-on-Record (1993, collegium), NJAC (2015), Shreya Singhal (2015) |
| Federalism | State of Rajasthan v. Union (1977), Nabam Rebia (2016) |
| Equality / Reservation | M. Nagaraj (2006), Jarnail Singh (2018), Janhit Abhiyan (2022) |
| Life / Liberty / Privacy | D.K. Basu (1997), Hussainara Khatoon (1979), Common Cause (euthanasia, 2018) |
| Environment | M.C. Mehta (Taj, 1997), Vellore Citizens (1996), ICELA Bichhri (1996), T.N. Godavarman (1997), Narmada Bachao (2000) |
| Elections / Democracy | ADR (2002), Lily Thomas (2013), PUCL NOTA (2013) |
| Criminal law | Bachan Singh (1980), Mithu (1983), Vineet Narain (1998), Lalita Kumari (2014), Arnesh Kumar (2014) |
| Gender / Women / Children | Mohini Jain (1992), Suchita Srivastava (2009), Independent Thought (2017), Joseph Shine (2018) |

Article references normalized corpus-wide to the canonical `Article N` format
(matching `garuda_reports` / `garuda_constitution` conventions).

## 5. Quality control (Phase 3)

`test/data/case_corpus_integrity_test.dart` asserts:
- 49 cases; no duplicate case IDs / object IDs; well-formed IDs.
- Required content: name, citation, court, bench, year, facts, decision, ratio,
  significance, typed category, judgment date.
- Every related-case reference resolves to an existing case in the corpus.
- Evidence coverage = 1.0; every evidence ID registered and resolvable.
- Official source is an `https://` URL; verification date present.
- Article refs match the canonical `Article N[(...)]` format.
- Doctrine refs match registered `garuda_doctrine` IDs.
- Body refs follow the `bod_` convention.
- JSON round-trip is lossless for every case; equality is keyed on objectId.
- No placeholder text (TBD/TODO/placeholder/lorem) in required fields.

## 6. Test & verification

- `flutter analyze` — 0 issues.
- `flutter test` — 28 tests pass (13 baseline updated + 15 integrity/domain).
- Repository-wide pytest / root Flutter suites: unaffected (this sprint touched
  only `garuda_case_law`).

## 7. Final corpus statistics

- Total landmark cases: **49** (20 Phase-I + 29 Phase-II).
- Landmark precedents: **41**; overruled/partially-superseded/other: **8**.
- Categories covered: Fundamental Rights, Basic Structure, Constitutional
  Amendments, Judicial Review, Separation of Powers, Federalism, DPSP,
  Elections, Reservation/affirmative action, Secularism, Equality/
  non-arbitrariness, Freedom of speech, Privacy, Life & personal liberty,
  Due process, Environmental jurisprudence, PIL, Administrative law,
  Centre-State relations, Emergency provisions, Tribunals, Gender justice,
  Education, Preventive detention, Criminal law safeguards, Data/privacy.
- Evidence coverage: **100%** (49/49 resolvable evidence IDs).
- Cross-package links: 49 cases × constitutional articles; doctrine links
  (Basic Structure, Proportionality, Manifest Arbitrariness, Prospective
  Overruling); precedent relationships (followed/overruled/distinguished);
  related bodies (`bod_*`), schemes, reports, current-affairs IDs, SDGs.

## 8. Next phases (TITAN-KO-015.0 P4+ — not yet implemented)

- P4 Judgment intelligence (UPSC analytics). P5 Precedent & doctrine graph.
  P6 Search engine. P7 Validation expansion. P8 Official ingestion pipeline.
  P9 Analytics engine. P10 UPSC intelligence. P11 Editorial integration.
  P12 Comprehensive tests. P13 Verification. P14 Documentation. P15 Git.
