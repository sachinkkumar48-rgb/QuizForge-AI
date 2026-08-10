import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P12 — Legal-safety boundaries (TITAN-KO-015.0 P12).
///
/// P12 re-presents validated P3–P11 evidence at the doctrine level; it never
/// derives legal meaning. Over the composed sections (`constituentCases`,
/// `precedentRelationships`, `chronology`, `structuralObservations`) it must
/// not invent citations, precedent relationships, overruling, refinement,
/// extension, current-law claims, legal-similarity claims, "related doctrine"
/// claims or unsupported doctrine evolution. A relationship word is permitted
/// only when a recorded P5 edge (`e:`) backs it.
void main() {
  final service = DoctrineKnowledgeProductService(
    cases: syntheticDoctrineCorpus(),
    doctrines: syntheticDoctrines(),
  );

  const composedSections = {
    DoctrineSectionType.constituentCases,
    DoctrineSectionType.precedentRelationships,
    DoctrineSectionType.chronology,
    DoctrineSectionType.structuralObservations,
  };

  Iterable<DoctrineStatement> composedStatements() sync* {
    for (final product in service.buildAll()) {
      for (final section in product.sections) {
        if (!composedSections.contains(section.type)) continue;
        for (final s in section.statements) {
          yield s;
        }
      }
    }
  }

  bool edgeBacked(DoctrineStatement s) =>
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
  });

  group('B. no fabricated precedent relationships', () {
    test('any P5 relationship word in a composed statement is edge-backed', () {
      const relationshipWords = [
        'overruled',
        'followed',
        'distinguished',
        'affirmed',
        'reversed',
        'applied',
        'expanded',
        'limited',
        'clarified',
        'approved',
      ];
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        final mentionsRelationship =
            relationshipWords.any((w) => hay.contains(w));
        if (mentionsRelationship) {
          expect(edgeBacked(s), isTrue,
              reason: 'statement "${s.label}" mentions a relationship without '
                  'a recorded edge');
        }
      }
    });

    test('a non-member overruling edge is never surfaced', () {
      // ALPHA overruled DELTA but DELTA is not a SYNTH_DOCTRINE member: the
      // product must not claim ALPHA overruled DELTA.
      final product = service.build('SYNTH_DOCTRINE')!;
      final precedent =
          product.sectionOf(DoctrineSectionType.precedentRelationships);
      if (precedent != null) {
        for (final s in precedent.statements) {
          expect(s.label, isNot('overruled'));
          expect(s.text, isNot(contains('Delta v. State')));
        }
      }
    });

    test('a sparse doctrine with no members claims no relationship', () {
      final product = service.build('SPARSE_DOCTRINE')!;
      expect(
        product.hasSection(DoctrineSectionType.precedentRelationships),
        isFalse,
      );
      expect(
        product.hasSection(DoctrineSectionType.constituentCases),
        isFalse,
      );
    });
  });

  group('C. no inferred overruling, refinement or extension', () {
    test('refined/refinement never appears in composed sections', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('refined')));
        expect(hay, isNot(contains('refinement')));
      }
    });

    test('extended/extension/evolved-from never appears in composed sections',
        () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('extended')));
        expect(hay, isNot(contains('extension')));
        expect(hay, isNot(contains('evolved from')));
      }
    });
  });

  group('D. chronology is never causation', () {
    test('no composed statement asserts doctrine evolution or development', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('developed into')));
        expect(hay, isNot(contains('grew into')));
        expect(hay, isNot(contains('became the')));
        expect(hay, isNot(contains('therefore')));
        expect(hay, isNot(contains('because')));
      }
    });
  });

  group('E. no unsupported legal conclusions', () {
    test('no legal-similarity or similarity claim is emitted', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('legally similar')));
        expect(hay, isNot(contains('legal similarity')));
        expect(hay, isNot(contains('similarity score')));
        expect(hay, isNot(contains('same doctrine')));
      }
    });

    test('no "related doctrine" or binding-authority claim is emitted', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('related doctrine')));
        expect(hay, isNot(contains('binding authority')));
        expect(hay, isNot(contains('binding precedent')));
      }
    });

    test('no current-law claim is emitted by composed statements', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('current law')));
        expect(hay, isNot(contains('current position of the law')));
      }
    });

    test('the shared-constituent-case overlap is explicitly non-legal', () {
      final product = service.build('SYNTH_DOCTRINE')!;
      final observations =
          product.sectionOf(DoctrineSectionType.structuralObservations)!;
      for (final s in observations.statements) {
        if (s.label == 'Shared constituent case (structural)') {
          expect(s.text, contains('not a legal relationship'));
          expect(s.text, isNot(contains('legally similar')));
          expect(s.text, isNot(contains('related doctrine')));
        }
      }
    });
  });

  group('F. overview re-presents only doctrine-record content', () {
    test('overview statements trace to the doctrine record, never inferred',
        () {
      for (final product in service.buildAll()) {
        final overview = product.sectionOf(DoctrineSectionType.overview);
        if (overview == null) continue;
        for (final s in overview.statements) {
          expect(s.provenance, startsWith('doctrine:${product.doctrineId}.'),
              reason: '${product.doctrineId} overview "${s.label}" is not '
                  'doctrine-record content');
        }
      }
    });
  });
}
