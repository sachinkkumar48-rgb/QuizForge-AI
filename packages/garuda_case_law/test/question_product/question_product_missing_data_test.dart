import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P15 — missing-data handling tests (TITAN-KO-015.0 P15).
///
/// Missing or incomplete source information is represented by an OMITTED
/// question, never by fabricated content. These tests cover: a case with no P4
/// intelligence, a disconnected case, a doctrine with no resolvable cases, a
/// provision with no recorded overview, a topic whose member lacks intelligence,
/// an incomplete explanation (holding without a principle), and empty optional
/// sections.
void main() {
  final svc = buildSyntheticQaService();

  group('A. sparse case (no P4 intelligence)', () {
    test('a case with no intelligence yields no product', () {
      expect(svc.buildForCase('DELTA'), isNull);
    });

    test('buildAll omits the sparse case entirely', () {
      final all = svc.buildAll();
      expect(all.where((p) => p.sourceId == 'DELTA'), isEmpty);
      expect(all.map((p) => p.sourceId).contains('ALPHA'), isTrue);
    });
  });

  group('B. disconnected case', () {
    test('a case with no P5 related edges still yields questions', () {
      final p = svc.buildForCase('GAMMA')!;
      expect(p.questions, isNotEmpty);
      for (final q in p.questions) {
        expect(q.answer.relatedCaseIds, isEmpty);
      }
    });
  });

  group('C. incomplete explanation (holding without a principle)', () {
    test('GAMMA keeps its issue question but drops the unprincipled holding',
        () {
      final p = svc.buildForCase('GAMMA')!;
      final types = p.questions.map((q) => q.questionType).toList();
      expect(types, [LegalQuestionType.issue]);
      expect(types, isNot(contains(LegalQuestionType.principle)));
    });
  });

  group('D. missing doctrine content', () {
    test('a doctrine with no resolvable cases yields only the definition', () {
      final p = svc.buildForDoctrine('SPARSE_DOCTRINE')!;
      expect(
        p.questions.any((q) => q.questionId.endsWith(':definition')),
        isTrue,
      );
      expect(
        p.questions.any((q) => q.questionId.endsWith(':constituent-cases')),
        isFalse,
      );
    });
  });

  group('E. missing statute content', () {
    test('a provision with no recorded overview yields kind but no definition',
        () {
      // GAMMA references an Act absent from the canonical acts corpus, so the
      // P13 product has no official-overview section.
      final p = svc.buildForStatute(
          ProvisionType.act, 'Reasonable Restrictions Act, 2000')!;
      expect(p.questions.any((q) => q.questionId.endsWith(':kind')), isTrue);
      expect(
        p.questions.any((q) => q.questionId.endsWith(':definition')),
        isFalse,
      );
    });
  });

  group('F. missing topic content', () {
    test('a topic whose member lacks intelligence still lists that member', () {
      // DELTA has no intelligence but is an explicit member of topic_sparse.
      final p = svc.buildForTopic('topic_sparse')!;
      final members =
          p.questions.firstWhere((q) => q.questionId.endsWith(':member-cases'));
      expect(members.answer.answerText, contains('Delta v. Authority'));
    });
  });

  group('G. empty optional sections', () {
    test('a doctrine with all content yields both definition and cases', () {
      final p = svc.buildForDoctrine('SYNTH_DOCTRINE')!;
      expect(
        p.questions.any((q) => q.questionId.endsWith(':definition')),
        isTrue,
      );
      expect(
        p.questions.any((q) => q.questionId.endsWith(':constituent-cases')),
        isTrue,
      );
    });
  });
}
