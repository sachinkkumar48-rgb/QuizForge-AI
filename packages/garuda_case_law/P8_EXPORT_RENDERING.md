# P8 — Export & Rendering Layer

**Package:** `packages/garuda_case_law`
**Prompt:** TITAN-KO-015.0 (Phase 8 — presentation & export sprint)
**Base:** P7 `Evidence-Gated Corpus Validation` at commit `609d1e7`
**Status:** ✅ P8 implemented & verified (0 analyzer issues, 416 package tests green, 49/49/49 corpus rendering)

---

## 1. Purpose

P8 is the deterministic, offline-first presentation layer over the existing
validated P3–P7 knowledge. It renders the 49-case landmark corpus into three
machine- and human-readable formats:

| Format | Intended use |
|---|---|
| **Markdown** | readable case briefs, corpus index, statistics |
| **HTML** | safe semantic rendering for web/docs, with stable `garuda-*` hooks |
| **JSON** | canonical machine-readable export for tooling and archives |

P8 performs **no legal research**. It consumes the P3–P7 knowledge exactly as it
exists: evidence comes from the official-source registry, precedent/doctrine
edges come from the P5 `LegalGraph`, UPSC content comes from P4
intelligence. Nothing is invented, fetched, enriched or rewritten.

## 2. Where it lives

```
lib/rendering/
  render_format.dart               RenderFormat { markdown, html, json }
  evidence_entry.dart              EvidenceEntry — registry-resolved evidence presentation
  html_safety.dart                 HtmlSafety — element/attribute escaping + safeUrl
  markdown_case_renderer.dart      MarkdownCaseRenderer
  html_case_renderer.dart          HtmlCaseRenderer
  json_case_renderer.dart          JsonCaseRenderer
  corpus_index_renderer.dart       CorpusIndex / CorpusIndexEntry / CorpusIndexRenderer
  corpus_statistics_renderer.dart  CorpusStatistics / CorpusStatisticsRenderer
  case_export_service.dart         CaseExportService — orchestration facade
```

All nine files are exported from the package barrel `garuda_case_law.dart`.

## 3. Rendering API

### Single case

```dart
final c = CaseSeedData.cases.first;                 // or via CaseRepository

final md   = MarkdownCaseRenderer.render(c);         // no graph → corpus fields
final md2  = MarkdownCaseRenderer.render(c, graph: g); // P5 edges when supplied
final html = HtmlCaseRenderer.render(c, graph: g);
final json = JsonCaseRenderer.renderString(c);       // canonical toJson, pretty 2-space
```

### Corpus, index, statistics — via the facade

```dart
final service = const CaseExportService();           // resolves via InMemoryCaseRepository

final md   = await service.exportCase('KESAVANANDA', RenderFormat.markdown);
final html = await service.exportCorpus(RenderFormat.html);
final json = await service.exportCorpus(RenderFormat.json);

final index = await service.exportCorpusIndexJson();        // totalCases + entries + groupings
final stats = await service.computeCorpusStatistics();      // delegates to P4/P5 analytics
```

`CaseExportService` accepts an injected `CaseRepository`, an explicit case list,
or an injected P5 `LegalGraph`. When no graph is injected it builds the existing
deterministic `LegalGraphSeed.fromCorpora(...)` projection — it never
reconstructs or infers the graph.

## 4. Evidence preservation

`EvidenceEntry.fromId(id)` resolves an evidence ID against the existing
`CaseOfficialSources` registry. Rendered evidence therefore:

* carries the exact evidence ID recorded on the case;
* resolves a type label and URL **only** against the official registry;
* is flagged `verified` vs `registered (unresolved)` — unresolved IDs are shown
  without a URL, never silently dropped or given a made-up source;
* never fetches, rewrites or fabricates citations.

Markdown renders evidence IDs, registry URLs and verification dates as recorded.
HTML emits a URL as a link only when `HtmlSafety.safeUrl` accepts it (http(s)
only). JSON reuses the canonical `toJson()` evidence fields verbatim.

## 5. P5 graph integration

The renderers consume **existing** P5 `LegalGraph` edges (`edgesFrom` /
`edgesTo` on the case node) for doctrine and precedent relationships. They do
not reconstruct the graph, infer new relationships, or duplicate graph
algorithms. When no graph is supplied they fall back to the corpus-declared
relationship fields (`precedentsFollowed`, `precedentsOverruled`, …) — again,
rendering only what is recorded.

## 6. P4 UPSC integration

UPSC sections render only existing P4 data: case-level relevance levels
(`prelimsRelevance`, `mainsRelevance`, …), themes, and any
`judgmentIntelligence.upscIntelligence` dimensions. No LLM, no generated
Prelims/Mains/Essay/Interview claims.

## 7. Corpus support

* individual case rendering (by caseId, objectId, citation, name or alias);
* full 49-case corpus rendering in all three formats;
* corpus index (`CorpusIndex`): chronology + doctrine / article / UPSC groupings,
  all derived from existing case metadata;
* corpus statistics (`CorpusStatistics`): delegates to the existing
  `JudgmentIntelligenceAnalytics`, `LegalGraphAnalytics` and
  `CaseCorpusSupport.evidenceCoverage` — nothing is independently recalculated.

## 8. Deterministic behavior

Identical input always produces byte-identical output:

* Markdown / HTML: sorted edge lists and relationship enumeration, fixed section
  order, no timestamps, random IDs or machine paths.
* JSON: canonical map insertion order from `toJson()` and a fixed 2-space indent.
* Index / statistics: sorted entries and sorted distribution maps.

Determinism is covered by tests across every renderer.

## 9. Offline behavior

Rendering requires no network, no external API, no LLM, no evidence retrieval
and no remote database. All content originates from local validated GARUDA /
TITAN data. The only URLs ever emitted trace to the local
`CaseOfficialSources` registry (the Supreme Court of India portal).

## 10. Security

`HtmlSafety` escapes all dynamic element text and attribute values and accepts
only `http(s)` URLs as link targets. There is no JavaScript and no inline
styling in emitted HTML. `<script>`, malformed markup, attribute breakout and
`javascript:` / `data:` schemes are neutralised and covered by injection tests.

## 11. Verification

```
flutter analyze          →  No issues found!
flutter test             →  416 tests passing (330 P3–P7 + 86 P8)
Corpus rendering         →  Markdown 49/49, HTML 49/49, JSON 49/49
Determinism              →  repeated renders byte-identical
Security                 →  injection + unsafe-URL tests green
Offline                  →  registry-only URLs asserted
```

## 12. Files

* added: `lib/rendering/` (9 files), `test/rendering/` (6 test files),
  `P8_EXPORT_RENDERING.md`.
* modified: `lib/garuda_case_law.dart` (P8 barrel exports).
* no Python, no Jinja2, no template engine, no new runtime; no changes to P3–P7.
