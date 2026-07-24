import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';

void main() {
  group('QuizScoringService Logic Tests', () {
    const service = QuizScoringService();

    final quiz = Quiz(
      id: 'quiz_score',
      title: 'Scoring Test Quiz',
      questions: [
        QuizQuestion(
          id: 'q1',
          question: 'Q1 (2 marks, 0.66 neg)',
          options: const [
            QuizOption(id: 'o1', text: 'A', isCorrect: true),
            QuizOption(id: 'o2', text: 'B', isCorrect: false),
          ],
          correctAnswerIndex: 0,
          marks: 2.0,
          negativeMarks: 0.66,
        ),
        QuizQuestion(
          id: 'q2',
          question: 'Q2 (3 marks, 1.0 neg)',
          options: const [
            QuizOption(id: 'o1', text: 'A', isCorrect: false),
            QuizOption(id: 'o2', text: 'B', isCorrect: true),
          ],
          correctAnswerIndex: 1,
          marks: 3.0,
          negativeMarks: 1.0,
        ),
        QuizQuestion(
          id: 'q3',
          question: 'Q3 (5 marks, 1.5 neg)',
          options: const [
            QuizOption(id: 'o1', text: 'A', isCorrect: true),
            QuizOption(id: 'o2', text: 'B', isCorrect: false),
          ],
          correctAnswerIndex: 0,
          marks: 5.0,
          negativeMarks: 1.5,
        ),
      ],
    );

    test('Evaluates all correct answers', () {
      final answers = [
        const UserAnswer(questionId: 'q1', selectedOptionIndex: 0),
        const UserAnswer(questionId: 'q2', selectedOptionIndex: 1),
        const UserAnswer(questionId: 'q3', selectedOptionIndex: 0),
      ];

      final eval = service.evaluateAnswers(quiz: quiz, answers: answers);
      expect(eval['attempted'], equals(3));
      expect(eval['correct'], equals(3));
      expect(eval['wrong'], equals(0));
      expect(eval['unanswered'], equals(0));
      expect(eval['score'], equals(10.0)); // 2 + 3 + 5
      expect(eval['maxScore'], equals(10.0));
    });

    test(
        'Evaluates mixed correct, wrong, and unanswered answers with custom negative marking',
        () {
      final answers = [
        const UserAnswer(
            questionId: 'q1', selectedOptionIndex: 0), // Correct (+2.0)
        const UserAnswer(
            questionId: 'q2', selectedOptionIndex: 0), // Wrong (-1.0)
        const UserAnswer(
            questionId: 'q3', selectedOptionIndex: null), // Unanswered (0)
      ];

      final eval = service.evaluateAnswers(quiz: quiz, answers: answers);
      expect(eval['attempted'], equals(2));
      expect(eval['correct'], equals(1));
      expect(eval['wrong'], equals(1));
      expect(eval['unanswered'], equals(1));
      expect(eval['score'], equals(1.0)); // 2.0 - 1.0 = 1.0
      expect(eval['maxScore'], equals(10.0));
    });

    test('Evaluates all wrong answers resulting in negative net score', () {
      final answers = [
        const UserAnswer(
            questionId: 'q1', selectedOptionIndex: 1), // Wrong (-0.66)
        const UserAnswer(
            questionId: 'q2', selectedOptionIndex: 0), // Wrong (-1.0)
        const UserAnswer(
            questionId: 'q3', selectedOptionIndex: 1), // Wrong (-1.5)
      ];

      final eval = service.evaluateAnswers(quiz: quiz, answers: answers);
      expect(eval['attempted'], equals(3));
      expect(eval['correct'], equals(0));
      expect(eval['wrong'], equals(3));
      expect(eval['unanswered'], equals(0));
      expect(eval['score'], closeTo(-3.16, 0.001)); // -0.66 - 1.0 - 1.5
    });
  });
}
