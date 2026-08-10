import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P12 — P9 discovery, P10 cross-case analysis and P11 case-explanation
/// integration (TITAN-KO-015.0 P12).
///
/// P12 reuses P9 discovery, P10 doctrine analysis and P11 case explanations
/// directly. The product's doctrine-level sections (chronology, structural
/// observations) come verbatim from P10; per-case knowledge is one P11
/// [CaseExplanation] per constituent case, never re-implemented.
void main() {
  final service = DoctrineKnowledgeProductService(
    cases: syntheticDoctrineCorpus(),
    doctrines: syntheticDoctrines(),
  );

  group('A. P9 discovery reuse', () {
    test('the discovery service is composed, not recreated', () {
      // Injecting a shared service proves P12 consumes the existing P9 layer.
      final shared = CaseDiscoveryService(cases: syntheticDoctrineCorpus());
      final svc = DoctrineKnowledgeProductService(
        cases: syntheticDoctrineCorpus(),
        doctrines: syntheticDoctrines(),
        discoveryService: shared,
      );
      expect(identical(svc.discoveryService, shared), isTrue);
    });

    test('related-case discovery does not fabricate doctrine membership', () {
      // GAMMA is disconnected: it must never appear as a member of any
      // doctrine product even though discovery knows it exists.
      for (final product in service.buildAll()) {
        final section = product.sectionOf(DoctrineSectionType.constituentCases);
        if (section == null) continue;
        for (final s in section.statements) {
          expect(s.sourceRefs, isNot(contains('GAMMA')));
        }
      }
    });
  });

  group('B. P10 doctrine analysis reuse', () {
    test('chronology section reflects the P10 chronological span', () {
      final product = service.build('SYNTH_DOCTRINE')!;
      final chronology = product.sectionOf(DoctrineSectionType.chronology)!;
      final byLabel = {for (final s in chronology.statements) s.label: s.text};
      expect(byLabel['Earliest'], 'Alpha v. State (2000)');
      expect(byLabel['Latest'], 'Beta v. Union (2005)');
      expect(byLabel['Year span'], '2000–2005');
      for (final s in chronology.statements) {
        expect(s.provenance, 'p10:chronology');
      }
    });

    test('structural observations reuse the P10 chronological-span observation',
        () {
      final product = service.build('SYNTH_DOCTRINE')!;
      final observations =
          product.sectionOf(DoctrineSectionType.structuralObservations)!;
      expect(
        observations.statements
            .any((s) => s.provenance == 'structural:chronology'),
        isTrue,
      );
    });

    test('shared-constituent-case overlap is structural, not legal', () {
      final product = service.build('SYNTH_DOCTRINE')!;
      final observations =
          product.sectionOf(DoctrineSectionType.structuralObservations)!;
      final overlap = observations.statements
          .where((s) => s.label == 'Shared constituent case (structural)');
      expect(overlap, isNotEmpty);
      for (final s in overlap) {
        expect(s.text, contains('SECOND_DOCTRINE'));
        expect(s.text, contains('structural grouping'));
        expect(s.text, contains('not a legal relationship'));
        expect(s.sourceRefs, contains('SYNTH_DOCTRINE'));
        expect(s.sourceRefs, contains('SECOND_DOCTRINE'));
        expect(s.provenance, 'p5:caseDoctrineEdges');
      }
    });

    test('a sparse doctrine has no structural observations', () {
      final product = service.build('SPARSE_DOCTRINE')!;
      expect(
        product.hasSection(DoctrineSectionType.structuralObservations),
        isFalse,
      );
    });
  });

  group('C. P11 case-explanation reuse', () {
    test('one P11 explanation per constituent case, chronological order', () {
      final product = service.build('SYNTH_DOCTRINE')!;
      expect(product.caseExplanations.map((e) => e.caseId).toList(),
          ['ALPHA', 'BETA']);
      for (final e in product.caseExplanations) {
        expect(e, isA<CaseExplanation>());
        expect(e.caseId, isNotEmpty);
        expect(e.sections, isNotEmpty);
      }
    });

    test('constituent cases and explanations are consistent', () {
      for (final product in service.buildAll()) {
        final section = product.sectionOf(DoctrineSectionType.constituentCases);
        if (section == null) {
          expect(product.caseExplanations, isEmpty);
          continue;
        }
        // Each constituent statement's first reference is its canonical case
        // ID; the explanation set must match it exactly (one P11 explanation
        // per constituent case, no more, no less).
        final statementCaseIds = [
          for (final s in section.statements) s.sourceRefs.first,
        ]..sort();
        final explanationCaseIds = [
          for (final e in product.caseExplanations) e.caseId,
        ]..sort();
        expect(statementCaseIds, explanationCaseIds);
      }
    });
  });
}
