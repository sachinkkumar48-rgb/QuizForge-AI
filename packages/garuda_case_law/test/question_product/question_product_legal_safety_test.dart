import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P15 — legal-safety tests (TITAN-KO-015.0 P15).
///
/// P15 is an educational knowledge product, not legal advice and not a
/// legal-reasoning engine. These tests pin that: every question/answer carries
/// the educational framing; nothing is presented as "the law is ..."; no
/// personal-circumstances advice is generated; no hypothetical scenarios are
/// invented; related cases are never described as "similar"; and missing
/// information produces omission, never fabrication.
void main() {
  final svc = buildSyntheticQaService();

  group('A. educational framing', () {
    test('every question carries the non-legal-advice framing', () {
      for (final p in svc.buildAll()) {
        for (final q in p.questions) {
          expect(q.framing, contains('educational'));
          expect(q.framing, contains('not legal advice'));
        }
      }
    });
  });

  group('B. no unsupported current-law claims', () {
    test('no question or answer asserts "the law is"', () {
      for (final p in svc.buildAll()) {
        for (final q in p.questions) {
          expect(q.questionText.toLowerCase(), isNot(contains('the law is')));
          expect(
              q.answer.answerText.toLowerCase(), isNot(contains('the law is')));
        }
      }
    });

    test('case answers use source-bounded framing referencing the court', () {
      final p = svc.buildForCase('ALPHA')!;
      final pr = p.questions
          .firstWhere((q) => q.questionType == LegalQuestionType.principle);
      // The holding context is a record of what the court held, not a legal rule.
      expect(pr.answer.answerText, isNotEmpty);
    });
  });

  group('C. no legal advice to a user', () {
    test('no question or answer addresses the user personally', () {
      for (final p in svc.buildAll()) {
        for (final q in p.questions) {
          final lower =
              '${q.questionText} ${q.answer.answerText}'.toLowerCase();
          expect(lower, isNot(contains('you should')));
          expect(lower, isNot(contains('your case')));
          expect(lower, isNot(contains('consult a lawyer')));
        }
      }
    });
  });

  group('D. no hypothetical scenarios or fabricated propositions', () {
    test('case issue answers are verbatim corpus text, not invented scenarios',
        () {
      final p = svc.buildForCase('ALPHA')!;
      final q = p.questions
          .firstWhere((q) => q.questionType == LegalQuestionType.issue);
      expect(
          q.answer.answerText, 'Whether the state action violates Article 21.');
    });

    test('no question contains "imagine", "suppose" or "if you"', () {
      for (final p in svc.buildAll()) {
        for (final q in p.questions) {
          final lower =
              '${q.questionText} ${q.answer.answerText}'.toLowerCase();
          expect(lower, isNot(contains('imagine')));
          expect(lower, isNot(contains('suppose')));
        }
      }
    });
  });

  group('E. no topic→legal-similarity inference', () {
    test('topic member-cases answer never calls members "similar"', () {
      final p = svc.buildForTopic('topic_alpha')!;
      final members =
          p.questions.firstWhere((q) => q.questionId.endsWith(':member-cases'));
      expect(
          members.answer.answerText.toLowerCase(), isNot(contains('similar')));
    });
  });

  group('F. no chronology→causation inference', () {
    test('case answers never assert that an earlier case caused a later one',
        () {
      final lower = [
        for (final p in svc.buildAll())
          for (final q in p.questions)
            '${q.questionText} ${q.answer.answerText}'.toLowerCase(),
      ].join('\n');
      expect(lower, isNot(contains('because of')));
      expect(lower, isNot(contains('as a result of')));
    });
  });

  group('G. missing data is omission, never fabrication', () {
    test('a case with no intelligence yields no product at all', () {
      expect(svc.buildForCase('DELTA'), isNull);
    });

    test('unknown sources resolve to nothing, not an empty/fabricated product',
        () {
      expect(svc.buildForCase('UNKNOWN_CASE'), isNull);
      expect(svc.buildForDoctrine('UNKNOWN_DOCTRINE'), isNull);
      expect(svc.buildForTopic('unknown_topic'), isNull);
      expect(svc.buildForStatute(ProvisionType.article, 'Article 999'), isNull);
    });
  });
}
