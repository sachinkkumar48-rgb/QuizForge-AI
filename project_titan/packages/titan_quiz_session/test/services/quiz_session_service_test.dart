import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

void main() {
  group('QuizSessionService Lifecycle and Action Tests', () {
    const sessionService = QuizSessionService();

    Quiz createSampleQuiz() {
      return Quiz(
        id: 'quiz_polity',
        title: 'Polity Quiz',
        description: 'Test on Polity',
        sourceDocumentId: 'doc_polity',
        difficulty: QuizDifficulty.medium,
        language: QuizLanguage.english,
        category: QuizCategory.upsc,
        questions: [
          QuizQuestion(
            id: 'q1',
            question: 'What is Article 14?',
            options: [
              QuizOption(id: 'opt1_1', text: 'Equality', isCorrect: true),
              QuizOption(id: 'opt1_2', text: 'Freedom', isCorrect: false),
            ],
            correctAnswerIndex: 0,
            marks: 2.0,
            negativeMarks: 0.66,
          ),
          QuizQuestion(
            id: 'q2',
            question: 'What is Article 21?',
            options: [
              QuizOption(id: 'opt2_1', text: 'Education', isCorrect: false),
              QuizOption(id: 'opt2_2', text: 'Life', isCorrect: true),
            ],
            correctAnswerIndex: 1,
            marks: 2.0,
            negativeMarks: 0.66,
          ),
        ],
      );
    }

    test('startSession initializes session inProgress with unanswered attempts',
        () {
      final quiz = createSampleQuiz();
      final session = sessionService.startSession(quiz);

      expect(session.status, equals(QuizSessionStatus.inProgress));
      expect(session.quizId, equals(quiz.id));
      expect(session.currentQuestionIndex, equals(0));
      expect(session.answers.length, equals(2));
      expect(session.answers.every((a) => !a.isAnswered), isTrue);
    });

    test('pauseSession and resumeSession update session state', () {
      final quiz = createSampleQuiz();
      var session = sessionService.startSession(quiz);

      session = sessionService.pauseSession(session);
      expect(session.status, equals(QuizSessionStatus.paused));

      session = sessionService.resumeSession(session);
      expect(session.status, equals(QuizSessionStatus.inProgress));
    });

    test('answerQuestion records user choice and timestamp', () {
      final quiz = createSampleQuiz();
      var session = sessionService.startSession(quiz);

      session = sessionService.answerQuestion(session, quiz, 'q1', 'opt1_1');
      expect(session.answers[0].isAnswered, isTrue);
      expect(session.answers[0].selectedOptionId, equals('opt1_1'));
    });

    test('moveNext and movePrevious update question index correctly', () {
      final quiz = createSampleQuiz();
      var session = sessionService.startSession(quiz);

      session = sessionService.moveNext(session, quiz);
      expect(session.currentQuestionIndex, equals(1));

      session = sessionService.movePrevious(session, quiz);
      expect(session.currentQuestionIndex, equals(0));

      expect(() => sessionService.movePrevious(session, quiz),
          throwsA(isA<ProgressException>()));
    });

    test('completeSession evaluates scores and returns QuizResultSummary', () {
      final quiz = createSampleQuiz();
      var session = sessionService.startSession(quiz);

      // Answer q1 correctly, q2 incorrectly
      session = sessionService.answerQuestion(
          session, quiz, 'q1', 'opt1_1'); // Correct (+2.0)
      session = sessionService.answerQuestion(
          session, quiz, 'q2', 'opt2_1'); // Incorrect (-0.66)

      final summary = sessionService.completeSession(session, quiz);

      expect(summary.totalQuestions, equals(2));
      expect(summary.attempted, equals(2));
      expect(summary.correct, equals(1));
      expect(summary.wrong, equals(1));
      expect(summary.unanswered, equals(0));
      expect(summary.score, closeTo(1.34, 0.01));
      expect(summary.maxScore, equals(4.0));
    });
  });
}
