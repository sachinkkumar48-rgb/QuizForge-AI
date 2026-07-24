import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';

void main() {
  group('QuizStatisticsService Metrics Generation Tests', () {
    const statsService = QuizStatisticsService();

    final quiz = Quiz(
      id: 'quiz_stats_test',
      title: 'Statistics Test Quiz',
      questions: [
        QuizQuestion(
          id: 'q1',
          question: 'Question 1',
          options: const [
            QuizOption(id: 'o1', text: 'A', isCorrect: true),
            QuizOption(id: 'o2', text: 'B', isCorrect: false),
          ],
          correctAnswerIndex: 0,
          marks: 5.0,
          negativeMarks: 1.0,
        ),
        QuizQuestion(
          id: 'q2',
          question: 'Question 2',
          options: const [
            QuizOption(id: 'o1', text: 'A', isCorrect: false),
            QuizOption(id: 'o2', text: 'B', isCorrect: true),
          ],
          correctAnswerIndex: 1,
          marks: 5.0,
          negativeMarks: 1.0,
        ),
      ],
    );

    test('Generates 100% percentage result for full score', () {
      final answers = [
        const UserAnswer(questionId: 'q1', selectedOptionIndex: 0),
        const UserAnswer(questionId: 'q2', selectedOptionIndex: 1),
      ];

      final result =
          statsService.generateStatistics(quiz: quiz, answers: answers);

      expect(result.quizId, equals('quiz_stats_test'));
      expect(result.attempted, equals(2));
      expect(result.correct, equals(2));
      expect(result.wrong, equals(0));
      expect(result.unanswered, equals(0));
      expect(result.score, equals(10.0));
      expect(result.maxScore, equals(10.0));
      expect(result.percentage, equals(100.0));
    });

    test('Generates partial percentage result for 1 correct, 1 wrong', () {
      final answers = [
        const UserAnswer(questionId: 'q1', selectedOptionIndex: 0), // +5.0
        const UserAnswer(
            questionId: 'q2', selectedOptionIndex: 0), // -1.0 -> net 4.0
      ];

      final result =
          statsService.generateStatistics(quiz: quiz, answers: answers);

      expect(result.attempted, equals(2));
      expect(result.correct, equals(1));
      expect(result.wrong, equals(1));
      expect(result.unanswered, equals(0));
      expect(result.score, equals(4.0));
      expect(result.maxScore, equals(10.0));
      expect(result.percentage, equals(40.0));
    });
  });
}
