import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P12 — Evidence and provenance traceability (TITAN-KO-015.0 P12).
///
/// Every meaningful doctrine-product statement must be traceable: it carries
/// non-empty source references and a provenance string naming the validated
/// doctrine-record field, corpus field, P5 edge or P10 analysis that
/// establishes it. No fabricated identifiers may appear, and evidence
/// presentation reuses the P8 `EvidenceEntry` registry resolution.
void main() {
  final service = DoctrineKnowledgeProductService(
    cases: syntheticDoctrineCorpus(),
    doctrines: syntheticDoctrines(),
  );

  final corpusIds = {for (final c in syntheticDoctrineCorpus()) c.caseId};
  final doctrineIds = {for (final d in syntheticDoctrines()) d.doctrineId};

  group('A. every statement is traceable', () {
    test('every statement has non-empty provenance and source references', () {
      for (final product in service.buildAll()) {
        for (final section in product.sections) {
          for (final s in section.statements) {
            expect(s.provenance.trim(), isNotEmpty,
                reason: 'statement ${s.label} of ${product.doctrineId}');
            expect(s.sourceRefs, isNotEmpty,
                reason: 'statement ${s.label} of ${product.doctrineId}');
          }
        }
      }
    });

    test('every section aggregates a non-empty provenance', () {
      for (final product in service.buildAll()) {
        for (final section in product.sections) {
          expect(section.provenance.trim(), isNotEmpty,
              reason: 'section ${section.type.name} of ${product.doctrineId}');
        }
      }
    });

    test('no statement text is empty or a placeholder', () {
      for (final product in service.buildAll()) {
        for (final section in product.sections) {
          for (final s in section.statements) {
            expect(s.text.trim(), isNotEmpty,
                reason: '${product.doctrineId}/${section.type.name}');
            expect(s.text, isNot(contains('N/A')));
            expect(s.text, isNot(contains('TBD')));
            expect(s.text, isNot(contains('unknown')));
          }
        }
      }
    });
  });

  group('B. references stay canonical', () {
    test('composed statements reference only validated identifiers', () {
      for (final product in service.buildAll()) {
        for (final section in product.sections) {
          for (final s in section.statements) {
            for (final id in s.sourceRefs) {
              final isCase = corpusIds.contains(id);
              final isDoctrine = doctrineIds.contains(id);
              final isEdge = id.startsWith('e:');
              final isEvidence = id.startsWith('ev_');
              final isHolding = id.startsWith('h-') || id.startsWith('i-');
              expect(isCase || isDoctrine || isEdge || isEvidence || isHolding,
                  isTrue,
                  reason: '$id in ${product.doctrineId}/${section.type.name} '
                      'is not a canonical ID');
            }
          }
        }
      }
    });

    test('referencedCaseIds never fabricate a case ID', () {
      for (final product in service.buildAll()) {
        for (final id in service.referencedCaseIds(product)) {
          expect(corpusIds, contains(id),
              reason: '${product.doctrineId} references unknown case $id');
        }
      }
    });
  });

  group('C. P8 evidence registry reuse', () {
    test('member-case evidence statements resolve through the registry', () {
      final product = service.build('SYNTH_DOCTRINE')!;
      final evidence = product.sectionOf(DoctrineSectionType.evidence)!;
      final memberEvidence =
          evidence.statements.where((s) => s.label.startsWith('Evidence — '));
      expect(memberEvidence, isNotEmpty);
      for (final s in memberEvidence) {
        expect(s.text, contains('verified'));
        expect(s.sourceRefs, anyElement(startsWith('ev_')));
      }
    });

    test('doctrine-record evidence is presented verbatim', () {
      final product = service.build('SYNTH_DOCTRINE')!;
      final evidence = product.sectionOf(DoctrineSectionType.evidence)!;
      expect(
        evidence.statements.any((s) => s.label == 'Recorded citation'),
        isTrue,
      );
      for (final s in evidence.statements) {
        if (s.provenance.startsWith('doctrine:')) {
          expect(s.sourceRefs, ['SYNTH_DOCTRINE']);
        }
      }
    });
  });

  group('D. source hierarchy', () {
    test('doctrine identity/overview provenance traces to the doctrine record',
        () {
      final product = service.build('SYNTH_DOCTRINE')!;
      final identity = product.sectionOf(DoctrineSectionType.identity)!;
      for (final s in identity.statements) {
        expect(s.provenance, startsWith('doctrine:SYNTH_DOCTRINE.'));
      }
      final overview = product.sectionOf(DoctrineSectionType.overview)!;
      for (final s in overview.statements) {
        expect(s.provenance, startsWith('doctrine:SYNTH_DOCTRINE.'));
      }
    });

    test('constituent-case provenance traces to the doctrine record role', () {
      final product = service.build('SYNTH_DOCTRINE')!;
      final constituent =
          product.sectionOf(DoctrineSectionType.constituentCases)!;
      // ALPHA's membership is established by the doctrine record's
      // originatingCase field.
      expect(constituent.statements.first.provenance,
          'doctrine:SYNTH_DOCTRINE.originatingCase');
    });
  });
}
