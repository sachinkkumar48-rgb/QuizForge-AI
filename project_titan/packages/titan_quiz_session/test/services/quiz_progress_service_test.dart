import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

void main() {
  group('QuizProgressService Tests', () {
    const progressService = QuizProgressService();

    Quiz createSampleQuiz() {
      return Quiz(
        id: 'quiz_1',
        title: 'Sample Quiz',
        description: 'Desc',
        sourceDocumentId: 'doc_1',
        difficulty: QuizDifficulty.medium,
        language: QuizLanguage.english,
        category: QuizCategory.upsc,
        questions: [
          QuizQuestion(
            id: 'q1',
            question: 'Question 1',
            options: [
              QuizOption(id: 'opt1', text: 'Ans A', isCorrect: true),
              QuizOption(id: 'opt2', text: 'Ans B', isCorrect: false),
            ],
            correctAnswerIndex: 0,
          ),
          QuizQuestion(
            id: 'q2',
            question: 'Question 2',
            options: [
              QuizOption(id: 'opt3', text: 'Ans A', isCorrect: false),
              QuizOption(id: 'opt4', text: 'Ans B', isCorrect: true),
            ],
            correctAnswerIndex: 1,
          ),
        ],
      );
    }

    test(
        'Calculates answered, remaining count and completion status accurately',
        () {
      final quiz = createSampleQuiz();
      final now = DateTime.now();

      final session = QuizSession(
        sessionId: 's1',
        quizId: quiz.id,
        startedAt: now,
        lastUpdatedAt: now,
        status: QuizSessionStatus.inProgress,
        answers: [
          QuestionAttempt(
              questionId: 'q1', selectedOptionId: 'opt1', isAnswered: true),
          QuestionAttempt.unanswered('q2'),
        ],
      );

      expect(progressService.getAnsweredCount(session), equals(1));
      expect(progressService.getRemainingCount(session, quiz), equals(1));
      expect(
          progressService.calculateProgressRatio(session, quiz), equals(0.5));
      expect(progressService.calculateProgressPercentage(session, quiz),
          equals(50.0));
      expect(progressService.isCompleted(session, quiz), isFalse);
    });
  });
}
