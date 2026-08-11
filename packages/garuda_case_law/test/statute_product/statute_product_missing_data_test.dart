import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P13 — Missing-data and sparse-provision behavior (TITAN-KO-015.0 P13).
///
/// Missing data is represented by an *absent* section, never by fabricated
/// content. These tests exercise a provision whose only case is disconnected
/// from every doctrine (`Article 400`), a provision absent from the canonical
/// constitution corpus (`Article 300`), and section products (which have no
/// section corpus) — verifying the product fails gracefully, invents nothing
/// and never claims a relationship that is not recorded.
void main() {
  final service = syntheticService();

  group('A. single-case provision with no doctrine', () {
    final product = service.build(ProvisionType.article, 'Article 400')!;

    test('identity and associated cases remain from corpus evidence', () {
      expect(product.provisionType, ProvisionType.article);
      expect(product.provisionId, '400');
      expect(product.hasSection(StatuteSectionType.identity), isTrue);
      expect(product.hasSection(StatuteSectionType.associatedCases), isTrue);
    });

    test('doctrine section is absent, never fabricated', () {
      expect(product.hasSection(StatuteSectionType.doctrines), isFalse);
    });

    test('overview is absent (Article 400 is in no constitution corpus)', () {
      expect(product.hasSection(StatuteSectionType.overview), isFalse);
    });

    test('chronology and structural observations remain', () {
      expect(product.hasSection(StatuteSectionType.chronology), isTrue);
      expect(product.hasSection(StatuteSectionType.structuralObservations),
          isTrue);
    });

    test('the product embeds its one case explanation', () {
      expect(product.caseExplanations, hasLength(1));
      expect(product.caseExplanations.first.caseId, 'ZETA');
    });
  });

  group('B. provision absent from the canonical corpus', () {
    final product = service.build(ProvisionType.article, 'Article 300')!;

    test('identity is verbatim-only and never invents an overview', () {
      expect(product.provisionId, '300');
      expect(product.hasSection(StatuteSectionType.overview), isFalse);
      final identity = product.sectionOf(StatuteSectionType.identity)!;
      expect(identity.textOf('Resolution'),
          contains('Verbatim corpus reference only'));
    });

    test('no constitutional text is invented', () {
      for (final s in product.sections) {
        for (final st in s.statements) {
          expect(st.provenance,
              isNot(contains('constitution:ArticleKnowledgeObject')));
        }
      }
    });
  });

  group('C. section products have no overview corpus', () {
    final product = service.build(ProvisionType.section, 'Section 154 CrPC')!;

    test('a section product never fabricates a section overview', () {
      expect(product.hasSection(StatuteSectionType.overview), isFalse);
      expect(product.provisionId, 'section 154 crpc');
      expect(product.hasSection(StatuteSectionType.associatedCases), isTrue);
    });
  });

  group('D. unknown provisions resolve to nothing', () {
    test('unknown input produces no product', () {
      expect(service.build(ProvisionType.article, 'Article 999'), isNull);
      expect(service.build(ProvisionType.act, 'No Such Act 1999'), isNull);
      expect(
          service.build(ProvisionType.section, 'Section 1 Nonsense'), isNull);
    });

    test('empty and whitespace input produces no product', () {
      expect(service.build(ProvisionType.article, ''), isNull);
      expect(service.build(ProvisionType.article, '   '), isNull);
    });
  });
}
