import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P13 — `StatuteKnowledgeProduct` / `StatuteSection` / `StatuteStatement`
/// domain-model tests (TITAN-KO-015.0 P13).
///
/// The statute product is an immutable, deterministic, provenance-preserving
/// value object mirroring the P12 doctrine-product model shape. These tests pin
/// the serialization round-trip, section accessors, provenance aggregation,
/// referenced-ID aggregation and the invariant that every statement carries
/// non-empty source references.
void main() {
  group('A. statement invariant', () {
    test('a statement without source references is rejected by assert', () {
      expect(
        () => StatuteStatement(
          label: 'Associated case 1',
          text: 'content',
          sourceRefs: const [],
          provenance: 'corpus:relatedArticles',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a statement with source references is accepted', () {
      final s = StatuteStatement(
        label: 'Associated case 1',
        text: 'content',
        sourceRefs: const ['ALPHA', 'e:ALPHA|followed|BETA'],
        provenance: 'corpus:relatedArticles',
      );
      expect(s.sourceRefs, ['ALPHA', 'e:ALPHA|followed|BETA']);
    });
  });

  group('B. section aggregation', () {
    test('provenance is unique, sorted and joined by ;', () {
      final section = StatuteSection(
        type: StatuteSectionType.associatedCases,
        title: 'Associated Cases',
        statements: [
          StatuteStatement(
            label: 'Associated case 1',
            text: 'a',
            sourceRefs: const ['A'],
            provenance: 'corpus:relatedArticles; p5:caseDoctrineEdges',
          ),
          StatuteStatement(
            label: 'Associated case 2',
            text: 'b',
            sourceRefs: const ['B'],
            provenance: 'corpus:relatedArticles',
          ),
        ],
      );
      expect(section.provenance, 'corpus:relatedArticles;p5:caseDoctrineEdges');
    });

    test('references are unique and sorted', () {
      final section = StatuteSection(
        type: StatuteSectionType.associatedCases,
        title: 'Associated Cases',
        statements: [
          StatuteStatement(
            label: 'a',
            text: 'a',
            sourceRefs: const ['B', 'A'],
            provenance: 'corpus:relatedArticles',
          ),
          StatuteStatement(
            label: 'b',
            text: 'b',
            sourceRefs: const ['A', 'C'],
            provenance: 'corpus:relatedArticles',
          ),
        ],
      );
      expect(section.references, ['A', 'B', 'C']);
    });

    test('hasLabel / statementOf / textOf find statements', () {
      final section = StatuteSection(
        type: StatuteSectionType.identity,
        title: 'Provision Identity',
        statements: [
          StatuteStatement(
            label: 'Provision key',
            text: '21',
            sourceRefs: const ['21'],
            provenance: 'statute:provisionId',
          ),
          StatuteStatement(
            label: 'Reference 1',
            text: 'Article 21',
            sourceRefs: const ['21'],
            provenance: 'corpus:relatedArticles',
          ),
        ],
      );
      expect(section.hasLabel('Provision key'), isTrue);
      expect(section.hasLabel('Missing'), isFalse);
      expect(section.statementOf('Provision key')!.text, '21');
      expect(section.textOf('Reference 1'), 'Article 21');
      expect(section.textOf('Missing'), '');
    });
  });

  group('C. product construction', () {
    test('a product from the synthetic corpus carries its identity', () {
      final product = syntheticService().build(
        ProvisionType.article,
        'Article 21',
      )!;
      expect(product.provisionType, ProvisionType.article);
      expect(product.provisionId, '21');
      expect(product.provisionName, 'Art. 21');
      expect(product.rawReferences, ['Art. 21', 'Article 21', 'article 21']);
      expect(product.sections, isNotEmpty);
      expect(product.isEmpty, isFalse);
      expect(product.caseExplanations, isNotEmpty);
    });

    test('sectionOf / hasSection answer by type', () {
      final product = syntheticService().build(
        ProvisionType.article,
        'Article 21',
      )!;
      expect(
        product.sectionOf(StatuteSectionType.identity),
        isNotNull,
      );
      expect(product.hasSection(StatuteSectionType.associatedCases), isTrue);
      expect(product.hasSection(StatuteSectionType.overview), isTrue);
    });

    test('serialization round-trips to an equal product', () {
      final product = syntheticService().build(
        ProvisionType.article,
        'Article 21',
      )!;
      final restored = StatuteKnowledgeProduct.fromJson(product.toJson());
      expect(restored, product);
    });

    test('equality is structural across products', () {
      final a = syntheticService().build(
        ProvisionType.article,
        'Article 21',
      )!;
      final b = syntheticService().build(
        ProvisionType.article,
        'Article 100',
      )!;
      expect(a, a);
      expect(a, isNot(b));
    });

    test('referencedIds include the provision key and canonical IDs', () {
      final product = syntheticService().build(
        ProvisionType.article,
        'Article 21',
      )!;
      final ids = product.referencedIds;
      expect(ids, contains('21'));
      expect(ids, contains('ALPHA'));
      expect(ids, contains('BETA'));
      expect(ids, contains('DELTA'));
      // Deterministically sorted.
      expect(ids, orderedEquals(([...ids]..sort())));
    });
  });
}
