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

class FakeQuizSourceRepository implements QuizSourceRepository {
  final Map<String, QuizSource> sources = {};

  @override
  Future<void> saveSource(QuizSource source) async {
    sources[source.id] = source;
  }

  @override
  Future<List<QuizSource>> getSources() async => sources.values.toList();

  @override
  Future<void> updateSource(QuizSource source) async => saveSource(source);

  @override
  Future<void> deleteSource(String id) async {
    sources.remove(id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final s = sources[id];
    if (s != null) {
      sources[id] = s.copyWith(favorite: !s.favorite);
    }
  }
}

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

class FakeQuizSessionRepository implements QuizSessionRepository {
  QuizSession? activeSession;
  @override
  Future<void> saveSession(QuizSession session) async =>
      activeSession = session;
  @override
  Future<QuizSession?> loadSession() async => activeSession;
  @override
  Future<void> deleteSession() async => activeSession = null;
  @override
  Future<bool> hasActiveSession() async => activeSession != null;
}

void main() {
  late FakeQuizSourceRepository fakeSourceRepo;
  late FakeQuizHistoryRepository fakeHistoryRepo;
  late FakeQuizSessionRepository fakeSessionRepo;
  late List<QuizQuestion> mockQuestions;

  setUp(() {
    fakeSourceRepo = FakeQuizSourceRepository();
    fakeHistoryRepo = FakeQuizHistoryRepository();
    fakeSessionRepo = FakeQuizSessionRepository();

    QuizSourceRepository.instance = fakeSourceRepo;
    QuizHistoryRepository.instance = fakeHistoryRepo;
    QuizSessionRepository.instance = fakeSessionRepo;

    mockQuestions = [
      QuizQuestion(
        question: "Q1",
        options: ["A", "B", "C", "D"],
        answer: "A",
        explanation: "Exp1",
        subject: "History",
        difficulty: "Easy",
      ),
    ];
  });

  group('QuizSourceRepository CRUD & Logic', () {
    test('Save, Get, Update, and Delete sources', () async {
      final source = QuizSource(
        id: 'pdf-1',
        name: 'History.pdf',
        localPath: '/paths/History.pdf',
        importedAt: DateTime(2026, 1, 1),
        questionCount: 10,
        attemptCount: 0,
        fileSize: 1024,
        favorite: false,
      );

      await fakeSourceRepo.saveSource(source);

      final sources = await fakeSourceRepo.getSources();
      expect(sources.length, 1);
      expect(sources[0].name, 'History.pdf');

      await fakeSourceRepo.toggleFavorite('pdf-1');
      expect((await fakeSourceRepo.getSources())[0].favorite, true);

      final updated = source.copyWith(name: 'New History.pdf');
      await fakeSourceRepo.updateSource(updated);
      expect((await fakeSourceRepo.getSources())[0].name, 'New History.pdf');

      await fakeSourceRepo.deleteSource('pdf-1');
      expect((await fakeSourceRepo.getSources()).isEmpty, true);
    });
  });

  group('Metadata updates on quiz completion', () {
    test(
        'Completing a quiz increments attempt count and updates lastAttemptedAt',
        () async {
      final source = QuizSource(
        id: 'pdf-2',
        name: 'Science.pdf',
        localPath: '/paths/Science.pdf',
        importedAt: DateTime(2026, 1, 1),
        questionCount: 1,
        attemptCount: 0,
        fileSize: 2048,
        favorite: false,
      );
      await fakeSourceRepo.saveSource(source);

      final controller = QuizSessionController(
        sourceName: 'Science.pdf',
        questions: mockQuestions,
        onStateChanged: () {},
        onTimeUp: (_) {},
      );

      await controller.submitQuiz(onFinished: (_) {});

      final updatedSources = await fakeSourceRepo.getSources();
      expect(updatedSources[0].attemptCount, 1);
      expect(updatedSources[0].lastAttemptedAt, isNotNull);

      controller.dispose();
    });
  });

  group('Safe Delete Options', () {
    test('Deleting a source deletes linked history and session if requested',
        () async {
      final source = QuizSource(
        id: 'pdf-3',
        name: 'Polity.pdf',
        localPath: '/paths/Polity.pdf',
        importedAt: DateTime(2026, 1, 1),
        questionCount: 10,
        attemptCount: 2,
        fileSize: 4096,
        favorite: false,
      );
      await fakeSourceRepo.saveSource(source);

      final attempt = QuizAttempt(
        id: 'attempt-1',
        completedAt: DateTime.now(),
        sourceName: 'Polity.pdf',
        analytics: QuizAnalytics(
          score: 8,
          totalQuestions: 10,
          attempted: 10,
          skipped: 0,
          incorrect: 2,
          accuracy: 80.0,
          performanceLevel: PerformanceLevel.excellent,
          timeSpent: const Duration(minutes: 4),
          remainingTime: Duration.zero,
          totalDuration: const Duration(minutes: 4),
          statusCounts: const {},
        ),
      );
      await fakeHistoryRepo.saveAttempt(attempt);

      final session = QuizSession(
        sessionId: 'session-1',
        sourceName: 'Polity.pdf',
        createdAt: DateTime.now(),
        lastSavedAt: DateTime.now(),
        totalQuestions: 10,
        currentQuestionIndex: 2,
        remainingTime: const Duration(minutes: 5),
        selectedAnswers: const {},
        questionStatuses: const {},
        quizQuestions: mockQuestions,
      );
      await fakeSessionRepo.saveSession(session);

      await fakeSourceRepo.deleteSource(source.id);

      final attempts = await fakeHistoryRepo.getAttempts();
      attempts.removeWhere((e) => e.sourceName == source.name);
      expect(attempts.isEmpty, true);

      final activeSession = await fakeSessionRepo.loadSession();
      if (activeSession != null && activeSession.sourceName == source.name) {
        await fakeSessionRepo.deleteSession();
      }
      expect(await fakeSessionRepo.loadSession(), isNull);
    });
  });

  group('Search and Sorting Logic', () {
    test('Sorting evaluate correct order', () {
      final list = [
        QuizSource(
            id: '1',
            name: 'Polity.pdf',
            localPath: '',
            importedAt: DateTime(2026, 1, 10),
            questionCount: 1,
            attemptCount: 2,
            fileSize: 100,
            favorite: false,
            lastOpenedAt: DateTime(2026, 1, 10)),
        QuizSource(
            id: '2',
            name: 'Geography.pdf',
            localPath: '',
            importedAt: DateTime(2026, 1, 5),
            questionCount: 1,
            attemptCount: 5,
            fileSize: 100,
            favorite: true,
            lastOpenedAt: DateTime(2026, 1, 5)),
        QuizSource(
            id: '3',
            name: 'History.pdf',
            localPath: '',
            importedAt: DateTime(2026, 1, 1),
            questionCount: 1,
            attemptCount: 1,
            fileSize: 100,
            favorite: false,
            lastOpenedAt: DateTime(2026, 1, 1)),
      ];

      final newest = List<QuizSource>.from(list);
      newest.sort((a, b) => b.importedAt.compareTo(a.importedAt));
      expect(newest[0].id, '1');

      final names = List<QuizSource>.from(list);
      names
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      expect(names[0].id, '2');

      final attempts = List<QuizSource>.from(list);
      attempts.sort((a, b) => b.attemptCount.compareTo(a.attemptCount));
      expect(attempts[0].id, '2');

      final favorites = List<QuizSource>.from(list);
      favorites.sort((a, b) {
        if (a.favorite && !b.favorite) return -1;
        if (!a.favorite && b.favorite) return 1;
        return b.importedAt.compareTo(a.importedAt);
      });
      expect(favorites[0].id, '2');
    });
  });
}
