import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

/// P8 — Markdown case rendering (TITAN-KO-015.0 P8).
///
/// Covers: complete case structure, optional/missing fields, empty
/// collections, evidence, P5 graph relationships, UPSC intelligence,
/// Unicode/Devanagari pass-through, special characters, and deterministic
/// output. Rendering must never fabricate content — absent fields are simply
/// omitted.
void main() {
  final corpus = CaseSeedData.cases;
  final kesavananda = corpus.firstWhere((c) => c.caseId == 'KESAVANANDA');

  LegalGraph graph() => LegalGraphSeed.fromCorpora(
        cases: corpus,
        doctrines: DoctrineSeedData.doctrines,
      ).build();

  CaseKnowledgeObject minimalCase() => CaseKnowledgeObject(
        objectId: 'KO-CASE-MIN',
        caseId: 'MIN',
        caseName: 'Minimal Case v. Union of India',
        citation: 'AIR 2025 SC MIN',
        year: 2025,
        bench: 'Bench',
        historicalContext: '',
        facts: '',
        decision: '',
        constitutionalSignificance: '',
        judgmentDate: DateTime(2025, 1, 1),
        garudaExplanation: '',
        oneLineSummary: '',
        detailedSummary: '',
        // Clear the non-empty constructor defaults so the case carries no
        // evidence metadata and no UPSC-relevance metadata at all.
        primarySource: '',
        examImportance: '',
        trend: '',
        prelimsRelevance: RelevanceLevel.notApplicable,
        mainsRelevance: RelevanceLevel.notApplicable,
        essayRelevance: RelevanceLevel.notApplicable,
        interviewRelevance: RelevanceLevel.notApplicable,
      );

  group('1. complete case', () {
    test('renders identity, legal content, judgment and evidence', () {
      final md = MarkdownCaseRenderer.render(kesavananda);
      expect(md, startsWith('# Kesavananda Bharati v. State of Kerala'));
      expect(md, contains('## Case Identity'));
      expect(md, contains('## Legal Content'));
      expect(md, contains('## Judgment'));
      expect(md, contains('**Case ID:** `KESAVANANDA`'));
      expect(md, contains('**Object ID:** `KO-CASE-KESAVANANDA`'));
      expect(md, contains('**Year:** 1973'));
      expect(md, contains('**Neutral citation:** (1973) 4 SCC 225'));
      expect(md, contains('## Evidence'));
    });

    test('renders facts, ratio and holding text', () {
      final md = MarkdownCaseRenderer.render(kesavananda);
      expect(md, contains('### Facts'));
      expect(md, contains('### Ratio Decidendi'));
      expect(md, contains('### Holding'));
      // Blockquotes carry the legal text.
      expect(md, contains('> '));
    });

    test('renders a citation line when neutral + reporter citations exist', () {
      final md = MarkdownCaseRenderer.render(kesavananda);
      expect(md, contains('*(1973) 4 SCC 225 | AIR 1973 SC 1461*'));
    });
  });

  group('2. optional / missing fields', () {
    test('minimal case renders identity only, omitting absent sections', () {
      final md = MarkdownCaseRenderer.render(minimalCase());
      expect(md, startsWith('# Minimal Case v. Union of India'));
      expect(md, contains('## Case Identity'));
      // No data present → no fabricated sections.
      expect(md, isNot(contains('## Evidence')));
      expect(md, isNot(contains('## UPSC Intelligence')));
      expect(md, isNot(contains('## Doctrines')));
      expect(md, isNot(contains('## Timeline')));
      expect(md, isNot(contains('## Precedent Relationships')));
      expect(md, isNot(contains('## Knowledge & Editorial')));
      expect(md, isNot(contains('## Judicial Significance')));
    });

    test('absent neutral citation is omitted, not invented', () {
      final c = kesavananda.copyWith(neutralCitation: '');
      final md = MarkdownCaseRenderer.render(c);
      expect(md, isNot(contains('| AIR 1973 SC 1461)*')));
      expect(md, contains('*AIR 1973 SC 1461*'));
    });
  });

  group('3. empty collections', () {
    test('empty list fields render no headings', () {
      final c = minimalCase().copyWith(
        issues: const [],
        relatedArticles: const [],
        doctrines: const [],
        evidenceIds: const [],
      );
      final md = MarkdownCaseRenderer.render(c);
      expect(md, isNot(contains('### Issues')));
      expect(md, isNot(contains('### Constitutional articles')));
    });

    test('no precedent edges and no corpus fields → no section', () {
      final c = minimalCase().copyWith(
        precedentsFollowed: const [],
        precedentRelationships: const [],
      );
      final md = MarkdownCaseRenderer.render(c, graph: graph());
      // MIN is not a graph node, so no edges exist for it.
      expect(md, isNot(contains('## Precedent Relationships')));
    });
  });

  group('4. evidence', () {
    test('registered evidence is presented with ID and status', () {
      final md = MarkdownCaseRenderer.render(kesavananda);
      expect(md, contains('`ev_KESAVANANDA_official`'));
      expect(md, contains('Official court record'));
      expect(md, contains('verified'));
      expect(md, contains('https://main.sci.gov.in/judgments'));
    });

    test('unresolved evidence is flagged and never given a URL', () {
      final c = kesavananda.copyWith(evidenceIds: const ['bogus_evidence']);
      final md = MarkdownCaseRenderer.render(c);
      expect(md, contains('`bogus_evidence`'));
      expect(md, contains('registered (unresolved)'));
      // The unresolved ID must not carry a source URL.
      expect(
        md,
        isNot(contains('`bogus_evidence` — registered (unresolved) — <')),
      );
    });

    test('evidence references / citations are preserved verbatim', () {
      final c = kesavananda.copyWith(
        citations: const ['(1973) 4 SCC 225', 'AIR 1973 SC 1461'],
        evidenceReferences: const ['Journal of Constitutional Studies, Vol. 4'],
        lastVerifiedDate: '2026-08-08',
      );
      final md = MarkdownCaseRenderer.render(c);
      expect(md, contains('(1973) 4 SCC 225'));
      expect(md, contains('Journal of Constitutional Studies, Vol. 4'));
      expect(md, contains('Last verified'));
      expect(md, contains('2026-08-08'));
    });
  });

  group('5. graph relationships (P5)', () {
    test('renders doctrine edges from the P5 graph', () {
      final md = MarkdownCaseRenderer.render(kesavananda, graph: graph());
      expect(md, contains('## Doctrines'));
      expect(md, contains('BASIC_STRUCTURE'));
    });

    test('renders outgoing and incoming precedent edges', () {
      final md = MarkdownCaseRenderer.render(kesavananda, graph: graph());
      expect(md, contains('## Precedent Relationships'));
      expect(md, contains('Precedents (outgoing)'));
      expect(md, contains('Cited by (incoming)'));
      // KESAVANANDA overrules GOLAKNATH (outgoing); MINERVA_MILLS follows it
      // (incoming).
      expect(md, contains('GOLAKNATH'));
      expect(md, contains('MINERVA_MILLS'));
      expect(md, contains('overruled'));
    });

    test('falls back to corpus-declared relationships without a graph', () {
      final md = MarkdownCaseRenderer.render(kesavananda);
      expect(md, contains('## Precedent Relationships'));
      expect(md, contains('Overruled'));
      expect(md, contains('GOLAKNATH'));
    });
  });

  group('6. UPSC intelligence (P4)', () {
    test('renders existing UPSC relevance and themes', () {
      final md = MarkdownCaseRenderer.render(kesavananda);
      expect(md, contains('## UPSC Intelligence'));
      expect(md, contains('**Prelims relevance:** critical'));
      expect(md, contains('**Mains relevance:** critical'));
      expect(md, contains('Themes'));
      expect(md, contains('Basic Structure'));
    });

    test('renders judgment-intelligence UPSC dimensions when present', () {
      final md = MarkdownCaseRenderer.render(kesavananda);
      final u = kesavananda.judgmentIntelligence!.upscIntelligence;
      if (u != null && u.mainsArguments.isNotEmpty) {
        expect(md, contains('Mains arguments'));
      }
    });
  });

  group('7. Unicode / Devanagari', () {
    test('Devanagari passes through unescaped', () {
      final c = kesavananda.copyWith(
        facts: 'मूल संरचना सिद्धांत (basic structure doctrine) का प्रतिपादन।',
      );
      final md = MarkdownCaseRenderer.render(c);
      expect(md, contains('मूल संरचना सिद्धांत'));
    });

    test('em-dashes and accented text pass through', () {
      final c = kesavananda.copyWith(
        decision: 'Résumé of the holding — settled à la H.R. Khanna.',
      );
      final md = MarkdownCaseRenderer.render(c);
      expect(md, contains('Résumé of the holding — settled à la'));
    });
  });

  group('8. special characters / markdown structure', () {
    test('leading heading token in content cannot hijack structure', () {
      final c = minimalCase().copyWith(
        facts: '# Fake Heading\nsecond line',
        oneLineSummary: '## Another Fake Heading',
      );
      final md = MarkdownCaseRenderer.render(c);
      // The rendered body must not contain a raw top-level heading derived
      // from case content.
      expect(md, contains(r'\# Fake Heading'));
      expect(md, contains(r'\## Another Fake Heading'));
    });

    test('leading list / blockquote tokens are neutralised', () {
      final c = minimalCase().copyWith(
        facts: '- item\n1. ordered',
        decision: '> quoted',
      );
      final md = MarkdownCaseRenderer.render(c);
      expect(md, contains(r'\- item'));
      // The renderer breaks an ordered-list start by escaping its first char.
      expect(md, contains(r'\1. ordered'));
      expect(md, contains(r'\> quoted'));
    });
  });

  group('9. determinism', () {
    test('identical input renders identical markdown', () {
      final g = graph();
      final a = MarkdownCaseRenderer.render(kesavananda, graph: g);
      final b = MarkdownCaseRenderer.render(kesavananda, graph: g);
      expect(a, b);
    });

    test('full corpus markdown is byte-identical across renders', () {
      final g = graph();
      final a =
          corpus.map((c) => MarkdownCaseRenderer.render(c, graph: g)).join();
      final b =
          corpus.map((c) => MarkdownCaseRenderer.render(c, graph: g)).join();
      expect(a, b);
    });
  });
}
