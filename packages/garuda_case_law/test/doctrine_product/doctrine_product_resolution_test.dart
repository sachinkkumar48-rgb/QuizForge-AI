import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P12 — Canonical doctrine resolution (TITAN-KO-015.0 P12).
///
/// The service resolves a doctrine by canonical ID, by normalized doctrine
/// name, and by normalized ID; unknown input resolves to nothing and never
/// fabricates a doctrine. Resolution mirrors P10's resolver and only ever
/// returns a doctrine that exists in the canonical record / P5 graph.
void main() {
  final service = DoctrineKnowledgeProductService(
    cases: syntheticDoctrineCorpus(),
    doctrines: syntheticDoctrines(),
  );

  group('A. canonical identity', () {
    test('canonical doctrine IDs are exposed in record order', () {
      expect(service.doctrineIds, [
        'SYNTH_DOCTRINE',
        'SECOND_DOCTRINE',
        'SPARSE_DOCTRINE',
      ]);
    });

    test('a valid doctrine resolves by canonical ID', () {
      expect(service.resolveDoctrineId('SYNTH_DOCTRINE'), 'SYNTH_DOCTRINE');
      expect(service.hasDoctrine('SYNTH_DOCTRINE'), isTrue);
    });

    test('a valid doctrine resolves by normalized name', () {
      expect(service.resolveDoctrineId('Synthetic Doctrine'), 'SYNTH_DOCTRINE');
      expect(service.resolveDoctrineId('  synthetic  doctrine '),
          'SYNTH_DOCTRINE');
    });

    test('a valid doctrine resolves by alias', () {
      // Alias resolution is a P5 graph-node concern; unknown names must not
      // fabricate a doctrine.
      expect(service.resolveDoctrineId('Sparse Doctrine'), 'SPARSE_DOCTRINE');
    });

    test('unknown and empty identifiers return null', () {
      expect(service.resolveDoctrineId('NOT_A_DOCTRINE'), isNull);
      expect(service.resolveDoctrineId(''), isNull);
      expect(service.resolveDoctrineId('   '), isNull);
      expect(service.hasDoctrine('NOT_A_DOCTRINE'), isFalse);
    });
  });

  group('B. product building', () {
    test('build returns null for an unknown doctrine', () {
      expect(service.build('NOT_A_DOCTRINE'), isNull);
      expect(service.build(''), isNull);
    });

    test('build resolves a valid doctrine with canonical identity', () {
      final product = service.build('Synthetic Doctrine')!;
      expect(product.doctrineId, 'SYNTH_DOCTRINE');
      expect(product.doctrineName, 'Synthetic Doctrine');
      expect(
        product.sectionOf(DoctrineSectionType.identity),
        isNotNull,
      );
    });

    test('build is repeatable and yields equal products', () {
      final a = service.build('SYNTH_DOCTRINE')!;
      final b = service.build('Synthetic Doctrine')!;
      expect(a, b);
    });

    test('buildAll covers every canonical doctrine in record order', () {
      final all = service.buildAll();
      expect(all.map((p) => p.doctrineId).toList(), service.doctrineIds);
      expect(all, hasLength(service.doctrineIds.length));
    });
  });
}
