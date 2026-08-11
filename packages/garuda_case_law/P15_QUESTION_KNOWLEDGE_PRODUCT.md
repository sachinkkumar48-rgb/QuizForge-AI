# P15 — Evidence-Backed Question-Answer Knowledge Products

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 15 of GARUDA Landmark Case Law)
**Base:** P14 `Topic Knowledge Products` at commit `91636df`
**Status:** ✅ P15 implemented & verified

---

## 1. Purpose

P15 is a **deterministic, offline-first, active-learning knowledge-product
layer** over the already-validated P4/P11–P14 GARUDA Case Law knowledge. It
answers:

> For one validated source (a case and its P4 intelligence, or a P12/P13/P14
> knowledge product), what evidence-backed educational questions can be posed —
> and what evidence-backed answers can be given — strictly from what the
> existing validated records already say?

P15 produces a single immutable **`QuestionKnowledgeProduct`** per validated
source: a deterministic collection of **`LegalQuestion`s**, each carrying a
stable ID, deterministic wording, a **`StructuredAnswer`** composed only from
validated P4/P11–P14 information, non-empty provenance and non-empty evidence
references, and an explicit educational framing.

P15 is **not** a quiz engine, **not** an AI question generator, **not** an
interactive user interface and **not** an assessment/grading system. It never
invents a question from general knowledge, never performs legal research and
never gives legal advice. A question is derived from an explicit validated
source; missing source information produces an **omitted** question, never a
fabricated one.

## 2. Where it lives

```
lib/question_product/
├── domain/
│   ├── question_product_enums.dart       # QuestionSourceType, LegalQuestionType
│   ├── structured_answer.dart            # StructuredAnswer
│   ├── legal_question.dart               # LegalQuestion
│   └── question_knowledge_product.dart   # QuestionKnowledgeProduct
└── service/question_knowledge_product_service.dart
test/question_product/
├── synthetic_corpus.dart                 # test-only synthetic corpus/doctrines/config
├── question_product_domain_model_test.dart
├── question_product_generation_test.dart
├── question_product_answer_composition_test.dart
├── question_product_legal_safety_test.dart
├── question_product_missing_data_test.dart
├── question_product_determinism_offline_test.dart
├── question_product_resolution_test.dart
└── question_product_corpus_test.dart     # corpus-wide verification
```

All public types are exported through `lib/garuda_case_law.dart`.

## 3. Architecture

P15 is an **additive composition layer**. It introduces no new legal algorithm,
no second explanation engine, no duplicate repository, evidence registry, search
engine, graph service or rendering framework. It re-presents existing validated
products deterministically:

```
P4 validated judgment intelligence (issues, holdings)
P11 CaseExplanation · P12 DoctrineKnowledgeProduct · P13 StatuteKnowledgeProduct
P14 TopicKnowledgeProduct · P5 related-case edges
        │
        ▼
QuestionKnowledgeProductService  (compose → QuestionKnowledgeProduct)
```

- **P4** — `JudgmentIntelligence.issues` drives **issue-based** questions and
  `JudgmentHolding.legalPrinciple` (only where non-empty) drives
  **principle-based** questions. Issue/holding texts are surfaced verbatim.
- **P5** — related cases on case products come ONLY from explicit
  `related` edges (`PrecedentGraphService.relatedCases`). They are never
  labelled "similar" and never inferred from topic membership, chronology or
  apparent relevance.
- **P11** — never re-implemented; the P12/P13/P14 products already embed one
  `CaseExplanation` per case, which P15 re-presents through its source products.
- **P12** — `DoctrineKnowledgeProductService.build` + `doctrineMemberIds` drive
  **doctrine-based** questions (recorded overview, recorded constituent cases).
- **P13** — `StatuteKnowledgeProductService.build` + `provisionRefMap` drive
  **statute-based** questions (provision kind, recorded overview, referenced
  cases).
- **P14** — `TopicKnowledgeProductService.build` drives **topic-based**
  questions (editorial overview, member cases, syllabus area).

The service is **offline-first**: the default constructor builds over the
canonical offline corpus and services, synchronously, with no network and no
LLM.

## 4. Domain model

- **`QuestionSourceType`** — the kind of validated source a product is built
  over: `caseLaw`, `doctrine`, `statute` or `topic`.
- **`LegalQuestionType`** — the kind of a question: `issue`, `principle`,
  `doctrine`, `statute` or `topic`.
- **`StructuredAnswer`** — immutable answer with verbatim `answerText`,
  non-empty `evidenceRefs`, `relatedCaseIds` (P5-only, never "similar"),
  `principles` (relevant context only when the source explicitly provides it)
  and non-empty `provenance`.
- **`LegalQuestion`** — immutable question with a stable deterministic
  `questionId`, deterministic `questionText`, `questionType`, non-empty
  `sourceRefs`, a `StructuredAnswer`, non-empty `provenance` and an explicit
  educational `framing`.
- **`QuestionKnowledgeProduct`** — immutable collection of `LegalQuestion`s for
  one source, with `productId`, `sourceType`, `sourceId`, `sourceName`, the
  `questions` list, a `referencedIds` aggregation and serialization.

All models are value objects with value `==` / `hashCode` consistent with
P11–P14.

## 5. Question types & deterministic generation

Every question is produced from explicit source information via a fixed
deterministic transformation. No LLM, randomization, embedding or hypothetical
scenario is involved, and no additional legal proposition is introduced to make
wording natural.

| Type | Source | Deterministic question wording |
|------|--------|-------------------------------|
| Issue | P4 `JudgmentIssue` | `In <case> (<year>), what legal issue did the Court consider?` |
| Principle | P4 `JudgmentHolding.legalPrinciple` (non-empty) | `In <case> (<year>), what legal principle did the Court state?` |
| Doctrine | P12 product overview / constituent cases | `What is the doctrine <name>?` · `Which cases are recorded as constituent cases of the doctrine <name>?` |
| Statute | P13 product identity / overview / associated cases | `What kind of provision is <provision>?` · `What is <provision>?` · `Which validated corpus cases reference <provision>?` |
| Topic | P14 product overview / member cases / syllabus area | `What is the topic <name> about?` · `Which cases are members of the topic <name>?` · `What syllabus area does the topic <name> fall under?` |

When multiple questions share a base wording for one source (e.g. several
issues), a deterministic ordinal disambiguator (`(1 of N)`, `(2 of N)`) is
appended only when N > 1. Question IDs are stable (`qa:case:ALPHA:issue:0`,
`qa:doctrine:SYNTH_DOCTRINE:definition`, …). A source element that lacks the
supporting data is omitted.

## 6. Source / evidence model

Each question carries `sourceRefs` (the canonical identifiers that establish
the question — e.g. a case ID + issue ID) and each answer carries
`evidenceRefs` (the canonical identifiers that establish the answer — e.g. a
case ID + holding ID + evidence ID). Only identifiers that resolve to a
validated corpus case are ever reported as case IDs
(`referencedCaseIds` / `otherCaseIds` filter raw identifiers against the
corpus), so no invalid case ID is ever fabricated.

## 7. Provenance

Every question and every answer carries a non-empty `provenance` string naming
the validated field it traces to, e.g.:

- `p4:issues`, `p4:holdings.legalPrinciple`
- `p12:DoctrineKnowledgeProduct.overview`, `p5:caseDoctrineEdges; p10:doctrineAnalysis`
- `p13:StatuteKnowledgeProduct.identity`, `p13:StatuteKnowledgeProduct.associatedCases`
- `p14:syllabusConfig.overview`, `p14:membership`, `p4:syllabusAreas`

There is no parallel evidence registry: P15 reuses the provenance that P4/P11–P14
already attach to their validated data.

## 8. Deterministic generation

P15 is fully deterministic. The same source and the same repository state
produce byte-identical serialized output:

- question IDs and wording are derived deterministically;
- ordering is explicit (issues-then-principles per case; canonical source order
  for doctrines/statutes/topics; `buildAll` iterates cases → doctrines →
  provisions → topics);
- no current/generated-at timestamps, random UUIDs, machine paths or
  environment-dependent values;
- referenced IDs are sorted and de-duplicated.

## 9. Offline behavior

P15 operates completely offline. All information originates from the existing
local validated GARUDA corpora and services; there is no HTTP, API, LLM, cloud
service, external database, network dependency, embedding or runtime remote
retrieval. The default constructor is synchronous and offline-first.

## 10. Legal-safety boundaries

P15 is an educational knowledge product, not legal advice. All content is
framed as historical/educational case-law information (`framing` on every
question). P15 never:

- provides legal advice or applies law to the user's circumstances;
- asserts unsupported present-tense statements such as "the law is ...";
- generates hypothetical legal scenarios;
- fabricates facts, citations or precedent relationships;
- infers topic→legal-similarity, chronology→causation, doctrinal evolution or
  current-law validity from the historical corpus;
- labels a related case "similar" (P5 relationship semantics are preserved
  verbatim);
- introduces legal propositions merely to make wording natural.

## 11. Missing-data behavior

Missing or incomplete source information is represented by an **omitted
question**, never by fabrication:

- a case with no P4 intelligence yields no product (`buildForCase` → null);
- a holding with an empty `legalPrinciple` yields no principle question;
- a doctrine with no resolvable constituent cases yields only its definition
  question;
- a provision with no recorded overview yields kind + associated-cases but no
  definition question;
- a topic whose member lacks intelligence still lists that member (membership
  is explicit, not gated on the member's own question eligibility).

## 12. Explicit exclusions

P15 is deliberately not a quiz engine and excludes: interactive quiz UI,
multiple choice, answer grading, scoring, user progress, adaptive difficulty,
spaced repetition, gamification, hints, question randomization, user-generated
questions, collaborative features, personalization, question search,
question recommendation, analytics and learning dashboards. These belong to
later phases. P15 introduces no persistence, no question bank and no user state.

## 13. API usage

```dart
final svc = QuestionKnowledgeProductService();

// Per-source products (null when the source does not resolve or yields nothing).
final caseProduct  = svc.buildForCase('KESAVANANDA');            // issue + principle
final doctrineProd = svc.buildForDoctrine('BASIC_STRUCTURE');    // doctrine
final statuteProd  = svc.buildForStatute(ProvisionType.article, 'Article 21'); // statute
final topicProd    = svc.buildForTopic('amending_power_and_basic_structure'); // topic

// Resolution.
svc.hasCase('KESAVANANDA');
svc.hasDoctrine('BASIC_STRUCTURE');
svc.hasProvision(ProvisionType.article, 'Article 21');
svc.hasTopic('amending_power_and_basic_structure');

// Corpus-wide.
final all = svc.buildAll();                 // cases → doctrines → provisions → topics

// Referenced case IDs (never fabricated).
svc.referencedCaseIds(caseProduct);         // corpus case IDs referenced
svc.otherCaseIds(caseProduct);              // excluding the source case itself
```

## 14. Limitations

- P15 poses only questions that a validated source can safely support; it does
  not attempt to cover every conceivable legal topic.
- Answers never extend beyond the recorded validated content: they do not state
  what the law currently is, do not apply law to a person's situation and do not
  infer doctrinal evolution or causation from chronology.
- Related cases are reported only where explicit P5 `related` edges exist; the
  relationship is never amplified into legal similarity.
- Difficulty metadata is deliberately omitted; P15 does not attempt to measure
  learner difficulty.
