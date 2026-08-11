import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P15 — answer-composition tests (TITAN-KO-015.0 P15).
///
/// Answers are composed ONLY from already-validated P4/P11–P14 information.
/// This suite pins that answer content traces to the validated source, that
/// evidence references and provenance are preserved, that relevant principles
/// are surfaced only when the source explicitly provides them, and that related
/// cases come ONLY from explicit P5 `related` edges (never labelled "similar",
/// never inferred).
void main() {
  final svc = buildSyntheticQaService();

  group('A. issue answers come from validated P4 issues', () {
    test('answer text is the verbatim P4 issue, with source refs + provenance',
        () {
      final p = svc.buildForCase('ALPHA')!;
      final q = p.questions
          .firstWhere((q) => q.questionType == LegalQuestionType.issue);
      expect(
          q.answer.answerText, 'Whether the state action violates Article 21.');
      expect(q.answer.evidenceRefs, contains('ALPHA'));
      expect(q.answer.evidenceRefs, contains('iss_alpha_1'));
      expect(q.answer.provenance, 'p4:issues');
      expect(q.sourceRefs, contains('iss_alpha_1'));
    });
  });

  group('B. principle answers come from validated P4 legal principles', () {
    test('answer text is the legal principle; holding text is context', () {
      final p = svc.buildForCase('ALPHA')!;
      final q = p.questions
          .firstWhere((q) => q.questionType == LegalQuestionType.principle);
      expect(q.answer.answerText,
          'Procedural fairness is essential to a valid restriction.');
      // The holding text is surfaced as relevant context, verbatim.
      expect(q.answer.principles,
          ['The court held that procedural fairness is essential.']);
      expect(q.answer.provenance, 'p4:holdings.legalPrinciple');
      expect(q.answer.evidenceRefs,
          contains(CaseOfficialSources.evidenceIdFor('ALPHA')));
    });
  });

  group('C. doctrine answers come from the P12 product', () {
    test('definition answer is the recorded doctrine one-line summary', () {
      final p = svc.buildForDoctrine('SYNTH_DOCTRINE')!;
      final def =
          p.questions.firstWhere((q) => q.questionId.endsWith(':definition'));
      expect(def.answer.answerText,
          'Synthetic one-line summary of Synthetic Doctrine.');
      expect(def.answer.evidenceRefs, ['SYNTH_DOCTRINE']);
      expect(def.answer.provenance, 'p12:DoctrineKnowledgeProduct.overview');
    });

    test('constituent-cases answer lists only validated P5 member cases', () {
      final p = svc.buildForDoctrine('SYNTH_DOCTRINE')!;
      final cases = p.questions
          .firstWhere((q) => q.questionId.endsWith(':constituent-cases'));
      expect(cases.answer.answerText, contains('Alpha v. State'));
      expect(cases.answer.answerText, contains('Beta v. Union'));
      // Evidence refs carry the doctrine id and the member case ids.
      expect(cases.answer.evidenceRefs, contains('SYNTH_DOCTRINE'));
      expect(cases.answer.evidenceRefs, contains('ALPHA'));
      expect(cases.answer.evidenceRefs, contains('BETA'));
    });
  });

  group('D. statute answers come from the P13 product', () {
    test('kind answer is the provision type display title', () {
      final p = svc.buildForStatute(ProvisionType.article, 'Article 21')!;
      final kind =
          p.questions.firstWhere((q) => q.questionId.endsWith(':kind'));
      expect(kind.answer.answerText, 'Constitutional Article');
      expect(kind.answer.provenance, 'p13:StatuteKnowledgeProduct.identity');
    });

    test(
        'associated-cases answer lists only cases that reference the provision',
        () {
      final p = svc.buildForStatute(ProvisionType.article, 'Article 21')!;
      final assoc = p.questions
          .firstWhere((q) => q.questionId.endsWith(':associated-cases'));
      expect(assoc.answer.answerText, contains('Alpha v. State'));
      expect(assoc.answer.evidenceRefs, contains('ALPHA'));
    });
  });

  group('E. topic answers come from the P14 product', () {
    test('overview answer is the P14 editorial overview', () {
      final p = svc.buildForTopic('topic_alpha')!;
      final overview =
          p.questions.firstWhere((q) => q.questionId.endsWith(':overview'));
      expect(overview.answer.answerText, 'Synthetic overview of topic alpha.');
      expect(overview.answer.provenance, 'p14:syllabusConfig.overview');
    });

    test('member-cases answer lists explicit P14 members', () {
      final p = svc.buildForTopic('topic_alpha')!;
      final members =
          p.questions.firstWhere((q) => q.questionId.endsWith(':member-cases'));
      expect(members.answer.answerText, contains('Alpha v. State'));
      expect(members.answer.answerText, contains('Beta v. Union'));
      expect(members.answer.provenance, 'p14:membership');
    });
  });

  group('F. related cases come ONLY from explicit P5 edges', () {
    test('BETA lists ALPHA as a P5 related case (explicit related edge)', () {
      final p = svc.buildForCase('BETA')!;
      for (final q in p.questions) {
        expect(q.answer.relatedCaseIds, contains('ALPHA'));
      }
    });

    test('ALPHA lists BETA as a P5 related case (reciprocal edge)', () {
      final p = svc.buildForCase('ALPHA')!;
      for (final q in p.questions) {
        expect(q.answer.relatedCaseIds, contains('BETA'));
      }
    });

    test('a case with no P5 related edges has an empty related-case list', () {
      final p = svc.buildForCase('GAMMA')!;
      for (final q in p.questions) {
        expect(q.answer.relatedCaseIds, isEmpty);
      }
    });

    test('related cases are never described as "similar"', () {
      final p = svc.buildForCase('BETA')!;
      for (final q in p.questions) {
        expect(q.questionText.toLowerCase(), isNot(contains('similar')));
        expect(q.answer.answerText.toLowerCase(), isNot(contains('similar')));
      }
    });
  });

  group('G. every answer carries non-empty evidence & provenance', () {
    test('across the whole synthetic product set', () {
      for (final p in svc.buildAll()) {
        expect(p.questions, isNotEmpty, reason: 'empty product $p');
        for (final q in p.questions) {
          expect(q.answer.evidenceRefs, isNotEmpty,
              reason: '${q.questionId} has no evidence');
          expect(q.answer.provenance.trim(), isNotEmpty,
              reason: '${q.questionId} has no provenance');
          expect(q.provenance.trim(), isNotEmpty,
              reason: '${q.questionId} has no question provenance');
        }
      }
    });
  });
}
