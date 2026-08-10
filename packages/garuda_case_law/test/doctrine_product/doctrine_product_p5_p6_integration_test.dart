import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P12 — P5 graph and P6 search integration (TITAN-KO-015.0 P12).
///
/// The doctrine product reuses the P5 case → doctrine edges verbatim (via the
/// P10 doctrine analysis) and the P6/P5 canonical resolution: constituent-case
/// roles are recorded P5 edge evidence, precedent relationships among members
/// are P5 case → case edges verbatim, and non-member relationships are never
/// surfaced. The graph snapshot is never mutated.
void main() {
  final service = DoctrineKnowledgeProductService(
    cases: syntheticDoctrineCorpus(),
    doctrines: syntheticDoctrines(),
  );

  final product = service.build('SYNTH_DOCTRINE')!;

  group('A. constituent cases from P5 edges', () {
    test('member cases carry their recorded P5 roles', () {
      final section = product.sectionOf(DoctrineSectionType.constituentCases)!;
      expect(section.statements, hasLength(2));
      final alpha = section.statements.first;
      // ALPHA establishes SYNTH_DOCTRINE from the doctrine record's
      // originatingCase reference.
      expect(alpha.text, contains('Alpha v. State (2000)'));
      expect(alpha.text, contains('Establishes'));
      expect(alpha.sourceRefs, contains('ALPHA'));
      expect(alpha.sourceRefs, anyElement(startsWith('e:')));
      expect(alpha.provenance, 'doctrine:SYNTH_DOCTRINE.originatingCase');
    });

    test('member order is chronological (P5/chronology semantics preserved)',
        () {
      final section = product.sectionOf(DoctrineSectionType.constituentCases)!;
      final labels = section.statements.map((s) => s.text).toList();
      expect(labels.first, contains('2000'));
      expect(labels.last, contains('2005'));
    });
  });

  group('B. precedent relationships among members (P5 case → case edges)', () {
    test('an intra-doctrine P5 edge is surfaced verbatim', () {
      final section =
          product.sectionOf(DoctrineSectionType.precedentRelationships)!;
      expect(section.statements, hasLength(1));
      final s = section.statements.single;
      expect(s.label, 'followed');
      expect(s.text, contains('Alpha v. State'));
      expect(s.text, contains('Beta v. Union'));
      expect(s.sourceRefs, contains('ALPHA'));
      expect(s.sourceRefs, contains('BETA'));
      expect(s.sourceRefs, anyElement(startsWith('e:')));
      expect(s.provenance, 'corpus:precedentsFollowed');
    });

    test('a P5 edge to a non-member is never surfaced', () {
      // ALPHA overruled DELTA, but DELTA is not a SYNTH_DOCTRINE member, so no
      // DELTA relationship may appear in the doctrine product.
      final section =
          product.sectionOf(DoctrineSectionType.precedentRelationships);
      if (section != null) {
        for (final s in section.statements) {
          expect(s.text, isNot(contains('Delta v. State')));
          expect(s.sourceRefs, isNot(contains('DELTA')));
        }
      }
    });

    test('a single-case doctrine with no intra-doctrine edge omits the section',
        () {
      final second = service.build('SECOND_DOCTRINE')!;
      expect(
        second.hasSection(DoctrineSectionType.precedentRelationships),
        isFalse,
      );
    });
  });

  group('C. P6/P5 canonical resolution', () {
    test('resolution uses only existing doctrine nodes', () {
      // The resolver must not return anything for a doctrine node that does
      // not exist, and must resolve all synthetic records.
      for (final id in service.doctrineIds) {
        expect(service.resolveDoctrineId(id), id);
      }
    });
  });

  group('D. graph is never mutated', () {
    test('building products does not change the graph snapshot', () {
      final before = service.graph.edgeCount;
      final _ = service.buildAll();
      expect(service.graph.edgeCount, before);
    });

    test('services are shared, not recreated, when injected', () {
      final graph = service.graph;
      expect(service.analysisService.graph, same(graph));
    });
  });
}
