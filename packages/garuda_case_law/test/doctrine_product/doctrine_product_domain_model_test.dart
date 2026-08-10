import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P12 — `DoctrineKnowledgeProduct` / `DoctrineSection` / `DoctrineStatement`
/// domain-model tests (TITAN-KO-015.0 P12).
///
/// The doctrine product is an immutable, deterministic, provenance-preserving
/// value object mirroring the P11 case-explanation model shape. These tests pin
/// the serialization round-trip, section accessors, provenance aggregation,
/// referenced-ID aggregation and the invariant that every statement carries
/// non-empty source references.
void main() {
  group('A. statement invariant', () {
    test('a statement without source references is rejected by assert', () {
      expect(
        () => DoctrineStatement(
          label: 'Constituent case 1',
          text: 'content',
          sourceRefs: const [],
          provenance: 'doctrine:D1.originatingCase',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a statement with source references is accepted', () {
      final s = DoctrineStatement(
        label: 'Constituent case 1',
        text: 'content',
        sourceRefs: const ['ALPHA', 'e:ALPHA|followed|BETA'],
        provenance: 'doctrine:D1.originatingCase',
      );
      expect(s.sourceRefs, ['ALPHA', 'e:ALPHA|followed|BETA']);
    });
  });

  group('B. section aggregation', () {
    test('provenance is unique, sorted and joined by ;', () {
      final section = DoctrineSection(
        type: DoctrineSectionType.constituentCases,
        title: 'Constituent Cases',
        statements: [
          DoctrineStatement(
            label: 'Constituent case 1',
            text: 'a',
            sourceRefs: const ['A'],
            provenance: 'p5:caseDoctrineEdges; corpus:relatedArticles',
          ),
          DoctrineStatement(
            label: 'Constituent case 2',
            text: 'b',
            sourceRefs: const ['A'],
            provenance: 'corpus:relatedArticles',
          ),
        ],
      );
      expect(
        section.provenance,
        'corpus:relatedArticles;p5:caseDoctrineEdges',
      );
    });

    test('references are unique and sorted', () {
      final section = DoctrineSection(
        type: DoctrineSectionType.articles,
        title: 'Relevant Articles',
        statements: [
          DoctrineStatement(
            label: 'Article 21',
            text: 'Article 21',
            sourceRefs: const ['D1', 'BETA', 'ALPHA'],
            provenance: 'corpus:relatedArticles',
          ),
        ],
      );
      expect(section.references, ['ALPHA', 'BETA', 'D1']);
    });

    test('statement serialization round-trips', () {
      final s = DoctrineStatement(
        label: 'Article 21',
        text: 'Article 21',
        sourceRefs: const ['D1', 'ALPHA'],
        provenance: 'corpus:relatedArticles',
      );
      expect(
        DoctrineStatement.fromJson(s.toJson()),
        s,
      );
    });

    test('section serialization round-trips', () {
      final section = DoctrineSection(
        type: DoctrineSectionType.overview,
        title: 'Doctrine Overview',
        statements: [
          DoctrineStatement(
            label: 'Official definition',
            text: 'definition',
            sourceRefs: const ['D1'],
            provenance: 'doctrine:D1.officialDefinition',
          ),
        ],
      );
      expect(DoctrineSection.fromJson(section.toJson()), section);
    });
  });

  group('C. product behavior', () {
    final identity = DoctrineSection(
      type: DoctrineSectionType.identity,
      title: 'Doctrine Identity',
      statements: [
        DoctrineStatement(
          label: 'Doctrine ID',
          text: 'D1',
          sourceRefs: const ['D1'],
          provenance: 'doctrine:D1.doctrineId',
        ),
      ],
    );

    test('sectionOf / hasSection reflect presence and absence', () {
      final product = DoctrineKnowledgeProduct(
        doctrineId: 'D1',
        doctrineName: 'Synthetic Doctrine',
        sections: [identity],
        caseExplanations: const [],
      );
      expect(product.hasSection(DoctrineSectionType.identity), isTrue);
      expect(product.sectionOf(DoctrineSectionType.identity), identity);
      expect(product.hasSection(DoctrineSectionType.overview), isFalse);
      expect(product.sectionOf(DoctrineSectionType.overview), isNull);
      expect(product.isEmpty, isFalse);
    });

    test('an empty product reports isEmpty', () {
      const product = DoctrineKnowledgeProduct(
        doctrineId: 'D1',
        doctrineName: 'Synthetic Doctrine',
        sections: [],
        caseExplanations: [],
      );
      expect(product.isEmpty, isTrue);
    });

    test('equality is structural across sections and explanations', () {
      final a = DoctrineKnowledgeProduct(
        doctrineId: 'D1',
        doctrineName: 'Synthetic Doctrine',
        sections: [identity],
        caseExplanations: const [],
      );
      final b = DoctrineKnowledgeProduct(
        doctrineId: 'D1',
        doctrineName: 'Synthetic Doctrine',
        sections: [identity],
        caseExplanations: const [],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('equality differs when sections differ', () {
      const a = DoctrineKnowledgeProduct(
        doctrineId: 'D1',
        doctrineName: 'Synthetic Doctrine',
        sections: [],
        caseExplanations: [],
      );
      final b = DoctrineKnowledgeProduct(
        doctrineId: 'D1',
        doctrineName: 'Synthetic Doctrine',
        sections: [identity],
        caseExplanations: const [],
      );
      expect(a, isNot(b));
    });

    test('referencedIds are unique and sorted across sections', () {
      final product = DoctrineKnowledgeProduct(
        doctrineId: 'D1',
        doctrineName: 'Synthetic Doctrine',
        sections: [
          identity,
          DoctrineSection(
            type: DoctrineSectionType.constituentCases,
            title: 'Constituent Cases',
            statements: [
              DoctrineStatement(
                label: 'Constituent case 1',
                text: 'a',
                sourceRefs: const ['ALPHA', 'e:ALPHA|followed|BETA'],
                provenance: 'doctrine:D1.originatingCase',
              ),
            ],
          ),
        ],
        caseExplanations: const [],
      );
      expect(product.referencedIds, ['ALPHA', 'D1', 'e:ALPHA|followed|BETA']);
    });

    test('serialization round-trips the full product', () {
      final product = DoctrineKnowledgeProduct(
        doctrineId: 'D1',
        doctrineName: 'Synthetic Doctrine',
        sections: [identity],
        caseExplanations: [
          CaseExplanation(
            caseId: 'ALPHA',
            caseName: 'Alpha v. State',
            sections: [
              ExplanationSection(
                type: ExplanationSectionType.identity,
                title: 'Case Identity',
                statements: [
                  ExplanationStatement(
                    label: 'Case ID',
                    text: 'ALPHA',
                    sourceRefs: const ['ALPHA'],
                    provenance: 'corpus:caseId',
                  ),
                ],
              ),
            ],
          ),
        ],
      );
      final restored = DoctrineKnowledgeProduct.fromJson(product.toJson());
      expect(restored, product);
      expect(restored.caseExplanations.single.caseId, 'ALPHA');
    });
  });
}
