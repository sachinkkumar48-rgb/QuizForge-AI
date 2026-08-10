import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P12 — Missing-data and sparse-doctrine behavior (TITAN-KO-015.0 P12).
///
/// Missing data is represented by an *absent* section, never by fabricated
/// content. These tests exercise a doctrine with zero resolvable constituent
/// cases (`SPARSE_DOCTRINE`), a single-case doctrine (`SECOND_DOCTRINE`), and a
/// fully disconnected case (`GAMMA`) — verifying the product fails gracefully,
/// invents nothing and never claims a relationship that is not recorded.
void main() {
  final corpus = syntheticDoctrineCorpus();
  final service = DoctrineKnowledgeProductService(
    cases: corpus,
    doctrines: syntheticDoctrines(),
  );

  group('A. sparse doctrine with no constituent cases', () {
    final product = service.build('SPARSE_DOCTRINE')!;

    test('identity and overview remain from the doctrine record', () {
      expect(product.doctrineId, 'SPARSE_DOCTRINE');
      expect(
        product.sectionOf(DoctrineSectionType.identity),
        isNotNull,
      );
      expect(product.sectionOf(DoctrineSectionType.overview), isNotNull);
    });

    test('member-derived sections are absent, never fabricated', () {
      const absent = {
        DoctrineSectionType.constituentCases,
        DoctrineSectionType.articles,
        DoctrineSectionType.acts,
        DoctrineSectionType.precedentRelationships,
        DoctrineSectionType.chronology,
        DoctrineSectionType.structuralObservations,
        DoctrineSectionType.upscRelevance,
      };
      for (final type in absent) {
        expect(product.hasSection(type), isFalse,
            reason: '${type.name} should be absent for SPARSE_DOCTRINE');
      }
      expect(product.caseExplanations, isEmpty);
    });

    test('doctrine-record evidence is still presented', () {
      expect(product.sectionOf(DoctrineSectionType.evidence), isNotNull);
    });

    test('product is not empty (identity + overview + evidence)', () {
      expect(product.isEmpty, isFalse);
    });
  });

  group('B. single-case doctrine', () {
    final product = service.build('SECOND_DOCTRINE')!;

    test('resolves with exactly one constituent case', () {
      final constituent =
          product.sectionOf(DoctrineSectionType.constituentCases)!;
      expect(constituent.statements, hasLength(1));
      expect(product.caseExplanations.map((e) => e.caseId).toList(), ['ALPHA']);
    });

    test('chronology collapses to a single point, no crash', () {
      final chronology = product.sectionOf(DoctrineSectionType.chronology)!;
      final byLabel = {for (final s in chronology.statements) s.label: s.text};
      expect(byLabel['Earliest'], 'Alpha v. State (2000)');
      expect(byLabel['Latest'], 'Alpha v. State (2000)');
      expect(byLabel['Year span'], '2000–2000');
    });

    test('no intra-doctrine precedent edge is invented', () {
      expect(
        product.hasSection(DoctrineSectionType.precedentRelationships),
        isFalse,
      );
    });

    test('the member still contributes articles/acts/UPSC evidence', () {
      expect(product.hasSection(DoctrineSectionType.articles), isTrue);
      expect(product.hasSection(DoctrineSectionType.acts), isTrue);
      expect(product.hasSection(DoctrineSectionType.upscRelevance), isTrue);
    });
  });

  group('C. disconnected case is never a member', () {
    test('GAMMA appears in no doctrine product', () {
      for (final product in service.buildAll()) {
        final section = product.sectionOf(DoctrineSectionType.constituentCases);
        if (section == null) continue;
        for (final s in section.statements) {
          expect(s.sourceRefs, isNot(contains('GAMMA')));
        }
        for (final e in product.caseExplanations) {
          expect(e.caseId, isNot('GAMMA'));
        }
      }
    });

    test('GAMMA still resolves as a case in the underlying corpus', () {
      // The case exists in the corpus; only its doctrine membership is absent.
      expect(service.hasDoctrine('GAMMA'), isFalse);
      final svc = CaseExplanationService(cases: corpus);
      expect(svc.explain('GAMMA'), isNotNull);
    });
  });

  group('D. robust handling', () {
    test('building every doctrine never throws', () {
      for (final id in service.doctrineIds) {
        expect(service.build(id), isNotNull, reason: id);
      }
    });

    test('no empty text or placeholder appears anywhere', () {
      for (final product in service.buildAll()) {
        for (final section in product.sections) {
          for (final s in section.statements) {
            expect(s.text.trim(), isNotEmpty);
            expect(s.text, isNot(contains('N/A')));
            expect(s.text, isNot(contains('TBD')));
          }
        }
      }
    });
  });
}
