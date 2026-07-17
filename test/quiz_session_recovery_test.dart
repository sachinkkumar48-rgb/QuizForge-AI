import 'package:flutter_test/flutter_test.dart';
import 'package:quizforge_upsc/controllers/quiz_session_controller.dart';
import 'package:quizforge_upsc/models/quiz_attempt.dart';
import 'package:quizforge_upsc/models/quiz_model.dart';
import 'package:quizforge_upsc/models/quiz_session.dart';
import 'package:quizforge_upsc/repositories/quiz_history_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_session_repository.dart';
import 'package:quizforge_upsc/repositories/quiz_source_repository.dart';
import 'package:quizforge_upsc/models/quiz_source.dart';

class FakeQuizHistoryRepository implements QuizHistoryRepository {
  final List<QuizAttempt> attempts = [];
  @override
  Future<void> saveAttempt(QuizAttempt attempt) async => attempts.add(attempt);
  @override
  Future<List<QuizAttempt>> getAttempts() async => attempts;
  @override
  Future<void> deleteAttempt(String id) async =>
      attempts.removeWhere((e) => e.id == id);
  @override
  Future<void> clearHistory() async => attempts.clear();
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

void main() {
  late List<QuizQuestion> mockQuestions;
  late FakeQuizSessionRepository fakeSessionRepo;
  late FakeQuizHistoryRepository fakeHistoryRepo;

  setUp(() {
    fakeSessionRepo = FakeQuizSessionRepository();
    fakeHistoryRepo = FakeQuizHistoryRepository();
    QuizSessionRepository.instance = fakeSessionRepo;
    QuizHistoryRepository.instance = fakeHistoryRepo;
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

  test(
      'Auto-saves session when answer is selected, mark-for-review toggled, and question navigated',
      () async {
    final controller = QuizSessionController(
      sourceName: "Auto Save Test",
      questions: mockQuestions,
      onStateChanged: () {},
      onTimeUp: (_) {},
    );

    expect(fakeSessionRepo.activeSession, isNull);

    controller.selectAnswer("A");
    expect(fakeSessionRepo.activeSession, isNotNull);
    expect(fakeSessionRepo.activeSession!.selectedAnswers[0], "A");
    expect(fakeSessionRepo.activeSession!.questionStatuses[0],
        QuestionStatus.answered);

    controller.toggleMarkForReview();
    expect(fakeSessionRepo.activeSession!.questionStatuses[0],
        QuestionStatus.markedForReview);

    controller.nextQuestion(onFinished: (_) {});
    expect(fakeSessionRepo.activeSession!.currentQuestionIndex, 1);

    controller.dispose();
  });

  test('Session state is restored correctly', () async {
    final originalSession = QuizSession(
      sessionId: "test-session-123",
      sourceName: "Recovered Quiz",
      createdAt: DateTime(2026, 1, 1),
      lastSavedAt: DateTime(2026, 1, 1),
      totalQuestions: 2,
      currentQuestionIndex: 1,
      remainingTime: const Duration(seconds: 45),
      selectedAnswers: const {0: "A"},
      questionStatuses: const {
        0: QuestionStatus.answered,
        1: QuestionStatus.visited
      },
      quizQuestions: mockQuestions,
    );

    final controller = QuizSessionController(
      sourceName: originalSession.sourceName,
      questions: mockQuestions,
      onStateChanged: () {},
      onTimeUp: (_) {},
      restoredSession: originalSession,
    );

    expect(controller.sessionId, "test-session-123");
    expect(controller.sourceName, "Recovered Quiz");
    expect(controller.currentQuestionIndex, 1);
    expect(controller.answers[0], "A");
    expect(controller.statuses[0], QuestionStatus.answered);
    expect(controller.statuses[1], QuestionStatus.visited);
    expect(controller.remainingTime.inSeconds, 45);

    controller.dispose();
  });

  test('Session is deleted when quiz is completed (submitted)', () async {
    final controller = QuizSessionController(
      sourceName: "Deletion Test",
      questions: mockQuestions,
      onStateChanged: () {},
      onTimeUp: (_) {},
    );

    controller.selectAnswer("A");
    expect(fakeSessionRepo.activeSession, isNotNull);

    await controller.submitQuiz(onFinished: (_) {});

    expect(fakeSessionRepo.activeSession, isNull);
    expect(fakeHistoryRepo.attempts.length, 1);

    controller.dispose();
  });

  test('Auto-saves every 30 seconds', () async {
    final controller = QuizSessionController(
      sourceName: "Periodic Save Test",
      questions: mockQuestions,
      onStateChanged: () {},
      onTimeUp: (_) {},
      duration: const Duration(seconds: 40),
    );

    expect(fakeSessionRepo.activeSession, isNull);

    await controller.saveSession();
    expect(fakeSessionRepo.activeSession, isNotNull);
    expect(fakeSessionRepo.activeSession!.sourceName, "Periodic Save Test");

    controller.dispose();
  });
}
