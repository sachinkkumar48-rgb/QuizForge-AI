import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P11 — Missing-data and sparse-case behavior (TITAN-KO-015.0 P11).
///
/// Missing data is represented by an *absent* section, never by fabricated
/// content. These tests exercise the sparse/disconnected `GAMMA`, a case with
/// no outgoing relationships (`DELTA`), a case with no own edges (`BETA`) and
/// absent contextual intelligence — and verify the explanation fails
/// gracefully, invents nothing and never claims a relationship that is not
/// recorded.
void main() {
  final service = CaseExplanationService(
    cases: syntheticExplanationCorpus(),
  );

  group('A. sparse and disconnected case (GAMMA)', () {
    test('GAMMA resolves to an explanation with canonical identity', () {
      final explanation = service.explain('GAMMA')!;
      expect(explanation.caseId, 'GAMMA');
      expect(explanation.caseName, 'Gamma v. Nobody');
      expect(
        explanation.sectionOf(ExplanationSectionType.identity),
        isNotNull,
      );
    });

    test('content sections are omitted, never fabricated', () {
      final explanation = service.explain('GAMMA')!;
      const absent = {
        ExplanationSectionType.overview,
        ExplanationSectionType.issues,
        ExplanationSectionType.holdings,
        ExplanationSectionType.reasoning,
        ExplanationSectionType.outcome,
        ExplanationSectionType.legalSignificance,
        ExplanationSectionType.doctrines,
        ExplanationSectionType.articles,
        ExplanationSectionType.acts,
        ExplanationSectionType.relatedCases,
        ExplanationSectionType.precedentContext,
        ExplanationSectionType.crossCaseContext,
      };
      for (final type in absent) {
        expect(explanation.hasSection(type), isFalse,
            reason: 'sparse GAMMA must not emit a ${type.name} section');
        expect(explanation.sectionOf(type), isNull,
            reason: 'sparse GAMMA must not fabricate a ${type.name} section');
      }
    });

    test('GAMMA references no other case — nothing is invented', () {
      final explanation = service.explain('GAMMA')!;
      expect(service.referencedCaseIds(explanation), ['GAMMA']);
      expect(service.otherCaseIds(explanation), isEmpty);
    });

    test('every present statement is traceable to the corpus record', () {
      final explanation = service.explain('GAMMA')!;
      expect(explanation.sections, isNotEmpty);
      for (final section in explanation.sections) {
        for (final s in section.statements) {
          expect(s.provenance, startsWith('corpus:'),
              reason: '${section.type.name} provenance ${s.provenance}');
          expect(s.sourceRefs, contains('GAMMA'));
        }
      }
    });
  });

  group('B. missing optional intelligence', () {
    test('a case without P4 intelligence emits no holdings/issues/outcome', () {
      final explanation = service.explain('GAMMA')!;
      expect(explanation.hasSection(ExplanationSectionType.holdings), isFalse);
      expect(explanation.hasSection(ExplanationSectionType.issues), isFalse);
      expect(explanation.hasSection(ExplanationSectionType.outcome), isFalse);
      expect(explanation.hasSection(ExplanationSectionType.reasoning), isFalse);
      expect(explanation.hasSection(ExplanationSectionType.legalSignificance),
          isFalse);
    });

    test('a case without doctrine/Act context omits those sections', () {
      // DELTA has intelligence + an Article but no doctrine and no Act.
      final explanation = service.explain('DELTA')!;
      expect(explanation.hasSection(ExplanationSectionType.doctrines), isFalse,
          reason: 'DELTA has no case → doctrine edge');
      expect(explanation.hasSection(ExplanationSectionType.acts), isFalse,
          reason: 'DELTA records no Act');
      expect(explanation.hasSection(ExplanationSectionType.articles), isTrue,
          reason: 'DELTA records Article 21');
    });
  });

  group('C. cases without outgoing relationships', () {
    test('DELTA emits only recorded incoming precedent edges, never outgoing',
        () {
      final explanation = service.explain('DELTA')!;
      final precedent =
          explanation.sectionOf(ExplanationSectionType.precedentContext)!;
      expect(precedent.statements, isNotEmpty,
          reason: 'ALPHA overruled DELTA is recorded');
      for (final s in precedent.statements) {
        expect(s.label, contains('(incoming)'),
            reason: 'DELTA has no outgoing edges; label was ${s.label}');
      }
      expect(
        precedent.statements.where((s) => s.label.contains('(outgoing)')),
        isEmpty,
        reason: 'DELTA must not claim it overruled/followed any case',
      );
    });

    test('a case with no edges at all emits no precedent section', () {
      final explanation = service.explain('GAMMA')!;
      expect(explanation.hasSection(ExplanationSectionType.precedentContext),
          isFalse);
      expect(
          explanation.hasSection(ExplanationSectionType.relatedCases), isFalse);
    });
  });

  group('D. absent contextual information', () {
    test('GAMMA emits no cross-case context (no chronology, no chains)', () {
      final explanation = service.explain('GAMMA')!;
      expect(explanation.hasSection(ExplanationSectionType.crossCaseContext),
          isFalse,
          reason: 'GAMMA has no related cases, chain hops or doctrine members');
    });

    test('a related case that lacks context still fails safely', () {
      // BETA has intelligence and a doctrine but no edges of its own; it must
      // still explain without fabricating outgoing relationships.
      final explanation = service.explain('BETA')!;
      expect(explanation.sectionOf(ExplanationSectionType.identity), isNotNull);
      final precedent =
          explanation.sectionOf(ExplanationSectionType.precedentContext);
      if (precedent != null) {
        for (final s in precedent.statements) {
          expect(s.label, contains('(incoming)'),
              reason: 'BETA only receives the ALPHA followed edge');
        }
      }
    });
  });

  group('E. never fabricates on missing data', () {
    test('no statement text in any synthetic case is invented', () {
      for (final id in ['ALPHA', 'BETA', 'GAMMA', 'DELTA']) {
        final explanation = service.explain(id)!;
        for (final section in explanation.sections) {
          for (final s in section.statements) {
            expect(s.text.trim(), isNotEmpty,
                reason: '$id/${section.type.name}/${s.label}');
            expect(s.provenance.trim(), isNotEmpty);
            expect(s.sourceRefs, isNotEmpty);
          }
        }
      }
    });

    test('missing data yields deterministic, equivalent output', () {
      final again = CaseExplanationService(cases: syntheticExplanationCorpus());
      for (final id in ['ALPHA', 'BETA', 'GAMMA', 'DELTA']) {
        expect(again.explain(id)!.toJson(), service.explain(id)!.toJson(),
            reason: '$id not deterministic across instances');
      }
    });
  });
}
