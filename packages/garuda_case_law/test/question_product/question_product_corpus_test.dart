import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

/// P15 — corpus-wide verification over the canonical production corpus
/// (TITAN-KO-015.0 P15).
///
/// Runs the question layer over every eligible case/doctrine/provision/topic in
/// the real corpus and pins the invariants: every product is non-empty, every
/// question carries non-empty provenance/evidence and the educational framing,
/// every referenced case ID resolves to a validated corpus case, nothing is
/// fabricated, and output for each supported source kind is byte-identical
/// across two independent service instances.
///
/// `buildAll` over the canonical corpus is heavy (it composes every P11–P14
/// product), so the product set is built ONCE and reused for the invariant
/// groups; determinism is verified on a representative product per source kind.
void main() {
  final svc = QuestionKnowledgeProductService();
  final corpusIds = {for (final c in svc.cases) c.caseId};
  final all = svc.buildAll();

  group('A. corpus-wide completeness', () {
    test('buildAll produces products for every supported source kind', () {
      expect(all, isNotEmpty);
      final kinds = all.map((p) => p.sourceType).toSet();
      expect(kinds, {
        QuestionSourceType.caseLaw,
        QuestionSourceType.doctrine,
        QuestionSourceType.statute,
        QuestionSourceType.topic,
      });
    });

    test('every product is non-empty with a stable product ID', () {
      for (final p in all) {
        expect(p.questions, isNotEmpty, reason: 'empty product ${p.productId}');
        expect(p.productId, startsWith('qa:'));
        expect(p.sourceId.trim(), isNotEmpty);
      }
    });
  });

  group('B. evidence & provenance invariants', () {
    test('every question carries provenance, evidence and framing', () {
      for (final p in all) {
        for (final q in p.questions) {
          expect(q.provenance.trim(), isNotEmpty,
              reason: '${q.questionId} provenance');
          expect(q.sourceRefs, isNotEmpty,
              reason: '${q.questionId} sourceRefs');
          expect(q.answer.evidenceRefs, isNotEmpty,
              reason: '${q.questionId} evidence');
          expect(q.answer.provenance.trim(), isNotEmpty,
              reason: '${q.questionId} answer provenance');
          expect(q.framing, contains('not legal advice'));
        }
      }
    });
  });

  group('C. no invalid or fabricated case IDs', () {
    test('every referenced case ID resolves to a validated corpus case', () {
      for (final p in all) {
        for (final id in svc.referencedCaseIds(p)) {
          expect(corpusIds, contains(id),
              reason: 'invalid case id $id in ${p.productId}');
        }
      }
    });

    test('related cases on case products resolve to corpus cases', () {
      for (final p in all) {
        for (final q in p.questions) {
          for (final id in q.answer.relatedCaseIds) {
            expect(corpusIds, contains(id),
                reason: 'invalid related case $id in ${q.questionId}');
          }
        }
      }
    });
  });

  group('D. legal safety across the corpus', () {
    test('no unsupported "the law is" or advice framing anywhere', () {
      for (final p in all) {
        for (final q in p.questions) {
          final lower =
              '${q.questionText} ${q.answer.answerText}'.toLowerCase();
          expect(lower, isNot(contains('the law is')));
          expect(lower, isNot(contains('you should')));
          expect(lower, isNot(contains('your case')));
        }
      }
    });
  });

  group('E. corpus-wide determinism', () {
    String bytesOf(QuestionKnowledgeProduct? p) =>
        p == null ? 'null' : jsonEncode(p.toJson());

    test('representative products are byte-identical across instances', () {
      final a = QuestionKnowledgeProductService();
      final b = QuestionKnowledgeProductService();

      final caseA = a.buildForCase(a.cases.first.caseId);
      final caseB = b.buildForCase(b.cases.first.caseId);
      expect(bytesOf(caseA), bytesOf(caseB));

      final docA =
          a.buildForDoctrine(a.doctrineProductService.doctrineIds.first);
      final docB =
          b.buildForDoctrine(b.doctrineProductService.doctrineIds.first);
      expect(bytesOf(docA), bytesOf(docB));

      final statuteKey =
          a.statuteProductService.provisionIds(ProvisionType.article).first;
      final statA = a.buildForStatute(ProvisionType.article, statuteKey);
      final statB = b.buildForStatute(ProvisionType.article, statuteKey);
      expect(bytesOf(statA), bytesOf(statB));

      final topicId = a.topicProductService.topics.first.id;
      final topA = a.buildForTopic(topicId);
      final topB = b.buildForTopic(topicId);
      expect(bytesOf(topA), bytesOf(topB));
    });
  });
}
