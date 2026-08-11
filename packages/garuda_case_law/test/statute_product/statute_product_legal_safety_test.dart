import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P13 — Legal-safety boundaries (TITAN-KO-015.0 P13).
///
/// P13 re-presents validated P3–P12 evidence at the provision level; it never
/// derives legal meaning. Over the composed sections (`associatedCases`,
/// `doctrines`, `precedentRelationships`, `chronology`,
/// `structuralObservations`) it must not invent citations, precedent
/// relationships, overruling, refinement, extension, doctrinal evolution,
/// current-law status or legal-similarity claims. A relationship word is
/// permitted only when a recorded P5 edge (`e:`) backs it.
void main() {
  final service = syntheticService();

  const composedSections = {
    StatuteSectionType.associatedCases,
    StatuteSectionType.doctrines,
    StatuteSectionType.precedentRelationships,
    StatuteSectionType.chronology,
    StatuteSectionType.structuralObservations,
  };

  Iterable<StatuteStatement> composedStatements() sync* {
    for (final product in service.buildAll()) {
      for (final section in product.sections) {
        if (!composedSections.contains(section.type)) continue;
        yield* section.statements;
      }
    }
  }

  bool edgeBacked(StatuteStatement s) =>
      s.sourceRefs.any((r) => r.startsWith('e:'));

  group('A. precedent relationship is never a citation', () {
    test('no composed statement uses citation vocabulary', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('cites')));
        expect(hay, isNot(contains('cited')));
        expect(hay, isNot(contains('citation')));
      }
    });

    test('every precedent relationship statement is backed by a P5 edge', () {
      for (final p in service.buildAll()) {
        final s = p.sectionOf(StatuteSectionType.precedentRelationships);
        if (s == null) continue;
        for (final st in s.statements) {
          expect(edgeBacked(st), isTrue,
              reason: '${st.label} of ${p.provisionId} lacks a P5 edge ref');
        }
      }
    });

    test('no relationship vocabulary appears without an edge reference', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        final relationshipWords = [
          'overrul',
          'distinguish',
          'follow',
          'expand',
          'limit',
          'refine',
          'extend',
          'develop'
        ];
        final mentions = relationshipWords.any(hay.contains);
        if (mentions) {
          expect(edgeBacked(s), isTrue,
              reason: '${s.label} mentions a relationship without an edge');
        }
      }
    });
  });

  group('B. no doctrinal evolution or current-law claims', () {
    test('no composed statement claims evolution, expansion or narrowing', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('evolved')));
        expect(hay, isNot(contains('evolution')));
        expect(hay, isNot(contains('doctrinal shift')));
        expect(hay, isNot(contains('refined')));
        expect(hay, isNot(contains('narrowed')));
        expect(hay, isNot(contains('expanded')));
      }
    });

    test('no composed statement asserts current-law status', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('still good law')));
        expect(hay, isNot(contains('current law')));
        expect(hay, isNot(contains('governing law')));
        expect(hay, isNot(contains('no longer valid')));
      }
    });

    test('no composed statement asserts legal similarity', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('legally similar')));
        expect(hay, isNot(contains('same ratio')));
        expect(hay, isNot(contains('identical in law')));
      }
    });
  });

  group('C. chronology is position, not causation', () {
    test('chronology uses position vocabulary only', () {
      for (final p in service.buildAll()) {
        final s = p.sectionOf(StatuteSectionType.chronology);
        if (s == null) continue;
        for (final st in s.statements) {
          expect(['Earliest', 'Latest', 'Year span'], contains(st.label));
          final hay = '${st.label} ${st.text}'.toLowerCase();
          expect(hay, isNot(contains('because')));
          expect(hay, isNot(contains('therefore')));
          expect(hay, isNot(contains('caused')));
        }
      }
    });

    test('doctrine statements never claim one case develops another', () {
      for (final p in service.buildAll()) {
        final s = p.sectionOf(StatuteSectionType.doctrines);
        if (s == null) continue;
        for (final st in s.statements) {
          final hay = '${st.label} ${st.text}'.toLowerCase();
          expect(hay, isNot(contains('develops')));
          expect(hay, isNot(contains('builds on')));
          expect(hay, isNot(contains('supersedes')));
        }
      }
    });
  });

  group('D. overview never adds legal interpretation', () {
    test('overview is limited to identity metadata', () {
      for (final p in service.buildAll()) {
        final s = p.sectionOf(StatuteSectionType.overview);
        if (s == null) continue;
        for (final st in s.statements) {
          expect([
            'Article number',
            'Official title',
            'Part',
            'Chapter',
            'Official name',
            'Short title',
            'Year',
            'Act number'
          ], contains(st.label));
        }
      }
    });

    test('the identity section never claims a legal status', () {
      for (final p in service.buildAll()) {
        final s = p.sectionOf(StatuteSectionType.identity);
        if (s == null) continue;
        for (final st in s.statements) {
          if (st.label == 'Resolution') continue;
          final hay = '${st.label} ${st.text}'.toLowerCase();
          expect(hay, isNot(contains('repealed')));
          expect(hay, isNot(contains('unconstitutional')));
        }
      }
    });
  });
}
