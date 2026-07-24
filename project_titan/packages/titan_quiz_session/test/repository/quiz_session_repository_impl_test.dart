import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_quiz_session/titan_quiz_session.dart';

void main() {
  group('QuizSessionRepositoryImpl Persistence Tests', () {
    late QuizSessionRepositoryImpl repo;

    Quiz createSampleQuiz() {
      return Quiz(
        id: 'quiz_repo_1',
        title: 'Repo Test Quiz',
        description: 'Desc',
        sourceDocumentId: 'doc_1',
        difficulty: QuizDifficulty.medium,
        language: QuizLanguage.english,
        category: QuizCategory.upsc,
        questions: [
          QuizQuestion(
            id: 'q1',
            question: 'Sample Q',
            options: [
              QuizOption(id: 'opt1', text: 'Option A', isCorrect: true),
              QuizOption(id: 'opt2', text: 'Option B', isCorrect: false),
            ],
            correctAnswerIndex: 0,
          ),
        ],
      );
    }

    setUp(() {
      repo = QuizSessionRepositoryImpl();
    });

    test('Throws exception if calling methods before initialize', () async {
      final quiz = createSampleQuiz();
      expect(() => repo.createSession(quiz),
          throwsA(isA<SessionStateException>()));
    });

    test('Initializes repo, creates, loads, saves, and deletes session',
        () async {
      await repo.initialize();
      expect(repo.isInitialized, isTrue);

      final quiz = createSampleQuiz();
      final session = await repo.createSession(quiz);

      final loaded = await repo.loadSession(session.sessionId);
      expect(loaded, isNotNull);
      expect(loaded!.sessionId, equals(session.sessionId));

      final updated = session.copyWith(status: QuizSessionStatus.paused);
      await repo.saveSession(updated);

      final reloaded = await repo.loadSession(session.sessionId);
      expect(reloaded!.status, equals(QuizSessionStatus.paused));

      await repo.deleteSession(session.sessionId);
      final deleted = await repo.loadSession(session.sessionId);
      expect(deleted, isNull);
    });

    test('resumeSession and completeSession lifecycle transitions', () async {
      await repo.initialize();
      final quiz = createSampleQuiz();

      final session = await repo.createSession(quiz);
      final pausedSession = session.copyWith(status: QuizSessionStatus.paused);
      await repo.saveSession(pausedSession);

      final resumed = await repo.resumeSession(session.sessionId);
      expect(resumed.status, equals(QuizSessionStatus.inProgress));

      final summary = await repo.completeSession(session.sessionId, quiz);
      expect(summary.totalQuestions, equals(1));

      final completedSession = await repo.loadSession(session.sessionId);
      expect(completedSession!.status, equals(QuizSessionStatus.completed));
    });
  });
}
