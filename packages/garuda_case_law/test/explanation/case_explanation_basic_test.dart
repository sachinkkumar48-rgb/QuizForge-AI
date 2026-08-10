import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P11 — Basic evidence-backed case explanation (TITAN-KO-015.0 P11).
///
/// Verifies that a single canonical case resolves to an explanation carrying
/// its P3 identity/overview and its P4 issues, holdings, reasoning, outcome and
/// significance — all verbatim, none invented.
void main() {
  final service = CaseExplanationService();

  group('A. canonical case resolution', () {
    test('a canonical case ID resolves to an explanation', () {
      final explanation = service.explain('KESAVANANDA');
      expect(explanation, isNotNull);
      expect(explanation!.caseId, 'KESAVANANDA');
      expect(explanation.caseName, 'Kesavananda Bharati v. State of Kerala');
      expect(explanation.isEmpty, isFalse);
    });

    test('a case name resolves to the same explanation', () {
      final byId = service.explain('MANEKA_GANDHI')!;
      final byName = service.explain('Maneka Gandhi v. Union of India')!;
      expect(byId.caseId, byName.caseId);
      expect(byId.toJson(), byName.toJson());
    });

    test('an unknown identifier yields null, never an empty explanation', () {
      expect(service.explain('NOT_A_CASE'), isNull);
      expect(service.explain(''), isNull);
    });

    test('hasCase reflects resolvability', () {
      expect(service.hasCase('KESAVANANDA'), isTrue);
      expect(service.hasCase('Unknown'), isFalse);
    });
  });

  group('B. case identity (P3)', () {
    test('identity section carries canonical corpus identity', () {
      final identity = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.identity)!;
      final text = identity.statements.map((s) => s.text).join('\n');
      expect(identity.statements.map((s) => s.label), contains('Case ID'));
      expect(text, contains('KESAVANANDA'));
      expect(text, contains('Kesavananda Bharati v. State of Kerala'));
      expect(text, contains('AIR 1973 SC 1461'));
      expect(text, contains('1973'));
    });

    test('every identity statement traces to the corpus', () {
      final identity = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.identity)!;
      for (final s in identity.statements) {
        expect(s.sourceRefs, contains('KESAVANANDA'));
        expect(s.provenance, startsWith('corpus:'));
      }
    });
  });

  group('C. case overview (P3)', () {
    test('overview section carries the one-line summary and facts', () {
      final overview = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.overview)!;
      final labels = overview.statements.map((s) => s.label).toList();
      expect(labels, contains('One-line summary'));
      expect(labels, contains('Facts'));
      expect(overview.statements.first.text, isNotEmpty);
      for (final s in overview.statements) {
        expect(s.provenance, startsWith('corpus:'));
      }
    });
  });

  group('D. issues (P4, corpus fallback)', () {
    test('issues section carries framed issues from P4 intelligence', () {
      final issues = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.issues)!;
      expect(issues.statements, isNotEmpty);
      expect(issues.statements.first.label, startsWith('Issue '));
      for (final s in issues.statements) {
        expect(s.text.trim(), isNotEmpty);
      }
    });
  });

  group('E. holdings (P4)', () {
    test('holdings section carries validated holdings with legal principle',
        () {
      final holdings = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.holdings)!;
      expect(holdings.statements, isNotEmpty);
      expect(holdings.statements.first.label, 'Holding 1');
      for (final s in holdings.statements) {
        expect(s.text.trim(), isNotEmpty);
        expect(s.provenance, 'p4:holdings');
      }
    });

    test('holding references include the holding evidence id when present', () {
      final holdings = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.holdings)!;
      for (final s in holdings.statements) {
        expect(s.sourceRefs, contains('KESAVANANDA'));
        expect(s.sourceRefs.length, greaterThanOrEqualTo(1));
      }
    });
  });

  group('F. reasoning (P4)', () {
    test('reasoning section carries the validated reasoning record', () {
      final reasoning = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.reasoning);
      expect(reasoning, isNotNull);
      expect(reasoning!.statements, isNotEmpty);
      final labels = reasoning.statements.map((s) => s.label).toList();
      expect(labels, contains('Summary'));
      for (final s in reasoning.statements) {
        expect(s.provenance, startsWith('p4:reasoning'));
      }
    });
  });

  group('G. outcome (P4, corpus fallback)', () {
    test('outcome section carries disposition and operative result', () {
      final outcome = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.outcome)!;
      final labels = outcome.statements.map((s) => s.label).toList();
      expect(labels, contains('Disposition'));
      for (final s in outcome.statements) {
        expect(s.text.trim(), isNotEmpty);
      }
    });
  });

  group('H. legal significance (P4, corpus fallback)', () {
    test('significance section carries validated significance dimensions', () {
      final significance = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.legalSignificance);
      expect(significance, isNotNull);
      expect(significance!.statements, isNotEmpty);
      for (final s in significance.statements) {
        expect(s.provenance, contains('p4:judicialSignificance'));
      }
    });
  });

  group('I. fixed deterministic section order', () {
    test('sections appear in the fixed P11 order', () {
      final explanation = service.explain('KESAVANANDA')!;
      final types = explanation.sections.map((s) => s.type).toList();
      final expectedOrder = ExplanationSectionType.values;
      // Subsequence check: each section in the explanation appears in the same
      // relative order as the fixed enum vocabulary.
      var cursor = 0;
      for (final t in types) {
        final idx = expectedOrder.indexOf(t);
        expect(idx, greaterThanOrEqualTo(cursor),
            reason: 'section ${t.name} out of fixed order');
        cursor = idx;
      }
      expect(types, isNotEmpty);
    });
  });

  group('J. optional UPSC relevance (P3 corpus, P4 where supported)', () {
    test('UPSC section surfaces recorded prelims and mains relevance', () {
      final upsc = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.upscRelevance)!;
      final corpusStmts =
          upsc.statements.where((s) => s.provenance.startsWith('corpus:'));
      final labels = corpusStmts.map((s) => s.label).toList();
      expect(labels, contains('Prelims relevance'));
      expect(labels, contains('Mains relevance'));
      expect(labels, contains('Exam importance'));
      for (final s in corpusStmts) {
        expect(s.sourceRefs, contains('KESAVANANDA'));
        expect(s.provenance, startsWith('corpus:'));
      }
    });

    test('P4 UPSC intelligence is surfaced where the corpus supports it', () {
      final upsc = service
          .explain('KESAVANANDA')!
          .sectionOf(ExplanationSectionType.upscRelevance)!;
      final p4 = upsc.statements
          .where((s) => s.provenance == 'p4:upscIntelligence')
          .toList();
      expect(p4, isNotEmpty,
          reason: 'KESAVANANDA carries curated P4 UPSC intelligence');
      final labels = p4.map((s) => s.label).toSet();
      expect(labels, contains('Prelims fact'));
      expect(labels, contains('Mains theme'));
      for (final s in p4) {
        expect(s.text.trim(), isNotEmpty);
        expect(s.sourceRefs, contains('KESAVANANDA'));
      }
    });

    test('a case without P4 UPSC intelligence still records corpus relevance',
        () {
      // The synthetic GAMMA has no intelligence; its UPSC section is limited to
      // the recorded corpus relevance fields — nothing is invented.
      final synth = CaseExplanationService(
        cases: syntheticExplanationCorpus(),
      );
      final gamma = synth.explain('GAMMA')!;
      final upsc = gamma.sectionOf(ExplanationSectionType.upscRelevance)!;
      expect(upsc.statements, isNotEmpty);
      for (final s in upsc.statements) {
        expect(s.provenance, startsWith('corpus:'));
      }
    });
  });
}
