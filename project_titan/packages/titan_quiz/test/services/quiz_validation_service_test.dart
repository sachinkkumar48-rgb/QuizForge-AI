import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';

void main() {
  group('QuizValidationService and QuizValidator Rules Tests', () {
    const service = QuizValidationService();

    QuizQuestion validQuestion({
      String id = 'q1',
      String question = 'What is the capital of India?',
      int correctIndex = 0,
      double marks = 1.0,
      double negativeMarks = 0.33,
    }) {
      return QuizQuestion(
        id: id,
        question: question,
        options: [
          QuizOption(id: 'o1', text: 'New Delhi', isCorrect: correctIndex == 0),
          QuizOption(id: 'o2', text: 'Mumbai', isCorrect: correctIndex == 1),
        ],
        correctAnswerIndex: correctIndex,
        marks: marks,
        negativeMarks: negativeMarks,
      );
    }

    test('Passes validation for a fully valid quiz and question', () {
      final quiz = Quiz(
        id: 'q_valid',
        title: 'General Knowledge Quiz',
        questions: [validQuestion()],
      );

      expect(() => service.validateQuiz(quiz), returnsNormally);
      expect(service.validateQuestion(validQuestion()), isEmpty);
    });

    test('Fails when quiz title is empty or whitespace', () {
      final quiz = Quiz(
        id: 'q_bad_title',
        title: '   ',
        questions: [validQuestion()],
      );

      expect(
        () => service.validateQuiz(quiz),
        throwsA(isA<QuizValidationException>().having(
          (e) => e.validationErrors,
          'validationErrors',
          contains('Quiz title cannot be empty.'),
        )),
      );
    });

    test('Fails when quiz has no questions', () {
      final quiz = Quiz(
        id: 'q_no_q',
        title: 'Empty Quiz',
        questions: const [],
      );

      expect(
        () => service.validateQuiz(quiz),
        throwsA(isA<QuizValidationException>().having(
          (e) => e.validationErrors,
          'validationErrors',
          contains('Quiz must contain at least one question.'),
        )),
      );
    });

    test('Fails when question text is empty', () {
      final q = QuizQuestion(
        id: 'q1',
        question: '  ',
        options: const [
          QuizOption(id: 'o1', text: 'A', isCorrect: true),
          QuizOption(id: 'o2', text: 'B', isCorrect: false),
        ],
        correctAnswerIndex: 0,
      );

      final errors = service.validateQuestion(q);
      expect(errors, contains('Question text cannot be empty.'));
    });

    test('Fails when question has fewer than 2 options', () {
      final q = QuizQuestion(
        id: 'q1',
        question: 'One Option Q',
        options: const [
          QuizOption(id: 'o1', text: 'Only Option', isCorrect: true),
        ],
        correctAnswerIndex: 0,
      );

      final errors = service.validateQuestion(q);
      expect(
          errors, contains('Question must have at least 2 options (found 1).'));
    });

    test('Fails when question does not have exactly 1 correct option', () {
      // 0 correct options
      final qNoCorrect = QuizQuestion(
        id: 'q1',
        question: 'No Correct',
        options: const [
          QuizOption(id: 'o1', text: 'A', isCorrect: false),
          QuizOption(id: 'o2', text: 'B', isCorrect: false),
        ],
        correctAnswerIndex: 0,
      );

      // 2 correct options
      final qMultipleCorrect = QuizQuestion(
        id: 'q2',
        question: 'Two Correct',
        options: const [
          QuizOption(id: 'o1', text: 'A', isCorrect: true),
          QuizOption(id: 'o2', text: 'B', isCorrect: true),
        ],
        correctAnswerIndex: 0,
      );

      expect(service.validateQuestion(qNoCorrect),
          contains('Question must have exactly one correct option (found 0).'));
      expect(service.validateQuestion(qMultipleCorrect),
          contains('Question must have exactly one correct option (found 2).'));
    });

    test('Fails when correctAnswerIndex is out of bounds or mismatches option',
        () {
      final qOutOfBounds = QuizQuestion(
        id: 'q1',
        question: 'Out of bounds index',
        options: const [
          QuizOption(id: 'o1', text: 'A', isCorrect: true),
          QuizOption(id: 'o2', text: 'B', isCorrect: false),
        ],
        correctAnswerIndex: 5,
      );

      final errors = service.validateQuestion(qOutOfBounds);
      expect(
          errors,
          contains(
              'Correct answer index (5) is out of bounds for options count (2).'));
    });

    test('Fails when marks or negative marks are negative', () {
      final qNegativeMarks = validQuestion(marks: -2.0, negativeMarks: -0.5);
      final errors = service.validateQuestion(qNegativeMarks);

      expect(errors, contains('Marks must be non-negative (found -2.0).'));
      expect(errors,
          contains('Negative marks must be non-negative (found -0.5).'));
    });
  });
}
