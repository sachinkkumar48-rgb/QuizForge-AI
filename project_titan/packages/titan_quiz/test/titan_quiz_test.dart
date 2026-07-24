import 'package:test/test.dart';
import 'package:titan_core/titan_core.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_storage/titan_storage.dart';

class _MockStorageService implements StorageService {
  bool _initialized = false;
  final Map<String, dynamic> _store = {};

  @override
  bool get isInitialized => _initialized;
  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> contains(StorageKey key) async =>
      _store.containsKey(key.qualifiedKey);

  @override
  Future<T?> read<T>(StorageKey key) async => _store[key.qualifiedKey] as T?;

  @override
  Future<StorageEntry<T>?> readEntry<T>(StorageKey key) async => null;

  @override
  Future<void> write<T>(StorageKey key, T value) async {
    _store[key.qualifiedKey] = value;
  }

  @override
  Future<void> delete(StorageKey key) async {
    _store.remove(key.qualifiedKey);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<List<StorageKey>> keys({String? namespace}) async {
    final result = <StorageKey>[];
    for (final k in _store.keys) {
      if (namespace == null || k.startsWith('$namespace:')) {
        final id = k.contains(':') ? k.split(':').last : k;
        result.add(StorageKey(id, namespace: namespace ?? 'default'));
      }
    }
    return result;
  }

  @override
  Future<void> close() async {
    _initialized = false;
  }
}

void main() {
  group('Titan Quiz Domain Module Foundation Tests', () {
    late TitanServiceLocator locator;
    late _MockStorageService mockStorage;

    setUp(() {
      locator = TitanServiceLocator.instance;
      locator.reset();

      mockStorage = _MockStorageService();
    });

    tearDown(() {
      locator.reset();
    });

    QuizQuestion sampleQuestion({
      required String id,
      required String questionText,
      int correctIndex = 0,
      double marks = 2.0,
      double negativeMarks = 0.66,
    }) {
      return QuizQuestion(
        id: id,
        question: questionText,
        options: [
          QuizOption(
              id: '${id}_opt_0',
              text: 'Option A',
              isCorrect: correctIndex == 0),
          QuizOption(
              id: '${id}_opt_1',
              text: 'Option B',
              isCorrect: correctIndex == 1),
          QuizOption(
              id: '${id}_opt_2',
              text: 'Option C',
              isCorrect: correctIndex == 2),
          QuizOption(
              id: '${id}_opt_3',
              text: 'Option D',
              isCorrect: correctIndex == 3),
        ],
        correctAnswerIndex: correctIndex,
        marks: marks,
        negativeMarks: negativeMarks,
      );
    }

    test(
        '1. QuizValidationService asserts title, questions count, options count, and single correct option',
        () {
      const validator = QuizValidationService();

      final validQuiz = Quiz(
        id: 'quiz_valid_1',
        title: 'UPSC Indian Polity Mock Test',
        questions: [
          sampleQuestion(id: 'q1', questionText: 'What is Article 32?')
        ],
      );

      expect(() => validator.validateQuiz(validQuiz), returnsNormally);

      // Empty title
      final invalidTitleQuiz = Quiz(
        id: 'quiz_invalid_1',
        title: '   ',
        questions: [sampleQuestion(id: 'q1', questionText: 'Valid Q')],
      );
      expect(
        () => validator.validateQuiz(invalidTitleQuiz),
        throwsA(isA<QuizValidationException>().having(
            (QuizValidationException e) => e.validationErrors.first,
            'error',
            contains('title'))),
      );

      // Empty questions list
      final noQuestionsQuiz = Quiz(
        id: 'quiz_invalid_2',
        title: 'Empty Quiz',
        questions: const [],
      );
      expect(
        () => validator.validateQuiz(noQuestionsQuiz),
        throwsA(isA<QuizValidationException>().having(
            (QuizValidationException e) => e.validationErrors.first,
            'error',
            contains('at least one question'))),
      );

      // Question with zero correct options
      final noCorrectQuestion = QuizQuestion(
        id: 'q_bad',
        question: 'Bad Question?',
        options: const [
          QuizOption(id: 'o1', text: 'A', isCorrect: false),
          QuizOption(id: 'o2', text: 'B', isCorrect: false),
        ],
        correctAnswerIndex: 0,
      );
      final badQuestionQuiz = Quiz(
        id: 'quiz_invalid_3',
        title: 'Bad Q Quiz',
        questions: [noCorrectQuestion],
      );
      expect(
        () => validator.validateQuiz(badQuestionQuiz),
        throwsA(isA<QuizValidationException>().having(
            (QuizValidationException e) => e.validationErrors.first,
            'error',
            contains('exactly one correct option'))),
      );
    });

    test(
        '2. QuizScoringService correctly evaluates correct, wrong, unanswered, and negative marking',
        () {
      const scoringService = QuizScoringService();
      final quiz = Quiz(
        id: 'quiz_score_1',
        title: 'History Quiz',
        questions: [
          sampleQuestion(
              id: 'q1',
              questionText: 'Q1',
              correctIndex: 0,
              marks: 2.0,
              negativeMarks: 0.5),
          sampleQuestion(
              id: 'q2',
              questionText: 'Q2',
              correctIndex: 1,
              marks: 2.0,
              negativeMarks: 0.5),
          sampleQuestion(
              id: 'q3',
              questionText: 'Q3',
              correctIndex: 2,
              marks: 2.0,
              negativeMarks: 0.5),
        ],
      );

      final answers = [
        const UserAnswer(
            questionId: 'q1', selectedOptionIndex: 0), // Correct (+2.0)
        const UserAnswer(
            questionId: 'q2', selectedOptionIndex: 0), // Wrong (-0.5)
        const UserAnswer(
            questionId: 'q3', selectedOptionIndex: null), // Unanswered (0)
      ];

      final eval = scoringService.evaluateAnswers(quiz: quiz, answers: answers);

      expect(eval['attempted'], equals(2));
      expect(eval['correct'], equals(1));
      expect(eval['wrong'], equals(1));
      expect(eval['unanswered'], equals(1));
      expect(eval['score'], equals(1.5)); // 2.0 - 0.5 = 1.5
      expect(eval['maxScore'], equals(6.0));
    });

    test(
        '3. QuizStatisticsService generates accurate QuizResult percentage metrics',
        () {
      const statsService = QuizStatisticsService();
      final quiz = Quiz(
        id: 'quiz_stats_1',
        title: 'Geography Quiz',
        questions: [
          sampleQuestion(
              id: 'q1',
              questionText: 'Q1',
              correctIndex: 0,
              marks: 4.0,
              negativeMarks: 1.0),
          sampleQuestion(
              id: 'q2',
              questionText: 'Q2',
              correctIndex: 1,
              marks: 4.0,
              negativeMarks: 1.0),
        ],
      );

      final answers = [
        const UserAnswer(
            questionId: 'q1', selectedOptionIndex: 0), // Correct (+4.0)
        const UserAnswer(
            questionId: 'q2', selectedOptionIndex: 1), // Correct (+4.0)
      ];

      final result =
          statsService.generateStatistics(quiz: quiz, answers: answers);

      expect(result.quizId, equals('quiz_stats_1'));
      expect(result.attempted, equals(2));
      expect(result.correct, equals(2));
      expect(result.wrong, equals(0));
      expect(result.unanswered, equals(0));
      expect(result.score, equals(8.0));
      expect(result.maxScore, equals(8.0));
      expect(result.percentage, equals(100.0));
    });

    test('4. QuizRepositoryImpl CRUD operations and storage persistence',
        () async {
      final repo = QuizRepositoryImpl(
        storageService: mockStorage,
      );

      await repo.initialize();
      expect(repo.isInitialized, isTrue);

      final createdQuiz = await repo.createQuiz(
        title: 'UPSC Prelims Mock 2026',
        category: QuizCategory.upsc,
        difficulty: QuizDifficulty.hard,
        questions: [
          sampleQuestion(
              id: 'q1',
              questionText: 'Which article deals with Fundamental Duties?')
        ],
      );

      expect(createdQuiz.id.isNotEmpty, isTrue);
      expect(createdQuiz.title, equals('UPSC Prelims Mock 2026'));

      final loadedQuiz = await repo.loadQuiz(createdQuiz.id);
      expect(loadedQuiz, isNotNull);
      expect(loadedQuiz!.id, equals(createdQuiz.id));

      final allQuizzes = await repo.listQuizzes();
      expect(allQuizzes.length, equals(1));
      expect(allQuizzes.first.id, equals(createdQuiz.id));

      await repo.deleteQuiz(createdQuiz.id);
      final afterDelete = await repo.loadQuiz(createdQuiz.id);
      expect(afterDelete, isNull);
    });

    test(
        '5. TitanQuizBootstrap validates dependencies and registers components in TitanServiceLocator',
        () async {
      final bootstrap = TitanQuizBootstrap();

      // Missing registered services throws exception
      expect(
        () => bootstrap.validate(),
        throwsA(isA<TitanMissingDependencyException>()),
      );

      locator.registerSingleton<StorageService>(mockStorage);

      expect(bootstrap.isInitialized, isFalse);
      await bootstrap.initialize();
      expect(bootstrap.isInitialized, isTrue);

      expect(locator.isRegistered<QuizRepository>(), isTrue);
      expect(locator.isRegistered<QuizValidationService>(), isTrue);
      expect(locator.isRegistered<QuizScoringService>(), isTrue);
      expect(locator.isRegistered<QuizStatisticsService>(), isTrue);

      final quizRepo = locator.get<QuizRepository>();
      expect(quizRepo, isA<QuizRepositoryImpl>());

      await bootstrap.dispose();
      expect(bootstrap.isInitialized, isFalse);
      expect(locator.isRegistered<QuizRepository>(), isFalse);
    });
  });
}
