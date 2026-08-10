import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_doctrine/garuda_doctrine.dart' show DoctrineSeedData;

import 'synthetic_corpus.dart';

/// P11 — Provenance and evidence traceability (TITAN-KO-015.0 P11).
///
/// Every meaningful statement must be traceable: it carries non-empty source
/// references and a provenance string naming the validated corpus field, graph
/// edge or analysis that establishes it. No fabricated identifiers may appear,
/// and provenance must be deterministic.
void main() {
  final service = CaseExplanationService();

  group('A. every statement is traceable', () {
    test('every statement across the corpus has non-empty provenance', () {
      for (final explanation in service.explainAll()) {
        for (final section in explanation.sections) {
          for (final s in section.statements) {
            expect(s.provenance.trim(), isNotEmpty,
                reason: 'statement ${s.label} of ${explanation.caseId}');
            expect(s.sourceRefs, isNotEmpty,
                reason: 'statement ${s.label} of ${explanation.caseId}');
          }
        }
      }
    });

    test('every section aggregates a non-empty provenance', () {
      for (final explanation in service.explainAll()) {
        for (final section in explanation.sections) {
          expect(section.provenance.trim(), isNotEmpty,
              reason: 'section ${section.type.name} of ${explanation.caseId}');
        }
      }
    });

    test('no statement text is empty or a placeholder', () {
      for (final explanation in service.explainAll()) {
        for (final section in explanation.sections) {
          for (final s in section.statements) {
            expect(s.text.trim(), isNotEmpty,
                reason:
                    '${explanation.caseId}/${section.type.name}/${s.label}');
            expect(s.text.toLowerCase(),
                isNot(anyOf(['n/a', 'not available', 'tbd', 'unknown'])));
          }
        }
      }
    });
  });

  group('B. no fabricated case IDs', () {
    test('referenced case IDs are always canonical corpus cases', () {
      for (final explanation in service.explainAll()) {
        final referenced = service.referencedCaseIds(explanation);
        expect(referenced, contains(explanation.caseId));
        for (final id in referenced) {
          expect(service.caseIds, contains(id),
              reason: '${explanation.caseId} referenced fabricated case $id');
        }
      }
    });

    test('otherCaseIds never contains the explained case', () {
      for (final explanation in service.explainAll()) {
        expect(service.otherCaseIds(explanation),
            isNot(contains(explanation.caseId)));
      }
    });

    test('every source reference is a resolvable canonical identifier', () {
      final knownDoctrines = {
        for (final d in DoctrineSeedData.doctrines) d.doctrineId,
      };
      for (final explanation in service.explainAll()) {
        for (final section in explanation.sections) {
          for (final s in section.statements) {
            for (final ref in s.sourceRefs) {
              // A reference is legitimate when it resolves to one of the
              // documented canonical categories: a corpus case ID, a known
              // doctrine ID, a P5 edge ID (e:), a P4 holding/issue ID, an
              // evidence ID, or a normalized article/Act discovery key
              // (always lowercase — e.g. `13`, `31a`, `passports act 1967`).
              // Any *uppercase* reference that is neither a case nor a known
              // doctrine would be a fabricated identifier and is rejected.
              final isCorpusCase = service.caseIds.contains(ref);
              final isDoctrine = knownDoctrines.contains(ref);
              final isEdge = ref.startsWith('e:');
              final isHoldingId = ref.startsWith('hol_');
              final isIssueId = ref.startsWith('iss_');
              final isEvidenceId = ref.startsWith('ev_');
              final isReasonKey = ref == ref.toLowerCase();
              expect(
                isCorpusCase ||
                    isDoctrine ||
                    isEdge ||
                    isHoldingId ||
                    isIssueId ||
                    isEvidenceId ||
                    isReasonKey,
                isTrue,
                reason: '${explanation.caseId}/${section.type.name} '
                    'referenced unresolvable identifier $ref',
              );
            }
          }
        }
      }
    });
  });

  group('C. deterministic provenance', () {
    test('the same input produces identical provenance and references', () {
      final a = service.explain('KESAVANANDA')!;
      final b = service.explain('KESAVANANDA')!;
      expect(a.toJson(), b.toJson());
      for (var i = 0; i < a.sections.length; i++) {
        expect(a.sections[i].provenance, b.sections[i].provenance);
        expect(a.sections[i].references, b.sections[i].references);
      }
    });

    test('references are unique and sorted within every section', () {
      for (final explanation in service.explainAll()) {
        for (final section in explanation.sections) {
          final refs = section.references;
          final sorted = [...refs]..sort();
          expect(refs, sorted,
              reason: '${explanation.caseId}/${section.type.name}');
          expect(refs.toSet(), hasLength(refs.length));
        }
      }
    });
  });

  group('D. synthetic corpus provenance', () {
    test('a synthetic case carries only its own source references', () {
      final synth = CaseExplanationService(
        cases: syntheticExplanationCorpus(),
      );
      final gamma = synth.explain('GAMMA')!;
      // GAMMA is disconnected: every reference resolves to GAMMA itself.
      expect(synth.referencedCaseIds(gamma), ['GAMMA']);
      for (final section in gamma.sections) {
        for (final s in section.statements) {
          expect(s.provenance, isNotEmpty);
          expect(s.sourceRefs, isNotEmpty);
        }
      }
    });
  });
}
