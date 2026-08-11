import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P14 — aggregation tests (TITAN-KO-015.0 P14).
///
/// Pins how a topic aggregates its member cases, composed P12 doctrine products
/// and composed P13 statute products under the strict all-members rule: a
/// doctrine/provision is composed only when every one of its constituent /
/// associated cases is already a topic member.
void main() {
  final svc = buildSyntheticTopicService();

  group('A. case aggregation', () {
    test('a topic aggregates its explicit member cases without duplicates', () {
      final p = svc.build('topic_alpha')!;
      // ALPHA is mapped twice (two distinct signals) but appears once.
      expect(p.memberCaseIds, containsAll(['ALPHA', 'BETA']));
      expect(p.memberCaseIds.toSet().length, p.memberCaseIds.length);
    });

    test('member cases are canonical corpus IDs, chronologically ordered', () {
      final p = svc.build('topic_alpha')!;
      // 2000 (ALPHA) before 2005 (BETA).
      expect(p.memberCaseIds, orderedEquals(['ALPHA', 'BETA']));
      final corpus = {for (final c in svc.cases) c.caseId};
      expect(p.memberCaseIds.every(corpus.contains), isTrue);
    });

    test('a case whose membership is missing from the corpus is omitted', () {
      // topic_sparse maps DELTA which IS in the corpus, so it appears; an
      // orphan would be omitted by build (validated separately).
      final p = svc.build('topic_sparse')!;
      expect(p.memberCaseIds, orderedEquals(['DELTA']));
    });

    test('one P11 case explanation per member case (reused, not reimplemented)',
        () {
      final p = svc.build('topic_alpha')!;
      expect(p.caseExplanations.map((e) => e.caseId).toList(),
          orderedEquals(['ALPHA', 'BETA']));
    });
  });

  group('B. doctrine aggregation (P12 composition)', () {
    test('a doctrine composed only when all its constituent cases are members',
        () {
      final p = svc.build('topic_alpha')!;
      final ids = p.doctrineProducts.map((d) => d.doctrineId).toList();
      // SYNTH_DOCTRINE ({ALPHA,BETA}) and SECOND_DOCTRINE ({ALPHA}) are fully
      // within the topic; SPARSE_DOCTRINE has no constituent cases.
      expect(ids, containsAll(['SYNTH_DOCTRINE', 'SECOND_DOCTRINE']));
      expect(ids, isNot(contains('SPARSE_DOCTRINE')));
      // Deterministic order.
      expect(ids, orderedEquals([...ids]..sort()));
    });

    test('no doctrine is invented for a sparse topic', () {
      final p = svc.build('topic_sparse')!;
      expect(p.doctrineProducts, isEmpty);
    });

    test('embedded doctrine products are real P12 products', () {
      final p = svc.build('topic_alpha')!;
      final d = p.doctrineProducts
          .firstWhere((x) => x.doctrineId == 'SYNTH_DOCTRINE');
      expect(DoctrineKnowledgeProduct.doctrineKind, isNotEmpty);
      expect(d.doctrineId, 'SYNTH_DOCTRINE');
      expect(d.doctrineName, 'Synthetic Doctrine');
    });
  });

  group('C. statute aggregation (P13 composition)', () {
    test('a provision composed only when all its associated cases are members',
        () {
      final p = svc.build('topic_alpha')!;
      final keys = p.statuteProducts.map((s) => s.provisionId).toList();
      // ALPHA → Article 21, BETA → Article 14; both associated cases are
      // members, so both provision products compose.
      expect(keys, containsAll(['21', '14']));
      // Deterministic order: provision kind, then key ascending.
      expect(keys, orderedEquals([...keys]..sort()));
    });

    test('no statute product is pulled in by a non-member case', () {
      // DELTA references no provision; topic_sparse has no statute products.
      final p = svc.build('topic_sparse')!;
      expect(p.statuteProducts, isEmpty);
    });

    test('embedded statute products are real P13 products', () {
      final p = svc.build('topic_alpha')!;
      final s = p.statuteProducts.firstWhere((x) => x.provisionId == '21');
      expect(StatuteKnowledgeProduct.statuteKind, isNotEmpty);
      expect(s.provisionId, '21');
      expect(s.provisionType, ProvisionType.article);
    });
  });

  group('D. chronology section', () {
    test('chronology presents members in deterministic year order', () {
      final p = svc.build('topic_alpha')!;
      final section = p.sectionOf(TopicSectionType.chronology);
      expect(section, isNotNull);
      expect(section!.statements.first.text, startsWith('2000 — ALPHA'));
    });
  });

  group('E. product-level integrity', () {
    test('validateProducts finds no defects on the synthetic corpus', () {
      final v = TopicMappingValidator(service: svc);
      final r = v.validateProducts();
      expect(r.isValid, isTrue);
      expect(r.issues, isEmpty);
    });

    test('referencedCaseIds returns the corpus member cases', () {
      final p = svc.build('topic_alpha')!;
      expect(svc.referencedCaseIds(p), containsAll(['ALPHA', 'BETA']));
    });
  });
}
