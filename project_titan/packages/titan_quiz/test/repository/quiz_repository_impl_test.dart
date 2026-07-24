import 'package:test/test.dart';
import 'package:titan_quiz/titan_quiz.dart';
import 'package:titan_storage/titan_storage.dart';

class MemoryStorageService implements StorageService {
  bool _initialized = false;
  final Map<String, dynamic> _data = {};

  @override
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<bool> contains(StorageKey key) async =>
      _data.containsKey(key.qualifiedKey);

  @override
  Future<T?> read<T>(StorageKey key) async => _data[key.qualifiedKey] as T?;

  @override
  Future<StorageEntry<T>?> readEntry<T>(StorageKey key) async => null;

  @override
  Future<void> write<T>(StorageKey key, T value) async {
    _data[key.qualifiedKey] = value;
  }

  @override
  Future<void> delete(StorageKey key) async {
    _data.remove(key.qualifiedKey);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<List<StorageKey>> keys({String? namespace}) async {
    final result = <StorageKey>[];
    for (final k in _data.keys) {
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
  group('QuizRepositoryImpl Lifecycle and CRUD Operations Tests', () {
    late MemoryStorageService storage;
    late QuizRepositoryImpl repo;

    setUp(() {
      storage = MemoryStorageService();
      repo = QuizRepositoryImpl(storageService: storage);
    });

    QuizQuestion sampleQ() => QuizQuestion(
          id: 'q1',
          question: 'Sample Question Text',
          options: const [
            QuizOption(id: 'o1', text: 'Opt 1', isCorrect: true),
            QuizOption(id: 'o2', text: 'Opt 2', isCorrect: false),
          ],
          correctAnswerIndex: 0,
        );

    test('Throws exception when calling methods on uninitialized repository',
        () async {
      expect(repo.isInitialized, isFalse);
      expect(() => repo.listQuizzes(), throwsA(isA<QuizRepositoryException>()));
    });

    test('Initializes repository and auto-initializes storage service',
        () async {
      expect(storage.isInitialized, isFalse);
      await repo.initialize();
      expect(repo.isInitialized, isTrue);
      expect(storage.isInitialized, isTrue);
    });

    test('Create, load, list, save, and delete quiz lifecycle', () async {
      await repo.initialize();

      // Create
      final quiz = await repo.createQuiz(
        title: 'BPSC Prelims Practice',
        category: QuizCategory.bpsc,
        difficulty: QuizDifficulty.medium,
        language: QuizLanguage.hindi,
        questions: [sampleQ()],
      );

      expect(quiz.id, isNotEmpty);
      expect(quiz.title, equals('BPSC Prelims Practice'));
      expect(quiz.category, equals(QuizCategory.bpsc));

      // Load
      final loaded = await repo.loadQuiz(quiz.id);
      expect(loaded, isNotNull);
      expect(loaded!.title, equals('BPSC Prelims Practice'));
      expect(loaded.questions.length, equals(1));

      // List
      final all = await repo.listQuizzes();
      expect(all.length, equals(1));

      // Save updated
      final updated = quiz.copyWith(title: 'BPSC Prelims Updated');
      await repo.saveQuiz(updated);
      final reloaded = await repo.loadQuiz(quiz.id);
      expect(reloaded!.title, equals('BPSC Prelims Updated'));

      // Delete
      await repo.deleteQuiz(quiz.id);
      final afterDelete = await repo.loadQuiz(quiz.id);
      expect(afterDelete, isNull);
    });

    test('Throws QuizValidationException when attempting to save invalid quiz',
        () async {
      await repo.initialize();
      final invalidQuiz = Quiz(
        id: 'bad_quiz',
        title: '   ', // invalid
        questions: [sampleQ()],
      );

      expect(() => repo.saveQuiz(invalidQuiz),
          throwsA(isA<QuizValidationException>()));
    });

    test('Throws QuizRepositoryException when called after dispose', () async {
      await repo.initialize();
      await repo.dispose();
      expect(repo.isInitialized, isFalse);

      expect(() => repo.loadQuiz('some_id'),
          throwsA(isA<QuizRepositoryException>()));
    });
  });
}
