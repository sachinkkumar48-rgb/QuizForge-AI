# P7 — Evidence-Gated Corpus-Level Validation

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 7 — validation & integrity sprint)
**Base:** P6 `Case Law Search Engine` at commit `e85a18b`
**Status:** ✅ P7 implemented & verified (0 analyzer issues, all package + repo tests green)

---

## 1. Why `CorpusValidator` exists

Per-record validation already existed (P3 `CaseValidator`, P4
`JudgmentIntelligenceValidator`, P5 `LegalGraphValidator`). P7 adds the one
capability they could not express: **corpus-level and cross-package integrity**.
`CorpusValidator` is an orchestration layer — it does not replace or weaken any
existing validator, and it never alters corpus content to pass.

## 2. What it reuses

| Component | Where |
|---|---|
| `CaseValidator` | `validators/case_validator.dart` — per-record identity, citations, metadata, evidence presence for approved records |
| `JudgmentIntelligenceValidator` | `intelligence/validation/` — evidence-gated intelligence structure |
| `LegalGraphValidator` | `graph/validation/` — edge/node structural integrity |
| `LegalGraphSeed.fromCorpora` | the deterministic corpus→graph projection oracle |
| `CaseOfficialSources` | the official evidence registry |
| `CaseSearchNormalizer` | P6 article-variant normalization |
| `ConstitutionSeedData` | `garuda_constitution` (133 seeded articles) |
| `DoctrineSeedData` | `garuda_doctrine` (canonical doctrine records) |
| `Phase1ActsCorpus` | `garuda_acts` (new dependency) |
| `DoctrineCaseNameResolver` | doctrine-record case reference resolution |

## 3. What it validates

```
validation/
  corpus_validation_models.dart   CorpusValidationSeverity / Category,
                                  CorpusValidationIssue, CorpusValidationResult,
                                  CorpusValidationReport (machine-readable JSON)
  corpus_validator.dart           CorpusValidator
```

- **A. Corpus identity** — duplicate case IDs / objectIds (ERROR), duplicate
  canonical case names (WARNING), alias collisions (WARNING).
- **B. Evidence resolution** — every case evidence ID resolves via
  `CaseOfficialSources`; official source present; every Judgment Intelligence
  evidence ID is a subset of the case's evidence IDs and resolves.
- **C. Constitutional references** — format (ERROR), constitutional range
  1–395 (ERROR), existence against the seeded constitution corpus (INFO when
  outside the seed's partial coverage). Clause forms (`Article 19(1)(a)`) are
  resolved to their base article (`19`).
- **D. Act references** — format (ERROR), existence against `garuda_acts`
  Phase-I corpus (INFO when outside partial coverage); section references
  checked for a section number.
- **E. Doctrine references** — every case `doctrines` ID resolves in
  `garuda_doctrine`; case↔doctrine role consistency via `doctrineRecordRoles`.
- **F. Precedent relationships** — missing targets (ERROR), self-references
  (ERROR), duplicates (ERROR), contradictions (follow+distinguish, mutual
  overrule) (ERROR), temporal paradox (a case cannot overrule a later case)
  (ERROR).
- **G. Graph ↔ corpus consistency** — the graph under validation is compared
  against the deterministic corpus projection: fabricated edges (ERROR),
  missing edges (ERROR), doctrine-role mismatches (ERROR), intentionally
  isolated cases (INFO); the existing `LegalGraphValidator` is also run.
- **H. Serialization** — per-case `toJson → fromJson` losslessness via deep
  comparison, including Judgment Intelligence and precedent relationships.

The report exposes `total/valid/invalid cases`, error/warning/info counts, the
issue list, evidence coverage, broken-reference count, graph-consistency and
serialization results, and an overall pass/fail.

## 4. What it deliberately does NOT validate

- **Legal scholarship** — it never judges whether a relationship is historically
  or legally correct; only structural/temporal/data integrity.
- **Out-of-corpus doctrine-record references** — doctrine records legitimately
  cite landmark cases outside the 49-case corpus; those are a scope boundary and
  are not flagged.
- **Real existence of every act** — the `garuda_acts` Phase-I corpus covers
  modern criminal/commercial codes; the case-law corpus references case-law-era
  statutes mostly outside that coverage. Such references surface as INFO, never
  as invented errors.
- **Real existence of every article** — the constitution seed covers 133 of the
  395 articles; valid in-range references outside the seed surface as INFO.
- **A second evidence database** — evidence resolution reuses the existing
  registry only.
- **Rebuilding the graph, corpus, or search engine** — it reads the graph and
  corpus; it never mutates them.

## 5. Cross-package resolution boundaries

- `garuda_constitution` / `garuda_doctrine` were already package dependencies;
  `garuda_acts` is the only new dependency (internal monorepo path dependency,
  required for P7's cross-package Act mandate).
- Resolution is **seed-based and offline**: no HTTP, no live sources.
- A reference that is well-formed and in range but absent from a partial seed is
  reported as INFO so the boundary is visible and auditable, while the corpus
  still passes validation (INFO/WARNING never fail the run).

## 6. Offline-first behavior

`CorpusValidator().validate()` is fully synchronous behind the awaited
repository hand-off: it derives the canonical graph, resolves every reference
against in-repo seeds, and runs deep serialization checks — all in memory, with
zero network access and zero external services. Determinism is a tested
property: two runs over the same corpus produce byte-identical issue lists.

## 7. Test coverage

34 new P7 tests in `test/validation/corpus_validator_test.dart` covering the
required 20 scenarios (real corpus passes 49/49; duplicate case ID / name /
alias; broken evidence / intelligence evidence; subset violations; broken
article / act / doctrine; missing precedent target, contradiction, temporal
paradox; fabricated / missing graph edges; doctrine-role mismatch; serialization
losslessness; determinism; and the full-suite regression).
