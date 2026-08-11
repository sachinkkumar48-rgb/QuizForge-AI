import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P13 — Determinism and offline behavior (TITAN-KO-015.0 P13).
///
/// The statute product is derived solely from the in-memory validated corpus
/// and canonical constitution/acts/doctrine records: no network, no AI, no
/// external service. Repeated and independent generation yields byte-identical
/// structured output, sections stay in the fixed deterministic order, and every
/// nested collection is deterministically sorted.
void main() {
  final corpus = syntheticStatuteCorpus();
  final constitution = syntheticConstitutionArticles();
  final acts = syntheticActs();
  final doctrines = syntheticDoctrines();

  group('A. repeatability', () {
    test('building the same provision twice yields an equal product', () {
      final service = syntheticService();
      final a = service.build(ProvisionType.article, 'Article 21')!;
      final b = service.build(ProvisionType.article, 'Article 21')!;
      expect(a, b);
    });

    test('independent service instances produce identical output', () {
      final s1 = syntheticService().build(ProvisionType.article, 'Article 21')!;
      final s2 = syntheticService().build(ProvisionType.article, 'Article 21')!;
      expect(s1.toJson(), s2.toJson());
    });

    test('serialization round-trips to an equal product', () {
      final service = syntheticService();
      final product = service.build(ProvisionType.article, 'Article 21')!;
      expect(StatuteKnowledgeProduct.fromJson(product.toJson()), product);
    });

    test('buildAll is repeatable and identical across fresh services', () {
      final p1 = syntheticService().buildAll();
      final p2 = syntheticService().buildAll();
      expect(p1.length, p2.length);
      for (var i = 0; i < p1.length; i++) {
        expect(p1[i].toJson(), p2[i].toJson());
      }
    });
  });

  group('B. deterministic ordering', () {
    test('sections appear in the fixed enum order', () {
      for (final product in syntheticService().buildAll()) {
        final expected = [
          for (final t in StatuteSectionType.values)
            if (product.hasSection(t)) t,
        ];
        final actual = [for (final s in product.sections) s.type];
        expect(actual, expected);
      }
    });

    test('raw references are sorted and unique', () {
      for (final product in syntheticService().buildAll()) {
        expect(product.rawReferences,
            orderedEquals([...product.rawReferences]..sort()));
        expect(
            product.rawReferences.toSet().length, product.rawReferences.length);
      }
    });

    test('section references are sorted', () {
      for (final product in syntheticService().buildAll()) {
        for (final section in product.sections) {
          expect(section.references,
              orderedEquals([...section.references]..sort()));
        }
      }
    });

    test('independent construction over fresh synthetic corpora is stable', () {
      final a = StatuteKnowledgeProductService(
        cases: corpus,
        constitutionArticles: constitution,
        acts: acts,
        doctrines: doctrines,
      ).buildAll();
      final b = StatuteKnowledgeProductService(
        cases: corpus,
        constitutionArticles: constitution,
        acts: acts,
        doctrines: doctrines,
      ).buildAll();
      expect(
          a.map((p) => p.toJson()).toList(), b.map((p) => p.toJson()).toList());
    });
  });

  group('C. offline', () {
    test('the service depends only on in-memory corpora', () {
      final service = syntheticService();
      final p = service.build(ProvisionType.article, 'Article 21')!;
      expect(p.sections, isNotEmpty);
      expect(p.caseExplanations, isNotEmpty);
    });

    test('default construction is offline-first (no IO)', () {
      final service = StatuteKnowledgeProductService();
      expect(service.cases, isNotEmpty);
      expect(service.buildAll(), isNotEmpty);
    });
  });
}
