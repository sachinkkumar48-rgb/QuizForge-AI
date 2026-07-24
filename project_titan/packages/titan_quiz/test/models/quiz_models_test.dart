import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';

void main() {
  group('Quiz Models Immutability and Equality Tests', () {
    test('QuizOption immutability, equality, and hashCode', () {
      const opt1 = QuizOption(id: 'o1', text: 'Option 1', isCorrect: true);
      const opt2 = QuizOption(id: 'o1', text: 'Option 1', isCorrect: true);
      const opt3 = QuizOption(id: 'o1', text: 'Option 1', isCorrect: false);

      expect(opt1, equals(opt2));
      expect(opt1.hashCode, equals(opt2.hashCode));
      expect(opt1 == opt3, isFalse);
      expect(opt1.toString(), contains('Option 1'));
    });

    test('QuizQuestion immutability, equality, and unmodifiable options', () {
      final q1 = QuizQuestion(
        id: 'q1',
        question: 'Sample Question',
        options: const [
          QuizOption(id: 'o1', text: 'Opt 1', isCorrect: true),
          QuizOption(id: 'o2', text: 'Opt 2', isCorrect: false),
        ],
        correctAnswerIndex: 0,
        explanation: 'Detailed explanation',
        difficulty: QuizDifficulty.easy,
        topic: 'Polity',
        subtopic: 'Preamble',
        pageReference: 42,
        marks: 2.0,
        negativeMarks: 0.66,
      );

      final q2 = QuizQuestion(
        id: 'q1',
        question: 'Sample Question',
        options: const [
          QuizOption(id: 'o1', text: 'Opt 1', isCorrect: true),
          QuizOption(id: 'o2', text: 'Opt 2', isCorrect: false),
        ],
        correctAnswerIndex: 0,
        explanation: 'Detailed explanation',
        difficulty: QuizDifficulty.easy,
        topic: 'Polity',
        subtopic: 'Preamble',
        pageReference: 42,
        marks: 2.0,
        negativeMarks: 0.66,
      );

      expect(q1, equals(q2));
      expect(q1.hashCode, equals(q2.hashCode));

      expect(
          () => (q1.options as List)
              .add(const QuizOption(id: 'o3', text: 'Opt 3')),
          throwsUnsupportedError);
    });

    test('QuizMetadata immutability, default values, and unmodifiable tags',
        () {
      final meta1 = QuizMetadata(
        totalQuestions: 10,
        estimatedDurationMinutes: 20,
        tags: ['UPSC', 'Polity'],
      );

      expect(meta1.generatedBy, equals('TITAN AI Generator'));
      expect(meta1.version, equals('1.0.0'));
      expect(meta1.tags, equals(['UPSC', 'Polity']));
      expect(() => (meta1.tags as List).add('Extra'), throwsUnsupportedError);
    });

    test('Quiz entity copyWith, equality, and auto metadata generation', () {
      final now = DateTime.now();
      final quiz1 = Quiz(
        id: 'qz1',
        title: 'Mock Quiz 1',
        description: 'Test Description',
        sourceDocumentId: 'doc_123',
        createdAt: now,
        updatedAt: now,
        difficulty: QuizDifficulty.medium,
        language: QuizLanguage.bilingual,
        category: QuizCategory.upsc,
        questions: [
          QuizQuestion(
            id: 'q1',
            question: 'Question Text',
            options: const [
              QuizOption(id: 'o1', text: 'A', isCorrect: true),
              QuizOption(id: 'o2', text: 'B', isCorrect: false),
            ],
            correctAnswerIndex: 0,
          ),
        ],
      );

      expect(quiz1.metadata.totalQuestions, equals(1));
      expect(quiz1.metadata.estimatedDurationMinutes, equals(2));

      final quiz2 = quiz1.copyWith(title: 'Updated Quiz Title');
      expect(quiz2.title, equals('Updated Quiz Title'));
      expect(quiz2.id, equals(quiz1.id));
      expect(quiz2.questions.length, equals(1));
    });

    test('UserAnswer and QuizResult model properties', () {
      const answer = UserAnswer(questionId: 'q1', selectedOptionIndex: 2);
      expect(answer.isAnswered, isTrue);

      const unanswered = UserAnswer(questionId: 'q2');
      expect(unanswered.isAnswered, isFalse);

      final result = QuizResult(
        quizId: 'qz1',
        attempted: 2,
        correct: 1,
        wrong: 1,
        unanswered: 1,
        score: 1.34,
        maxScore: 4.0,
        percentage: 33.5,
        answers: const [answer, unanswered],
      );

      expect(result.quizId, equals('qz1'));
      expect(result.answers.length, equals(2));
      expect(result.toString(), contains('score: 1.34/4.0'));
    });
  });
}
