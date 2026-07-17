import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/quiz_session_controller.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';

void main() {
  late List<QuizQuestion> mockQuestions;

  setUp(() {
    mockQuestions = [
      QuizQuestion(
        question: "Q1",
        options: ["A", "B", "C", "D"],
        answer: "A",
        explanation: "Exp1",
        subject: "History",
        difficulty: "Easy",
      ),
      QuizQuestion(
        question: "Q2",
        options: ["A", "B", "C", "D"],
        answer: "B",
        explanation: "Exp2",
        subject: "Geography",
        difficulty: "Medium",
      ),
    ];
  });

  group('QuizSessionController - Basic State & Navigation', () {
    test('Initial state is correct', () {
      int stateChangedCount = 0;
      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () => stateChangedCount++,
        duration: const Duration(seconds: 5),
        onTimeUp: (score, total, attempted) {},
      );

      expect(controller.currentQuestionIndex, 0);
      expect(controller.currentQuestion.question, "Q1");
      expect(controller.statuses[0], QuestionStatus.visited);
      expect(controller.statuses[1], isNull);
      expect(stateChangedCount, 0);
      controller.dispose();
    });

    test('selectAnswer updates answers and statuses', () {
      int stateChangedCount = 0;
      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () => stateChangedCount++,
        duration: const Duration(seconds: 5),
        onTimeUp: (score, total, attempted) {},
      );

      controller.selectAnswer("A");
      expect(controller.answers[0], "A");
      expect(controller.statuses[0], QuestionStatus.answered);
      expect(stateChangedCount, 1);
      controller.dispose();
    });

    test('toggleMarkForReview toggles markedForReview status correctly', () {
      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () {},
        duration: const Duration(seconds: 5),
        onTimeUp: (score, total, attempted) {},
      );

      controller.toggleMarkForReview();
      expect(controller.statuses[0], QuestionStatus.markedForReview);

      controller.toggleMarkForReview();
      expect(controller.statuses[0], QuestionStatus.visited);

      controller.selectAnswer("A");
      controller.toggleMarkForReview();
      expect(controller.statuses[0], QuestionStatus.markedForReview);

      controller.toggleMarkForReview();
      expect(controller.statuses[0], QuestionStatus.answered);

      controller.dispose();
    });

    test('previousQuestion and nextQuestion navigation', () {
      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () {},
        duration: const Duration(seconds: 5),
        onTimeUp: (score, total, attempted) {},
      );

      controller.nextQuestion(onFinished: (score, total, attempted) {});
      expect(controller.currentQuestionIndex, 1);
      expect(controller.statuses[1], QuestionStatus.visited);

      controller.previousQuestion();
      expect(controller.currentQuestionIndex, 0);

      controller.dispose();
    });

    test('jumpToQuestion jumps directly', () {
      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () {},
        duration: const Duration(seconds: 5),
        onTimeUp: (score, total, attempted) {},
      );

      controller.jumpToQuestion(1);
      expect(controller.currentQuestionIndex, 1);
      expect(controller.statuses[1], QuestionStatus.visited);
      controller.dispose();
    });

    test('submitQuiz calculates correct results', () {
      bool finishedCalled = false;
      int finalScore = 0;
      int totalQuestions = 0;
      int attemptedQuestions = 0;

      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () {},
        duration: const Duration(seconds: 5),
        onTimeUp: (score, total, attempted) {},
      );

      controller.selectAnswer("A");

      controller.jumpToQuestion(1);
      controller.selectAnswer("C");

      controller.submitQuiz(
        onFinished: (score, total, attempted) {
          finishedCalled = true;
          finalScore = score;
          totalQuestions = total;
          attemptedQuestions = attempted;
        },
      );

      expect(finishedCalled, true);
      expect(finalScore, 1);
      expect(totalQuestions, 2);
      expect(attemptedQuestions, 2);

      controller.dispose();
    });
  });

  group('QuizSessionController - Timer Logic', () {
    test('Initial duration is correct', () {
      final duration = const Duration(minutes: 5);
      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () {},
        duration: duration,
        onTimeUp: (score, total, attempted) {},
      );

      expect(controller.remainingTime.inSeconds, duration.inSeconds);
      expect(controller.formattedRemainingTime, "00:05:00");
      expect(controller.isTimeUp, false);
      controller.dispose();
    });

    test('Timer countdown tick updates remaining time', () async {
      int stateChangedCount = 0;
      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () {
          stateChangedCount++;
        },
        duration: const Duration(seconds: 3),
        onTimeUp: (score, total, attempted) {},
      );

      await Future.delayed(const Duration(milliseconds: 1100));

      expect(controller.remainingTime.inSeconds, 2);
      expect(stateChangedCount, greaterThanOrEqualTo(1));
      controller.dispose();
    });

    test('Timer completion triggers onTimeUp automatically', () async {
      bool timeUpCalled = false;
      int finalScore = -1;

      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () {},
        duration: const Duration(seconds: 1),
        onTimeUp: (score, total, attempted) {
          timeUpCalled = true;
          finalScore = score;
        },
      );

      controller.selectAnswer("A");

      await Future.delayed(const Duration(milliseconds: 1500));

      expect(timeUpCalled, true);
      expect(finalScore, 1);
      expect(controller.isTimeUp, true);
      controller.dispose();
    });
  });
}
