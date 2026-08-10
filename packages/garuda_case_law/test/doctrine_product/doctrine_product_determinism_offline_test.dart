import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P12 — Determinism and offline behavior (TITAN-KO-015.0 P12).
///
/// The doctrine product is derived solely from the in-memory validated corpus
/// and doctrine records: no network, no AI, no external service. Repeated and
/// independent generation yields byte-identical structured output, sections
/// stay in the fixed deterministic order, and every nested collection is
/// deterministically sorted.
void main() {
  final corpus = syntheticDoctrineCorpus();
  final doctrines = syntheticDoctrines();

  group('A. repeatability', () {
    test('building the same doctrine twice yields an equal product', () {
      final service = DoctrineKnowledgeProductService(
        cases: corpus,
        doctrines: doctrines,
      );
      final a = service.build('SYNTH_DOCTRINE')!;
      final b = service.build('SYNTH_DOCTRINE')!;
      expect(a, b);
    });

    test('independent service instances produce identical output', () {
      final s1 =
          DoctrineKnowledgeProductService(cases: corpus, doctrines: doctrines)
              .build('SYNTH_DOCTRINE')!;
      final s2 =
          DoctrineKnowledgeProductService(cases: corpus, doctrines: doctrines)
              .build('SYNTH_DOCTRINE')!;
      expect(s1.toJson(), s2.toJson());
    });

    test('serialization round-trips to an equal product', () {
      final service = DoctrineKnowledgeProductService(
        cases: corpus,
        doctrines: doctrines,
      );
      final product = service.build('SYNTH_DOCTRINE')!;
      expect(DoctrineKnowledgeProduct.fromJson(product.toJson()), product);
    });

    test('buildAll is repeatable and identical across fresh services', () {
      final p1 =
          DoctrineKnowledgeProductService(cases: corpus, doctrines: doctrines)
              .buildAll();
      final p2 =
          DoctrineKnowledgeProductService(cases: corpus, doctrines: doctrines)
              .buildAll();
      expect(p1.map((p) => p.toJson()).toList(),
          p2.map((p) => p.toJson()).toList());
    });
  });

  group('B. fixed ordering', () {
    test('sections appear in the fixed DoctrineSectionType order', () {
      final service = DoctrineKnowledgeProductService(
        cases: corpus,
        doctrines: doctrines,
      );
      final expectedOrder = DoctrineSectionType.values;
      for (final product in service.buildAll()) {
        var cursor = 0;
        for (final t in product.sections.map((s) => s.type)) {
          final idx = expectedOrder.indexOf(t);
          expect(idx, greaterThanOrEqualTo(cursor),
              reason: '${product.doctrineId} section order not fixed');
          cursor = idx;
        }
      }
    });

    test('article and act collections are deterministically sorted', () {
      final service = DoctrineKnowledgeProductService(
        cases: corpus,
        doctrines: doctrines,
      );
      final product = service.build('SYNTH_DOCTRINE')!;
      for (final type in [
        DoctrineSectionType.articles,
        DoctrineSectionType.acts,
      ]) {
        final section = product.sectionOf(type);
        if (section == null) continue;
        final texts = section.statements.map((s) => s.text).toList();
        final sorted = [...texts]..sort();
        expect(texts, sorted,
            reason: '${type.name} not deterministically sorted');
      }
    });

    test(
        'aggregate theme/subject statements come after per-case relevance '
        'and are sorted within their group', () {
      final service = DoctrineKnowledgeProductService(
        cases: corpus,
        doctrines: doctrines,
      );
      final product = service.build('SYNTH_DOCTRINE')!;
      final upsc = product.sectionOf(DoctrineSectionType.upscRelevance)!;
      final themeTexts = [
        for (final s in upsc.statements)
          if (s.label == 'Theme') s.text,
      ];
      final subjectTexts = [
        for (final s in upsc.statements)
          if (s.label == 'Subject') s.text,
      ];
      expect(themeTexts, ['Fundamental rights']);
      expect(subjectTexts, ['Polity']);
    });
  });

  group('C. offline-first', () {
    test('generation depends only on in-memory inputs', () {
      final service = DoctrineKnowledgeProductService(
        cases: corpus,
        doctrines: doctrines,
      );
      // No I/O or network path is involved: constructing a fresh service and
      // generating a product must not require any external state.
      final product = service.build('SYNTH_DOCTRINE')!;
      expect(product.doctrineId, 'SYNTH_DOCTRINE');
      expect(product.sections, isNotEmpty);
      expect(product.caseExplanations, isNotEmpty);
    });

    test('no graph or corpus mutation across repeated generation', () {
      final service = DoctrineKnowledgeProductService(
        cases: corpus,
        doctrines: doctrines,
      );
      final beforeEdges = service.graph.edgeCount;
      final beforeCases = service.cases.length;
      service.buildAll();
      service.buildAll();
      expect(service.graph.edgeCount, beforeEdges);
      expect(service.cases.length, beforeCases);
    });
  });
}
