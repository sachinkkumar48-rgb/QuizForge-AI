import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/quiz_session_controller.dart';
import 'package:quizforge_upsc/models/quiz_analytics.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';

void main() {
  late List<QuizQuestion> mockQuestions;

  setUp(() {
    QuizHistoryRepository.instance = FakeQuizHistoryRepository();
    QuizSessionRepository.instance = FakeQuizSessionRepository();
    QuizSourceRepository.instance = FakeQuizSourceRepository();
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
        onTimeUp: (analytics) {},
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
        onTimeUp: (analytics) {},
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
        onTimeUp: (analytics) {},
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
        onTimeUp: (analytics) {},
      );

      controller.nextQuestion(onFinished: (analytics) {});
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
        onTimeUp: (analytics) {},
      );

      controller.jumpToQuestion(1);
      expect(controller.currentQuestionIndex, 1);
      expect(controller.statuses[1], QuestionStatus.visited);
      controller.dispose();
    });

    test('submitQuiz calculates correct results', () async {
      bool finishedCalled = false;
      late QuizAnalytics results;

      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () {},
        duration: const Duration(seconds: 5),
        onTimeUp: (analytics) {},
      );

      controller.selectAnswer("A");

      controller.jumpToQuestion(1);
      controller.selectAnswer("C");

      await controller.submitQuiz(
        onFinished: (analytics) {
          finishedCalled = true;
          results = analytics;
        },
      );

      expect(finishedCalled, true);
      expect(results.score, 1);
      expect(results.incorrect, 1);
      expect(results.totalQuestions, 2);
      expect(results.attempted, 2);
      expect(results.skipped, 0);
      expect(results.accuracy, 50.0);
      expect(results.performanceLevel, PerformanceLevel.average);

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
        onTimeUp: (analytics) {},
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
        onTimeUp: (analytics) {},
      );

      await Future.delayed(const Duration(milliseconds: 1100));

      expect(controller.remainingTime.inSeconds, 2);
      expect(stateChangedCount, greaterThanOrEqualTo(1));
      controller.dispose();
    });

    test('Timer completion triggers onTimeUp automatically', () async {
      bool timeUpCalled = false;
      late QuizAnalytics results;

      final controller = QuizSessionController(
        questions: mockQuestions,
        onStateChanged: () {},
        duration: const Duration(seconds: 1),
        onTimeUp: (analytics) {
          timeUpCalled = true;
          results = analytics;
        },
      );

      controller.selectAnswer("A");

      await Future.delayed(const Duration(milliseconds: 1500));

      expect(timeUpCalled, true);
      expect(results.score, 1);
      expect(controller.isTimeUp, true);
      controller.dispose();
    });
  });
}

class FakeQuizHistoryRepository implements QuizHistoryRepository {
  final List<QuizAttempt> attempts = [];

  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {
    attempts.add(attempt);
  }

  @override
  Future<List<QuizAttempt>> getAttempts() async => attempts;

  @override
  Future<void> deleteAttempt(String id) async {
    attempts.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> clearHistory() async {
    attempts.clear();
  }
}

class FakeQuizSessionRepository implements QuizSessionRepository {
  QuizSession? activeSession;

  @override
  Future<void> saveSession(QuizSession session) async {
    activeSession = session;
  }

  @override
  Future<QuizSession?> loadSession() async {
    return activeSession;
  }

  @override
  Future<void> deleteSession() async {
    activeSession = null;
  }

  @override
  Future<bool> hasActiveSession() async {
    return activeSession != null;
  }
}

class FakeQuizSourceRepository implements QuizSourceRepository {
  final Map<String, QuizSource> sources = {};
  @override
  Future<void> saveSource(QuizSource source) async =>
      sources[source.id] = source;
  @override
  Future<List<QuizSource>> getSources() async => sources.values.toList();
  @override
  Future<void> updateSource(QuizSource source) async => saveSource(source);
  @override
  Future<void> deleteSource(String id) async => sources.remove(id);
  @override
  Future<void> toggleFavorite(String id) async {
    final s = sources[id];
    if (s != null) sources[id] = s.copyWith(favorite: !s.favorite);
  }
}
