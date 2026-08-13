import 'package:flutter_test/flutter_test.dart';
import 'package:garuda_case_law/garuda_case_law.dart';
import 'package:garuda_learning/garuda_learning.dart';

void main() {
  group('Answer Evaluators Tests (TITAN-KO-018.0 P18)', () {
    late LegalQuestion mcQuestion;
    late LegalQuestion tfQuestion;
    late LegalQuestion shortQuestion;
    late LegalQuestion essayQuestion;

    setUp(() {
      mcQuestion = LegalQuestion(
        questionId: 'q_mc_01',
        questionText: 'Which case established the Basic Structure Doctrine?',
        questionType: LegalQuestionType.doctrine,
        sourceRefs: const ['KESAVANANDA'],
        answer: StructuredAnswer(
          answerText: 'Kesavananda Bharati v. State of Kerala (1973)',
          evidenceRefs: const ['AIR 1973 SC 1461'],
          provenance: 'p11:case_explanation',
        ),
        provenance: 'p15:question',
        framing: QuestionKnowledgeProductService.framing,
      );

      tfQuestion = LegalQuestion(
        questionId: 'q_tf_01',
        questionText:
            'True or False: Article 21 can be suspended during a National Emergency.',
        questionType: LegalQuestionType.statute,
        sourceRefs: const ['21'],
        answer: StructuredAnswer(
          answerText: 'False',
          evidenceRefs: const ['44th Amendment Act 1978'],
          provenance: 'p13:statute_product',
        ),
        provenance: 'p15:question',
        framing: QuestionKnowledgeProductService.framing,
      );

      shortQuestion = LegalQuestion(
        questionId: 'q_sa_01',
        questionText:
            'What standard replaces procedure established by law in Article 21?',
        questionType: LegalQuestionType.issue,
        sourceRefs: const ['MANEKA_GANDHI'],
        answer: StructuredAnswer(
          answerText:
              'Due Process of Law and Procedure established by law must be just, fair and reasonable.',
          evidenceRefs: const ['MANEKA_GANDHI'],
          principles: const [
            'due process',
            'just fair reasonable',
            'procedure established by law'
          ],
          provenance: 'p4:holdings',
        ),
        provenance: 'p15:question',
        framing: QuestionKnowledgeProductService.framing,
      );

      essayQuestion = LegalQuestion(
        questionId: 'q_essay_01',
        questionText:
            'Critically analyze the evolution of judicial review under Article 368.',
        questionType: LegalQuestionType.issue,
        sourceRefs: const ['KESAVANANDA', 'MINERVA_MILLS'],
        answer: StructuredAnswer(
          answerText:
              'Detailed essay response analyzing Kesavananda, Minerva Mills, and I.R. Coelho.',
          evidenceRefs: const ['P11 Corpus'],
          provenance: 'p11:essay',
        ),
        provenance: 'p15:question',
        framing: QuestionKnowledgeProductService.framing,
      );
    });

    group('MultipleChoiceEvaluator', () {
      const evaluator = MultipleChoiceEvaluator();

      test('Supported method is multipleChoice', () {
        expect(
            evaluator.supportedMethod, equals(EvaluationMethod.multipleChoice));
      });

      test('Exact answer text match returns correct result (score 1.0)', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_mc_1',
          learnerId: 'l1',
          questionId: mcQuestion.questionId,
          objectiveId: 'lo_basic_structure',
          submittedAnswer: 'Kesavananda Bharati v. State of Kerala (1973)',
        );

        final result =
            evaluator.evaluate(attempt: attempt, question: mcQuestion);
        expect(result.isCorrect, isTrue);
        expect(result.score, equals(1.0));
        expect(
            result.evaluationMethod, equals(EvaluationMethod.multipleChoice));
      });

      test('Case-insensitive match returns correct result', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_mc_2',
          learnerId: 'l1',
          questionId: mcQuestion.questionId,
          objectiveId: 'lo_basic_structure',
          submittedAnswer: 'kesavananda bharati v. state of kerala (1973)',
        );

        final result =
            evaluator.evaluate(attempt: attempt, question: mcQuestion);
        expect(result.isCorrect, isTrue);
        expect(result.score, equals(1.0));
      });

      test('Single option letter matching leading text works', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_mc_3',
          learnerId: 'l1',
          questionId: mcQuestion.questionId,
          objectiveId: 'lo_basic_structure',
          submittedAnswer: 'K',
        );

        final result =
            evaluator.evaluate(attempt: attempt, question: mcQuestion);
        expect(result.isCorrect, isTrue);
        expect(result.score, equals(1.0));
      });

      test('Incorrect answer returns score 0.0', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_mc_4',
          learnerId: 'l1',
          questionId: mcQuestion.questionId,
          objectiveId: 'lo_basic_structure',
          submittedAnswer: 'Golaknath v. State of Punjab',
        );

        final result =
            evaluator.evaluate(attempt: attempt, question: mcQuestion);
        expect(result.isCorrect, isFalse);
        expect(result.score, equals(0.0));
      });
    });

    group('TrueFalseEvaluator', () {
      const evaluator = TrueFalseEvaluator();

      test('Supported method is trueFalse', () {
        expect(evaluator.supportedMethod, equals(EvaluationMethod.trueFalse));
      });

      test('Correct boolean match ("False" vs "false") returns score 1.0', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_tf_1',
          learnerId: 'l1',
          questionId: tfQuestion.questionId,
          objectiveId: 'lo_art21',
          submittedAnswer: 'false',
        );

        final result =
            evaluator.evaluate(attempt: attempt, question: tfQuestion);
        expect(result.isCorrect, isTrue);
        expect(result.score, equals(1.0));
        expect(result.evaluationMethod, equals(EvaluationMethod.trueFalse));
      });

      test(
          'Correct normalized boolean variations ("f", "0", "no") return correct',
          () {
        for (final input in ['f', '0', 'no', 'False', 'FALSE']) {
          final attempt = QuestionAttempt(
            attemptId: 'att_tf_$input',
            learnerId: 'l1',
            questionId: tfQuestion.questionId,
            objectiveId: 'lo_art21',
            submittedAnswer: input,
          );

          final result =
              evaluator.evaluate(attempt: attempt, question: tfQuestion);
          expect(result.isCorrect, isTrue, reason: 'Failed for input: $input');
          expect(result.score, equals(1.0));
        }
      });

      test('Incorrect boolean response returns score 0.0', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_tf_err',
          learnerId: 'l1',
          questionId: tfQuestion.questionId,
          objectiveId: 'lo_art21',
          submittedAnswer: 'true',
        );

        final result =
            evaluator.evaluate(attempt: attempt, question: tfQuestion);
        expect(result.isCorrect, isFalse);
        expect(result.score, equals(0.0));
      });
    });

    group('ShortAnswerEvaluator', () {
      const evaluator = ShortAnswerEvaluator();

      test('Supported method is shortAnswerKeyword', () {
        expect(evaluator.supportedMethod,
            equals(EvaluationMethod.shortAnswerKeyword));
      });

      test('Empty submission returns score 0.0', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_sa_0',
          learnerId: 'l1',
          questionId: shortQuestion.questionId,
          objectiveId: 'lo_art21',
          submittedAnswer: '   ',
        );

        final result =
            evaluator.evaluate(attempt: attempt, question: shortQuestion);
        expect(result.isCorrect, isFalse);
        expect(result.score, equals(0.0));
      });

      test('Matching keywords returns non-zero score', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_sa_1',
          learnerId: 'l1',
          questionId: shortQuestion.questionId,
          objectiveId: 'lo_art21',
          submittedAnswer:
              'due process of law must be just, fair and reasonable',
        );

        final result =
            evaluator.evaluate(attempt: attempt, question: shortQuestion);
        expect(result.score, greaterThan(0.0));
        expect(result.evaluationMethod,
            equals(EvaluationMethod.shortAnswerKeyword));
      });

      test('Custom required keywords evaluator works deterministically', () {
        const customEvaluator = ShortAnswerEvaluator(
          requiredKeywords: ['due process', 'reasonable'],
        );

        final attempt1 = QuestionAttempt(
          attemptId: 'att_c1',
          learnerId: 'l1',
          questionId: shortQuestion.questionId,
          objectiveId: 'lo_art21',
          submittedAnswer: 'due process requires reasonable procedure',
        );

        final result1 = customEvaluator.evaluate(
            attempt: attempt1, question: shortQuestion);
        expect(result1.isCorrect, isTrue);
        expect(result1.score, equals(1.0));

        final attempt2 = QuestionAttempt(
          attemptId: 'att_c2',
          learnerId: 'l1',
          questionId: shortQuestion.questionId,
          objectiveId: 'lo_art21',
          submittedAnswer: 'procedure established by law only',
        );

        final result2 = customEvaluator.evaluate(
            attempt: attempt2, question: shortQuestion);
        expect(result2.isCorrect, isFalse);
        expect(result2.score, equals(0.0));
      });
    });

    group('ManualEvaluator', () {
      const evaluator = ManualEvaluator();

      test('Supported method is manual', () {
        expect(evaluator.supportedMethod, equals(EvaluationMethod.manual));
      });

      test('Essay question evaluation is explicitly non-automated', () {
        final attempt = QuestionAttempt(
          attemptId: 'att_essay_1',
          learnerId: 'l1',
          questionId: essayQuestion.questionId,
          objectiveId: 'lo_basic_structure',
          submittedAnswer: 'Detailed legal essay on Article 368...',
        );

        final result =
            evaluator.evaluate(attempt: attempt, question: essayQuestion);
        expect(result.isCorrect, isFalse);
        expect(result.score, equals(0.0));
        expect(result.evaluationMethod, equals(EvaluationMethod.manual));
        expect(result.feedback, contains('Manual evaluation required'));
        expect(result.feedback, contains('disabled'));
      });
    });
  });
}
