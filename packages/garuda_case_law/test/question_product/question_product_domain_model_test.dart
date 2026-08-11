import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';

import 'synthetic_corpus.dart';

/// P15 — `QuestionKnowledgeProduct` / `LegalQuestion` / `StructuredAnswer`
/// domain-model tests (TITAN-KO-015.0 P15).
///
/// The question product is an immutable, deterministic, provenance-preserving
/// value object. These tests pin the serialization round-trip, question
/// accessors, referenced-ID aggregation, value semantics and the invariants
/// that every question/answer carries non-empty source/evidence references and
/// non-empty provenance.
///
/// Note: assert-invariant tests invoke the constructors NON-const with `const
/// []` argument lists (matching P11–P14), so the asserts run at runtime in
/// debug mode rather than failing at compile time.
void main() {
  StructuredAnswer answer() => StructuredAnswer(
        answerText: 'The court held that procedural fairness is essential.',
        evidenceRefs: const ['ALPHA', 'hol_alpha_1'],
        relatedCaseIds: const ['BETA'],
        principles: const ['Procedural fairness is essential.'],
        provenance: 'p4:holdings.legalPrinciple',
      );

  LegalQuestion question() => LegalQuestion(
        questionId: 'qa:case:ALPHA:issue:0',
        questionText:
            'In Alpha v. State (2000), what legal issue did the Court '
            'consider?',
        questionType: LegalQuestionType.issue,
        sourceRefs: const ['ALPHA', 'iss_alpha_1'],
        answer: answer(),
        provenance: 'p4:issues',
        framing: QuestionKnowledgeProductService.framing,
      );

  QuestionKnowledgeProduct product() => QuestionKnowledgeProduct(
        productId: 'qa:case:ALPHA',
        sourceType: QuestionSourceType.caseLaw,
        sourceId: 'ALPHA',
        sourceName: 'Alpha v. State',
        questions: [question()],
      );

  group('A. answer invariant', () {
    test('an answer without evidence references is rejected by assert', () {
      expect(
        () => StructuredAnswer(
          answerText: 'x',
          evidenceRefs: const [],
          provenance: 'p4:issues',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an answer without provenance is rejected by assert', () {
      expect(
        () => StructuredAnswer(
          answerText: 'x',
          evidenceRefs: const ['ALPHA'],
          provenance: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an answer with evidence and provenance is accepted', () {
      final a = answer();
      expect(a.answerText, contains('procedural fairness'));
      expect(a.evidenceRefs, ['ALPHA', 'hol_alpha_1']);
      expect(a.hasRelatedCases, isTrue);
    });
  });

  group('B. question invariant', () {
    test('a question without source references is rejected by assert', () {
      expect(
        () => LegalQuestion(
          questionId: 'x',
          questionText: 'q',
          questionType: LegalQuestionType.issue,
          sourceRefs: const [],
          answer: answer(),
          provenance: 'p4:issues',
          framing: QuestionKnowledgeProductService.framing,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a question without provenance or framing is rejected by assert', () {
      expect(
        () => LegalQuestion(
          questionId: 'x',
          questionText: 'q',
          questionType: LegalQuestionType.issue,
          sourceRefs: const ['ALPHA'],
          answer: answer(),
          provenance: '',
          framing: QuestionKnowledgeProductService.framing,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('C. referenced IDs', () {
    test('referencedIds aggregates source + answer evidence, sorted, deduped',
        () {
      final p = product();
      final expected = ['ALPHA', 'hol_alpha_1', 'iss_alpha_1', 'qa:case:ALPHA']
        ..sort();
      expect(p.referencedIds, orderedEquals(expected));
    });

    test('referencedCaseIds filters raw identifiers to validated corpus cases',
        () {
      final svc = buildSyntheticQaService();
      final p = svc.buildForCase('ALPHA')!;
      // The source case ALPHA is referenced; BETA is only a P5 related case
      // (in answer.relatedCaseIds, not in source/evidence refs).
      final caseIds = svc.referencedCaseIds(p);
      expect(caseIds, contains('ALPHA'));
      expect(caseIds, isNot(contains('BETA')));
      expect(caseIds.any((id) => id.startsWith('hol_')), isFalse);
      expect(caseIds.any((id) => id.startsWith('iss_')), isFalse);
    });

    test('questionOf returns the question or null', () {
      final p = product();
      expect(p.questionOf('qa:case:ALPHA:issue:0')!.questionText,
          contains('legal issue'));
      expect(p.questionOf('missing'), isNull);
    });
  });

  group('D. serialization round-trip', () {
    test('StructuredAnswer round-trips', () {
      final a = answer();
      expect(StructuredAnswer.fromJson(a.toJson()), a);
    });

    test('LegalQuestion round-trips', () {
      final q = question();
      expect(LegalQuestion.fromJson(q.toJson()), q);
    });

    test('QuestionKnowledgeProduct round-trips', () {
      final p = product();
      expect(QuestionKnowledgeProduct.fromJson(p.toJson()), p);
    });

    test('serialization carries the fixed kind marker', () {
      expect(product().toJson()['questionKind'],
          QuestionKnowledgeProduct.questionKind);
      expect(product().toJson()['sourceType'], 'caseLaw');
    });
  });

  group('E. equality & immutability', () {
    test('equal products are equal, unequal products are not', () {
      expect(product(), product());
      expect(
        product(),
        isNot(QuestionKnowledgeProduct(
          productId: 'qa:case:BETA',
          sourceType: QuestionSourceType.caseLaw,
          sourceId: 'BETA',
          sourceName: 'Beta v. Union',
          questions: [question()],
        )),
      );
    });

    test('service-built questions list is structurally immutable', () {
      final p = buildSyntheticQaService().buildForCase('ALPHA')!;
      expect(
          () => p.questions.add(question()), throwsA(isA<UnsupportedError>()));
    });
  });
}
