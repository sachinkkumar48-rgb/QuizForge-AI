import 'package:flutter_test/flutter_test.dart';
import 'package:titan_question_bank/titan_question_bank.dart';

void main() {
  group('Question Bank Unit Tests', () {
    late QuestionBankRepository repository;

    setUp(() {
      repository = QuestionBankRepositoryImpl();
    });

    test('getQuestions returns seeded PYQ item', () async {
      final pyqs = await repository.getQuestions(type: KmpQuestionType.pyq);
      expect(pyqs.isNotEmpty, isTrue);
      expect(pyqs.first.pyqYear, equals(2023));
    });

    test('createQuestion supports Assertion-Reason item', () async {
      final item = KmpQuestionItem(
        id: 'q_ar_1',
        topicId: 'topic_polity',
        topicName: 'Polity',
        type: KmpQuestionType.assertionReason,
        stem: 'Evaluate Assertion (A) and Reason (R).',
        assertionText:
            'The Supreme Court is the guardian of Fundamental Rights.',
        reasonText:
            'Article 32 allows citizens to directly move the Supreme Court.',
        options: [
          'Both A and R are true and R is correct explanation of A.',
          'Both A and R are true but R is NOT correct explanation.',
          'A is true but R is false.',
          'A is false but R is true.'
        ],
        correctAnswerIndex: 0,
        solutionExplanation: 'Article 32 provides constitutional remedies.',
        createdAt: DateTime.now(),
      );

      await repository.createQuestion(item);
      final fetched = await repository.getQuestionById('q_ar_1');
      expect(fetched, isNotNull);
      expect(fetched!.type, equals(KmpQuestionType.assertionReason));
    });
  });
}
