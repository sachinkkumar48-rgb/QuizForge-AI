import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P11 — Legal-safety boundaries (TITAN-KO-015.0 P11).
///
/// P11 re-presents validated P3–P10 evidence; it never derives legal meaning.
/// Over the composed sections (`doctrines`, `relatedCases`,
/// `precedentContext`, `crossCaseContext`) it must not invent citations,
/// precedent relationships, overruling, refinement, extension, current-law
/// claims, legal-similarity claims or unsupported doctrine/precedent evolution.
/// A relationship word is permitted only when a recorded P5 edge (`e:`) backs
/// it, and an authoritative overruling edge is surfaced verbatim as evidence —
/// never as an inference.
void main() {
  final service = CaseExplanationService();

  const composedSections = {
    ExplanationSectionType.doctrines,
    ExplanationSectionType.relatedCases,
    ExplanationSectionType.precedentContext,
    ExplanationSectionType.crossCaseContext,
  };

  Iterable<ExplanationStatement> composedStatements() sync* {
    for (final explanation in service.explainAll()) {
      for (final section in explanation.sections) {
        if (!composedSections.contains(section.type)) continue;
        for (final s in section.statements) {
          yield s;
        }
      }
    }
  }

  group('A. precedent relationship is never a citation', () {
    test('no composed statement uses citation vocabulary', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('cites')));
        expect(hay, isNot(contains('cited')));
        expect(hay, isNot(contains('citation')));
      }
    });

    test('citation statements only exist where the corpus records them', () {
      for (final explanation in service.explainAll()) {
        for (final section in explanation.sections) {
          for (final s in section.statements) {
            if (!s.label.contains('itation')) continue;
            // Citations are surfaced only as verbatim corpus identity/evidence.
            expect(
              section.type == ExplanationSectionType.identity ||
                  section.type == ExplanationSectionType.evidence,
              isTrue,
              reason: '${explanation.caseId} has a citation statement in '
                  '${section.type.name}',
            );
            expect(s.provenance, startsWith('corpus:'),
                reason: 'citation must trace to the corpus record');
          }
        }
      }
    });

    test('precedent-context labels are verbatim P5 relationship labels', () {
      const p5Vocabulary = {
        'followed',
        'overruled',
        'distinguished',
        'related',
        'affirmed',
        'reversed',
        'applied',
        'expanded',
        'limited',
        'clarified',
        'approved',
      };
      final verbPattern = RegExp('^(${p5Vocabulary.join('|')}) '
          r'\((outgoing|incoming)\)$');
      for (final explanation in service.explainAll()) {
        final precedent =
            explanation.sectionOf(ExplanationSectionType.precedentContext);
        if (precedent == null) continue;
        for (final s in precedent.statements) {
          expect(verbPattern.hasMatch(s.label), isTrue,
              reason: '${explanation.caseId} label "${s.label}" is not a '
                  'verbatim P5 relationship label');
          expect(s.sourceRefs.any((r) => r.startsWith('e:')), isTrue);
        }
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
          expect(s.sourceRefs.any((r) => r.startsWith('e:')), isTrue,
              reason: 'statement "${s.label}" mentions a relationship without '
                  'a recorded edge');
        }
      }
    });

    test('an authoritative overruling edge is surfaced verbatim, not inferred',
        () {
      // MANEKA_GANDHI overruled AK_GOPALAN is recorded P5 evidence.
      final explanation = service.explain('MANEKA_GANDHI')!;
      final precedent =
          explanation.sectionOf(ExplanationSectionType.precedentContext)!;
      final overruled = precedent.statements
          .where((s) => s.label.startsWith('overruled'))
          .toList();
      expect(overruled, isNotEmpty);
      for (final s in overruled) {
        expect(s.sourceRefs, contains('AK_GOPALAN'));
        expect(s.sourceRefs.any((r) => r.startsWith('e:')), isTrue);
        expect(s.provenance, isNotEmpty);
      }
    });

    test('a case with no recorded edge claims no precedent relationship', () {
      // Disconnected cases may still share articles, but P11 must not invent a
      // precedent link from that.
      final explanation = service.explain('OLGA_TELLIS')!;
      final precedent =
          explanation.sectionOf(ExplanationSectionType.precedentContext);
      if (precedent == null) return; // no edges → no section: correct
      for (final s in precedent.statements) {
        expect(s.sourceRefs.any((r) => r.startsWith('e:')), isTrue);
      }
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

    test('extended/extension never appears in composed sections', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('extended')));
        expect(hay, isNot(contains('extension')));
        expect(hay, isNot(contains('evolved from')));
      }
    });
  });

  group('D. no unsupported legal conclusions', () {
    test('no legal-similarity or similarity-score claim is emitted', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('legally similar')));
        expect(hay, isNot(contains('legal similarity')));
        expect(hay, isNot(contains('similarity score')));
      }
    });

    test('no current-law claim is emitted', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('current law')));
      }
    });

    test('shared articles/doctrines are surfaced, never as similarity', () {
      final explanation = service.explain('MANEKA_GANDHI')!;
      final related =
          explanation.sectionOf(ExplanationSectionType.relatedCases)!;
      final texts = related.statements.map((s) => s.text.toLowerCase()).join();
      // Shared-article reasons are verbatim P9 discoveries...
      expect(texts, contains('shared article'));
      // ...never reworded into a similarity verdict.
      expect(texts, isNot(contains('similar')));
      expect(texts, isNot(contains('same legal position')));
    });
  });

  group('E. no unsupported doctrine or precedent evolution', () {
    test('composed sections never narrate doctrine evolution', () {
      for (final s in composedStatements()) {
        final hay = '${s.label} ${s.text}'.toLowerCase();
        expect(hay, isNot(contains('doctrine evolved')));
        expect(hay, isNot(contains('law evolved')));
        expect(hay, isNot(contains('over time the law')));
      }
    });

    test('chronology is position, never causation', () {
      for (final explanation in service.explainAll()) {
        final context =
            explanation.sectionOf(ExplanationSectionType.crossCaseContext);
        if (context == null) continue;
        for (final s in context.statements) {
          if (s.label != 'Chronological position') continue;
          final hay = s.text.toLowerCase();
          expect(hay, isNot(contains('because')));
          expect(hay, isNot(contains('therefore')));
          expect(hay, isNot(contains('evolved')));
          expect(s.provenance, 'p10:chronology');
        }
      }
    });
  });
}
