import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P15 — deterministic question-generation tests (TITAN-KO-015.0 P15).
///
/// Every supported question type (issue, principle, doctrine, statute, topic)
/// is generated deterministically from explicit validated source data, is
/// unique, carries stable IDs and non-empty provenance, and never fabricates
/// content. Ordering is fixed and duplicates are eliminated.
void main() {
  final svc = buildSyntheticQaService();

  group('A. issue-based generation (P4)', () {
    test('ALPHA yields two issue questions with stable IDs and wording', () {
      final p = svc.buildForCase('ALPHA')!;
      final issues = p.questions
          .where((q) => q.questionType == LegalQuestionType.issue)
          .toList();
      expect(issues.length, 2);
      expect(issues[0].questionId, 'qa:case:ALPHA:issue:0');
      expect(issues[1].questionId, 'qa:case:ALPHA:issue:1');
      expect(
          issues[0].questionText,
          'In Alpha v. State (2000), what legal issue did the Court consider? '
          '(1 of 2)');
      expect(
          issues[1].questionText,
          'In Alpha v. State (2000), what legal issue did the Court consider? '
          '(2 of 2)');
    });

    test('a single-issue case omits the ordinal disambiguator', () {
      final p = svc.buildForCase('BETA')!;
      final issues = p.questions
          .where((q) => q.questionType == LegalQuestionType.issue)
          .toList();
      expect(issues.length, 1);
      expect(issues[0].questionText,
          'In Beta v. Union (2005), what legal issue did the Court consider?');
    });

    test('issue answers are the verbatim P4 issue text', () {
      final p = svc.buildForCase('ALPHA')!;
      final q0 = p.questions
          .firstWhere((q) => q.questionType == LegalQuestionType.issue);
      expect(q0.answer.answerText,
          'Whether the state action violates Article 21.');
      expect(q0.provenance, 'p4:issues');
    });
  });

  group('B. principle-based generation (P4 legalPrinciple)', () {
    test('ALPHA yields two principle questions from explicit legal principles',
        () {
      final p = svc.buildForCase('ALPHA')!;
      final principles = p.questions
          .where((q) => q.questionType == LegalQuestionType.principle)
          .toList();
      expect(principles.length, 2);
      expect(
          principles[0].questionText,
          'In Alpha v. State (2000), what legal principle did the Court state? '
          '(1 of 2)');
      expect(principles[0].answer.answerText,
          'Procedural fairness is essential to a valid restriction.');
      expect(principles[0].provenance, 'p4:holdings.legalPrinciple');
    });

    test('principle questions reference the holding evidence id', () {
      final p = svc.buildForCase('ALPHA')!;
      final pr = p.questions
          .firstWhere((q) => q.questionType == LegalQuestionType.principle);
      expect(
        pr.answer.evidenceRefs,
        contains(CaseOfficialSources.evidenceIdFor('ALPHA')),
      );
    });

    test('a holding with an empty legal principle is omitted, never fabricated',
        () {
      // GAMMA has a holding whose legalPrinciple is empty.
      final p = svc.buildForCase('GAMMA')!;
      expect(
        p.questions.any((q) => q.questionType == LegalQuestionType.principle),
        isFalse,
      );
      expect(
        p.questions.any((q) => q.questionType == LegalQuestionType.issue),
        isTrue,
      );
    });
  });

  group('C. doctrine-based generation (P12)', () {
    test('a doctrine product yields definition and constituent-cases questions',
        () {
      final p = svc.buildForDoctrine('SYNTH_DOCTRINE')!;
      final def =
          p.questions.firstWhere((q) => q.questionId.endsWith(':definition'));
      expect(def.questionText, 'What is the doctrine Synthetic Doctrine?');
      expect(def.answer.answerText,
          'Synthetic one-line summary of Synthetic Doctrine.');
      expect(def.provenance, 'p12:DoctrineKnowledgeProduct.overview');

      final cases = p.questions
          .firstWhere((q) => q.questionId.endsWith(':constituent-cases'));
      expect(
          cases.questionText,
          'Which cases are recorded as constituent cases of the doctrine '
          'Synthetic Doctrine?');
      expect(cases.answer.answerText, contains('Alpha v. State'));
      expect(cases.answer.answerText, contains('Beta v. Union'));
    });

    test('a doctrine with no resolvable cases still yields a definition', () {
      final p = svc.buildForDoctrine('SPARSE_DOCTRINE')!;
      final types = p.questions.map((q) => q.questionType).toSet();
      expect(types, {LegalQuestionType.doctrine});
      expect(
        p.questions.any((q) => q.questionId.endsWith(':constituent-cases')),
        isFalse,
      );
      expect(
        p.questions.any((q) => q.questionId.endsWith(':definition')),
        isTrue,
      );
    });
  });

  group('D. statute-based generation (P13)', () {
    test('an article product yields kind + associated-cases questions', () {
      final p = svc.buildForStatute(ProvisionType.article, 'Article 21')!;
      final kinds =
          p.questions.where((q) => q.questionId.endsWith(':kind')).toList();
      expect(kinds.length, 1);
      expect(kinds[0].questionText, 'What kind of provision is Article 21?');
      expect(kinds[0].answer.answerText, 'Constitutional Article');

      final assoc = p.questions
          .firstWhere((q) => q.questionId.endsWith(':associated-cases'));
      expect(assoc.questionText,
          'Which validated corpus cases reference Article 21?');
      expect(assoc.answer.answerText, contains('Alpha v. State'));
    });
  });

  group('E. topic-based generation (P14)', () {
    test('a topic product yields overview + member-cases + syllabus-area', () {
      final p = svc.buildForTopic('topic_alpha')!;
      final types = p.questions.map((q) => q.questionType).toSet();
      expect(types, {LegalQuestionType.topic});

      final overview =
          p.questions.firstWhere((q) => q.questionId.endsWith(':overview'));
      expect(overview.questionText,
          'What is the topic Synthetic Topic Alpha about?');
      expect(overview.answer.answerText, 'Synthetic overview of topic alpha.');

      final members =
          p.questions.firstWhere((q) => q.questionId.endsWith(':member-cases'));
      expect(members.answer.answerText, contains('Alpha v. State'));
      expect(members.answer.answerText, contains('Beta v. Union'));

      final area = p.questions
          .firstWhere((q) => q.questionId.endsWith(':syllabus-area'));
      expect(area.answer.answerText, contains('GS'));
    });
  });

  group('F. duplicate elimination & stable ordering', () {
    test('question IDs within a product are unique', () {
      for (final source in ['ALPHA', 'BETA', 'GAMMA']) {
        final p = svc.buildForCase(source)!;
        final ids = p.questions.map((q) => q.questionId).toList();
        expect(ids.toSet().length, ids.length,
            reason: 'duplicate IDs in $source');
      }
      for (final d in ['SYNTH_DOCTRINE', 'SPARSE_DOCTRINE']) {
        final p = svc.buildForDoctrine(d)!;
        final ids = p.questions.map((q) => q.questionId).toList();
        expect(ids.toSet().length, ids.length, reason: 'duplicate IDs in $d');
      }
      final tp = svc.buildForTopic('topic_alpha')!;
      final tids = tp.questions.map((q) => q.questionId).toList();
      expect(tids.toSet().length, tids.length);
    });

    test('case questions are ordered issues-then-principles', () {
      final p = svc.buildForCase('ALPHA')!;
      final types = p.questions.map((q) => q.questionType).toList();
      expect(types.sublist(0, 2),
          [LegalQuestionType.issue, LegalQuestionType.issue]);
      expect(types.sublist(2, 4),
          [LegalQuestionType.principle, LegalQuestionType.principle]);
    });

    test('buildAll ordering is deterministic across source kinds', () {
      final all = svc.buildAll();
      expect(all, isNotEmpty);
      // Groups: cases first, then doctrines, then statutes, then topics.
      final kinds = all.map((p) => p.sourceType).toList();
      final firstCase = kinds.indexOf(QuestionSourceType.caseLaw);
      final firstDoctrine = kinds.indexOf(QuestionSourceType.doctrine);
      final firstStatute = kinds.indexOf(QuestionSourceType.statute);
      final firstTopic = kinds.indexOf(QuestionSourceType.topic);
      expect(firstCase < firstDoctrine, isTrue);
      expect(firstDoctrine < firstStatute, isTrue);
      expect(firstStatute < firstTopic, isTrue);
    });
  });

  group('G. determinism of wording', () {
    test('identical service instances produce identical question text', () {
      final a = buildSyntheticQaService().buildForCase('ALPHA')!;
      final b = buildSyntheticQaService().buildForCase('ALPHA')!;
      expect(
        a.questions.map((q) => q.questionText).toList(),
        b.questions.map((q) => q.questionText).toList(),
      );
    });
  });
}
